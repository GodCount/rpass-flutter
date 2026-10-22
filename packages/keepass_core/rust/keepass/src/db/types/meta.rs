use chrono::NaiveDateTime;
use indexmap::IndexMap;
use uuid::Uuid;

use crate::db::{Color, CustomDataItem};

/// Customized, record maintenance_history_days_changed modification time
pub const CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED: &str = "MAINTENANCE_HISTORY_DAYS_CHANGED";
/// Customized, record color_changed modification time
pub const CUSTOM_COLOR_CHANGED: &str = "COLOR_CHANGED";
/// Customized, record master_key_change_rec_changed modification time
pub const CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED: &str = "MASTER_KEY_CHANGE_REC_CHANGED";
/// Customized, record master_key_change_force_changed modification time
pub const CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED: &str = "MASTER_KEY_CHANGE_FORCE";
/// Customized, record memory_protection_changed modification time
pub const CUSTOM_MEMORY_PROTECTION_CHANGED: &str = "MEMORY_PROTECTION_CHANGED";
/// Customized, record history_max_items_changed modification time
pub const CUSTOM_HISTORY_MAX_ITEMS_CHANGED: &str = "HISTORY_MAX_ITEMS_CHANGED";
/// Customized, record history_max_size_changed modification time
pub const CUSTOM_HISTORY_MAX_SIZE_CHANGED: &str = "HISTORY_MAX_SIZE_CHANGED";
/// Customized, record database_config_changed modification time
pub const CUSTOM_DATABASE_CONFIG_CHANGED: &str = "DATABASE_CONFIG_CHANGED";

/// Database metadata
#[derive(Debug, Default, Eq, PartialEq, Clone)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub struct Meta {
    /// the program that generated the database file.
    pub generator: Option<String>,

    /// name of the database
    pub database_name: Option<String>,

    /// time the database name was last changed
    pub database_name_changed: Option<NaiveDateTime>,

    /// description of the database
    pub database_description: Option<String>,

    /// time the database description was last changed
    pub database_description_changed: Option<NaiveDateTime>,

    /// default username
    pub default_username: Option<String>,

    /// time the default username was last changed
    pub default_username_changed: Option<NaiveDateTime>,

    /// number of days of maintenance history to keep
    pub maintenance_history_days: Option<usize>,

    /// color code for the database
    pub color: Option<Color>,

    /// time the master key was last changed
    pub master_key_changed: Option<NaiveDateTime>,

    /// Number of days until a change of the master key is recommended. -1 means never.
    pub master_key_change_rec: Option<isize>,

    /// Number of days until a change of the master key is forced. -1 means never.
    pub master_key_change_force: Option<isize>,

    /// memory protection settings
    pub memory_protection: Option<MemoryProtection>,

    /// whether the recycle bin is enabled
    pub recyclebin_enabled: Option<bool>,

    /// A UUID for the recycle bin group
    pub recyclebin_uuid: Option<Uuid>,

    /// last time the recycle bin was changed
    pub recyclebin_changed: Option<NaiveDateTime>,

    /// UUID of the group containing entry templates
    pub entry_templates_group: Option<Uuid>,

    /// last time the group containing entry templates was changed
    pub entry_templates_group_changed: Option<NaiveDateTime>,

    /// UUID of the last selected group
    pub last_selected_group: Option<Uuid>,

    /// UUID of the last top-visible group
    pub last_top_visible_group: Option<Uuid>,

    /// Maximum number of items of history to keep
    pub history_max_items: Option<isize>,

    /// Maximum size of the history to keep
    pub history_max_size: Option<isize>,

    /// Last time the settings were changed
    pub settings_changed: Option<NaiveDateTime>,

    /// Additional custom data fields
    pub custom_data: IndexMap<String, CustomDataItem>,
}

impl Meta {
    /// get custom data time
    pub fn get_custom_time_changed(&self, key: &str, default: NaiveDateTime) -> NaiveDateTime {
        self.custom_data
            .get(key)
            .and_then(|item| item.last_modification_time)
            .unwrap_or(default)
    }

    /// set custom data time
    pub fn set_custom_time_changed(&mut self, key: &str, time: NaiveDateTime) {
        if let Some(item) = self.custom_data.get_mut(key) {
            item.last_modification_time = Some(time);
        } else {
            self.custom_data.insert(
                key.to_string(),
                CustomDataItem {
                    value: None,
                    last_modification_time: Some(time),
                },
            );
        }
    }
}

/// Database memory protection settings
#[derive(Debug, PartialEq, Eq, Clone)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub struct MemoryProtection {
    /// Whether titles should be protected
    pub protect_title: bool,

    /// Whether user names should be protected
    pub protect_username: bool,

    /// Whether passwords should be protected
    pub protect_password: bool,

    /// Whether URLs should be protected
    pub protect_url: bool,

    /// Whether notes should be protected
    pub protect_notes: bool,
}

impl Default for MemoryProtection {
    fn default() -> Self {
        Self {
            protect_title: false,
            protect_username: false,
            protect_password: true,
            protect_url: false,
            protect_notes: false,
        }
    }
}
