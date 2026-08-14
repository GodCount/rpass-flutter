use std::char;
use std::collections::HashMap;
use std::io::Write;
use std::sync::{Arc, RwLock};
use std::{collections::HashSet, fs::File};

use flutter_rust_bridge::{frb, BaseAsyncRuntime, DartFnFuture};
use keepass::db::{AttachmentId, CustomIconId, EntryId, GroupId, GroupRef, Value};
use keepass::{
    config::{DatabaseConfig, KdfConfig as KdfConfig2},
    db::{uuid_by_str, EntryRef, Uuid},
    Database, DatabaseKey,
};

use chrono::{DateTime, NaiveDateTime};
pub use keepass::{
    config::{
        CompressionConfig, InnerCipherConfig, OuterCipherConfig, VariantDictionaryValue,
        Version as Argon2Version,
    },
    db::{
        merge::{MergeEventTarget as MergeEventTarget2, MergeEventType, MergeLog as MergeLog2},
        AutoType, AutoTypeAssociation, Color, CustomDataItem, CustomDataValue,
        DataTransferObfuscation, MemoryProtection, Times,
    },
};
use log::{info, warn};
use utils_proc_macro::frb_string_constant;
use zeroize::Zeroize;

use crate::api::kdbx::KdbxAction::UpdateSyncEntry;
use crate::api::utils::{contains_domain, random_bytes, simple_to_domain, transform_xor};
use crate::frb_generated::FLUTTER_RUST_BRIDGE_HANDLER;

frb_string_constant! {
    KdbxKey {
        KEY_TITLE = "Title",
        KEY_URL = "URL",
        KEY_URL1 = "URL1",
        KEY_URL2 = "URL2",
        KEY_URL3 = "URL3",
        KEY_URL4 = "URL4",
        KEY_URL5 = "URL5",
        KEY_USER_NAME = "UserName",
        KEY_EMAIL = "Email",
        KEY_PASSWORD = "Password",
        KEY_NOTES = "Notes",
        KEY_OTP = "OTPAuth",

        SPECIAL_KEY_TAGS = "Tags",
        SPECIAL_KEY_ATTACH = "Attach",
        SPECIAL_KEY_EXPIRES = "Expires",
        SPECIAL_KEY_AUTO_TYPE = "AutoType",
        SPECIAL_KEY_AUTO_FILL_PACKAGE_NAME = "AutoFillPackageName",
    }
}

const KDBX_KEY_ALL: [&str; 17] = [
    KEY_TITLE,
    KEY_URL,
    KEY_URL1,
    KEY_URL2,
    KEY_URL3,
    KEY_URL4,
    KEY_URL5,
    KEY_USER_NAME,
    KEY_EMAIL,
    KEY_PASSWORD,
    KEY_NOTES,
    KEY_OTP,
    SPECIAL_KEY_TAGS,
    SPECIAL_KEY_ATTACH,
    SPECIAL_KEY_EXPIRES,
    SPECIAL_KEY_AUTO_TYPE,
    SPECIAL_KEY_AUTO_FILL_PACKAGE_NAME,
];

static MAP_FIELD_TABLE: phf::Map<&'static str, &'static str> = phf::phf_map! {
    "t" => KEY_TITLE,
    "title"=> KEY_TITLE,
    "url"=> KEY_URL,
    "u"=> KEY_USER_NAME,
    "user"=> KEY_USER_NAME,
    "e"=> KEY_EMAIL,
    "email"=> KEY_EMAIL,
    "n"=> KEY_NOTES,
    "note"=> KEY_NOTES,
    "p"=> KEY_PASSWORD,
    "password"=> KEY_PASSWORD,
    "otp"=> KEY_OTP,
    "OTPAuth"=> KEY_OTP,
    "url1"=> KEY_URL1,
    "url2"=> KEY_URL2,
    "url3"=> KEY_URL3,
    "url4"=> KEY_URL4,
    "url5"=> KEY_URL5,

    // 特殊字段
    "tag"=> SPECIAL_KEY_TAGS,
    "g"=> "Group",
    "group"=> "Group",
};

const DEFAULT_AUTO_TYPE_SEQUENCE: &str = "{UserName}{TAB}{Password}{ENTER}";

const AUTOFILL_FIELD_LABEL: &str = "label";
const AUTOFILL_FIELD_USERNAME: &str = "username";
const AUTOFILL_FIELD_EMAIL: &str = "email";

const AUTOFILL_FIELD_PASSWORD: &str = "password";
const AUTOFILL_FIELD_OTP: &str = "otp";

const CUSTOM_DATA_SYNC_UUID: &str = "sync_account_uuid";

#[derive(Debug, Clone)]
pub enum KdbxEvent {
    Saved,
    None(String),
}

#[frb(opaque)]
pub struct Kdbx {
    emit: Option<Arc<dyn Fn(KdbxEvent) -> DartFnFuture<()> + Send + Sync + 'static>>,
    database: RwLock<Database>,
    credentials: Credentials,
    filepath: Option<String>,
}

impl Kdbx {
    #[frb[sync]]
    pub fn create(
        credentials: Credentials,
        config: Option<KdbxConfig>,
        filepath: Option<String>,
    ) -> Self {
        let mut database = if let Some(config) = config {
            Database::with_config(config.into())
        } else {
            Database::new()
        };

        database.meta.generator = Some("frb_keepass".into());

        Self::enable_recyclebin(&mut database);

        Self {
            emit: None,
            database: RwLock::new(database),
            credentials,
            filepath,
        }
    }

    fn enable_recyclebin(db: &mut Database) {
        if let Some(uuid) = db.meta.recyclebin_uuid {
            if db.group(GroupId::from_uuid(uuid)).is_some() {
                if db.meta.recyclebin_enabled != Some(true) {
                    db.meta.recyclebin_enabled = Some(true);
                    db.meta.recyclebin_changed = Some(Times::now());
                }
                return;
            }
        }

        let uuid = {
            let mut root = db.root_mut();
            let mut recycle = root.add_group();

            recycle.set_icon_builtin(43);
            recycle.name = "Recycle Bin".into();
            recycle.enable_autotype = Some(false);
            recycle.enable_searching = Some(false);
            recycle.enable_display = Some(false);
            recycle.id().uuid()
        };

        db.meta.recyclebin_enabled = Some(true);
        db.meta.recyclebin_uuid = Some(uuid);
        db.meta.recyclebin_changed = Some(Times::now());
    }

    pub fn open(credentials: Credentials, filepath: String) -> anyhow::Result<Self> {
        let mut file = File::open(&filepath)?;

        let database = Database::open(&mut file, credentials.key.clone())?;

        Ok(Self {
            emit: None,
            database: RwLock::new(database),
            credentials,
            filepath: Some(filepath),
        })
    }

    pub fn open_bytes(
        credentials: Credentials,
        bytes: Vec<u8>,
        filepath: Option<String>,
    ) -> anyhow::Result<Self> {
        let database = Database::parse(&bytes, credentials.key.clone())?;

        Ok(Self {
            emit: None,
            database: RwLock::new(database),
            credentials,
            filepath: filepath,
        })
    }

    pub fn save_file(&self, filepath: Option<String>) -> anyhow::Result<()> {
        let file_path = filepath
            .as_ref()
            .or(self.filepath.as_ref())
            .ok_or(anyhow::anyhow!(
                "Cannot save database: no filepath was provided."
            ))?;

        let mut file = File::create(file_path)?;

        file.write(&self.save()?)?;
        file.flush()?;

        self.emit(KdbxEvent::Saved);

        Ok(())
    }

    pub fn save(&self) -> anyhow::Result<Vec<u8>> {
        let db = self.database.read().unwrap();

        let mut buf = Vec::new();

        db.save(&mut buf, self.credentials.key.clone())?;

        Ok(buf)
    }

    pub fn export_xml(&self) -> anyhow::Result<Vec<u8>> {
        todo!("")
    }

    #[frb(sync)]
    pub fn bind_event_callback(
        &mut self,
        callback: impl Fn(KdbxEvent) -> DartFnFuture<()> + Send + Sync + 'static,
    ) {
        self.emit = Some(Arc::new(callback));
    }

    fn emit(&self, event: KdbxEvent) {
        if let Some(emit) = &self.emit {
            let emit_clone = emit.clone();
            FLUTTER_RUST_BRIDGE_HANDLER
                .async_runtime()
                .spawn(async move { emit_clone(event).await });
        }
    }

    pub fn get_meta(&self) -> anyhow::Result<Meta> {
        let db = self.database.read().unwrap();
        Ok(Meta::from(&db.meta))
    }

    pub fn get_config(&self) -> anyhow::Result<KdbxConfig> {
        let db = self.database.read().unwrap();
        Ok(KdbxConfig::from(&db.config))
    }

    pub fn get_entrys(
        &self,
        sreach: Option<String>,
        group_id: Option<String>,
        ignore_group_config: Option<bool>,
        include_recycle: Option<bool>,
        case_sensitive: Option<bool>,
    ) -> anyhow::Result<Vec<EntryData>> {
        let db = self.database.read().unwrap();

        let mut result: Vec<EntryData> = Vec::new();

        let ignore_group_config = ignore_group_config.unwrap_or(false);
        let include_recycle = include_recycle.unwrap_or(false);

        let sreach_parse = sreach.and_then(|input| {
            if input.trim().is_empty() {
                None
            } else {
                Some(SearchInputParse::from(
                    input,
                    !case_sensitive.unwrap_or(false),
                ))
            }
        });

        let group = if let Some(id) = group_id {
            db.group(GroupId::from_uuid(uuid_by_str(id.as_str())?))
                .ok_or(anyhow::anyhow!("Group with ID {id} not found"))?
        } else {
            db.root()
        };

        let recycle_id = if include_recycle {
            db.recycle_bin().map(|it| it.id())
        } else {
            None
        };

        let mut stack = vec![group.id()];

        while let Some(group_id) = stack.pop() {
            let group = db.group(group_id).unwrap();

            if let Some(id) = recycle_id {
                if group
                    .find_parent(None, |group| {
                        if group.id().uuid() == id.uuid() {
                            Some(true)
                        } else {
                            None
                        }
                    })
                    .is_some()
                {
                    continue;
                }
            }

            if let Some(sreach_parse) = &sreach_parse {
                if !ignore_group_config
                    && group.find_parent(Some(true), |group| group.enable_display) != Some(true)
                {
                    continue;
                }

                for entry in group.entries() {
                    if sreach_parse.is_match(&entry) {
                        result.push(EntryData::from(&entry));
                    }
                }
            } else {
                if !ignore_group_config
                    && group.find_parent(Some(true), |group| group.enable_display) != Some(true)
                {
                    continue;
                }

                result.extend(group.entries().map(|item| EntryData::from(&item)));
            }

            stack.extend(group.group_ids());
        }

        Ok(result)
    }

    pub fn get_entry(&self, id: String, history_index: Option<i32>) -> anyhow::Result<EntryData> {
        let db = self.database.read().unwrap();
        let entry = db
            .entry(EntryId::from_uuid(uuid_by_str(id.as_str())?))
            .ok_or(anyhow::anyhow!("Entry with ID {id} not found"))?;

        if let Some(index) = history_index {
            if let Some(entry) = entry.historical(index as usize) {
                return Ok(EntryData::from(&entry));
            }
            return Err(anyhow::anyhow!(
                "History entry with index {index} not found for entry with ID {id}"
            ));
        }

        Ok(EntryData::from(&entry))
    }

    pub fn get_auto_type_sequence(&self, id: String) -> anyhow::Result<(EntryData, String)> {
        let db = self.database.read().unwrap();
        let entry = db
            .entry(EntryId::from_uuid(uuid_by_str(id.as_str())?))
            .ok_or(anyhow::anyhow!("Entry with ID {id} not found"))?;

        let sequence = entry
            .autotype
            .as_ref()
            .and_then(|item| item.default_sequence.clone())
            .filter(|seq| !seq.is_empty())
            .or_else(|| {
                entry
                    .parent()
                    .find_parent(None, |group| group.default_autotype_sequence.clone())
            })
            .unwrap_or(DEFAULT_AUTO_TYPE_SEQUENCE.into());

        Ok((EntryData::from(&entry), sequence))
    }

    pub fn get_entry_historys(&self, id: String) -> anyhow::Result<Vec<EntryData>> {
        let db = self.database.read().unwrap();
        let entry = db
            .entry(EntryId::from_uuid(uuid_by_str(id.as_str())?))
            .ok_or(anyhow::anyhow!("Entry with ID {id} not found"))?;

        if let Some(history) = &entry.history {
            Ok((0..history.get_entries().len())
                .map(|i| EntryData::from(&entry.historical(i).unwrap()))
                .collect())
        } else {
            Ok(vec![])
        }
    }

    pub fn get_attachment(&self, id: i32) -> anyhow::Result<Vec<u8>> {
        let db = self.database.read().unwrap();
        if let Some(attach) = db.attachment(AttachmentId::new(id as usize)) {
            Ok(attach.get().clone())
        } else {
            Err(anyhow::anyhow!("Attachment with ID {id} not found"))
        }
    }

    pub fn get_custom_data(&self, key: String, id: Option<String>) -> Option<CustomDataItem> {
        let db = self.database.read().unwrap();

        if let Some(uuid) = id {
            if let Some(uuid) = uuid_by_str(uuid.as_str()).ok() {
                if let Some(entry) = db.entry(EntryId::from_uuid(uuid)) {
                    return entry.custom_data.get(&key).cloned();
                } else if let Some(group) = db.group(GroupId::from_uuid(uuid)) {
                    return group.custom_data.get(&key).cloned();
                }
            }
            None
        } else {
            db.meta.custom_data.get(&key).cloned()
        }
    }

    pub fn get_public_custom_data(&self, key: String) -> Option<VariantDictionaryValue> {
        let db = self.database.read().unwrap();

        db.config
            .public_custom_data
            .as_ref()
            .and_then(|var| var.get(&key).cloned())
    }

    pub fn get_groups(&self) -> anyhow::Result<HashMap<String, GroupData>> {
        let db = self.database.read().unwrap();
        Ok(db
            .iter_all_groups()
            .map(|it| GroupData::from(&it))
            .map(|item| (item.id.clone(), item))
            .collect())
    }

    pub fn get_group(&self, id: String) -> anyhow::Result<GroupData> {
        let db = self.database.read().unwrap();
        let group = db
            .group(GroupId::from_uuid(uuid_by_str(id.as_str())?))
            .ok_or(anyhow::anyhow!("Entry with ID {id} not found"))?;

        Ok(GroupData::from(&group))
    }

    pub fn get_recycle_items(&self) -> anyhow::Result<(Vec<GroupData>, Vec<EntryData>)> {
        let db = self.database.read().unwrap();

        if let Some(recycle) = db.recycle_bin() {
            Ok((
                recycle
                    .groups()
                    .map(|item| GroupData::from(&item))
                    .collect(),
                recycle
                    .entries()
                    .map(|item| EntryData::from(&item))
                    .collect(),
            ))
        } else {
            Ok((vec![], vec![]))
        }
    }

    #[frb(sync)]
    pub fn new_entry(&self) -> anyhow::Result<EntryData> {
        let db = self.database.read().unwrap();
        Ok(EntryData::new(db.root().id().to_string()))
    }

    #[frb(sync)]
    pub fn new_group(&self) -> anyhow::Result<GroupData> {
        let db = self.database.read().unwrap();
        Ok(GroupData::new(db.root().id().to_string()))
    }

    pub fn action(&self, action: KdbxAction) -> anyhow::Result<()> {
        let mut db = self.database.write().unwrap();

        Self::impl_action(&mut db, action)?;

        drop(db);

        self.save_file(None)?;

        Ok(())
    }

    fn impl_action(db: &mut Database, action: KdbxAction) -> anyhow::Result<()> {
        match action {
            KdbxAction::UpdateEntry(entry_data) => {
                let uuid = EntryId::from_uuid(uuid_by_str(&entry_data.id)?);

                let group_uuid = GroupId::from_uuid(uuid_by_str(&entry_data.parent)?);

                // 验证组是否存在
                let _ = db.group(group_uuid).ok_or(anyhow::anyhow!(
                    "Destination group with ID {group_uuid} not found"
                ))?;

                if let Some(mut entry) = db.entry_mut(uuid.clone()) {
                    let entry_ref = entry.as_ref();

                    if group_uuid != entry_ref.parent().id() {
                        entry.move_to(group_uuid)?;
                    }

                    entry.fields = entry_data
                        .fields
                        .into_iter()
                        .map(|(key, value)| (key, value.get()))
                        .collect();

                    entry.autotype = entry_data.autotype;
                    entry.tags = entry_data.tags;

                    entry.times.expiry = entry_data.times.expiry;
                    entry.times.expires = entry_data.times.expires;
                    entry.times.usage_count = entry_data.times.usage_count;

                    entry
                        .custom_data
                        .retain(|key, _| entry_data.custom_data.contains_key(key));
                    for (key, value) in entry_data.custom_data {
                        if let Some(value) = value {
                            entry.custom_data.insert(
                                key,
                                CustomDataItem {
                                    value: Some(value),
                                    last_modification_time: Some(Times::now()),
                                },
                            );
                        }
                    }

                    if let Some(icon) = entry_data.icon {
                        match icon {
                            KdbxIcon::BuiltIn(id) => {
                                entry.set_icon_builtin(id as usize);
                            }
                            KdbxIcon::Custom(id, items) => {
                                if let Some(data) = items {
                                    entry.set_icon_custom_new(data);
                                } else {
                                    entry.set_icon_custom(CustomIconId::from_uuid(uuid_by_str(
                                        &id,
                                    )?))?;
                                }
                            }
                        }
                    } else {
                        entry.set_icon_none();
                    }

                    entry.foreground_color = entry_data.foreground_color;
                    entry.background_color = entry_data.background_color;
                    entry.override_url = entry_data.override_url;
                    entry.quality_check = entry_data.quality_check;

                    let new_ids: HashSet<_> =
                        entry_data.attachments.iter().map(|item| item.id).collect();

                    let remove_ids: Vec<AttachmentId> = entry
                        .attachments
                        .values()
                        .cloned()
                        .filter(|&item| !new_ids.contains(&(item.id() as i32)))
                        .collect();

                    for item in remove_ids {
                        entry.remove_attachment_by_id(item);
                    }

                    for item in entry_data.attachments {
                        if let Some(data) = item.data {
                            if let Some(mut attach) =
                                entry.attachment_mut(AttachmentId::new(item.id as usize))
                            {
                                attach.data = Value::unprotected(data);
                            } else {
                                entry.add_attachment(item.name, Value::unprotected(data));
                            }
                        }
                    }

                    entry.times.last_modification = Some(Times::now())
                } else {
                    let mut group = db.group_mut(group_uuid).ok_or(anyhow::anyhow!(
                        "Destination group with ID {group_uuid} not found"
                    ))?;

                    let mut entry = group.add_entry_with_id(uuid)?;

                    entry.fields = entry_data
                        .fields
                        .into_iter()
                        .map(|(key, value)| (key, value.get()))
                        .collect();

                    entry.autotype = entry_data.autotype;
                    entry.tags = entry_data.tags;

                    entry.times.expiry = entry_data.times.expiry;
                    entry.times.expires = entry_data.times.expires;
                    entry.times.usage_count = entry_data.times.usage_count;

                    for (key, value) in entry_data.custom_data {
                        if let Some(value) = value {
                            entry.custom_data.insert(
                                key,
                                CustomDataItem {
                                    value: Some(value),
                                    last_modification_time: Some(Times::now()),
                                },
                            );
                        }
                    }

                    if let Some(icon) = entry_data.icon {
                        match icon {
                            KdbxIcon::BuiltIn(id) => {
                                entry.set_icon_builtin(id as usize);
                            }
                            KdbxIcon::Custom(id, items) => {
                                if let Some(data) = items {
                                    entry.set_icon_custom_new(data);
                                } else {
                                    entry.set_icon_custom(CustomIconId::from_uuid(uuid_by_str(
                                        &id,
                                    )?))?;
                                }
                            }
                        }
                    }

                    entry.foreground_color = entry_data.foreground_color;
                    entry.background_color = entry_data.background_color;
                    entry.override_url = entry_data.override_url;
                    entry.quality_check = entry_data.quality_check;

                    for item in entry_data.attachments {
                        if let Some(data) = item.data {
                            if let Some(mut attach) =
                                entry.attachment_mut(AttachmentId::new(item.id as usize))
                            {
                                attach.data = Value::unprotected(data);
                            } else {
                                entry.add_attachment(item.name, Value::unprotected(data));
                            }
                        }
                    }
                }
            }
            KdbxAction::UpdateGroup(group_data) => {
                let uuid = GroupId::from_uuid(uuid_by_str(&group_data.id)?);

                let parent = if let Some(parent) = &group_data.parent {
                    Some(GroupId::from_uuid(uuid_by_str(parent)?))
                } else {
                    None
                };

                if let Some(mut group) = db.group_mut(uuid) {
                    let group_ref = group.as_ref();

                    if parent.is_some() && group_ref.parent_id() != parent {
                        group.move_to(parent.unwrap())?;
                    }

                    group.name = group_data.name;
                    group.notes = group_data.notes;
                    group.tags = group_data.tags;

                    if let Some(icon) = group_data.icon {
                        match icon {
                            KdbxIcon::BuiltIn(id) => {
                                group.set_icon_builtin(id as usize);
                            }
                            KdbxIcon::Custom(id, items) => {
                                if let Some(data) = items {
                                    group.set_icon_custom_new(data);
                                } else {
                                    group.set_icon_custom(CustomIconId::from_uuid(uuid_by_str(
                                        &id,
                                    )?))?;
                                }
                            }
                        }
                    } else {
                        group.set_icon_none();
                    }

                    group.times.expiry = group_data.times.expiry;
                    group.times.expires = group_data.times.expires;
                    group.times.usage_count = group_data.times.usage_count;

                    group
                        .custom_data
                        .retain(|key, _| group_data.custom_data.contains_key(key));
                    for (key, value) in group_data.custom_data {
                        if let Some(value) = value {
                            group.custom_data.insert(
                                key,
                                CustomDataItem {
                                    value: Some(value),
                                    last_modification_time: Some(Times::now()),
                                },
                            );
                        }
                    }

                    group.is_expanded = group_data.is_expanded;
                    group.default_autotype_sequence = group_data.default_autotype_sequence;
                    group.enable_autotype = group_data.enable_autotype;
                    group.enable_searching = group_data.enable_searching;
                    group.enable_display = group_data.enable_display;
                    group.last_top_visible_entry = match group_data.last_top_visible_entry {
                        Some(id) => Some(EntryId::from_uuid(uuid_by_str(&id)?)),
                        _ => None,
                    };

                    group.previous_parent_group = match group_data.previous_parent_group {
                        Some(id) => Some(GroupId::from_uuid(uuid_by_str(&id)?)),
                        _ => None,
                    };
                    group.times.last_modification = Some(Times::now())
                } else {
                    let mut parent_group = match parent {
                        Some(id) => db
                            .group_mut(id)
                            .ok_or(anyhow::anyhow!("Destination group with ID {id} not found"))?,
                        None => db.root_mut(),
                    };

                    let mut group = parent_group.add_group_with_id(uuid)?;

                    group.name = group_data.name;
                    group.notes = group_data.notes;
                    group.tags = group_data.tags;

                    if let Some(icon) = group_data.icon {
                        match icon {
                            KdbxIcon::BuiltIn(id) => {
                                group.set_icon_builtin(id as usize);
                            }
                            KdbxIcon::Custom(id, items) => {
                                if let Some(data) = items {
                                    group.set_icon_custom_new(data);
                                } else {
                                    group.set_icon_custom(CustomIconId::from_uuid(uuid_by_str(
                                        &id,
                                    )?))?;
                                }
                            }
                        }
                    }

                    group.times.expiry = group_data.times.expiry;
                    group.times.expires = group_data.times.expires;
                    group.times.usage_count = group_data.times.usage_count;

                    for (key, value) in group_data.custom_data {
                        if let Some(value) = value {
                            group.custom_data.insert(
                                key,
                                CustomDataItem {
                                    value: Some(value),
                                    last_modification_time: Some(Times::now()),
                                },
                            );
                        }
                    }

                    group.is_expanded = group_data.is_expanded;
                    group.default_autotype_sequence = group_data.default_autotype_sequence;
                    group.enable_autotype = group_data.enable_autotype;
                    group.enable_searching = group_data.enable_searching;
                    group.enable_display = group_data.enable_display;
                    group.last_top_visible_entry = match group_data.last_top_visible_entry {
                        Some(id) => Some(EntryId::from_uuid(uuid_by_str(&id)?)),
                        _ => None,
                    };

                    group.previous_parent_group = match group_data.previous_parent_group {
                        Some(id) => Some(GroupId::from_uuid(uuid_by_str(&id)?)),
                        _ => None,
                    };
                }
            }
            KdbxAction::UpdateMeta {
                database_name,
                database_description,
                maintenance_history_days,
                color,
                history_max_items,
                history_max_size,
            } => {
                if let Some(value) = database_name {
                    db.meta.database_name = Some(value);
                    db.meta.database_name_changed = Some(Times::now());
                }

                if let Some(value) = database_description {
                    db.meta.database_description = Some(value);
                    db.meta.database_description_changed = Some(Times::now());
                }

                if let Some(value) = maintenance_history_days {
                    db.meta.maintenance_history_days = Some(value as usize);
                }

                if let Some(value) = color {
                    db.meta.color = Some(value);
                }

                if let Some(value) = history_max_items {
                    db.meta.history_max_items = Some(value);
                }

                if let Some(value) = history_max_size {
                    db.meta.history_max_size = Some(value);
                }
            }
            KdbxAction::UpdateMetaCustomData(hash_map) => {
                for (key, value) in hash_map {
                    if let Some(value) = value {
                        db.meta.custom_data.insert(
                            key,
                            CustomDataItem {
                                value: Some(value),
                                last_modification_time: Some(Times::now()),
                            },
                        );
                    } else if db.meta.custom_data.contains_key(&key) {
                        db.meta.custom_data.remove(&key);
                    }
                }
            }
            KdbxAction::UpdateConfig {
                outer_cipher_config,
                compression_config,
                inner_cipher_config,
                kdf_config,
            } => {
                if let Some(config) = outer_cipher_config {
                    db.config.outer_cipher_config = config;
                }

                if let Some(config) = compression_config {
                    db.config.compression_config = config;
                }

                if let Some(config) = inner_cipher_config {
                    db.config.inner_cipher_config = config;
                }

                if let Some(config) = kdf_config {
                    db.config.kdf_config = config.into();
                }
            }
            KdbxAction::Move2Trash(items) => {
                Self::enable_recyclebin(db);

                let recyclebin_id = db
                    .meta
                    .recyclebin_uuid
                    .map(GroupId::from_uuid)
                    .expect("Unexpected recyclebin uuid is None");

                let mut ids: Vec<Uuid> = Vec::with_capacity(items.len());

                for id in items {
                    ids.push(uuid_by_str(&id)?);
                }

                for uuid in ids {
                    if let Some(mut entry) = db.entry_mut(EntryId::from_uuid(uuid)) {
                        entry.move_to(recyclebin_id)?;
                    } else if let Some(mut group) = db.group_mut(GroupId::from_uuid(uuid)) {
                        group.move_to(recyclebin_id)?;
                    } else {
                        warn!(
                            "Cannot move entry or group with ID {uuid} to recycle bin because it does not exist in the database."
                        );
                    }
                }
            }
            KdbxAction::Delete(items) => {
                let mut ids: Vec<Uuid> = Vec::with_capacity(items.len());

                for id in items {
                    ids.push(uuid_by_str(&id)?);
                }

                for uuid in ids {
                    if let Some(entry) = db.entry_mut(EntryId::from_uuid(uuid)) {
                        entry.remove();
                    } else if let Some(group) = db.group_mut(GroupId::from_uuid(uuid)) {
                        group.remove();
                    } else {
                        warn!(
                            "Cannot delete entry or group with ID {uuid} because it does not exist in the database."
                        );
                    }
                }
            }
            KdbxAction::Restore(items) => {
                let root_id = db.root_id();

                let mut recycle = db
                    .recycle_bin_mut()
                    .ok_or(anyhow::anyhow!("Recycle bin has not been created yet"))?;

                let mut ids: Vec<Uuid> = Vec::with_capacity(items.len());

                for id in items {
                    ids.push(uuid_by_str(&id)?);
                }

                // TODO! 效验组移动到组是否合法的
                for uuid in ids {
                    if let Some(mut entry) = recycle.entry_mut(EntryId::from_uuid(uuid)) {
                        let group_id = entry.previous_parent_group.unwrap_or(root_id);
                        entry.move_to(group_id)?;
                    } else if let Some(mut group) = recycle.group_mut(GroupId::from_uuid(uuid)) {
                        let group_id = group.previous_parent_group.unwrap_or(root_id);
                        group.move_to(group_id)?;
                    } else {
                        warn!(
                            "Cannot restore entry or group with ID {uuid} because it does not exist in the recycle bin."
                        );
                    }
                }
            }
            KdbxAction::Move2Group { from, to } => {
                let group_id = db
                    .group(GroupId::from_uuid(uuid_by_str(to.as_str())?))
                    .ok_or(anyhow::anyhow!("Entry with ID {to} not found"))?
                    .id();

                let mut ids: Vec<Uuid> = Vec::with_capacity(from.len());

                for id in from {
                    ids.push(uuid_by_str(&id)?);
                }

                // TODO! 效验组移动到组是否合法的
                for uuid in ids {
                    if let Some(mut entry) = db.entry_mut(EntryId::from_uuid(uuid)) {
                        entry.move_to(group_id)?;
                    } else if let Some(mut group) = db.group_mut(GroupId::from_uuid(uuid)) {
                        group.move_to(group_id)?;
                    } else {
                        warn!(
                            "Cannot move entry or group with ID {uuid} to recycle bin because it does not exist in the database."
                        );
                    }
                }
            }
            KdbxAction::ImportEntry { items, to } => {
                let mut group = match to {
                    Some(id) => db
                        .group_mut(GroupId::from_uuid(uuid_by_str(&id)?))
                        .ok_or(anyhow::anyhow!("Destination group with ID {id} not found"))?,
                    None => db.root_mut(),
                };

                for item in items {
                    let mut entry = group.add_entry();
                    entry.fields = item
                        .into_iter()
                        .map(|(key, value)| (key, Value::unprotected(value)))
                        .collect();
                }
            }
            UpdateSyncEntry(entry_data) => {
                if let Some(entry) = entry_data {
                    Self::impl_action(
                        db,
                        KdbxAction::UpdateMetaCustomData(HashMap::from([(
                            CUSTOM_DATA_SYNC_UUID.to_string(),
                            Some(CustomDataValue::String(entry.id.clone())),
                        )])),
                    )?;
                    Self::impl_action(db, KdbxAction::UpdateEntry(entry))?;
                } else {
                    Self::impl_action(
                        db,
                        KdbxAction::UpdateMetaCustomData(HashMap::from([(
                            CUSTOM_DATA_SYNC_UUID.to_string(),
                            None,
                        )])),
                    )?;
                }
            }
        }
        Ok(())
    }

    pub fn modify_password(&mut self, credentials: Credentials) -> anyhow::Result<()> {
        let mut db = self.database.write().unwrap();

        let _ = std::mem::replace(&mut self.credentials, credentials);
        db.meta.master_key_changed = Some(Times::now());

        drop(db);

        self.save_file(None)?;
        Ok(())
    }

    pub fn verify_credentials(&self, credentials: Credentials) -> anyhow::Result<bool> {
        Ok(credentials.get_composite_key()? == self.credentials.get_composite_key()?)
    }

    pub fn get_composite_key(&self) -> anyhow::Result<Vec<u8>> {
        self.credentials.get_composite_key()
    }

    pub fn merge(&mut self, kdbx: Kdbx) -> anyhow::Result<MergeLog> {
        let mut dest_db = self.database.write().unwrap();
        let source_db = kdbx.database.read().unwrap();

        if dest_db.root_id() != source_db.root_id() {
            return Err(anyhow::anyhow!(
                "Root groups of source and dest file do not match."
            ));
        }

        let dest_master_key_changed = dest_db
            .meta
            .master_key_changed
            .clone()
            .unwrap_or(DateTime::from_timestamp(0, 0).unwrap().naive_utc());

        let source_master_key_changed = source_db
            .meta
            .master_key_changed
            .clone()
            .unwrap_or(DateTime::from_timestamp(0, 0).unwrap().naive_utc());

        let mut merge_log = MergeLog::from(dest_db.merge(&source_db)?);

        if match (
            self.credentials.get_composite_key(),
            kdbx.credentials.get_composite_key(),
        ) {
            (Ok(a), Ok(b)) => a == b,
            _ => false,
        } {
            merge_log.master_key_changed = true;
            if source_master_key_changed.gt(&dest_master_key_changed) {
                merge_log.is_update_master_key = true;
                let _ = std::mem::replace(&mut self.credentials, kdbx.credentials.clone());
                dest_db.meta.master_key_changed = Some(Times::now())
            }
        }

        drop(dest_db);

        self.save_file(None)?;

        Ok(merge_log)
    }

    pub fn summary(&self) -> anyhow::Result<(FieldSummary, Meta, HashMap<String, GroupData>)> {
        let db = self.database.read().unwrap();

        Ok((
            FieldSummary::from(&db),
            Meta::from(&db.meta),
            db.iter_all_groups()
                .map(|it| GroupData::from(&it))
                .map(|item| (item.id.clone(), item))
                .collect(),
        ))
    }

    pub fn autofill_search(
        &self,
        metadata: AutofillMetadata,
        entry_id: Option<String>,
    ) -> anyhow::Result<AutofillDataset> {
        let db = self.database.read().unwrap();

        let mut datasets: Vec<HashMap<String, Option<String>>> = Vec::new();

        fn to_autofill_dataset(
            item: EntryRef<'_>,
            metadata: &AutofillMetadata,
        ) -> HashMap<String, Option<String>> {
            fn get_option_string(value: Option<&Value<String>>) -> Option<String> {
                value.and_then(|item| {
                    if item.is_empty() {
                        None
                    } else {
                        Some(item.get().clone())
                    }
                })
            }

            let title = get_option_string(item.fields.get(KEY_TITLE));
            let email = get_option_string(item.fields.get(KEY_EMAIL));
            let user = get_option_string(item.fields.get(KEY_USER_NAME));

            let mut dataset = HashMap::from([
                (AUTOFILL_FIELD_LABEL.to_string(), title.or(user.clone())),
                (
                    AUTOFILL_FIELD_USERNAME.to_string(),
                    if metadata.field_types.contains(AUTOFILL_FIELD_EMAIL) {
                        email.clone().or(user.clone())
                    } else {
                        user.clone().or(email.clone())
                    },
                ),
                (
                    AUTOFILL_FIELD_EMAIL.to_string(),
                    if metadata.field_types.contains(AUTOFILL_FIELD_EMAIL) {
                        email.or(user)
                    } else {
                        user
                    },
                ),
            ]);

            if metadata.field_types.contains(AUTOFILL_FIELD_PASSWORD) {
                dataset.insert(
                    AUTOFILL_FIELD_PASSWORD.to_string(),
                    get_option_string(item.fields.get(KEY_PASSWORD)),
                );
            }

            if metadata.field_types.contains(AUTOFILL_FIELD_OTP) {
                dataset.insert(
                    AUTOFILL_FIELD_OTP.to_string(),
                    if let Ok(otp) = item.get_otp() {
                        otp.value_now().map(|item| item.code).ok()
                    } else {
                        None
                    },
                );
            }

            dataset
        }

        if let Some(uuid) = entry_id {
            if let Some(item) = db.entry(EntryId::from_uuid(uuid_by_str(&uuid)?)) {
                datasets.push(to_autofill_dataset(item, &metadata));
            }

            return Ok(AutofillDataset {
                unlock: Some(true),
                manual: Some(true),
                message: None,
                data: datasets,
            });
        }

        let domain = metadata
            .web_domain
            .as_ref()
            .map(|item| simple_to_domain(&item));

        for item in db.iter_all_entries() {
            // TODO! 是否跳过回收站

            let match_app = item
                .fields
                .get(SPECIAL_KEY_AUTO_FILL_PACKAGE_NAME)
                .zip(metadata.package_name.as_ref())
                .map(|(a, b)| a.get() == b)
                .unwrap_or(false);

            let match_domain = if let Some(domain) = &domain {
                contains_domain(
                    domain,
                    [KEY_URL, KEY_URL1, KEY_URL2, KEY_URL3, KEY_URL4, KEY_URL5]
                        .iter()
                        .filter_map(|&key| item.fields.get(key).map(|item| item.get().as_ref()))
                        .collect(),
                )
            } else {
                false
            };

            if match_app || match_domain {
                datasets.push(to_autofill_dataset(item, &metadata));
            }
        }

        Ok(AutofillDataset {
            unlock: Some(true),
            manual: None,
            message: None,
            data: datasets,
        })
    }
}

impl Drop for Kdbx {
    fn drop(&mut self) {
        info!("kdbx close");
    }
}

#[frb]
pub enum KdbxAction {
    UpdateEntry(EntryData),
    UpdateGroup(GroupData),
    UpdateMeta {
        database_name: Option<String>,
        database_description: Option<String>,
        #[frb(type_64bit_int)]
        maintenance_history_days: Option<isize>,
        color: Option<Color>,
        #[frb(type_64bit_int)]
        history_max_items: Option<isize>,
        #[frb(type_64bit_int)]
        history_max_size: Option<isize>,
    },
    UpdateMetaCustomData(HashMap<String, Option<CustomDataValue>>),
    UpdateConfig {
        outer_cipher_config: Option<OuterCipherConfig>,
        compression_config: Option<CompressionConfig>,
        inner_cipher_config: Option<InnerCipherConfig>,
        kdf_config: Option<KdfConfig>,
    },
    Move2Trash(Vec<String>),
    Delete(Vec<String>),
    Restore(Vec<String>),
    Move2Group {
        from: Vec<String>,
        to: String,
    },
    ImportEntry {
        items: Vec<HashMap<String, String>>,
        to: Option<String>,
    },
    UpdateSyncEntry(Option<EntryData>),
}

#[frb]
#[derive(Clone)]
pub struct EntryData {
    pub id: String,
    #[frb(non_final)]
    pub parent: String,
    pub fields: HashMap<String, FieldValue>, // todo: 内存加密
    #[frb(non_final)]
    pub autotype: Option<AutoType>,
    pub tags: Vec<String>,
    pub times: Times,
    pub custom_data: HashMap<String, Option<CustomDataValue>>,
    #[frb(non_final)]
    pub icon: Option<KdbxIcon>,
    #[frb(non_final)]
    pub foreground_color: Option<Color>,
    #[frb(non_final)]
    pub background_color: Option<Color>,
    #[frb(non_final)]
    pub override_url: Option<String>,
    #[frb(non_final)]
    pub quality_check: bool,
    #[frb(non_final)]
    pub previous_parent_group: Option<String>,
    pub attachments: Vec<Attachment>,
}

impl EntryData {
    #[frb(sync)]
    pub fn clone(&self) -> Self {
        let mut new_entry = Clone::clone(self);
        new_entry.id = EntryId::new().to_string();
        new_entry
    }

    #[frb[sync]]
    pub fn new(parent: String) -> Self {
        Self {
            id: EntryId::new().to_string(),
            parent,
            fields: HashMap::new(),
            autotype: None,
            tags: Vec::new(),
            times: Times::new(),
            custom_data: HashMap::new(),
            icon: Some(KdbxIcon::BuiltIn(0)),
            foreground_color: None,
            background_color: None,
            override_url: None,
            quality_check: true,
            previous_parent_group: None,
            attachments: Vec::new(),
        }
    }
}

impl From<&EntryRef<'_>> for EntryData {
    fn from(value: &EntryRef<'_>) -> Self {
        Self {
            id: value.id().to_string(),
            parent: value.parent().id().to_string(),
            fields: value
                .fields
                .iter()
                .map(|(key, value)| (key.clone(), FieldValue::from(value)))
                .collect(),
            autotype: value.autotype.clone(),
            tags: value.tags.clone(),
            times: value.times.clone(),
            custom_data: value
                .custom_data
                .iter()
                .map(|(key, _)| (key.clone(), None))
                .collect(),
            icon: match value.icon() {
                Some(icon) => Some(KdbxIcon::from(icon)),
                _ => None,
            },
            foreground_color: value.foreground_color.clone(),
            background_color: value.background_color.clone(),
            override_url: value.override_url.clone(),
            quality_check: value.quality_check.clone(),
            previous_parent_group: match value.previous_parent_group {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            attachments: value
                .attachments
                .iter()
                .map(|(name, id)| Attachment {
                    id: id.id() as i32,
                    name: name.clone(),
                    size: value.database().attachment(*id).unwrap().data.len() as i32,
                    data: None,
                })
                .collect(),
        }
    }
}

#[frb(dart_code = r#"
  import 'dart:convert';
  import 'dart:math';

  static Uint8List _transformXor(Uint8List a, Uint8List b) {
    assert(a.length == b.length);
    final ret = Uint8List(a.length);
    for (var i = 0; i < a.length; i++) {
      ret[i] = a[i] ^ b[i];
    }
    return ret;
  }

  static final _random = Random.secure();

  static Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
        List.generate(length, (i) => _random.nextInt(0xff)));
  }


  factory FieldValue.protected(String value) {
    final valueBytes = utf8.encode(value);
    final salt = _randomBytes(valueBytes.length);

    return FieldValue.raw(value:_transformXor(valueBytes, salt), salt:salt);
  }

  factory FieldValue.plaintext(String value) {
    return FieldValue.raw(value:utf8.encode(value));
  }

  String get() {
    return utf8.decode(salt != null ? _transformXor(value, salt!) : value);
  }

"#)]
#[derive(Clone)]
pub struct FieldValue {
    pub value: Vec<u8>,
    pub salt: Option<Vec<u8>>,
}

#[frb]
impl FieldValue {
    #[frb(sync)]
    pub fn new(value: String, protected: Option<bool>) -> Self {
        let mut value = value.into_bytes();
        let mut salt: Option<Vec<u8>> = None;

        if protected == Some(true) {
            let s = random_bytes(value.len());
            let v = transform_xor(&value, &s);

            value.zeroize();

            value = v;
            salt = Some(s);
        }

        Self { value, salt }
    }

    fn get(self) -> Value<String> {
        if let Some(salt) = self.salt {
            Value::protected(unsafe {
                String::from_utf8_unchecked(transform_xor(&self.value, &salt))
            })
        } else {
            Value::unprotected(unsafe { String::from_utf8_unchecked(self.value) })
        }
    }
}

impl From<&Value<String>> for FieldValue {
    fn from(value: &Value<String>) -> Self {
        FieldValue::new(value.get().clone(), Some(value.is_protected()))
    }
}

#[frb]
#[derive(Clone)]
pub struct GroupData {
    pub id: String,
    #[frb(non_final)]
    pub parent: Option<String>,
    #[frb(non_final)]
    pub name: String,
    #[frb(non_final)]
    pub notes: Option<String>,
    pub tags: Vec<String>,
    #[frb(non_final)]
    pub icon: Option<KdbxIcon>,
    pub times: Times,
    pub custom_data: HashMap<String, Option<CustomDataValue>>,
    #[frb(non_final)]
    pub is_expanded: bool,
    #[frb(non_final)]
    pub default_autotype_sequence: Option<String>,
    #[frb(non_final)]
    pub enable_autotype: Option<bool>,
    #[frb(non_final)]
    pub enable_searching: Option<bool>,
    #[frb(non_final)]
    pub enable_display: Option<bool>,
    #[frb(non_final)]
    pub last_top_visible_entry: Option<String>,
    #[frb(non_final)]
    pub previous_parent_group: Option<String>,

    pub is_recycle_bin: bool,
}

impl GroupData {
    #[frb[sync]]
    pub fn new(parent: String) -> Self {
        Self {
            id: GroupId::new().to_string(),
            parent: Some(parent),
            name: String::new(),
            notes: None,
            tags: Vec::new(),
            icon: Some(KdbxIcon::BuiltIn(48)),
            times: Times::new(),
            custom_data: HashMap::new(),
            is_expanded: true,
            default_autotype_sequence: None,
            enable_autotype: None,
            enable_searching: None,
            enable_display: None,
            last_top_visible_entry: None,
            previous_parent_group: None,
            is_recycle_bin: false,
        }
    }
}

impl From<&GroupRef<'_>> for GroupData {
    fn from(value: &GroupRef<'_>) -> Self {
        Self {
            id: value.id().to_string(),
            parent: match value.parent() {
                Some(group) => Some(group.id().to_string()),
                _ => None,
            },
            name: value.name.clone(),
            notes: value.notes.clone(),
            tags: value.tags.clone(),
            icon: match value.icon() {
                Some(icon) => Some(KdbxIcon::from(icon)),
                _ => None,
            },
            times: value.times.clone(),
            custom_data: value
                .custom_data
                .iter()
                .map(|(key, _)| (key.clone(), None))
                .collect(),
            is_expanded: value.is_expanded,
            default_autotype_sequence: value.default_autotype_sequence.clone(),
            enable_autotype: value.enable_autotype.clone(),
            enable_searching: value.enable_searching.clone(),
            enable_display: value.enable_display.clone(),
            last_top_visible_entry: match value.last_top_visible_entry {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            previous_parent_group: match value.previous_parent_group {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            is_recycle_bin: value.database().meta.recyclebin_uuid == Some(value.id().uuid()),
        }
    }
}

#[frb]
#[derive(Clone)]
pub struct Meta {
    pub generator: Option<String>,
    pub database_name: Option<String>,
    pub database_name_changed: Option<NaiveDateTime>,
    pub database_description: Option<String>,
    pub database_description_changed: Option<NaiveDateTime>,
    pub default_username: Option<String>,
    pub default_username_changed: Option<NaiveDateTime>,
    #[frb(type_64bit_int)]
    pub maintenance_history_days: Option<usize>,
    pub color: Option<Color>,
    pub master_key_changed: Option<NaiveDateTime>,
    #[frb(type_64bit_int)]
    pub master_key_change_rec: Option<isize>,
    #[frb(type_64bit_int)]
    pub master_key_change_force: Option<isize>,
    pub memory_protection: Option<MemoryProtection>,
    pub recyclebin_enabled: Option<bool>,
    pub recyclebin_uuid: Option<String>,
    pub recyclebin_changed: Option<NaiveDateTime>,
    pub entry_templates_group: Option<String>,
    pub entry_templates_group_changed: Option<NaiveDateTime>,
    pub last_selected_group: Option<String>,
    pub last_top_visible_group: Option<String>,
    #[frb(type_64bit_int)]
    pub history_max_items: Option<isize>,
    #[frb(type_64bit_int)]
    pub history_max_size: Option<isize>,
    pub settings_changed: Option<NaiveDateTime>,
    pub custom_data: HashSet<String>,
}

impl From<&keepass::db::Meta> for Meta {
    fn from(value: &keepass::db::Meta) -> Self {
        Self {
            generator: value.generator.clone(),
            database_name: value.database_name.clone(),
            database_name_changed: value.database_name_changed.clone(),
            database_description: value.database_description.clone(),
            database_description_changed: value.database_description_changed.clone(),
            default_username: value.default_username.clone(),
            default_username_changed: value.default_username_changed.clone(),
            maintenance_history_days: value.maintenance_history_days.clone(),
            color: value.color.clone(),
            master_key_changed: value.master_key_changed.clone(),
            master_key_change_rec: value.master_key_change_rec.clone(),
            master_key_change_force: value.master_key_change_force.clone(),
            memory_protection: value.memory_protection.clone(),
            recyclebin_enabled: value.recyclebin_enabled.clone(),
            recyclebin_uuid: match value.recyclebin_uuid {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            recyclebin_changed: value.recyclebin_changed.clone(),
            entry_templates_group: match value.entry_templates_group {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            entry_templates_group_changed: value.entry_templates_group_changed.clone(),
            last_selected_group: match value.last_selected_group {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            last_top_visible_group: match value.last_top_visible_group {
                Some(id) => Some(id.to_string()),
                _ => None,
            },
            history_max_items: value.history_max_items.clone(),
            history_max_size: value.history_max_size.clone(),
            settings_changed: value.settings_changed.clone(),
            custom_data: value.custom_data.keys().cloned().collect(),
        }
    }
}

#[frb(mirror(MemoryProtection))]
pub struct _MemoryProtection {
    pub protect_title: bool,
    pub protect_username: bool,
    pub protect_password: bool,
    pub protect_url: bool,
    pub protect_notes: bool,
}

#[frb(opaque)]
#[derive(Clone)]
pub struct Credentials {
    key: DatabaseKey,
}

impl Credentials {
    #[frb(sync)]
    pub fn from(password: Option<String>, keyfile: Option<Vec<u8>>) -> anyhow::Result<Self> {
        if password.is_none() && keyfile.is_none() {
            return Err(anyhow::anyhow!("No password or keyfile was provided."));
        }

        let mut key = DatabaseKey::new();

        if let Some(pass) = password {
            key = key.with_password(pass.as_str());
        }

        if let Some(keyfile) = keyfile {
            let mut keyfile = keyfile.as_slice();
            key = key.with_keyfile(&mut keyfile)?;
        }

        Ok(Self { key })
    }

    #[frb(sync)]
    pub fn form_composite_key(key: Vec<u8>) -> anyhow::Result<Self> {
        Ok(Self {
            key: DatabaseKey::form_composite_key(key)?,
        })
    }

    #[frb(sync)]
    pub fn get_composite_key(&self) -> anyhow::Result<Vec<u8>> {
        Ok(self.key.get_composite_key()?.to_vec())
    }

    pub fn random_key_file() -> anyhow::Result<Vec<u8>> {
        todo!("未实现")
    }
}

pub struct KdbxConfig {
    pub outer_cipher_config: OuterCipherConfig,
    pub compression_config: CompressionConfig,
    pub inner_cipher_config: InnerCipherConfig,
    pub kdf_config: KdfConfig,
}

impl Into<DatabaseConfig> for KdbxConfig {
    fn into(self) -> DatabaseConfig {
        let mut db_config: DatabaseConfig = DatabaseConfig::default();

        db_config.outer_cipher_config = self.outer_cipher_config;
        db_config.compression_config = self.compression_config;
        db_config.inner_cipher_config = self.inner_cipher_config;
        db_config.kdf_config = self.kdf_config.into();
        db_config
    }
}

impl From<&DatabaseConfig> for KdbxConfig {
    fn from(value: &DatabaseConfig) -> Self {
        Self {
            outer_cipher_config: value.outer_cipher_config.clone(),
            compression_config: value.compression_config.clone(),
            inner_cipher_config: value.inner_cipher_config.clone(),
            kdf_config: KdfConfig::from(&value.kdf_config),
        }
    }
}

#[frb(mirror(OuterCipherConfig))]
pub enum _OuterCipherConfig {
    AES256,
    Twofish,
    ChaCha20,
}

#[frb(mirror(CompressionConfig))]
pub enum _CompressionConfig {
    None,
    GZip,
}

#[frb(mirror(InnerCipherConfig))]
pub enum _InnerCipherConfig {
    Plain,
    Salsa20,
    ChaCha20,
}

#[frb]
pub enum KdfConfig {
    Aes {
        #[frb(type_64bit_int)]
        rounds: u64,
    },
    Argon2 {
        #[frb(type_64bit_int)]
        iterations: u64,
        #[frb(type_64bit_int)]
        memory: u64,
        parallelism: u32,
        version: Argon2Version,
    },
    Argon2id {
        #[frb(type_64bit_int)]
        iterations: u64,
        #[frb(type_64bit_int)]
        memory: u64,
        parallelism: u32,
        version: Argon2Version,
    },
}

impl Into<KdfConfig2> for KdfConfig {
    fn into(self) -> KdfConfig2 {
        match self {
            KdfConfig::Aes { rounds } => KdfConfig2::Aes { rounds },
            KdfConfig::Argon2 {
                iterations,
                memory,
                parallelism,
                version,
            } => KdfConfig2::Argon2 {
                iterations,
                memory,
                parallelism,
                version: version,
            },
            KdfConfig::Argon2id {
                iterations,
                memory,
                parallelism,
                version,
            } => KdfConfig2::Argon2id {
                iterations,
                memory,
                parallelism,
                version,
            },
        }
    }
}

impl From<&KdfConfig2> for KdfConfig {
    fn from(value: &KdfConfig2) -> Self {
        match *value {
            KdfConfig2::Aes { rounds } => KdfConfig::Aes { rounds },
            KdfConfig2::Argon2 {
                iterations,
                memory,
                parallelism,
                version,
            } => KdfConfig::Argon2 {
                iterations,
                memory,
                parallelism,
                version: version,
            },
            KdfConfig2::Argon2id {
                iterations,
                memory,
                parallelism,
                version,
            } => KdfConfig::Argon2id {
                iterations,
                memory,
                parallelism,
                version,
            },
            _ => panic!("non-exhaustive"),
        }
    }
}

#[frb(mirror(Argon2Version))]
pub enum _Argon2Version {
    Version10 = 0x10,
    Version13 = 0x13,
}

#[frb(mirror(Times))]
#[frb(serialize)]
pub struct _Times {
    pub creation: Option<NaiveDateTime>,
    pub last_modification: Option<NaiveDateTime>,
    pub last_access: Option<NaiveDateTime>,
    #[frb(non_final)]
    pub expiry: Option<NaiveDateTime>,
    pub location_changed: Option<NaiveDateTime>,
    #[frb(non_final)]
    pub expires: Option<bool>,
    #[frb(non_final)]
    pub usage_count: Option<usize>,
}

#[frb(mirror(AutoType))]
pub struct _AutoType {
    #[frb(non_final)]
    pub enabled: bool,
    #[frb(non_final)]
    pub default_sequence: Option<String>,
    #[frb(non_final)]
    pub data_transfer_obfuscation: DataTransferObfuscation,
    pub associations: Vec<AutoTypeAssociation>,
}

#[frb(mirror(DataTransferObfuscation))]
pub enum _DataTransferObfuscation {
    None,
    UseClipboard,
}

#[frb(mirror(AutoTypeAssociation))]
pub struct _AutoTypeAssociation {
    pub window: String,
    pub sequence: String,
}

#[frb(mirror(CustomDataItem))]
pub struct _CustomDataItem {
    pub value: Option<CustomDataValue>,
    pub last_modification_time: Option<NaiveDateTime>,
}

#[frb(mirror(CustomDataValue))]
pub enum _CustomDataValue {
    String(String),
    Binary(Vec<u8>),
}

#[derive(Clone)]
pub enum KdbxIcon {
    BuiltIn(i32),
    Custom(String, Option<Vec<u8>>),
}

impl From<&keepass::db::Icon> for KdbxIcon {
    fn from(value: &keepass::db::Icon) -> Self {
        match value {
            keepass::db::Icon::BuiltIn(id) => KdbxIcon::BuiltIn(*id as i32),
            keepass::db::Icon::Custom(id) => KdbxIcon::Custom(id.to_string(), None),
        }
    }
}

#[frb]
#[derive(Clone)]
pub struct Attachment {
    pub id: i32,
    pub name: String,
    pub size: i32,
    pub data: Option<Vec<u8>>,
}

#[frb(mirror(VariantDictionaryValue))]
pub enum _VariantDictionaryValue {
    UInt32(u32),
    UInt64(u64),
    Bool(bool),
    Int32(i32),
    Int64(i64),
    String(String),
    ByteArray(Vec<u8>),
}

pub struct MergeLog {
    pub master_key_changed: bool,
    pub is_update_master_key: bool,
    pub warnings: Vec<String>,
    pub events: Vec<MergeEvent>,
}

impl From<MergeLog2> for MergeLog {
    fn from(value: MergeLog2) -> Self {
        Self {
            master_key_changed: false,
            is_update_master_key: false,
            warnings: value.warnings,
            events: value
                .events
                .into_iter()
                .map(|item| MergeEvent {
                    target: item.target.into(),
                    event_type: item.event_type.into(),
                })
                .collect(),
        }
    }
}

pub struct MergeEvent {
    pub target: MergeEventTarget,
    pub event_type: MergeEventType,
}

pub enum MergeEventTarget {
    Entry(String),
    Group(String),
    Icon(String),
}

impl From<MergeEventTarget2> for MergeEventTarget {
    fn from(value: MergeEventTarget2) -> Self {
        match value {
            MergeEventTarget2::Entry(id) => MergeEventTarget::Entry(id.to_string()),
            MergeEventTarget2::Group(id) => MergeEventTarget::Group(id.to_string()),
            MergeEventTarget2::Icon(id) => MergeEventTarget::Icon(id.to_string()),
        }
    }
}

#[frb(mirror(MergeEventType))]
pub enum _MergeEventType {
    Created,
    Deleted,
    LocationUpdated,
    Updated,
}

#[frb]
#[derive(Debug, Default, Clone)]
pub struct FieldSummary {
    pub urls: HashSet<String>,
    pub user_names: HashSet<String>,
    pub emails: HashSet<String>,
    pub tags: HashSet<String>,
    pub custom_fields: HashSet<String>,
    pub custom_icons: HashMap<String, Vec<u8>>,
    pub public_custom_data: HashSet<String>,
    pub total_entry_count: i32,
    pub total_group_count: i32,
}

impl FieldSummary {
    fn from(db: &Database) -> Self {
        let mut field_summary = Self {
            urls: HashSet::new(),
            user_names: HashSet::new(),
            emails: HashSet::new(),
            tags: HashSet::new(),
            custom_fields: HashSet::new(),
            custom_icons: HashMap::new(),
            public_custom_data: match &db.config.public_custom_data {
                Some(data) => data.keys().cloned().collect(),
                _ => HashSet::new(),
            },
            total_entry_count: db.num_entries() as i32,
            total_group_count: db.num_groups() as i32,
        };

        for entry in db.iter_all_entries() {
            field_summary.summary(&entry);
        }

        for icon in db.iter_all_custom_icons() {
            field_summary
                .custom_icons
                .insert(icon.id().to_string(), icon.data.clone());
        }

        field_summary
    }

    fn summary(&mut self, entry: &EntryRef<'_>) {
        if let Some(url) = entry.get(KEY_URL) {
            self.urls.insert(url.into());
        }
        if let Some(url) = entry.get(KEY_URL1) {
            self.urls.insert(url.into());
        }
        if let Some(url) = entry.get(KEY_URL2) {
            self.urls.insert(url.into());
        }
        if let Some(url) = entry.get(KEY_URL3) {
            self.urls.insert(url.into());
        }
        if let Some(url) = entry.get(KEY_URL4) {
            self.urls.insert(url.into());
        }
        if let Some(url) = entry.get(KEY_URL5) {
            self.urls.insert(url.into());
        }
        if let Some(name) = entry.get(KEY_USER_NAME) {
            self.user_names.insert(name.into());
        }
        if let Some(email) = entry.get(KEY_EMAIL) {
            self.emails.insert(email.into());
        }

        self.tags.extend(entry.tags.clone());

        self.custom_fields.extend(
            entry
                .fields
                .keys()
                .filter(|&it| !KDBX_KEY_ALL.contains(&it.as_str()))
                .cloned(),
        );
    }
}

///
/// [["]字段名["]:]["]关键句["]
///
#[frb(ignore)]
#[derive(Debug)]
struct SearchInputParse {
    parse_objects: Vec<(Option<String>, String)>,
    ignore_case: bool,
}

impl SearchInputParse {
    fn from(value: String, ignore_case: bool) -> Self {
        let mut objects: Vec<(Option<String>, String)> = vec![];

        let mut chunk = String::new();
        let mut key: Option<String> = None;
        let mut quote: Option<char> = None;

        let mut commit = |key: Option<String>, value: String| {
            objects.push((
                key,
                if ignore_case {
                    value.to_lowercase()
                } else {
                    value
                },
            ));
        };

        let mut chars = value.chars().peekable();

        while let Some(c) = chars.next() {
            if let Some(q) = quote {
                if q == c {
                    // 引号闭合, key 存在, 或者下个值不是冒号
                    if !chunk.is_empty() && (key.is_some() || chars.peek() != Some(&':')) {
                        commit(key.take(), std::mem::take(&mut chunk));
                    }
                    quote = None;
                } else {
                    chunk.push(c);
                }
            } else if c.is_whitespace() {
                if !chunk.is_empty() {
                    commit(key.take(), std::mem::take(&mut chunk));
                    quote = None;
                }
            } else if c == ':' && key.is_none() && !chunk.is_empty() {
                key = Some(std::mem::take(&mut chunk));
            } else if c == '"' || c == '\'' {
                if !chunk.is_empty() {
                    commit(key.take(), std::mem::take(&mut chunk));
                }
                quote = Some(c);
            } else {
                chunk.push(c);
            }
        }

        if !chunk.is_empty() {
            commit(key, chunk);
        }

        Self {
            parse_objects: objects,
            ignore_case,
        }
    }

    pub fn is_match(&self, entry: &EntryRef<'_>) -> bool {
        for (key, value) in &self.parse_objects {
            if let Some(key) = key {
                let key = *MAP_FIELD_TABLE.get(key).unwrap_or(&key.as_str());

                if key == SPECIAL_KEY_TAGS {
                    for tag in &entry.tags {
                        if (self.ignore_case && tag.to_lowercase() == *value) || tag == value {
                            return true;
                        }
                    }
                } else if key == "Group" {
                    if (self.ignore_case && &entry.parent().name == value)
                        || &entry.parent().name == value
                    {
                        return true;
                    }
                } else if let Some(val) = entry.get(key) {
                    if (self.ignore_case && val.to_lowercase().contains(value))
                        || val.contains(value)
                    {
                        return true;
                    }
                }
            } else {
                for tag in &entry.tags {
                    if (self.ignore_case && tag.to_lowercase() == *value) || tag == value {
                        return true;
                    }
                }
                for key in &KDBX_KEY_ALL[0..9] {
                    if let Some(val) = entry.get(key) {
                        if (self.ignore_case && val.to_lowercase().contains(value))
                            || val.contains(value)
                        {
                            return true;
                        }
                    }
                }
            }
        }
        false
    }
}

#[frb(dart_code = r#"
  factory AutofillMetadata.fromJson(Map<dynamic, dynamic> json) =>
      AutofillMetadata(
        fieldTypes: (json['fieldTypes'] as Iterable)
            .map((dynamic e) => e as String)
            .toSet(),
        manual: json["manual"] as bool?,
        packageName: json['packageName'] as String?,
        webDomain: json['webDomain'] as String?,
        webScheme: json['webScheme'] as String?,
      );
"#)]
#[derive(Clone)]
pub struct AutofillMetadata {
    pub manual: Option<bool>,
    pub package_name: Option<String>,
    pub web_domain: Option<String>,
    pub web_scheme: Option<String>,
    pub field_types: HashSet<String>,
}

#[frb(dart_code = r#"
  Map<String, Object?> toJson() => {
    'unlock': unlock,
    "manual": manual,
    'message': message,
    'data': data,
  };
"#)]
#[derive(Clone)]
pub struct AutofillDataset {
    #[frb(non_final)]
    pub unlock: Option<bool>,
    #[frb(non_final)]
    pub manual: Option<bool>,
    #[frb(non_final)]
    pub message: Option<String>,
    #[frb(non_final)]
    pub data: Vec<HashMap<String, Option<String>>>,
}

#[frb(rust2dart(dart_type = "Color", dart_code = "Color({})"))]
pub fn encode_color_type(color: Color) -> u32 {
    ((color.r as u32) << 16) | ((color.g as u32) << 8) | (color.b as u32)
}

#[frb(dart2rust(dart_type = "Color", dart_code = "{}.toARGB32()"))]
pub fn decode_color_type(val: u32) -> Color {
    Color {
        r: (val >> 16 & 0xff) as u8,
        g: (val >> 8 & 0xff) as u8,
        b: (val & 0xff) as u8,
    }
}

#[frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[cfg(test)]
mod test {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};

    /// 一个用完即删的临时数据库路径
    struct TempFile(String);

    impl TempFile {
        fn new(tag: &str) -> Self {
            static COUNTER: AtomicUsize = AtomicUsize::new(0);

            let mut path = std::env::temp_dir();
            path.push(format!(
                "kdbxdb_test_{tag}_{}_{}.kdbx",
                std::process::id(),
                COUNTER.fetch_add(1, Ordering::Relaxed)
            ));

            Self(path.to_string_lossy().into_owned())
        }

        fn path(&self) -> String {
            self.0.clone()
        }
    }

    impl Drop for TempFile {
        fn drop(&mut self) {
            let _ = std::fs::remove_file(&self.0);
        }
    }

    fn credentials(password: &str) -> Credentials {
        Credentials::from(Some(password.to_string()), None).unwrap()
    }

    /// 测试用配置, 使用最轻量的 KDF 以免拖慢测试
    fn test_config() -> KdbxConfig {
        KdbxConfig {
            outer_cipher_config: OuterCipherConfig::AES256,
            compression_config: CompressionConfig::None,
            inner_cipher_config: InnerCipherConfig::Salsa20,
            kdf_config: KdfConfig::Aes { rounds: 10 },
        }
    }

    fn new_kdbx(file: &TempFile) -> Kdbx {
        Kdbx::create(
            credentials("password"),
            Some(test_config()),
            Some(file.path()),
        )
    }

    fn new_entry(parent: &str, title: &str) -> EntryData {
        EntryData {
            id: EntryId::new().to_string(),
            parent: parent.to_string(),
            fields: HashMap::from([
                (
                    KEY_TITLE.to_string(),
                    FieldValue::new(title.to_string(), None),
                ),
                (
                    KEY_PASSWORD.to_string(),
                    FieldValue::new("s3cr3t".to_string(), Some(true)),
                ),
            ]),
            autotype: None,
            tags: vec![],
            times: Times::new(),
            custom_data: HashMap::new(),
            icon: None,
            foreground_color: None,
            background_color: None,
            override_url: None,
            quality_check: true,
            previous_parent_group: None,
            attachments: vec![],
        }
    }

    fn new_group(id: &str, parent: Option<String>, name: &str) -> GroupData {
        GroupData {
            id: id.to_string(),
            parent,
            name: name.to_string(),
            notes: None,
            tags: vec![],
            icon: None,
            times: Times::new(),
            custom_data: HashMap::new(),
            is_expanded: true,
            default_autotype_sequence: None,
            enable_autotype: None,
            enable_searching: None,
            enable_display: None,
            last_top_visible_entry: None,
            previous_parent_group: None,
            is_recycle_bin: false,
        }
    }

    fn root_id(kdbx: &Kdbx) -> String {
        kdbx.get_groups()
            .unwrap()
            .into_values()
            .into_iter()
            .find(|group| group.parent.is_none())
            .expect("database without root group")
            .id
    }

    fn field(entry: &EntryData, key: &str) -> String {
        entry
            .fields
            .get(key)
            .unwrap()
            .clone()
            .get()
            .get()
            .to_string()
    }

    #[test]
    fn field_value_roundtrip() {
        let plain = FieldValue::new("hello".to_string(), None);
        assert!(plain.salt.is_none());
        assert_eq!(plain.value, b"hello");

        let value = plain.get();
        assert!(!value.is_protected());
        assert_eq!(value.get().as_str(), "hello");

        let protected = FieldValue::new("hello".to_string(), Some(true));
        assert!(protected.salt.is_some());
        assert_ne!(protected.value, b"hello");

        let value = protected.get();
        assert!(value.is_protected());
        assert_eq!(value.get().as_str(), "hello");
    }

    #[test]
    fn transform_xor_is_reversible() {
        let value = b"hello world".to_vec();
        let salt = random_bytes(value.len());
        assert_eq!(salt.len(), value.len());

        let masked = transform_xor(&value, &salt);
        assert_ne!(masked, value);
        assert_eq!(transform_xor(&masked, &salt), value);
    }

    #[test]
    fn color_codec_roundtrip() {
        assert_eq!(
            encode_color_type(Color {
                r: 0x12,
                g: 0x34,
                b: 0x56
            }),
            0x123456
        );

        let color = decode_color_type(0x123456);
        assert_eq!((color.r, color.g, color.b), (0x12, 0x34, 0x56));
    }

    #[test]
    fn credentials_need_password_or_keyfile() {
        assert!(Credentials::from(None, None).is_err());
        assert!(Credentials::from(Some("password".to_string()), None).is_ok());
    }

    #[test]
    fn create_initializes_meta_and_recycle_bin() {
        let kdbx = Kdbx::create(credentials("password"), Some(test_config()), None);

        let meta = kdbx.get_meta().unwrap();
        assert_eq!(meta.generator.as_deref(), Some("frb_keepass"));
        assert_eq!(meta.recyclebin_enabled, Some(true));

        let recycle_id = meta.recyclebin_uuid.expect("recycle bin was not created");
        let groups = kdbx.get_groups().unwrap();
        assert!(groups
            .values()
            .any(|group| group.id == recycle_id && group.name == "Recycle Bin"));

        assert!(kdbx
            .get_entrys(None, None, None, None, None)
            .unwrap()
            .is_empty());

        // 没有 filepath 时无法保存
        assert!(kdbx.save_file(None).is_err());
    }

    #[test]
    fn lookups_with_unknown_ids_fail() {
        let kdbx = Kdbx::create(credentials("password"), Some(test_config()), None);
        let unknown = Uuid::new_v4().to_string();

        assert!(kdbx.get_entry("not-a-uuid".to_string(), None).is_err());
        assert!(kdbx.get_entry(unknown.clone(), None).is_err());
        assert!(kdbx
            .get_entrys(None, Some(unknown.clone()), None, None, None)
            .is_err());
        assert!(kdbx.get_attachment(42).is_err());
        assert!(kdbx.get_custom_data("missing".to_string(), None).is_none());
        assert!(kdbx.get_public_custom_data("missing".to_string()).is_none());
    }

    #[test]
    fn save_and_open_roundtrip() {
        let file = TempFile::new("roundtrip");

        {
            let kdbx = new_kdbx(&file);
            let root = root_id(&kdbx);

            kdbx.action(KdbxAction::UpdateEntry(new_entry(&root, "Alice")))
                .unwrap();
            kdbx.action(KdbxAction::UpdateMeta {
                database_name: Some("MyDatabase".to_string()),
                database_description: None,
                maintenance_history_days: None,
                color: None,
                history_max_items: None,
                history_max_size: None,
            })
            .unwrap();
        }

        let opened = Kdbx::open(credentials("password"), file.path()).unwrap();

        assert_eq!(
            opened.get_meta().unwrap().database_name.as_deref(),
            Some("MyDatabase")
        );
        assert!(matches!(
            opened.get_config().unwrap().kdf_config,
            KdfConfig::Aes { rounds: 10 }
        ));

        let entries = opened.get_entrys(None, None, None, None, None).unwrap();
        assert_eq!(entries.len(), 1);
        assert_eq!(field(&entries[0], KEY_TITLE), "Alice");
        assert_eq!(field(&entries[0], KEY_PASSWORD), "s3cr3t");

        assert!(Kdbx::open(credentials("wrong"), file.path()).is_err());
    }

    #[test]
    fn update_entry_creates_then_modifies() {
        let file = TempFile::new("update_entry");
        let kdbx = new_kdbx(&file);
        let root = root_id(&kdbx);

        let entry = new_entry(&root, "Alice");
        let id = entry.id.clone();
        kdbx.action(KdbxAction::UpdateEntry(entry)).unwrap();

        let mut entry = new_entry(&root, "Alice Renamed");
        entry.id = id.clone();
        entry.tags = vec!["work".to_string()];
        kdbx.action(KdbxAction::UpdateEntry(entry)).unwrap();

        let stored = kdbx.get_entry(id, None).unwrap();
        assert_eq!(field(&stored, KEY_TITLE), "Alice Renamed");
        assert_eq!(stored.tags, vec!["work".to_string()]);
        assert_eq!(stored.parent, root);
    }

    #[test]
    fn update_group_creates_and_scopes_entries() {
        let file = TempFile::new("update_group");
        let kdbx = new_kdbx(&file);
        let root = root_id(&kdbx);

        let group_id = Uuid::new_v4().to_string();
        kdbx.action(KdbxAction::UpdateGroup(new_group(
            &group_id,
            Some(root.clone()),
            "Work",
        )))
        .unwrap();

        let groups = kdbx.get_groups().unwrap();
        let created = groups
            .values()
            .find(|group| group.id == group_id)
            .expect("group was not created");
        assert_eq!(created.name, "Work");
        assert_eq!(created.parent.as_deref(), Some(root.as_str()));

        kdbx.action(KdbxAction::UpdateEntry(new_entry(&group_id, "Alice")))
            .unwrap();
        kdbx.action(KdbxAction::UpdateEntry(new_entry(&root, "Bob")))
            .unwrap();

        // 指定分组时只返回该分组(及其子组)内的条目
        let scoped = kdbx
            .get_entrys(None, Some(group_id.clone()), None, None, None)
            .unwrap();
        assert_eq!(scoped.len(), 1);
        assert_eq!(field(&scoped[0], KEY_TITLE), "Alice");

        // 从根开始则两个条目都能拿到
        assert_eq!(
            kdbx.get_entrys(None, None, None, None, None).unwrap().len(),
            2
        );
    }

    #[test]
    fn search_matches_fields_and_case_option() {
        let file = TempFile::new("search");
        let kdbx = new_kdbx(&file);
        let root = root_id(&kdbx);

        kdbx.action(KdbxAction::UpdateEntry(new_entry(&root, "Alice")))
            .unwrap();
        kdbx.action(KdbxAction::UpdateEntry(new_entry(&root, "Bob")))
            .unwrap();

        let search = |input: &str, case_sensitive: Option<bool>| {
            kdbx.get_entrys(Some(input.to_string()), None, None, None, case_sensitive)
                .unwrap()
        };

        // 默认忽略大小写
        assert_eq!(search("alice", None).len(), 1);
        assert_eq!(search("alice", Some(true)).len(), 0);
        assert_eq!(search("Alice", Some(true)).len(), 1);

        // 字段别名 t -> Title
        assert_eq!(search("t:bob", None).len(), 1);
        assert_eq!(search("t:nobody", None).len(), 0);
    }

    #[test]
    fn trash_restore_and_delete() {
        let file = TempFile::new("trash");
        let kdbx = new_kdbx(&file);
        let root = root_id(&kdbx);

        let entry = new_entry(&root, "Alice");
        let id = entry.id.clone();
        kdbx.action(KdbxAction::UpdateEntry(entry)).unwrap();

        kdbx.action(KdbxAction::Move2Trash(vec![id.clone()]))
            .unwrap();

        let recycle_id = kdbx.get_meta().unwrap().recyclebin_uuid.unwrap();
        assert_eq!(kdbx.get_entry(id.clone(), None).unwrap().parent, recycle_id);
        // 回收站内的条目不会出现在普通列表中
        assert!(kdbx
            .get_entrys(None, None, None, None, None)
            .unwrap()
            .is_empty());

        kdbx.action(KdbxAction::Restore(vec![id.clone()])).unwrap();
        assert_eq!(kdbx.get_entry(id.clone(), None).unwrap().parent, root);
        assert_eq!(
            kdbx.get_entrys(None, None, None, None, None).unwrap().len(),
            1
        );

        kdbx.action(KdbxAction::Delete(vec![id.clone()])).unwrap();
        assert!(kdbx.get_entry(id, None).is_err());
    }

    #[test]
    fn attachments_are_stored_and_readable() {
        let file = TempFile::new("attachment");
        let kdbx = new_kdbx(&file);
        let root = root_id(&kdbx);

        let mut entry = new_entry(&root, "Alice");
        entry.attachments = vec![Attachment {
            id: 0,
            name: "note.txt".to_string(),
            size: 3,
            data: Some(vec![1, 2, 3]),
        }];
        let id = entry.id.clone();
        kdbx.action(KdbxAction::UpdateEntry(entry)).unwrap();

        let stored = kdbx.get_entry(id, None).unwrap();
        assert_eq!(stored.attachments.len(), 1);

        let attachment = &stored.attachments[0];
        assert_eq!(attachment.name, "note.txt");
        assert_eq!(attachment.size, 3);
        // 列表里不带数据, 需要单独取
        assert!(attachment.data.is_none());
        assert_eq!(kdbx.get_attachment(attachment.id).unwrap(), vec![1, 2, 3]);
    }

    #[test]
    fn summary_collects_entry_fields() {
        let file = TempFile::new("summary");
        let kdbx = new_kdbx(&file);
        let root = root_id(&kdbx);

        let mut entry = new_entry(&root, "Alice");
        entry.fields.insert(
            KEY_URL.to_string(),
            FieldValue::new("https://example.com".to_string(), None),
        );
        entry.fields.insert(
            KEY_USER_NAME.to_string(),
            FieldValue::new("alice".to_string(), None),
        );
        entry.fields.insert(
            KEY_EMAIL.to_string(),
            FieldValue::new("alice@example.com".to_string(), None),
        );
        entry.fields.insert(
            "MyField".to_string(),
            FieldValue::new("whatever".to_string(), None),
        );
        entry.tags = vec!["work".to_string()];

        kdbx.action(KdbxAction::UpdateEntry(entry)).unwrap();

        let (summary, _, _) = kdbx.summary().unwrap();
        assert!(summary.urls.contains("https://example.com"));
        assert!(summary.user_names.contains("alice"));
        assert!(summary.emails.contains("alice@example.com"));
        assert!(summary.tags.contains("work"));
        assert!(summary.custom_fields.contains("MyField"));
        // 内置字段不算自定义字段
        assert!(!summary.custom_fields.contains(KEY_TITLE));
    }

    #[test]
    fn modify_password_changes_the_key() {
        let file = TempFile::new("modify_password");

        {
            let mut kdbx = new_kdbx(&file);
            let root = root_id(&kdbx);

            kdbx.action(KdbxAction::UpdateEntry(new_entry(&root, "Alice")))
                .unwrap();
            kdbx.modify_password(credentials("new-password")).unwrap();
        }

        assert!(Kdbx::open(credentials("password"), file.path()).is_err());
    }

    #[test]
    fn entry_data_clone_assigns_a_new_id() {
        let source = new_entry(&Uuid::new_v4().to_string(), "Alice");
        let copy = source.clone();

        assert_ne!(copy.id, source.id);
        assert_eq!(copy.parent, source.parent);
        assert_eq!(field(&copy, KEY_TITLE), "Alice");
    }

    fn expected(pairs: Vec<(Option<&str>, &str)>) -> Vec<(Option<String>, String)> {
        pairs
            .into_iter()
            .map(|(k, v)| (k.map(String::from), String::from(v)))
            .collect()
    }

    #[test]
    fn test_parse_all_cases() {
        // ============================================================
        // 第一部分：ignore_case = false
        // ============================================================
        let ignore = false;

        // 1. 空输入
        let parsed = SearchInputParse::from(String::new(), ignore);
        assert_eq!(parsed.parse_objects, vec![]);

        // 2. 纯空白
        let parsed = SearchInputParse::from("   \t\n  ".to_string(), ignore);
        assert_eq!(parsed.parse_objects, vec![]);

        // 3. 简单无字段
        let parsed = SearchInputParse::from("hello".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(None, "hello")]));

        // 4. 简单字段
        let parsed = SearchInputParse::from("field:value".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "value")])
        );

        // 5. 多个字段
        let parsed = SearchInputParse::from("a:1 b:2 c:3".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("a"), "1"), (Some("b"), "2"), (Some("c"), "3")])
        );

        // 6. 值含空格未引号 → 分裂
        let parsed = SearchInputParse::from("field:value with space".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![
                (Some("field"), "value"),
                (None, "with"),
                (None, "space")
            ])
        );

        // 7. 双引号值
        let parsed = SearchInputParse::from("field:\"value with spaces\"".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "value with spaces")])
        );

        // 8. 单引号值
        let parsed = SearchInputParse::from("field:'single quoted'".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "single quoted")])
        );

        // 9. 混合引号和普通（多个字段）
        let input = r#"a:"hello world" b:'foo bar' c:plain"#.to_string();
        let parsed = SearchInputParse::from(input, ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![
                (Some("a"), "hello world"),
                (Some("b"), "foo bar"),
                (Some("c"), "plain")
            ])
        );

        // 10. key 带引号，后跟冒号
        let parsed = SearchInputParse::from("\"key\":value".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("key"), "value")]));

        // 11. key 带引号，后跟冒号和空格
        let parsed = SearchInputParse::from("\"key\": \"value\"".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("key"), "value")]));

        // 12. key 带引号，后跟空格（无冒号）
        let parsed = SearchInputParse::from("\"key\" value".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(None, "key"), (None, "value")])
        );

        // 13. 多个 key 引号
        let parsed = SearchInputParse::from("\"a\":1 \"b\":2".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("a"), "1"), (Some("b"), "2")])
        );

        // 14. 混合 key 引号和无引号字段
        let parsed = SearchInputParse::from("\"a\":1 b:2".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("a"), "1"), (Some("b"), "2")])
        );

        // 15. key 引号，值含空格未引号（分裂）
        let parsed = SearchInputParse::from("\"key\":value with space".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![
                (Some("key"), "value"),
                (None, "with"),
                (None, "space")
            ])
        );

        // 16. key 引号，值带引号
        let parsed = SearchInputParse::from("\"key\":\"value\"".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("key"), "value")]));

        // 17. key 引号，值带引号且内部含冒号
        let parsed = SearchInputParse::from("\"key\":\"a:b\"".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("key"), "a:b")]));

        // 18. 无字段名的引号块
        let parsed = SearchInputParse::from("\"just a quote\"".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(None, "just a quote")]));

        // 19. 多个引号块无字段
        let parsed = SearchInputParse::from("\"a\" \"b\" 'c'".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(None, "a"), (None, "b"), (None, "c")])
        );

        // 20. 混合字段、引号和普通词
        let parsed = SearchInputParse::from(r#"a:"first" b second 'third'"#.to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![
                (Some("a"), "first"),
                (None, "b"),
                (None, "second"),
                (None, "third")
            ])
        );

        // 21. 引号前有普通块（空格分隔）
        let parsed = SearchInputParse::from("hello \"world\"".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(None, "hello"), (None, "world")])
        );

        // 22. 引号前有字段块（冒号）
        let parsed = SearchInputParse::from("field:value 'extra'".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "value"), (None, "extra")])
        );

        // 23. 空引号夹在中间
        let parsed = SearchInputParse::from("hello \"\" world".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(None, "hello"), (None, "world")])
        );

        // 24. 空引号单独
        let parsed = SearchInputParse::from("\"\"".to_string(), ignore);
        assert_eq!(parsed.parse_objects, vec![]);

        // 25. 字段名后空引号（丢弃）
        let parsed = SearchInputParse::from("field:\"\"".to_string(), ignore);
        assert_eq!(parsed.parse_objects, vec![]);

        // 26. 未闭合引号（有字段名）
        let parsed = SearchInputParse::from("field:\"unclosed".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "unclosed")])
        );

        // 27. 未闭合引号（无字段名）
        let parsed = SearchInputParse::from("\"no end".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(None, "no end")]));

        // 28. 相邻引号无空格
        let parsed = SearchInputParse::from("hello'world'".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(None, "hello"), (None, "world")])
        );

        // 29. 字段后紧接引号（无空格）
        let parsed = SearchInputParse::from("field:\"value\"".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "value")])
        );

        // 30. 多个字段带引号
        let parsed = SearchInputParse::from(
            r#"user:"alice" role:'admin' status:active"#.to_string(),
            ignore,
        );
        assert_eq!(
            parsed.parse_objects,
            expected(vec![
                (Some("user"), "alice"),
                (Some("role"), "admin"),
                (Some("status"), "active")
            ])
        );

        // 31. 多个冒号（后面的当作普通字符）
        let parsed = SearchInputParse::from("a:b:c".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("a"), "b:c")]));

        // 32. 冒号前后有空格（不作为分隔符）
        let parsed = SearchInputParse::from("a :b".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(None, "a"), (None, ":b")])
        );

        // 33. 带有 Unicode 字符
        let parsed = SearchInputParse::from("名字:张三 \"你好世界\"".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("名字"), "张三"), (None, "你好世界")])
        );

        // 34. 混合多个空格和引号
        let parsed = SearchInputParse::from("a:1  b:'2 3'  c:4".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("a"), "1"), (Some("b"), "2 3"), (Some("c"), "4")])
        );

        // 35. 多个冒号连续
        let parsed = SearchInputParse::from("a:b:c:d".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("a"), "b:c:d")]));

        // ============================================================
        // 第二部分：ignore_case = true
        // ============================================================
        let ignore = true;

        // 36. 普通字段值大写
        let parsed = SearchInputParse::from("field:VALUE".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "value")])
        );

        // 37. key 引号，值大写
        let parsed = SearchInputParse::from("\"KEY\":VALUE".to_string(), ignore);
        assert_eq!(parsed.parse_objects, expected(vec![(Some("KEY"), "value")]));

        // 38. 值带引号大写
        let parsed = SearchInputParse::from("field:\"VALUE WITH SPACES\"".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "value with spaces")])
        );

        // 39. 混合大小写字段
        let parsed = SearchInputParse::from("A:1 B:'TWO' C:THREE".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![
                (Some("A"), "1"),
                (Some("B"), "two"),
                (Some("C"), "three")
            ])
        );

        // 40. 未闭合引号大写
        let parsed = SearchInputParse::from("field:\"UNCLOSED".to_string(), ignore);
        assert_eq!(
            parsed.parse_objects,
            expected(vec![(Some("field"), "unclosed")])
        );
    }
}
