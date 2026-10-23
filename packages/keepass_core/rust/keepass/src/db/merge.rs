//! Merging two versions of the same database.
//!
//! See [`Database::merge`][crate::Database::merge] for the entry point. The
//! types in this module describe what a merge changed, via the returned
//! [`MergeLog`].

use std::{collections::HashSet, ops::Deref};

use chrono::NaiveDateTime;
use thiserror::Error;
use uuid::Uuid;

use crate::{
    Database,
    db::{
        AttachmentId, CustomIconId, Entry, EntryId, EntryMut, EntryRef, Group, GroupId, GroupRef, History,
        MoveGroupError, Times,
        meta::{
            CUSTOM_COLOR_CHANGED, CUSTOM_DATABASE_CONFIG_CHANGED, CUSTOM_HISTORY_MAX_ITEMS_CHANGED,
            CUSTOM_HISTORY_MAX_SIZE_CHANGED, CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED,
            CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED, CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED,
            CUSTOM_MEMORY_PROTECTION_CHANGED,
        },
    },
};

/// The kind of change a merge applied to an object.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MergeEventType {
    /// The object existed only in the source and was created in the destination.
    Created,
    /// The object was deleted as a result of the merge.
    Deleted,
    /// The object was moved to a different location (parent group).
    LocationUpdated,
    /// The object's contents were updated from the source.
    Updated,
}

/// The object a [`MergeEvent`] applies to.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MergeEventTarget {
    /// An entry, identified by its UUID.
    Entry(EntryId),
    /// A group, identified by its UUID.
    Group(GroupId),
    /// A custom icon, identified by its UUID.
    Icon(CustomIconId),
    /// A piece of database metadata.
    Meta(MetaField),
    /// The record of a deleted object, identified by the UUID of the deleted object.
    DeletedObject(Uuid),
}

/// A piece of database metadata that a merge can change, see [`MergeEventTarget::Meta`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MetaField {
    /// The database name.
    DatabaseName,
    /// The database description.
    DatabaseDescription,
    /// The default username for new entries.
    DefaultUsername,
    /// The recycle bin group and whether the recycle bin is enabled.
    RecycleBin,
    /// The group containing entry templates.
    EntryTemplatesGroup,
    /// The database master key changed
    MasterKeyChanged,

    /// The database maintenance history days
    MaintenanceHistoryDays,
    /// The database color.
    Color,
    /// The database master key change rec
    MasterKeyChangeRec,
    /// The database master key change force
    MasterKeyChangeForce,
    /// The database memory protection
    MemoryProtection,
    /// The database history max items
    HistoryMaxItems,
    /// The database history max size
    HistoryMaxSize,
    /// The database encrypt config
    Config,

    /// A database-wide custom data item, identified by its key.
    CustomData(String),
}

/// A single change applied to the destination database during a merge.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MergeEvent {
    /// The object that was changed.
    pub target: MergeEventTarget,
    /// The kind of change that was applied.
    pub event_type: MergeEventType,
}

/// Errors while merge two databases
#[derive(Error, Debug)]
#[non_exhaustive]
pub enum MergeError {
    /// Two entries with the same UUID have the same modification time but different contents.
    #[error("Entries with UUID {0} have the same modification time but have diverged.")]
    EntryModificationTimeNotUpdated(EntryId),

    /// Two groups with the same UUID have the same modification time but different contents.
    #[error("Groups with UUID {0} have the same modification time but have diverged.")]
    GroupModificationTimeNotUpdated(GroupId),

    /// An entry has two history items sharing the same timestamp, so their order is ambiguous.
    #[error("Found history entries with the same timestamp ({0}) for entry {1}.")]
    DuplicateHistoryEntries(NaiveDateTime, EntryId),

    /// A group could not be moved to its merged location.
    #[error(transparent)]
    MoveGroupError(#[from] MoveGroupError),
}

/// Record of everything a merge changed, returned by [`Database::merge`].
#[derive(Debug, Default, Clone)]
pub struct MergeLog {
    /// Non-fatal issues encountered during the merge.
    pub warnings: Vec<String>,
    /// Changes copied from the source because the source was newer.
    pub events: Vec<MergeEvent>,
    /// Changes kept from the destination: objects that exist or were deleted only
    /// there, and updates or moves where the destination is newer than the source.
    pub dest_events: Vec<MergeEvent>,
}

impl Database {
    /// Merge a database with another version of the same database, applying the changes to self.
    ///
    /// This function will use the UUIDs to detect what entries and groups are the same.
    pub fn merge(&mut self, other: &Database) -> Result<MergeLog, MergeError> {
        let mut log = MergeLog::default();
        merge_meta(self, other, &mut log)?;
        merge_icons(self, other, &mut log)?;
        merge_groups(self, other, &mut log)?;
        merge_deleted_objects(self, other, &mut log)?;
        self.cleanup();

        Ok(log)
    }
}

/// Get the last update time (modification or location change) of a group, considering its entries and subgroups.
fn get_last_update(group: GroupRef<'_>) -> Option<NaiveDateTime> {
    let last_update = group.times.last_modification.or(group.times.location_changed);

    group
        .entries()
        .filter_map(|e| e.times.last_modification.or(e.times.location_changed))
        .chain(
            group
                .groups()
                .filter_map(|g| g.times.last_modification.or(g.times.location_changed)),
        )
        .chain(last_update)
        .max()
}

/// Merge groups from `source` into `dest`, appending to a log of the merge process.
///
/// NOTE: this function will also call `merge_entries` to handle entries within the groups.
fn merge_groups(dest_db: &mut Database, source_db: &Database, log: &mut MergeLog) -> Result<(), MergeError> {
    let dest_groups = dest_db.groups.keys().cloned().collect::<HashSet<_>>();
    let source_groups = source_db.groups.keys().cloned().collect::<HashSet<_>>();

    // Handle groups that exist only in source and might need to be added.
    let mut groups_to_add = HashSet::new();
    for &id in source_groups.difference(&dest_groups) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let source = source_db.group(id).unwrap();

        // was the group deleted in dest?
        if let Some(deletion_time) = dest_db.deleted_objects.get(&id.uuid()) {
            // get the last modification time of the group in source.
            let source_last_update = get_last_update(source);

            let mut is_deleted = false;

            // compare deletion time and last update time to decide whether to re-add the group
            match (deletion_time, source_last_update) {
                (Some(deletion_time), Some(source_last_update)) => {
                    // if the group was deleted after its last modification time in source,
                    // do not re-add it, otherwise we can re-add the group
                    if *deletion_time >= source_last_update {
                        is_deleted = true;
                    }
                }
                (Some(_), None) => {
                    // blank last update time in source - do not re-add the group
                    is_deleted = true;
                }
                (None, Some(_)) => {
                    // blank deletion time is probably older than concrete update time - re-add the
                    // group
                }
                (None, None) => {
                    // both times are blank - do not re-add the group
                    is_deleted = true;
                }
            }

            if is_deleted {
                log.dest_events.push(MergeEvent {
                    target: MergeEventTarget::Group(id),
                    event_type: MergeEventType::Deleted,
                });
                continue;
            }
        }

        groups_to_add.insert(id);
    }

    // actually add groups from groups_to_add. Use a stack to ensure that parent groups are added as needed
    let mut add_stack = Vec::new();
    loop {
        // refill the stack if it's empty
        if add_stack.is_empty() {
            if let Some(&next) = groups_to_add.iter().next() {
                // refill the stack with an arbitrary group to re-add
                add_stack.push(next);
                groups_to_add.remove(&next);
            } else {
                // no more groups to re-add
                break;
            }
        }

        // get the current group from the stack
        #[allow(clippy::expect_used)] // stack is guaranteed to be non-empty
        let &id = add_stack.last().expect("non-empty queue");

        // get the desired parent of the group to be re-added
        #[allow(clippy::expect_used)] // id is guaranteed to exist in source
        let source = source_db.group(id).expect("source group exists");

        #[allow(clippy::expect_used)] // this would be a severe issue with the algorithm
        let parent_id = source.parent().expect("cannot re-add root").id();

        // does the parent exist in dest?
        if let Some(mut parent) = dest_db.group_mut(parent_id) {
            // yes - re-add the group
            #[allow(clippy::expect_used)] // id was selected from source_groups.difference(dest_groups)
            let mut dest_group = parent
                .add_group_with_id(id)
                .expect("group to be re-added should not exist yet");
            dest_group.times = source.times.clone();
            dest_group.name = source.name.clone();
            dest_group.notes = source.notes.clone();
            dest_group.tags = source.tags.clone();
            dest_group.icon = source.icon.clone();
            dest_group.custom_data = source.custom_data.clone();
            dest_group.is_expanded = source.is_expanded;
            dest_group.default_autotype_sequence = source.default_autotype_sequence.clone();
            dest_group.enable_autotype = source.enable_autotype;
            dest_group.enable_searching = source.enable_searching;
            dest_group.enable_display = source.enable_display;
            dest_group.last_top_visible_entry = source.last_top_visible_entry;

            log.events.push(MergeEvent {
                target: MergeEventTarget::Group(id),
                event_type: MergeEventType::Created,
            });

            // success - remove the current item from the stack (it was already removed from the set)
            add_stack.pop();
        } else {
            // the parent does not exist yet - add it to the stack to be re-added first
            add_stack.push(parent_id);

            // since we will deal with the parent now, it doesn't need to be handled later
            groups_to_add.remove(&parent_id);
        }
    }

    // Handle groups that exist only in destination. These groups might need to be deleted.
    let mut to_delete = Vec::new();
    for &id in dest_groups.difference(&source_groups) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let dest = dest_db.group_mut(id).unwrap();

        // was the group deleted in source?
        if let Some(deletion_time) = source_db.deleted_objects.get(&id.uuid()) {
            let dest_last_updated = get_last_update(dest.as_ref());
            if let (Some(deletion_time), Some(dest_last_updated)) = (deletion_time, dest_last_updated) {
                // if the group was deleted and then later modified in dest, do not delete it
                if *deletion_time < dest_last_updated {
                    continue;
                }
            }

            // queue the deletion so that all subgroups will also emit a deletion event
            to_delete.push(id);
            dest_db.deleted_objects.insert(id.uuid(), *deletion_time);

            log.events.push(MergeEvent {
                target: MergeEventTarget::Group(id),
                event_type: MergeEventType::Deleted,
            });
        } else {
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Group(id),
                event_type: MergeEventType::Created,
            });
        }
    }

    // perform the entry merges now that all groups that need adding are added but the groups that
    // need deleting still haven't been deleted, so that the entries can still be accessed and
    // generate events
    merge_entries(dest_db, source_db, log)?;

    // perform all group deletions
    while let Some(id) = to_delete.pop() {
        if let Some(group) = dest_db.group_mut(id) {
            group.remove();
        }
    }

    // re-compute the group set after additions and deletions
    let dest_groups = dest_db.groups.keys().cloned().collect::<HashSet<_>>();

    // Handle groups that exist in both source and destination.
    let mut moves = Vec::new();
    let root_id = dest_db.root().id();
    for &id in dest_groups.intersection(&source_groups) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let mut dest = dest_db.group_mut(id).unwrap();

        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let source = source_db.group(id).unwrap();

        let dest_parent_id = dest.as_ref().parent().map(|p| p.id());
        let source_parent_id = source.parent().map(|p| p.id());

        // was the group moved?
        if dest_parent_id != source_parent_id {
            let dest_location_changed = dest.times.location_changed;
            let source_location_changed = source.times.location_changed;

            if let (Some(dlc), Some(slc)) = (dest_location_changed, source_location_changed) {
                if slc > dlc {
                    // the source group has been moved more recently than the destination group.
                    // try to move the destination group to the new location.

                    let Some(parent_id) = source.parent().map(|p| p.id()) else {
                        log.warnings.push(format!("Cannot move root group {}", id,));
                        continue;
                    };

                    if !dest_groups.contains(&parent_id) {
                        log.warnings.push(format!(
                            "Cannot move group {} to group {} because the group does not exist in the destination database.",
                            id,
                            parent_id,
                        ));
                        continue;
                    };

                    // to avoid creating cycles in situations where two groups swap their parent-child
                    // relationship, move all groups to root first and then to their final destination
                    moves.push((id, parent_id));
                    dest.move_to(root_id)?;
                    dest.times.location_changed = Some(slc);

                    log.events.push(MergeEvent {
                        target: MergeEventTarget::Group(id),
                        event_type: MergeEventType::LocationUpdated,
                    });
                } else {
                    log.dest_events.push(MergeEvent {
                        target: MergeEventTarget::Group(id),
                        event_type: MergeEventType::LocationUpdated,
                    });
                }
            } else {
                log.warnings.push(format!(
                    "Cannot determine which group {} move is more recent because one of the groups does not have a location changed timestamp.",
                    id,
                ));
            }
        }

        let dest_last_modification = dest.times.last_modification.unwrap_or_else(|| {
            log.warnings.push(format!(
                "Destination group {} did not have a last modification timestamp",
                id
            ));
            Times::now()
        });

        let source_last_modification = source.times.last_modification.unwrap_or_else(|| {
            log.warnings.push(format!(
                "Source group {} did not have a last modification timestamp",
                id
            ));
            Times::epoch()
        });

        if dest_last_modification == source_last_modification {
            if have_groups_diverged(&dest, &source) {
                // Both sides changed the group within the same second (timestamps have no
                // finer resolution), or one side changed it without updating the timestamp.
                // There is no telling which change is newer: keep the destination's.
                log.warnings.push(format!(
                    "Group {} was changed on both sides at the same time {}; kept the destination's version.",
                    id, dest_last_modification,
                ));
            }
            continue;
        }

        if dest_last_modification > source_last_modification {
            // The destination group is more recent than the source group.
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Group(id),
                event_type: MergeEventType::Updated,
            });
            continue;
        }

        // The source group is more recent than the destination group. Update dest with source.
        dest.name = source.name.clone();
        dest.notes = source.notes.clone();
        dest.tags = source.tags.clone();
        dest.icon = source.icon.clone();
        dest.custom_data = source.custom_data.clone();
        dest.times.last_modification = source.times.last_modification.or(dest.times.last_modification);
        dest.times.expiry = source.times.expiry;
        dest.times.expires = source.times.expires;
        dest.is_expanded = source.is_expanded;
        dest.default_autotype_sequence = source.default_autotype_sequence.clone();
        dest.enable_autotype = source.enable_autotype;
        dest.enable_searching = source.enable_searching;
        dest.enable_display = source.enable_display;
        dest.last_top_visible_entry = source.last_top_visible_entry;

        log.events.push(MergeEvent {
            target: MergeEventTarget::Group(id),
            event_type: MergeEventType::Updated,
        });
    }

    // perform all the moves that were queued up
    for (group_id, parent_id) in moves {
        #[allow(clippy::unwrap_used)] // group_id and parent_id are guaranteed to exist
        let mut group = dest_db.group_mut(group_id).unwrap();
        group.move_to(parent_id)?;
    }

    Ok(())
}

/// Merge entries from `source` into `dest`, appending to a log of the merge process.
fn merge_entries(dest_db: &mut Database, source_db: &Database, log: &mut MergeLog) -> Result<(), MergeError> {
    let dest_entries = dest_db.entries.keys().cloned().collect::<HashSet<_>>();
    let source_entries = source_db.entries.keys().cloned().collect::<HashSet<_>>();

    // Handle entries that exist only in source and might need to be added.
    for &id in source_entries.difference(&dest_entries) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let source_entry = source_db.entry(id).unwrap();

        // was the entry deleted in dest?
        if let Some(deletion_time) = dest_db.deleted_objects.get(&id.uuid()) {
            // get the last modification or location change time in source.
            let source_update_time = source_entry
                .times
                .last_modification
                .or(source_entry.times.location_changed);

            let mut is_deleted = false;

            match (deletion_time, source_update_time) {
                (Some(deletion_time), Some(source_update_time)) => {
                    // if the entry was deleted after its last modification time in source,
                    // do not re-add it
                    if *deletion_time >= source_update_time {
                        is_deleted = true;
                    }
                }
                (Some(_), None) => {
                    // blank last update time in source - do not re-add the entry
                    is_deleted = true;
                }
                (None, Some(_)) => {
                    // blank deletion time is probably older than concrete update time - re-add the
                    // entry
                }
                (None, None) => {
                    // both times are blank - do not re-add the entry
                    is_deleted = true;
                }
            }

            if is_deleted {
                log.dest_events.push(MergeEvent {
                    target: MergeEventTarget::Entry(id),
                    event_type: MergeEventType::Deleted,
                });
                continue;
            }

            // otherwise, we can re-add the entry
        }

        let parent_id = source_entry.parent().id();

        let Some(mut parent) = dest_db.group_mut(parent_id) else {
            log.warnings.push(format!(
                "Cannot add entry {} because its parent group {} does not exist in the destination database.",
                id, parent_id,
            ));
            continue;
        };

        #[allow(clippy::expect_used)] // id was selected from source_entries.difference(dest_entries)
        let mut entry = parent
            .add_entry_with_id(id)
            .expect("entry to be (re-)added should not exist yet");

        let mut entry_clone = source_entry.deref().clone();
        entry_clone.attachments.clear();

        if let Some(history) = entry_clone.history.as_mut() {
            let entry_id = id;

            for (history_id, history_entry) in &mut history.entries {
                for (_, id) in &mut history_entry.attachments {
                    #[allow(clippy::expect_used)]
                    let attch = source_db
                        .attachment(*id)
                        .expect("Unexpected attachment does not exist");
                    *id = entry
                        .database_mut()
                        .add_attachment(&attch.data, vec![(entry_id, Some(*history_id))]);
                }
            }
        }

        *entry = entry_clone;

        for (name, attach) in source_entry.attachments_named() {
            entry.add_attachment(name, attach.data.clone());
        }

        log.events.push(MergeEvent {
            target: MergeEventTarget::Entry(id),
            event_type: MergeEventType::Created,
        });
    }

    // Handle entries that exist only in destination. These entries might need to be deleted.
    for &id in dest_entries.difference(&source_entries) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let dest_entry = dest_db.entry_mut(id).unwrap();

        // was the entry deleted in source?
        if let Some(deletion_time) = source_db.deleted_objects.get(&id.uuid()) {
            let dest_update_time = dest_entry
                .times
                .last_modification
                .or(dest_entry.times.location_changed);

            if let (Some(deletion_time), Some(dest_update_time)) = (deletion_time, dest_update_time) {
                // if the entry was deleted and then later modified in dest, do not delete it
                if *deletion_time < dest_update_time {
                    continue;
                }
            }

            dest_entry.remove();
            dest_db.deleted_objects.insert(id.uuid(), *deletion_time);

            log.events.push(MergeEvent {
                target: MergeEventTarget::Entry(id),
                event_type: MergeEventType::Deleted,
            });
        } else {
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Entry(id),
                event_type: MergeEventType::Created,
            });
        }
    }

    // Handle entries that exist in both source and destination.
    for &id in dest_entries.intersection(&source_entries) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist in both dest and source
        let mut dest_entry = dest_db.entry_mut(id).unwrap();

        #[allow(clippy::unwrap_used)] // id is guaranteed to exist in both dest and source
        let source_entry = source_db.entry(id).unwrap();

        let dest_parent_id = dest_entry.as_ref().parent().id();
        let source_parent_id = source_entry.parent().id();

        let dest_entry_clone = dest_entry.deref().clone();

        // has the entry moved?
        if dest_parent_id != source_parent_id {
            // which move is more recent?
            let source_location_changed = source_entry.times.location_changed;
            let dest_location_changed = dest_entry.times.location_changed;
            if let (Some(slc), Some(dlc)) = (source_location_changed, dest_location_changed) {
                if slc > dlc {
                    // the source entry has been moved more recently than the destination entry.
                    // try to move the destination entry to the new location.

                    if dest_entry.move_to(source_parent_id).is_ok() {
                        log.events.push(MergeEvent {
                            target: MergeEventTarget::Entry(id),
                            event_type: MergeEventType::LocationUpdated,
                        });
                        dest_entry.times.location_changed = Some(slc);
                    } else {
                        log.warnings.push(format!(
                            "Cannot move entry {} to group {} because the group does not exist in the destination database.",
                            id,
                            source_parent_id,
                        ));
                    }
                } else {
                    log.dest_events.push(MergeEvent {
                        target: MergeEventTarget::Entry(id),
                        event_type: MergeEventType::LocationUpdated,
                    });
                }
            } else {
                log.warnings.push(format!(
                    "Cannot determine which entry {} move is more recent because one of the entries does not have a location changed timestamp.",
                    id,
                ));
            }
        }

        let source_last_modification = source_entry.times.last_modification.unwrap_or_else(|| {
            log.warnings.push(format!(
                "Source entry {} did not have a last modification timestamp",
                id
            ));
            Times::epoch()
        });

        let dest_last_modification = dest_entry.times.last_modification.unwrap_or_else(|| {
            log.warnings.push(format!(
                "Destination entry {} did not have a last modification timestamp",
                id
            ));
            Times::now()
        });

        if dest_last_modification == source_last_modification {
            if !have_entries_diverged(&dest_entry, &source_entry) {
                continue;
            }

            // Both sides changed the entry within the same second (timestamps have no finer
            // resolution), or one side changed it without updating the timestamp. There is
            // no telling which change is newer: keep the destination's, and file the
            // source's in the history below so it is not lost.
            log.warnings.push(format!(
                "Entry {} was changed on both sides at the same time {}; kept the destination's version.",
                id, dest_last_modification,
            ));
        }

        let mut source_history = source_entry.history.clone().unwrap_or_else(|| {
            log.warnings.push(format!("Source entry {} had no history.", id));
            History::default()
        });
        source_history.add_entry(source_entry.deref().clone());

        let mut dest_history = dest_entry.history.clone().unwrap_or_else(|| {
            log.warnings
                .push(format!("Destination entry {} had no history.", id));
            History::default()
        });

        // 如果修改时间相同,则保留目标条目,所以不需要放进历史列表合并
        if dest_last_modification != source_last_modification {
            dest_history.add_entry(dest_entry_clone);
        }

        let mut merged_history = merge_history(&dest_history, &source_history, log)?;

        // 来源是最新时, 并且列表顶部是来源则删除, 来源合并到目标条目
        if source_last_modification > dest_last_modification {
            #[allow(clippy::indexing_slicing)]
            if merged_history[0].0 {
                merged_history.remove(0);
            }
        } else if dest_last_modification > source_last_modification {
            // 目标条目是最新时,并且列表顶部是目标则删除,目标条目没有变化
            #[allow(clippy::indexing_slicing)]
            if !merged_history[0].0 {
                merged_history.remove(0);
            }
        } // 时间相同时必然存在分歧, 把来源条目放进历史

        let merged_location_timestamp = dest_entry
            .times
            .location_changed
            .or(source_entry.times.location_changed);

        if source_last_modification > dest_last_modification {
            // The source entry is more recent than the destination entry. Replace dest with source.
            dest_entry.times.last_modification = source_entry.times.last_modification;
            dest_entry.times.expiry = source_entry.times.expiry;
            dest_entry.times.expires = source_entry.times.expires;
            dest_entry.fields = source_entry.fields.clone();
            dest_entry.autotype = source_entry.autotype.clone();
            dest_entry.tags = source_entry.tags.clone();
            dest_entry.custom_data = source_entry.custom_data.clone();
            dest_entry.icon = source_entry.icon.clone();
            dest_entry.foreground_color = source_entry.foreground_color.clone();
            dest_entry.background_color = source_entry.background_color.clone();
            dest_entry.override_url = source_entry.override_url.clone();
            dest_entry.quality_check = source_entry.quality_check;
            dest_entry.previous_parent_group = source_entry.previous_parent_group;

            merge_attachments(&mut dest_entry, &source_entry, log);

            log.events.push(MergeEvent {
                target: MergeEventTarget::Entry(id),
                event_type: MergeEventType::Updated,
            });
        } else {
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Entry(id),
                event_type: MergeEventType::Updated,
            });
        }

        // 清除目标条目历史记录附件的所有反向引用
        let entry_id = dest_entry.id();
        dest_entry
            .database_mut()
            .foreach_attachment_mut(move |mut attach| {
                attach
                    .entries
                    .retain(move |(id, history_id)| id != &entry_id || history_id.is_none());
            });

        // 添加来源附件和重建历史记录附件的所有反向引用
        for (index, (is_source, entry)) in merged_history.iter_mut().enumerate() {
            let entry_id = entry.id();
            for (_, id) in &mut entry.attachments {
                if *is_source {
                    #[allow(clippy::expect_used)]
                    let attch = source_db
                        .attachment(*id)
                        .expect("Unexpected attachment does not exist");
                    *id = dest_entry
                        .database_mut()
                        .add_attachment(&attch.data, vec![(entry_id, Some(index as u32))]);
                } else {
                    #[allow(clippy::expect_used)]
                    let mut attach = dest_entry
                        .database_mut()
                        .attachment_mut(*id)
                        .expect("Unexpected attachment does not exist");
                    attach.entries.push((entry_id, Some(index as u32)));
                }
            }
        }

        dest_entry.history = Some(History::from(
            merged_history.into_iter().map(|(_, item)| item).collect(),
        ));
        dest_entry.times.location_changed = merged_location_timestamp;
    }

    Ok(())
}

fn merge_attachments(dest_entry: &mut EntryMut<'_>, source_entry: &EntryRef<'_>, _log: &mut MergeLog) {
    let dest_names = dest_entry.attachments.keys().cloned().collect::<HashSet<_>>();
    let source_names = source_entry.attachments.keys().cloned().collect::<HashSet<_>>();

    for name in dest_names.difference(&source_names) {
        dest_entry.remove_attachment_by_name(name);
    }

    for name in source_names {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let attach = source_entry.attachment_by_name(&name).unwrap();
        dest_entry.add_attachment(name, attach.data.clone());
    }
}

/// Merge two histories together, returning the merged Vec<Entry>.
fn merge_history(
    dest: &History,
    source: &History,
    log: &mut MergeLog,
) -> Result<Vec<(bool, Entry)>, MergeError> {
    let mut entries: Vec<(bool, Entry)> = Vec::new();

    let mut entries_dest: Vec<Entry> = dest.get_entries().iter().map(|(_, item)| item).cloned().collect();
    let mut entries_source: Vec<Entry> = source
        .get_entries()
        .iter()
        .map(|(_, item)| item)
        .cloned()
        .collect();

    for e in entries_dest.iter_mut() {
        if e.times.last_modification.is_none() {
            log.warnings.push(format!(
                "Destination history entry {} did not have a last modification timestamp",
                e.id()
            ));
            e.times.last_modification = Some(Times::epoch());
        }
    }

    for e in entries_source.iter_mut() {
        if e.times.last_modification.is_none() {
            log.warnings.push(format!(
                "Source history entry {} did not have a last modification timestamp",
                e.id()
            ));
            e.times.last_modification = Some(Times::epoch());
        }
    }

    entries_dest.sort_by_key(|e| e.times.last_modification);
    entries_source.sort_by_key(|e| e.times.last_modification);

    // perform a merge of both histories, which are sorted by last modification time.
    //
    // this code has a lot of unwraps but they are all checked - entry lists are checked for
    // emptiness, and times are made not-none before sorting, so the unwraps should never panic.
    #[allow(clippy::unwrap_used)]
    loop {
        match (entries_dest.is_empty(), entries_source.is_empty()) {
            (false, false) => {
                // Both histories have entries left to process.
                let dest_entry = entries_dest.last().unwrap();
                let source_entry = entries_source.last().unwrap();

                let dest_time = dest_entry.times.last_modification.unwrap();

                let source_time = source_entry.times.last_modification.unwrap();

                if dest_time > source_time {
                    entries.push((false, entries_dest.pop().unwrap()));
                } else if source_time > dest_time {
                    entries.push((true, entries_source.pop().unwrap()));
                } else if have_entries_diverged(dest_entry, source_entry) {
                    log.warnings.push(format!(
                        "History entries for {} have the same modification timestamp {} but have diverged.",
                        dest_entry.id(),
                        source_time,
                    ));

                    // Both entries have the same timestamp but are different.
                    entries.push((false, entries_dest.pop().unwrap()));
                    entries.push((true, entries_source.pop().unwrap()));
                } else {
                    // The entries are the same, so we can just take one of them.
                    entries.push((false, entries_dest.pop().unwrap()));
                    entries_source.pop();
                }
            }

            (true, false) => {
                // Only the source history has entries left to process - just take them all.
                entries.push((true, entries_source.pop().unwrap()));
            }
            (false, true) => {
                // Only the destination history has entries left to process - just take them all.
                entries.push((false, entries_dest.pop().unwrap()));
            }
            (true, true) => break,
        }
    }

    Ok(entries)
}

/// Merge custom icons, returning the merged history
fn merge_icons(dest_db: &mut Database, source_db: &Database, log: &mut MergeLog) -> Result<(), MergeError> {
    let dest_icons = dest_db.custom_icons.keys().cloned().collect::<HashSet<_>>();
    let source_icons = source_db.custom_icons.keys().cloned().collect::<HashSet<_>>();

    // Handle icons that exist only in source and might need to be added.
    for &id in source_icons.difference(&dest_icons) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let source_icon = source_db.custom_icons.get(&id).unwrap();

        if let Some(deletion_time) = dest_db.deleted_objects.get(&id.uuid()) {
            let source_last_modification = source_icon.last_modification_time;

            let mut is_deleted = false;

            if let (Some(deletion_time), Some(source_last_modification)) =
                (deletion_time, source_last_modification)
            {
                // if the icon was deleted after its last modification time in source,
                // do not re-add it
                if *deletion_time >= source_last_modification {
                    is_deleted = true;
                }
            } else if deletion_time.is_some() && source_last_modification.is_none() {
                // blank last modification time in source - do not re-add the icon
                is_deleted = true;
            } else if deletion_time.is_none() && source_last_modification.is_some() {
                // blank deletion time is probably older than concrete update time - re-add the icon
            } else {
                // both times are blank - do not re-add the icon
                is_deleted = true;
            }

            if is_deleted {
                log.dest_events.push(MergeEvent {
                    target: MergeEventTarget::Icon(id),
                    event_type: MergeEventType::Deleted,
                });
                continue;
            }
        }

        dest_db.custom_icons.insert(id, source_icon.clone());

        log.events.push(MergeEvent {
            target: MergeEventTarget::Icon(id),
            event_type: MergeEventType::Created,
        });
    }

    // Handle icons that exist only in destination. These icons might need to be deleted.
    for &id in dest_icons.difference(&source_icons) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist
        let dest_icon = dest_db.custom_icons.get(&id).unwrap();

        if let Some(deletion_time) = source_db.deleted_objects.get(&id.uuid()) {
            let dest_last_modification = dest_icon.last_modification_time;

            if let (Some(deletion_time), Some(dest_last_modification)) = (deletion_time, dest_last_modification)
            {
                // if the icon was deleted and then later modified in dest, do not delete it
                if *deletion_time < dest_last_modification {
                    continue;
                }
            }

            dest_db.custom_icons.shift_remove(&id);
            dest_db.deleted_objects.insert(id.uuid(), *deletion_time);

            log.events.push(MergeEvent {
                target: MergeEventTarget::Icon(id),
                event_type: MergeEventType::Deleted,
            });
        } else {
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Icon(id),
                event_type: MergeEventType::Created,
            });
        }
    }

    for &id in dest_icons.intersection(&source_icons) {
        #[allow(clippy::unwrap_used)] // id is guaranteed to exist in both dest and source
        let dest_icon = dest_db.custom_icons.get(&id).unwrap();

        #[allow(clippy::unwrap_used)] // id is guaranteed to exist in both dest and source
        let source_icon = source_db.custom_icons.get(&id).unwrap();

        let dest_last_modification = dest_icon.last_modification_time.unwrap_or_else(|| {
            log.warnings.push(format!(
                "Destination custom icon {} did not have a last modification timestamp",
                id
            ));
            Times::epoch()
        });

        let source_last_modification = source_icon.last_modification_time.unwrap_or_else(|| {
            log.warnings.push(format!(
                "Source custom icon {} did not have a last modification timestamp",
                id
            ));
            Times::epoch()
        });

        if dest_last_modification == source_last_modification {
            if dest_icon != source_icon {
                log.warnings.push(format!(
                    "Custom icons with UUID {} have the same modification time but have diverged.",
                    id,
                ));
            }
            continue;
        }

        if dest_last_modification > source_last_modification {
            // The destination icon is more recent than the source icon.
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Icon(id),
                event_type: MergeEventType::Updated,
            });
            continue;
        }

        // The source icon is more recent than the destination icon. Update dest with source.
        dest_db.custom_icons.insert(id, source_icon.clone());

        log.events.push(MergeEvent {
            target: MergeEventTarget::Icon(id),
            event_type: MergeEventType::Updated,
        });
    }

    Ok(())
}

fn merge_meta(dest_db: &mut Database, source_db: &Database, log: &mut MergeLog) -> Result<(), MergeError> {
    let dest_database_name_changed = dest_db.meta.database_name_changed.unwrap_or(Times::epoch());
    let source_database_name_changed = source_db.meta.database_name_changed.unwrap_or(Times::epoch());

    if source_database_name_changed > dest_database_name_changed {
        dest_db.meta.database_name_changed = Some(source_database_name_changed);
        dest_db.meta.database_name = source_db.meta.database_name.clone();
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::DatabaseName),
            event_type: MergeEventType::Updated,
        });
    } else if source_database_name_changed < dest_database_name_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::DatabaseName),
            event_type: MergeEventType::Updated,
        });
    } else if source_db.meta.database_name != dest_db.meta.database_name {
        log.warnings
            .push("The database name change times are the same, but there’s already a deviation.".into());
    }

    let dest_database_description_changed = dest_db
        .meta
        .database_description_changed
        .unwrap_or(Times::epoch());
    let source_database_description_changed = source_db
        .meta
        .database_description_changed
        .unwrap_or(Times::epoch());

    if source_database_description_changed > dest_database_description_changed {
        dest_db.meta.database_description_changed = Some(source_database_description_changed);
        dest_db.meta.database_description = source_db.meta.database_description.clone();
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::DatabaseDescription),
            event_type: MergeEventType::Updated,
        });
    } else if source_database_description_changed < dest_database_description_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::DatabaseDescription),
            event_type: MergeEventType::Updated,
        });
    } else if source_db.meta.database_description != dest_db.meta.database_description {
        log.warnings.push(
            "The database description change times are the same, but there’s already a deviation.".into(),
        );
    }

    let dest_default_username_changed = dest_db.meta.default_username_changed.unwrap_or(Times::epoch());
    let source_default_username_changed = source_db.meta.default_username_changed.unwrap_or(Times::epoch());

    if source_default_username_changed > dest_default_username_changed {
        dest_db.meta.default_username_changed = Some(source_default_username_changed);
        dest_db.meta.default_username = source_db.meta.default_username.clone();
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::DefaultUsername),
            event_type: MergeEventType::Updated,
        });
    } else if source_default_username_changed < dest_default_username_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::DefaultUsername),
            event_type: MergeEventType::Updated,
        });
    } else if source_db.meta.default_username != dest_db.meta.default_username {
        log.warnings
            .push("The default user name change times are the same, but there’s already a deviation.".into());
    }

    let dest_recyclebin_changed = dest_db.meta.recyclebin_changed.unwrap_or(Times::epoch());
    let source_recyclebin_changed = source_db.meta.recyclebin_changed.unwrap_or(Times::epoch());

    if source_recyclebin_changed > dest_recyclebin_changed {
        dest_db.meta.recyclebin_changed = Some(source_recyclebin_changed);
        dest_db.meta.recyclebin_enabled = source_db.meta.recyclebin_enabled;
        dest_db.meta.recyclebin_uuid = source_db.meta.recyclebin_uuid;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::RecycleBin),
            event_type: MergeEventType::Updated,
        });
    } else if source_recyclebin_changed < dest_recyclebin_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::RecycleBin),
            event_type: MergeEventType::Updated,
        });
    } else if source_db.meta.recyclebin_enabled != dest_db.meta.recyclebin_enabled
        || source_db.meta.recyclebin_uuid != dest_db.meta.recyclebin_uuid
    {
        log.warnings
            .push("The recycle bin change times are the same, but there’s already a deviation.".into());
    }

    let dest_entry_templates_group_changed = dest_db
        .meta
        .entry_templates_group_changed
        .unwrap_or(Times::epoch());
    let source_entry_templates_group_changed = source_db
        .meta
        .entry_templates_group_changed
        .unwrap_or(Times::epoch());

    if source_entry_templates_group_changed > dest_entry_templates_group_changed {
        dest_db.meta.entry_templates_group_changed = Some(source_entry_templates_group_changed);
        dest_db.meta.entry_templates_group = source_db.meta.entry_templates_group;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::EntryTemplatesGroup),
            event_type: MergeEventType::Updated,
        });
    } else if source_entry_templates_group_changed < dest_entry_templates_group_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::EntryTemplatesGroup),
            event_type: MergeEventType::Updated,
        });
    } else if source_db.meta.entry_templates_group != dest_db.meta.entry_templates_group {
        log.warnings.push(
            "The entry templates group change times are the same, but there’s already a deviation.".into(),
        );
    }

    let dest_master_key_changed = dest_db.meta.master_key_changed.unwrap_or(Times::epoch());
    let source_master_key_changed = source_db.meta.master_key_changed.unwrap_or(Times::epoch());

    if source_master_key_changed > dest_master_key_changed {
        dest_db.meta.master_key_changed = source_db.meta.master_key_changed;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MasterKeyChanged),
            event_type: MergeEventType::Updated,
        });
    } else if source_master_key_changed < dest_master_key_changed {
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MasterKeyChanged),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_settings_changed = dest_db.meta.settings_changed.unwrap_or(Times::epoch());
    let source_settings_changed = source_db.meta.settings_changed.unwrap_or(Times::epoch());

    let dest_maintenance_history_days_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED, dest_settings_changed);
    let source_maintenance_history_days_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED, source_settings_changed);

    if source_maintenance_history_days_changed > dest_maintenance_history_days_changed {
        dest_db.meta.set_custom_time_changed(
            CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED,
            source_maintenance_history_days_changed,
        );
        dest_db.meta.maintenance_history_days = source_db.meta.maintenance_history_days;

        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MaintenanceHistoryDays),
            event_type: MergeEventType::Updated,
        });
    } else if source_maintenance_history_days_changed < dest_maintenance_history_days_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MaintenanceHistoryDays),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_color_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_COLOR_CHANGED, dest_settings_changed);
    let source_color_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_COLOR_CHANGED, source_settings_changed);

    if source_color_changed > dest_color_changed {
        dest_db
            .meta
            .set_custom_time_changed(CUSTOM_COLOR_CHANGED, source_color_changed);
        dest_db.meta.color = source_db.meta.color.clone();
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::Color),
            event_type: MergeEventType::Updated,
        });
    } else if source_color_changed < dest_color_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::Color),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_master_key_change_rec_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED, dest_settings_changed);
    let source_master_key_change_rec_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED, source_settings_changed);

    if source_master_key_change_rec_changed > dest_master_key_change_rec_changed {
        dest_db.meta.set_custom_time_changed(
            CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED,
            source_master_key_change_rec_changed,
        );
        dest_db.meta.master_key_change_rec = source_db.meta.master_key_change_rec;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MasterKeyChangeRec),
            event_type: MergeEventType::Updated,
        });
    } else if source_master_key_change_rec_changed < dest_master_key_change_rec_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MasterKeyChangeRec),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_master_key_change_force_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED, dest_settings_changed);
    let source_master_key_change_force_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED, source_settings_changed);

    if source_master_key_change_force_changed > dest_master_key_change_force_changed {
        dest_db.meta.set_custom_time_changed(
            CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED,
            source_master_key_change_force_changed,
        );
        dest_db.meta.master_key_change_force = source_db.meta.master_key_change_force;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MasterKeyChangeForce),
            event_type: MergeEventType::Updated,
        });
    } else if source_master_key_change_force_changed < dest_master_key_change_force_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MasterKeyChangeForce),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_memory_protection_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_MEMORY_PROTECTION_CHANGED, dest_settings_changed);
    let source_memory_protection_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_MEMORY_PROTECTION_CHANGED, source_settings_changed);

    if source_memory_protection_changed > dest_memory_protection_changed {
        dest_db
            .meta
            .set_custom_time_changed(CUSTOM_MEMORY_PROTECTION_CHANGED, source_memory_protection_changed);
        dest_db.meta.memory_protection = source_db.meta.memory_protection.clone();
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MemoryProtection),
            event_type: MergeEventType::Updated,
        });
    } else if source_memory_protection_changed < dest_memory_protection_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::MemoryProtection),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_history_max_items_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, dest_settings_changed);
    let source_history_max_items_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, source_settings_changed);

    if source_history_max_items_changed > dest_history_max_items_changed {
        dest_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, source_history_max_items_changed);
        dest_db.meta.history_max_items = source_db.meta.history_max_items;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::HistoryMaxItems),
            event_type: MergeEventType::Updated,
        });
    } else if source_history_max_items_changed < dest_history_max_items_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::HistoryMaxItems),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_history_max_size_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, dest_settings_changed);
    let source_history_max_size_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, source_settings_changed);

    if source_history_max_size_changed > dest_history_max_size_changed {
        dest_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, source_history_max_size_changed);
        dest_db.meta.history_max_size = source_db.meta.history_max_size;
        dest_db.meta.history_max_items = source_db.meta.history_max_items;
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::HistoryMaxSize),
            event_type: MergeEventType::Updated,
        });
    } else if source_history_max_size_changed < dest_history_max_size_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::HistoryMaxSize),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_database_config_changed = dest_db
        .meta
        .get_custom_time_changed(CUSTOM_DATABASE_CONFIG_CHANGED, dest_settings_changed);
    let source_database_config_changed = source_db
        .meta
        .get_custom_time_changed(CUSTOM_DATABASE_CONFIG_CHANGED, source_settings_changed);

    if source_database_config_changed > dest_database_config_changed {
        dest_db
            .meta
            .set_custom_time_changed(CUSTOM_DATABASE_CONFIG_CHANGED, source_database_config_changed);
        dest_db.config.outer_cipher_config = source_db.config.outer_cipher_config.clone();
        dest_db.config.compression_config = source_db.config.compression_config.clone();
        dest_db.config.inner_cipher_config = source_db.config.inner_cipher_config.clone();
        dest_db.config.kdf_config = source_db.config.kdf_config.clone();
        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::Config),
            event_type: MergeEventType::Updated,
        });
    } else if source_database_config_changed < dest_database_config_changed {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::Config),
            event_type: MergeEventType::Updated,
        });
    }

    let dest_custom_data = dest_db.meta.custom_data.keys().cloned().collect::<HashSet<_>>();
    let source_custom_data = source_db.meta.custom_data.keys().cloned().collect::<HashSet<_>>();

    fn skip_customm_time_key(key: &str) -> bool {
        key == CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED
            || key == CUSTOM_COLOR_CHANGED
            || key == CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED
            || key == CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED
            || key == CUSTOM_MEMORY_PROTECTION_CHANGED
            || key == CUSTOM_HISTORY_MAX_ITEMS_CHANGED
            || key == CUSTOM_HISTORY_MAX_SIZE_CHANGED
            || key == CUSTOM_DATABASE_CONFIG_CHANGED
    }

    for key in source_custom_data.difference(&dest_custom_data) {
        if skip_customm_time_key(key) {
            continue;
        }

        #[allow(clippy::unwrap_used)]
        let value = source_db.meta.custom_data.get(key).unwrap().clone();
        dest_db.meta.custom_data.insert(key.clone(), value);

        log.events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::CustomData(key.clone())),
            event_type: MergeEventType::Created,
        });
    }

    for key in dest_custom_data.difference(&source_custom_data) {
        if skip_customm_time_key(key) {
            continue;
        }

        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::Meta(MetaField::CustomData(key.clone())),
            event_type: MergeEventType::Created,
        });
    }

    for key in dest_custom_data.intersection(&source_custom_data) {
        if skip_customm_time_key(key) {
            continue;
        }

        #[allow(clippy::unwrap_used)]
        let dest_value_time = dest_db
            .meta
            .custom_data
            .get(key)
            .unwrap()
            .last_modification_time
            .unwrap_or(Times::epoch());

        #[allow(clippy::unwrap_used)]
        let source_value = source_db.meta.custom_data.get(key).unwrap();

        let source_value_time = source_value.last_modification_time.unwrap_or(Times::epoch());

        if source_value_time > dest_value_time {
            dest_db.meta.custom_data.insert(key.clone(), source_value.clone());
            log.events.push(MergeEvent {
                target: MergeEventTarget::Meta(MetaField::CustomData(key.clone())),
                event_type: MergeEventType::Updated,
            });
        } else if source_value_time < dest_value_time {
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::Meta(MetaField::CustomData(key.clone())),
                event_type: MergeEventType::Updated,
            });
        }
    }

    if source_settings_changed > dest_settings_changed {
        dest_db.meta.settings_changed = Some(source_settings_changed);
    }

    Ok(())
}

/// Merge the records of deleted objects from `source` into `dest`.
///
/// This runs after everything else was merged. Records are kept for objects that are not in the
/// merged database, so that a later merge with a third copy still knows about the deletion. For an
/// object deleted on both sides, the earlier deletion time is kept, like KeePassXC does. Records for
/// objects that are still in the merged database, because they were changed after being deleted,
/// are dropped.
fn merge_deleted_objects(
    dest_db: &mut Database,
    source_db: &Database,
    log: &mut MergeLog,
) -> Result<(), MergeError> {
    let present: HashSet<Uuid> = dest_db
        .entries
        .keys()
        .map(|id| id.uuid())
        .chain(dest_db.groups.keys().map(|id| id.uuid()))
        .chain(dest_db.custom_icons.keys().map(|id| id.uuid()))
        .collect();

    let dropped: Vec<Uuid> = dest_db
        .deleted_objects
        .keys()
        .filter(|uuid| present.contains(uuid))
        .copied()
        .collect();

    for uuid in dropped {
        dest_db.deleted_objects.shift_remove(&uuid);
        log.events.push(MergeEvent {
            target: MergeEventTarget::DeletedObject(uuid),
            event_type: MergeEventType::Deleted,
        });
    }

    let uuids: Vec<&Uuid> = source_db.deleted_objects.keys().collect();

    for uuid in uuids {
        if present.contains(uuid) {
            continue;
        }

        #[allow(clippy::unwrap_used)] // uuid was taken from source_db.deleted_objects
        let source_time = *source_db.deleted_objects.get(uuid).unwrap();

        let event_type = match dest_db.deleted_objects.get(uuid) {
            None => MergeEventType::Created,
            Some(dest_time) if is_earlier(source_time, *dest_time) => MergeEventType::Updated,
            Some(_) => continue,
        };

        dest_db.deleted_objects.insert(*uuid, source_time);
        log.events.push(MergeEvent {
            target: MergeEventTarget::DeletedObject(*uuid),
            event_type,
        });
    }

    let dest_uuid = dest_db.deleted_objects.keys().collect::<HashSet<_>>();
    let source_uuid = source_db.deleted_objects.keys().collect::<HashSet<_>>();

    for &uuid in dest_uuid.difference(&source_uuid) {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::DeletedObject(*uuid),
            event_type: MergeEventType::Created,
        });
    }

    for &uuid in source_uuid.difference(&dest_uuid) {
        log.dest_events.push(MergeEvent {
            target: MergeEventTarget::DeletedObject(*uuid),
            event_type: MergeEventType::Deleted,
        });
    }

    for &uuid in dest_uuid.intersection(&source_uuid) {
        #[allow(clippy::unwrap_used)] // uuid was taken from dest_db.deleted_objects
        let dest_time = dest_db.deleted_objects.get(uuid).unwrap();
        #[allow(clippy::unwrap_used)] // uuid was taken from source_db.deleted_objects
        let source_time = source_db.deleted_objects.get(uuid).unwrap();

        if is_earlier(*dest_time, *source_time) {
            log.dest_events.push(MergeEvent {
                target: MergeEventTarget::DeletedObject(*uuid),
                event_type: MergeEventType::Updated,
            });
        }
    }

    Ok(())
}

/// Whether deletion time `a` is known and earlier than `b`, or `b` is unknown.
fn is_earlier(a: Option<NaiveDateTime>, b: Option<NaiveDateTime>) -> bool {
    match (a, b) {
        (Some(a), Some(b)) => a < b,
        (Some(_), None) => true,
        (None, _) => false,
    }
}

fn have_groups_diverged(a: &Group, b: &Group) -> bool {
    let new_times = Times::default();

    let mut a = a.clone();
    a.times = new_times.clone();
    a.entries.clear();
    a.groups.clear();
    a.parent = None;

    let mut b = b.clone();
    b.times = new_times.clone();
    b.entries.clear();
    b.groups.clear();
    b.parent = None;

    !a.eq(&b)
}

/// Check if two entries are dissimilar, ignoring their timestamps.
fn have_entries_diverged(a: &Entry, b: &Entry) -> bool {
    let new_times = Times::default();

    let mut a = a.clone();
    // 附件ID在每个副本的情况是不一样的
    a.attachments = a
        .attachments
        .into_iter()
        .map(|(item, _)| (item, AttachmentId::new(0)))
        .collect();
    a.times = new_times.clone();
    a.history = None;

    let mut b = b.clone();
    b.attachments = b
        .attachments
        .into_iter()
        .map(|(item, _)| (item, AttachmentId::new(0)))
        .collect();
    b.times = new_times.clone();
    b.history = None;

    !a.eq(&b)
}

#[allow(clippy::indexing_slicing, clippy::unwrap_used, clippy::expect_used)]
#[cfg(test)]
mod merge_tests {
    use uuid::uuid;

    use crate::config::{
        CompressionConfig, DatabaseConfig, DatabaseVersion, InnerCipherConfig, KdfConfig, OuterCipherConfig,
    };
    use crate::db::{Color, CustomDataItem, EntryId, GroupId, History, MemoryProtection, Times, fields};
    use crate::db::{CustomDataValue, merge::*};
    use crate::{Database, DatabaseKey};

    const ROOT_GROUP_ID: GroupId = GroupId::from_uuid(uuid!("00000000-0000-0000-0000-000000000001"));
    const GROUP1_ID: GroupId = GroupId::from_uuid(uuid!("00000000-0000-0000-0000-000000000002"));
    const GROUP2_ID: GroupId = GroupId::from_uuid(uuid!("00000000-0000-0000-0000-000000000003"));
    const SUBGROUP1_ID: GroupId = GroupId::from_uuid(uuid!("00000000-0000-0000-0000-000000000004"));
    const SUBGROUP2_ID: GroupId = GroupId::from_uuid(uuid!("00000000-0000-0000-0000-000000000005"));
    const ENTRY1_ID: EntryId = EntryId::from_uuid(uuid!("00000000-0000-0000-0000-000000000006"));
    const ENTRY2_ID: EntryId = EntryId::from_uuid(uuid!("00000000-0000-0000-0000-000000000007"));

    /// Build up an example database for testing
    ///
    /// The database structure is as follows:
    ///
    /// root (ROOT_GROUP_ID)
    /// ├── entry1 (ENTRY1_ID)
    /// ├── group1 (GROUP1_ID)
    /// │   └── subgroup1 (SUBGROUP1_ID)
    /// │       └── entry2 (ENTRY2_ID)
    /// └── group2 (GROUP2_ID)
    ///    └── subgroup2 (SUBGROUP2_ID)
    ///
    fn create_test_database() -> Database {
        let mut db = Database::new_with_root_id(ROOT_GROUP_ID);

        db.config = DatabaseConfig::fast_new();

        // build up root -> group1 -> subgroup1 -> entry2
        db.root_mut()
            .add_group_with_id(GROUP1_ID)
            .unwrap()
            .edit(|g| g.name = "group1".to_string())
            .add_group_with_id(SUBGROUP1_ID)
            .unwrap()
            .edit(|sg| sg.name = "subgroup1".to_string())
            .add_entry_with_id(ENTRY2_ID)
            .unwrap()
            .edit(|e| e.set_unprotected("Title", "entry2"));

        // build up root -> group2 -> subgroup2
        db.root_mut()
            .add_group_with_id(GROUP2_ID)
            .unwrap()
            .edit(|g| g.name = "group2".to_string())
            .add_group_with_id(SUBGROUP2_ID)
            .unwrap()
            .edit(|sg| sg.name = "subgroup2".to_string());

        // Placing the first entry in the root group
        db.root_mut()
            .add_entry_with_id(ENTRY1_ID)
            .unwrap()
            .edit(|e| e.set_unprotected("Title", "entry1"));

        db
    }

    /// sleep for 1 second to ensure different timestamps
    fn sleep() {
        std::thread::sleep(std::time::Duration::from_secs(1));
    }

    fn assert_history_ordered(history: &History) {
        let mut last_modification_time: Option<&chrono::NaiveDateTime> = None;
        for (_, entry) in history.get_entries() {
            if last_modification_time.is_none() {
                last_modification_time = entry.times.last_modification.as_ref();
            }

            if let Some(entry_modification_time) = entry.times.last_modification.as_ref() {
                if last_modification_time.unwrap() < entry_modification_time {
                    panic!(
                        "History entries are not ordered by last modification time: {:?} came after {:?}",
                        last_modification_time, entry_modification_time
                    );
                }
                last_modification_time = Some(entry_modification_time);
            }
        }
    }

    #[cfg(feature = "save_kdbx4")]
    fn save_open(db: &Database) -> Database {
        let mut output = Vec::new();
        let key = DatabaseKey::new().with_password("demopass");

        db.save(&mut output, key.clone(), None).unwrap();
        Database::parse(&output, key, None).unwrap()
    }

    /// Test that merging a database with itself results in no changes.
    #[test]
    fn test_idempotence() {
        let mut destination_db = create_test_database();
        let source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);
        assert_eq!(destination_db.root().entries().count(), 1);
        assert_eq!(destination_db.root().groups().count(), 2);

        assert_eq!(destination_db.entries.len(), entry_count_before);
        assert_eq!(destination_db.groups.len(), group_count_before);

        // The two groups should be exactly the same after merging, since
        // nothing was performed during the merge.
        assert_eq!(destination_db, source_db);

        sleep();

        // Now modify an entry in the destination database, and merge again.
        destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .edit_tracking(|e| e.set_unprotected("Title", "entry1_updated"));

        // Merging should ignore the change, since destination is more recent.
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);
        let destination_db_just_after_merge = destination_db.clone();

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        // Merging twice in a row, even if the first merge updated the destination group,
        // should not create more changes.
        assert_eq!(destination_db_just_after_merge, destination_db);
    }

    /// Destination-side changes are recorded on `dest_events` and are not overwritten by an older source.
    #[test]
    fn test_dest_events() {
        let mut destination_db = create_test_database();

        let icon_id = destination_db
            .group_mut(SUBGROUP2_ID)
            .unwrap()
            .set_icon_custom_new(vec![1, 2, 3, 4])
            .id();

        let mut source_db = destination_db.clone();

        sleep();

        // Source is newer only for the description, so this belongs in `events`.
        source_db.meta.database_description = Some("from-source".into());
        source_db.meta.database_description_changed = Some(Times::now());

        sleep();

        let created_entry_id = destination_db
            .root_mut()
            .add_entry()
            .edit_tracking(|e| e.set_unprotected("Title", "dest_only_entry"))
            .id();

        let created_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "dest_only_group".into())
            .id();

        destination_db
            .entry_mut(ENTRY2_ID)
            .unwrap()
            .track_changes()
            .remove();

        destination_db
            .group_mut(GROUP1_ID)
            .unwrap()
            .track_changes()
            .edit(|g| g.name = "group1_from_dest".into());

        // A tracked move updates both the location time and the modification time.
        destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .track_changes()
            .move_to(GROUP2_ID)
            .unwrap();

        destination_db.custom_icon_mut(icon_id).unwrap().data = vec![5, 6, 7, 8];
        destination_db
            .custom_icon_mut(icon_id)
            .unwrap()
            .last_modification_time = Some(Times::now());

        destination_db.meta.database_name = Some("from-dest".into());
        destination_db.meta.database_name_changed = Some(Times::now());

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(
            merge_result.events,
            vec![MergeEvent {
                target: MergeEventTarget::Meta(MetaField::DatabaseDescription),
                event_type: MergeEventType::Updated,
            }]
        );
        assert_eq!(
            merge_result.dest_events,
            vec![
                MergeEvent {
                    target: MergeEventTarget::Meta(MetaField::DatabaseName),
                    event_type: MergeEventType::Updated,
                },
                MergeEvent {
                    target: MergeEventTarget::Icon(icon_id),
                    event_type: MergeEventType::Updated,
                },
                MergeEvent {
                    target: MergeEventTarget::Group(created_group_id),
                    event_type: MergeEventType::Created,
                },
                MergeEvent {
                    target: MergeEventTarget::Entry(ENTRY2_ID),
                    event_type: MergeEventType::Deleted,
                },
                MergeEvent {
                    target: MergeEventTarget::Entry(created_entry_id),
                    event_type: MergeEventType::Created,
                },
                MergeEvent {
                    target: MergeEventTarget::Entry(ENTRY1_ID),
                    event_type: MergeEventType::LocationUpdated,
                },
                MergeEvent {
                    target: MergeEventTarget::Entry(ENTRY1_ID),
                    event_type: MergeEventType::Updated,
                },
                MergeEvent {
                    target: MergeEventTarget::Group(GROUP1_ID),
                    event_type: MergeEventType::Updated,
                },
                MergeEvent {
                    target: MergeEventTarget::DeletedObject(ENTRY2_ID.uuid()),
                    event_type: MergeEventType::Created
                }
            ]
        );

        assert_eq!(destination_db.entry(ENTRY1_ID).unwrap().parent().id(), GROUP2_ID);
        assert_eq!(
            destination_db.entry(ENTRY1_ID).unwrap().get(fields::TITLE),
            Some("entry1")
        );
        assert!(destination_db.entry(ENTRY2_ID).is_none());
        assert_eq!(
            destination_db.entry(created_entry_id).unwrap().get(fields::TITLE),
            Some("dest_only_entry")
        );
        assert_eq!(
            destination_db.group(created_group_id).unwrap().name,
            "dest_only_group"
        );
        assert_eq!(destination_db.group(GROUP1_ID).unwrap().name, "group1_from_dest");
        assert_eq!(
            destination_db.custom_icon(icon_id).unwrap().data,
            vec![5, 6, 7, 8]
        );
        assert_eq!(destination_db.meta.database_name.as_deref(), Some("from-dest"));
        assert_eq!(
            destination_db.meta.database_description.as_deref(),
            Some("from-source")
        );
    }

    /// Test that a new entry in source is added to destination when merging.
    #[test]
    fn test_add_new_entry() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // create a new entry in source_db and retain its id
        let new_entry_id = source_db
            .root_mut()
            .add_entry()
            .edit_tracking(|e| e.set_unprotected("Title", "new_entry"))
            .id();

        // merge source_db into destination_db -- this should add the new entry
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before + 1);
        assert_eq!(group_count_after, group_count_before);

        let root_entries_count = destination_db.root().entries().count();
        assert_eq!(root_entries_count, 2);

        let new_entry = destination_db
            .entry(new_entry_id)
            .expect("New entry should exist");
        assert_eq!(new_entry.get(fields::TITLE), Some("new_entry"));

        // Merging the same group again should not create a duplicate entry.
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before + 1);
        assert_eq!(group_count_after, group_count_before);

        let root_entries_count = destination_db.root().entries().count();
        assert_eq!(root_entries_count, 2);
    }

    /// Test that an entry that is marked as deleted in the destination database is not re-added
    /// when merging from source
    #[test]
    fn test_deleted_entry_in_destination() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // add a new entry in source_db that will be marked as deleted in destination_db
        let deleted_entry_id = source_db
            .root_mut()
            .add_entry()
            .edit_tracking(|e| {
                e.set_unprotected("Title", "deleted_entry");
            })
            .id();

        // mark the entry as deleted in destination_db
        destination_db
            .deleted_objects
            .insert(deleted_entry_id.uuid(), Some(Times::now()));

        // merge source_db into destination_db -- the entry should not be added
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.entry(deleted_entry_id).is_none());
    }

    /// Test that an entry that is updated and moved to a group in source but that group is deleted
    /// later in dest should cause the group to be re-added and the entry to be moved there.
    #[test]
    fn test_updated_entry_under_deleted_group() {
        let mut destination_db = create_test_database();

        let modified_entry_id = destination_db
            .root_mut()
            .add_entry()
            .edit(|e| e.set_unprotected("Title", "original_title"))
            .id();

        let deleted_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "deleted_group".to_string())
            .id();

        let mut source_db = destination_db.clone();

        sleep();

        // perform the update of the entry in source_db and move it to the group that will be
        // deleted
        source_db
            .entry_mut(modified_entry_id)
            .unwrap()
            .track_changes()
            .edit(|e| {
                e.set_unprotected("Title", "modified_title");
            })
            .move_to(deleted_group_id)
            .unwrap();

        sleep();

        // delete the group in destination_db
        destination_db.group_mut(deleted_group_id).unwrap().remove();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // perform the merge - the group should be re-added and the entry moved there
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 3); // recreate group, move entry, update entry

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before + 1);

        assert!(destination_db.group(deleted_group_id).is_some());
        assert!(destination_db.entry(modified_entry_id).is_some());
    }

    /// Test that a group that is marked as deleted in the destination database is not re-added
    /// when merging from source
    #[test]
    fn test_deleted_group_in_destination() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // add a new group in source_db
        let deleted_group_id = source_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "deleted_group".to_string())
            .id();

        // mark the group as deleted in destination_db
        destination_db
            .deleted_objects
            .insert(deleted_group_id.uuid(), Some(Times::now()));

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(deleted_group_id).is_none());
    }

    /// Test that an entry that is marked as deleted in the source database is deleted from destination
    #[test]
    fn test_deleted_entry_in_source() {
        let mut destination_db = create_test_database();

        let deleted_entry_id = destination_db
            .root_mut()
            .add_entry()
            .edit_tracking(|e| e.set_unprotected("Title", "deleted_entry"))
            .id();

        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // mark the entry as deleted in source_db
        source_db
            .entry_mut(deleted_entry_id)
            .unwrap()
            .track_changes()
            .remove();

        // perform the merge - the entry should be deleted
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        // verify that the entry was deleted
        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before - 1);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.entry(deleted_entry_id).is_none());
        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_entry_id.uuid())
        );
    }

    /// Test that a group that is marked as deleted in the source database is deleted from destination
    #[test]
    fn test_deleted_group_in_source() {
        let mut destination_db = create_test_database();

        let deleted_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "deleted_group".to_string())
            .id();

        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // mark the entry as deleted in source_db
        source_db
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .remove()
            .unwrap();

        // perform the merge - the entry should be deleted
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        // verify that the entry was deleted
        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before - 1);

        assert!(destination_db.group(deleted_group_id).is_none());
        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_group_id.uuid())
        );
    }

    /// Test that an entry that is marked as deleted in the source database but modified in
    /// destination is not deleted
    #[test]
    fn test_deleted_entry_in_source_modified_in_destination() {
        let mut destination_db = create_test_database();

        let deleted_entry_id = destination_db
            .root_mut()
            .add_entry()
            .edit_tracking(|e| e.set_unprotected("Title", "deleted_entry"))
            .id();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        let mut source_db = destination_db.clone();

        // mark the entry as deleted in source_db
        source_db
            .entry_mut(deleted_entry_id)
            .unwrap()
            .track_changes()
            .remove();

        sleep();

        // modify the entry in destination_db
        destination_db
            .entry_mut(deleted_entry_id)
            .unwrap()
            .edit_tracking(|e| e.set_unprotected("Title", "modified_in_destination"));

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.entry(deleted_entry_id).is_some());
        assert!(
            !destination_db
                .deleted_objects
                .contains_key(&deleted_entry_id.uuid())
        );
    }

    /// Test that a group subtree that is marked as deleted in the source database is deleted from
    /// destination
    #[test]
    fn test_group_subtree_deletion() {
        let mut destination_db = create_test_database();

        let deleted_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| {
                g.name = "deleted_group".to_string();
            })
            .id();

        let deleted_subgroup_id = destination_db
            .group_mut(deleted_group_id)
            .unwrap()
            .add_group()
            .edit(|g| {
                g.name = "deleted_subgroup".to_string();
            })
            .id();

        let deleted_entry_id = destination_db
            .group_mut(deleted_subgroup_id)
            .unwrap()
            .add_entry()
            .edit_tracking(|e| {
                e.set_unprotected("Title", "deleted_entry");
            })
            .id();

        let mut source_db = destination_db.clone();

        // mark the entire group subtree as deleted in source_db
        source_db
            .root_mut()
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .remove()
            .unwrap();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // perform the merge - the entire subtree should be deleted
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 3);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before - 1);
        assert_eq!(group_count_after, group_count_before - 2);

        assert!(destination_db.entry(deleted_entry_id).is_none());
        assert!(destination_db.group(deleted_subgroup_id).is_none());
        assert!(destination_db.group(deleted_group_id).is_none());

        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_entry_id.uuid())
        );
        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_subgroup_id.uuid())
        );
        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_group_id.uuid())
        );
    }

    /// Test that a tree that was deleted in source, but contains a group that is newer in
    /// destination is only partially deleted.
    #[test]
    fn test_group_subtree_partial_deletion() {
        let mut destination_db = create_test_database();

        let deleted_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| {
                g.name = "deleted_group".to_string();
            })
            .id();

        let deleted_subgroup_id = destination_db
            .group_mut(deleted_group_id)
            .unwrap()
            .add_group()
            .edit(|g| {
                g.name = "deleted_subgroup".to_string();
            })
            .id();

        let deleted_entry_id = destination_db
            .group_mut(deleted_subgroup_id)
            .unwrap()
            .add_entry()
            .edit(|e| {
                e.set_unprotected("Title", "deleted_entry");
            })
            .id();

        let mut source_db = destination_db.clone();

        sleep();

        // mark the entire group subtree as deleted in source_db
        source_db
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .remove()
            .unwrap();

        sleep();

        // modify the deleted subgroup in destination_db to be newer than the deletion time
        destination_db
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .edit(|g| {
                g.notes = Some("modified in destination".to_string());
            });

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // perform the merge - the entry and subgroup should be deleted, but the group should
        // remain
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 2);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before - 1);
        assert_eq!(group_count_after, group_count_before - 1);

        assert!(destination_db.entry(deleted_entry_id).is_none());
        assert!(destination_db.group(deleted_subgroup_id).is_none());
        assert!(destination_db.group(deleted_group_id).is_some());

        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_entry_id.uuid())
        );
        assert!(
            destination_db
                .deleted_objects
                .contains_key(&deleted_subgroup_id.uuid())
        );
        assert!(
            !destination_db
                .deleted_objects
                .contains_key(&deleted_group_id.uuid())
        );
    }

    /// Test that a group that is marked as deleted in the source database but modified in
    /// destination is not deleted
    #[test]
    fn test_deleted_group_in_source_modified_in_destination() {
        let mut destination_db = create_test_database();

        let deleted_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "deleted_group".to_string())
            .id();

        let mut source_db = destination_db.clone();

        // mark the group as deleted in source_db
        source_db
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .remove()
            .unwrap();

        sleep();

        // modify the group in destination_db
        destination_db
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .edit(|g| g.notes = Some("modified_in_destination".to_string()));

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // perform the merge - the group should not be deleted
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(deleted_group_id).is_some());

        assert!(
            !destination_db
                .deleted_objects
                .contains_key(&deleted_group_id.uuid())
        );
    }

    /// Test that a group that is marked as deleted in the source database but has new entries
    /// added in destination is not deleted
    #[test]
    fn test_deleted_group_has_new_entries() {
        let mut destination_db = create_test_database();

        let deleted_group_id = destination_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "deleted_group".to_string())
            .id();

        let mut source_db = destination_db.clone();

        // mark the group as deleted in source_db
        source_db
            .group_mut(deleted_group_id)
            .unwrap()
            .track_changes()
            .remove()
            .unwrap();

        sleep();

        // add a new entry to the deleted group in destination_db
        let new_entry_id = destination_db
            .group_mut(deleted_group_id)
            .unwrap()
            .add_entry()
            .edit_tracking(|e| {
                e.set_unprotected("Title", "new_entry_in_deleted_group");
            })
            .id();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        // perform the merge - the group should not be deleted
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(deleted_group_id).is_some());
        assert!(destination_db.entry(new_entry_id).is_some());

        assert!(
            !destination_db
                .deleted_objects
                .contains_key(&deleted_group_id.uuid())
        );
        assert!(!destination_db.deleted_objects.contains_key(&new_entry_id.uuid()));
    }

    /// Test that a new entry in a non-root group in source is added to destination when merging.
    #[test]
    fn test_add_new_non_root_entry() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        let new_entry_id = source_db
            .group_mut(GROUP1_ID)
            .unwrap()
            .add_entry()
            .edit_tracking(|e| {
                e.set_unprotected("Title", "new_entry");
            })
            .id();

        // perform the merge - this should add the new entry
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before + 1);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.entry(new_entry_id).is_some());
    }

    // Test that a new entry in source under a new group/subgroup is added to destination when
    // merging.
    #[test]
    fn test_add_new_entry_new_group() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        let new_group_id = source_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "new_group".to_string())
            .id();

        let new_subgroup_id = source_db
            .group_mut(new_group_id)
            .unwrap()
            .add_group()
            .edit(|g| g.name = "new_subgroup".to_string())
            .id();

        let new_entry_id = source_db
            .group_mut(new_subgroup_id)
            .unwrap()
            .add_entry()
            .edit_tracking(|e| {
                e.set_unprotected("Title", "new_entry");
            })
            .id();

        // perform the merge - this should add the new entry along with the new group and subgroup
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 3);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before + 1);
        assert_eq!(group_count_after, group_count_before + 2);

        assert!(destination_db.group(new_group_id).is_some());
        assert!(destination_db.group(new_subgroup_id).is_some());
        assert!(destination_db.entry(new_entry_id).is_some());
    }

    /// Test that an entry is relocated from one group to another in source and the relocation
    /// is reflected in destination when merging.
    #[test]
    fn test_entry_relocation_existing_group() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // before
        // root (ROOT_GROUP_ID)
        // ├── entry1 (ENTRY1_ID)
        // ├── group1 (GROUP1_ID)
        // │   └── subgroup1 (SUBGROUP1_ID)
        // │       └── entry2 (ENTRY2_ID)   <-- this entry
        // └── group2 (GROUP2_ID)
        //    └── subgroup2 (SUBGROUP2_ID)
        //
        // after
        // root (ROOT_GROUP_ID)
        // ├── entry1 (ENTRY1_ID)
        // ├── group1 (GROUP1_ID)
        // │   └── subgroup1 (SUBGROUP1_ID)
        // └── group2 (GROUP2_ID)
        //     ├── entry2 (ENTRY2_ID)   <-- moved here
        //     └── subgroup2 (SUBGROUP2_ID)
        //
        source_db
            .entry_mut(ENTRY2_ID)
            .unwrap()
            .track_changes()
            .move_to(GROUP2_ID)
            .expect("move successful");

        let location_changed_timestamp = source_db
            .entry(ENTRY2_ID)
            .unwrap()
            .times
            .location_changed
            .unwrap();

        // perform the merge - this should relocate the entry in destination_db
        destination_db.merge(&source_db).unwrap();

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(group_count_after, group_count_before);
        assert_eq!(entry_count_after, entry_count_before);

        assert!(destination_db.entry(ENTRY2_ID).is_some());

        let entry = destination_db.entry(ENTRY2_ID).unwrap();
        assert_eq!(entry.parent().id(), GROUP2_ID);
        assert_eq!(entry.times.location_changed, Some(location_changed_timestamp));
    }

    /// Test that an entry is relocated in source and modified in both source and destination
    /// and the correct content is kept after merging.
    #[test]
    fn test_entry_relocation_and_update() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // perform first edit of entry in source
        source_db.entry_mut(ENTRY2_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "entry2_modified_in_source");
        });

        sleep();
        // relocate entry in source
        source_db
            .entry_mut(ENTRY2_ID)
            .unwrap()
            .track_changes()
            .move_to(GROUP2_ID)
            .expect("move successful");

        let location_changed_timestamp = source_db
            .entry(ENTRY2_ID)
            .unwrap()
            .times
            .location_changed
            .unwrap();

        sleep();

        // perform second edit of entry in destination
        destination_db.entry_mut(ENTRY2_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "entry2_modified_in_destination");
        });

        let entry_modified_timestamp = destination_db
            .entry(ENTRY2_ID)
            .unwrap()
            .times
            .last_modification
            .unwrap();

        // perform the merge - this should relocate the entry in destination_db and keep the
        // content from destination_db since it was modified later
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(group_count_after, group_count_before);
        assert_eq!(entry_count_after, entry_count_before);

        // check that move occurred
        assert!(destination_db.entry(ENTRY2_ID).is_some());
        let entry = destination_db.entry(ENTRY2_ID).unwrap();
        assert_eq!(entry.parent().id(), GROUP2_ID);
        assert_eq!(entry.times.location_changed, Some(location_changed_timestamp));

        // check that content from destination is kept
        assert_eq!(entry.get(fields::TITLE), Some("entry2_modified_in_destination"));
        assert_eq!(entry.times.last_modification, Some(entry_modified_timestamp));

        // and the source's edit is in the history
        let history = entry.history.clone().unwrap();
        assert_history_ordered(&history);
        assert_eq!(
            history.get_entry_index(0).unwrap().get(fields::TITLE),
            Some("entry2_modified_in_source")
        );
    }

    /// 测试条目在源中修改, 并在目标中移动, 合并后来源中的条目应该放进目标中的历史
    #[test]
    fn test_entry_relocation_in_destination_and_update() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // edit entry in source
        source_db.entry_mut(ENTRY2_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected(fields::TITLE, "entry2_modified_in_source");
        });

        sleep();

        // relocate entry in destination
        destination_db
            .entry_mut(ENTRY2_ID)
            .unwrap()
            .track_changes()
            .move_to(GROUP2_ID)
            .expect("move successful");

        let location_changed_timestamp = destination_db
            .entry(ENTRY2_ID)
            .unwrap()
            .times
            .location_changed
            .unwrap();

        destination_db.merge(&source_db).unwrap();

        assert_eq!(
            destination_db
                .entry(ENTRY2_ID)
                .unwrap()
                .history
                .as_ref()
                .unwrap()
                .get_entries()
                .len(),
            2
        );

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(group_count_after, group_count_before);
        assert_eq!(entry_count_after, entry_count_before);

        // check that move occurred
        assert!(destination_db.entry(ENTRY2_ID).is_some());

        let entry = destination_db.entry(ENTRY2_ID).unwrap();
        assert_eq!(entry.parent().id(), GROUP2_ID);
        assert_eq!(entry.times.location_changed, Some(location_changed_timestamp));

        assert_eq!(
            entry.iter_all_historical().nth(0).unwrap().get(fields::TITLE),
            Some("entry2_modified_in_source")
        );
    }

    /// Test that an entry can be relocated into a newly created group
    #[test]
    fn test_entry_relocation_new_group() {
        let mut destination_db = create_test_database();

        let new_entry_id = destination_db
            .root_mut()
            .add_entry()
            .edit(|e| {
                e.set_unprotected("Title", "new_entry");
            })
            .id();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        let mut source_db = destination_db.clone();

        let new_group_id = source_db
            .root_mut()
            .add_group()
            .edit(|g| g.name = "new_group".to_string())
            .id();

        sleep();

        // modify the entry in source
        source_db.entry_mut(new_entry_id).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "new_entry_modified_in_source");
        });

        sleep();
        // relocate the entry to the new group in source
        {
            source_db
                .entry_mut(new_entry_id)
                .unwrap()
                .track_changes()
                .move_to(new_group_id)
                .expect("move successful");
        }

        // perform the merge - this should create the new group and update and relocate the entry there
        destination_db.merge(&source_db).unwrap();

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before + 1);

        assert!(destination_db.entry(new_entry_id).is_some());
        let entry = destination_db.entry(new_entry_id).unwrap();
        assert_eq!(entry.parent().id(), new_group_id);
        assert_eq!(entry.get(fields::TITLE), Some("new_entry_modified_in_source"));
    }

    /// Test that a group relocation in source is reflected in destination when merging.
    #[test]
    fn test_group_relocation() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // before
        // root (ROOT_GROUP_ID)
        // ├── entry1 (ENTRY1_ID)
        // ├── group1 (GROUP1_ID)
        // │   └── subgroup1 (SUBGROUP1_ID) <-- this group
        // │       └── entry2 (ENTRY2_ID)
        // └── group2 (GROUP2_ID)
        //    └── subgroup2 (SUBGROUP2_ID)
        //
        // after
        // root (ROOT_GROUP_ID)
        // ├── entry1 (ENTRY1_ID)
        // ├── group1 (GROUP1_ID)
        // └── group2 (GROUP2_ID)
        //    └── subgroup2 (SUBGROUP2_ID)
        //        └── subgroup1 (SUBGROUP1_ID) <-- moved here
        //            └── entry2 (ENTRY2_ID)

        source_db
            .group_mut(SUBGROUP1_ID)
            .unwrap()
            .track_changes()
            .move_to(GROUP2_ID)
            .expect("move successful");

        let location_changed_timestamp = source_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .location_changed
            .unwrap();

        // perform the merge - this should relocate the group in destination_db
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 2);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(SUBGROUP1_ID).is_some());
        assert!(destination_db.entry(ENTRY2_ID).is_some());

        let group = destination_db.group(SUBGROUP1_ID).unwrap();
        assert_eq!(group.parent().unwrap().id(), GROUP2_ID);
        assert_eq!(group.times.location_changed, Some(location_changed_timestamp));
    }

    /// Test that an entry updated in destination is not touched when merging.
    #[test]
    fn test_update_in_destination_no_conflict() {
        let mut destination_db = create_test_database();
        let source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // update entry in destination
        destination_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "entry1_updated");
        });

        // perform the merge - this should not change anything since source is older
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        // check that history is preserved
        let merged_history = destination_db.entry(ENTRY1_ID).unwrap().history.clone().unwrap();
        assert_history_ordered(&merged_history);
        assert_eq!(merged_history.get_entries().len(), 1);

        // check that we can find the old version of the entry
        let merged_entry = &merged_history.get_entry_index(0).unwrap();
        assert_eq!(merged_entry.get(fields::TITLE), Some("entry1"));

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert_eq!(
            destination_db.entry(ENTRY1_ID).unwrap().get(fields::TITLE),
            Some("entry1_updated")
        );
    }

    /// Test that an entry updated in source is merged into destination when merging.
    #[test]
    fn test_update_in_source_no_conflict() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // update entry in source
        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "entry1_updated");
        });

        // perform the merge - this should update the entry in destination_db
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        // check that history is preserved
        let merged_history = destination_db.entry(ENTRY1_ID).unwrap().history.clone().unwrap();
        assert_history_ordered(&merged_history);
        assert_eq!(merged_history.get_entries().len(), 1);

        // check that we can find the old version of the entry
        let merged_entry = &merged_history.get_entry_index(0).unwrap();
        assert_eq!(merged_entry.get(fields::TITLE), Some("entry1"));

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        // check that the entry was updated
        assert_eq!(
            destination_db.entry(ENTRY1_ID).unwrap().get(fields::TITLE),
            Some("entry1_updated")
        );
    }

    /// Test that an entry updated in both source and destination is merged correctly.
    #[test]
    fn test_update_with_conflicts() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // update entry in destination
        destination_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "entry1_updated_from_destination");
        });

        sleep();

        // update entry in source
        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|e| {
            e.set_unprotected("Title", "entry1_updated_from_source");
        });

        // perform the merge - this should merge the changes from both databases, keeping the newer
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        // check that the entry was updated with the source change (newer)
        let entry = destination_db.entry(ENTRY1_ID).unwrap();
        assert_eq!(entry.get(fields::TITLE), Some("entry1_updated_from_source"));

        // check that history is preserved and contains both older versions
        let merged_history = entry.history.clone().unwrap();
        assert_history_ordered(&merged_history);
        assert_eq!(merged_history.get_entries().len(), 2);
        assert_eq!(
            merged_history.get_entry_index(0).unwrap().get(fields::TITLE),
            Some("entry1_updated_from_destination")
        );
        assert_eq!(
            merged_history.get_entry_index(1).unwrap().get(fields::TITLE),
            Some("entry1")
        );

        // Merging again should not result in any additional change.
        let merge_result = destination_db.merge(&destination_db.clone()).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);
    }

    /// Test that a group's tags and expiry, and an entry's expiry, come over from a newer
    /// source, and a new group arrives with its tags.
    #[test]
    fn test_tags_and_expiry_from_source() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        sleep();

        let expiry = Times::now();
        source_db.group_mut(GROUP1_ID).unwrap().edit_tracking(|g| {
            g.tags = vec!["important".to_string()];
            g.times.expiry = Some(expiry);
            g.times.expires = Some(true);
        });
        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|e| {
            e.times.expiry = Some(expiry);
            e.times.expires = Some(true);
            e.times.last_modification = Some(Times::now());
        });
        source_db
            .group_mut(GROUP2_ID)
            .unwrap()
            .add_group()
            .edit_tracking(|g| {
                g.name = "tagged".to_string();
                g.tags = vec!["new".to_string()];
            });

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);

        let group = destination_db.group(GROUP1_ID).unwrap();
        assert_eq!(group.tags, vec!["important".to_string()]);
        assert_eq!(group.times.expiry, Some(expiry));
        assert_eq!(group.times.expires, Some(true));

        let entry = destination_db.entry(ENTRY1_ID).unwrap();
        assert_eq!(entry.times.expiry, Some(expiry));
        assert_eq!(entry.times.expires, Some(true));

        let tagged = destination_db
            .iter_all_groups()
            .find(|g| g.name == "tagged")
            .unwrap();
        assert_eq!(tagged.tags, vec!["new".to_string()]);
    }

    /// Test that a group updated in source is merged into destination when merging.
    #[test]
    fn test_group_update_in_source() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        source_db.group_mut(SUBGROUP1_ID).unwrap().edit_tracking(|g| {
            g.name = "subgroup1_updated_name".to_string();
        });

        let modification_timestamp = source_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .last_modification
            .unwrap();

        // perform the merge - this should update the group in destination
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(SUBGROUP1_ID).is_some());

        assert_eq!(
            destination_db.group(SUBGROUP1_ID).unwrap().name,
            "subgroup1_updated_name"
        );
        assert_eq!(
            destination_db
                .group(SUBGROUP1_ID)
                .unwrap()
                .times
                .last_modification,
            Some(modification_timestamp)
        );
    }

    /// Test that a group updated in destination is not changed when merging.
    #[test]
    fn test_group_update_in_destination() {
        let mut destination_db = create_test_database();
        let source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        destination_db
            .group_mut(SUBGROUP1_ID)
            .unwrap()
            .edit_tracking(|g| {
                g.name = "subgroup1_updated_name".to_string();
            });

        let last_modification = destination_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .last_modification
            .unwrap();

        // perform the merge - this should not change anything since source is older
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(SUBGROUP1_ID).is_some());
        assert_eq!(
            destination_db.group(SUBGROUP1_ID).unwrap().name,
            "subgroup1_updated_name"
        );

        assert_eq!(
            destination_db
                .group(SUBGROUP1_ID)
                .unwrap()
                .times
                .last_modification,
            Some(last_modification)
        );
    }

    /// Test that a group updated in source and relocated is merged correctly.
    #[test]
    fn test_group_update_and_relocation() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        source_db
            .group_mut(SUBGROUP1_ID)
            .unwrap()
            .track_changes()
            .edit(|g| {
                g.name = "subgroup1_updated_name".to_string();
            })
            .move_to(GROUP2_ID)
            .expect("move successful");

        let modification_timestamp = source_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .last_modification
            .unwrap();

        let location_changed_timestamp = source_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .location_changed
            .unwrap();

        // perform the merge - this should update and relocate the group in destination
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 2);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(SUBGROUP1_ID).is_some());
        let group = destination_db.group(SUBGROUP1_ID).unwrap();
        assert_eq!(group.name, "subgroup1_updated_name");
        assert_eq!(group.parent().unwrap().id(), GROUP2_ID);
        assert_eq!(group.times.last_modification, Some(modification_timestamp));
        assert_eq!(group.times.location_changed, Some(location_changed_timestamp));
    }

    /// Test that a group updated in source and relocated in destionation is merged correctly.
    #[test]
    fn test_group_update_in_destination_and_relocation_in_source() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let entry_count_before = destination_db.entries.len();
        let group_count_before = destination_db.groups.len();

        sleep();

        // rename group in source
        source_db.group_mut(SUBGROUP1_ID).unwrap().edit_tracking(|g| {
            g.name = "subgroup1_updated_name".to_string();
        });

        sleep();

        // relocate group in destination
        destination_db
            .group_mut(SUBGROUP1_ID)
            .unwrap()
            .track_changes()
            .move_to(GROUP2_ID)
            .expect("move successful");

        let location_changed_timestamp = destination_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .location_changed
            .unwrap();

        let modification_timestamp = destination_db
            .group(SUBGROUP1_ID)
            .unwrap()
            .times
            .last_modification
            .unwrap();

        // 不进行任何合并, 因为移动操作也会更新 last_modification, 目标的 last_modification 是最新的
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let entry_count_after = destination_db.entries.len();
        let group_count_after = destination_db.groups.len();
        assert_eq!(entry_count_after, entry_count_before);
        assert_eq!(group_count_after, group_count_before);

        assert!(destination_db.group(SUBGROUP1_ID).is_some());
        let group = destination_db.group(SUBGROUP1_ID).unwrap();
        assert_eq!(group.name, "subgroup1");
        assert_eq!(group.parent().unwrap().id(), GROUP2_ID);
        assert_eq!(group.times.last_modification, Some(modification_timestamp));
        assert_eq!(group.times.location_changed, Some(location_changed_timestamp));
    }

    #[test]
    fn test_merge_untracked_group_history() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        // this is an invalid edit as the last modified timestamp of the group is not updated
        source_db
            .group_mut(GROUP1_ID)
            .unwrap()
            .edit(|g| {
                g.name = "group1_updated_name".to_string();
            })
            .move_to(GROUP2_ID)
            .expect("move successful");

        assert_eq!(
            destination_db.group(GROUP1_ID).unwrap().times,
            source_db.group(GROUP1_ID).unwrap().times
        );

        // the edit in source_db is not tracked and has the same timestamp as the group in
        // destination_db, so there is no telling which is newer: the destination's is kept
        let mut merged_db = destination_db.clone();
        let merge_result = merged_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 1);
        assert_eq!(merge_result.events.len(), 0);
        assert_eq!(merged_db.group(GROUP1_ID).unwrap().name, "group1");

        // remove the timestamps to test warnings
        destination_db
            .group_mut(GROUP1_ID)
            .unwrap()
            .times
            .last_modification = None;
        destination_db
            .group_mut(GROUP1_ID)
            .unwrap()
            .times
            .location_changed = None;
        source_db.group_mut(GROUP1_ID).unwrap().times.last_modification = None;
        source_db.group_mut(GROUP1_ID).unwrap().times.location_changed = None;

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 3);
        assert_eq!(merge_result.events.len(), 0);
    }

    #[test]
    fn test_merge_untracked_entry_history() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        // this is an invalid edit as the last modified timestamp of the entry is not updated
        source_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .edit(|e| {
                e.set_unprotected("Title", "entry1_updated_title");
            })
            .move_to(GROUP2_ID)
            .expect("move successful");

        assert_eq!(
            destination_db.entry(ENTRY1_ID).unwrap().times,
            source_db.entry(ENTRY1_ID).unwrap().times
        );

        // the edit in source_db is not tracked and has the same timestamp as the entry in
        // destination_db, so there is no telling which is newer: the destination's is kept and
        // the source's is filed in the history
        let mut merged_db = destination_db.clone();
        merged_db.merge(&source_db).unwrap();

        assert_eq!(
            merged_db.entry(ENTRY1_ID).unwrap().iter_all_historical().count(),
            1
        );

        let entry = merged_db.entry(ENTRY1_ID).unwrap();
        assert_eq!(entry.get(fields::TITLE), Some("entry1"));
        let history = entry.history.clone().unwrap();
        assert_eq!(
            history.get_entry_index(0).unwrap().get(fields::TITLE),
            Some("entry1_updated_title")
        );

        // merging the same source again changes nothing more
        merged_db.merge(&source_db).unwrap();

        assert_eq!(
            merged_db.entry(ENTRY1_ID).unwrap().iter_all_historical().count(),
            1
        );

        let entry = merged_db.entry(ENTRY1_ID).unwrap();
        assert_eq!(entry.get(fields::TITLE), Some("entry1"));
        let history = entry.history.clone().unwrap();
        assert_eq!(
            history.get_entry_index(0).unwrap().get(fields::TITLE),
            Some("entry1_updated_title")
        );

        // remove the timestamps to test warnings
        destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .times
            .last_modification = None;
        destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .times
            .location_changed = None;
        source_db.entry_mut(ENTRY1_ID).unwrap().times.last_modification = None;
        source_db.entry_mut(ENTRY1_ID).unwrap().times.location_changed = None;

        destination_db.merge(&source_db).unwrap();
        assert_eq!(
            destination_db
                .entry(ENTRY1_ID)
                .unwrap()
                .iter_all_historical()
                .count(),
            1
        );
        let entry = destination_db.entry(ENTRY1_ID).unwrap();
        assert_eq!(entry.get(fields::TITLE), Some("entry1"));
        let history = entry.history.clone().unwrap();
        assert_eq!(
            history.get_entry_index(0).unwrap().get(fields::TITLE),
            Some("entry1_updated_title")
        );
    }

    #[test]
    fn test_icon_added_in_source() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        sleep();

        // add a new icon in source
        let new_icon_id = {
            let mut source_entry = source_db.entry_mut(ENTRY1_ID).unwrap();
            let mut source_track = source_entry.track_changes();
            let new_icon_id = source_track.set_icon_custom_new(vec![1, 2, 3, 4]).id();

            new_icon_id
        };

        // perform the merge - this should add the new icon to destination and update the entry's icon reference
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 2);

        assert!(destination_db.custom_icon(new_icon_id).is_some());
    }

    #[test]
    fn test_icon_updated_in_source() {
        let mut destination_db = create_test_database();

        // add a new icon in destination
        let icon_id = destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .track_changes()
            .as_mut()
            .set_icon_custom_new(vec![1, 2, 3, 4])
            .id();

        let mut source_db = destination_db.clone();

        sleep();

        // update the icon in source
        let mut source_entry = source_db.entry_mut(ENTRY1_ID).unwrap();
        let mut source_icon = source_entry.custom_icon_mut().unwrap();
        source_icon.data = vec![5, 6, 7, 8];
        source_icon.last_modification_time = Some(Times::now());

        // perform the merge - this should update the icon in destination
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 1);

        let icon = destination_db.custom_icon(icon_id).unwrap();
        assert_eq!(icon.data, vec![5, 6, 7, 8]);
    }

    #[test]
    fn test_icon_updated_in_destination() {
        let mut destination_db = create_test_database();

        // add a new icon in destination
        let icon_id = destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .track_changes()
            .as_mut()
            .set_icon_custom_new(vec![1, 2, 3, 4])
            .id();

        let source_db = destination_db.clone();

        sleep();

        // update the icon in destination
        let mut destination_icon = destination_db.custom_icon_mut(icon_id).unwrap();
        destination_icon.data = vec![5, 6, 7, 8];
        destination_icon.last_modification_time = Some(Times::now());

        // perform the merge - this should keep the icon update in destination since it's newer
        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        let icon = destination_db.custom_icon(icon_id).unwrap();
        assert_eq!(icon.data, vec![5, 6, 7, 8]);
    }

    #[test]
    fn test_meta_updated_in_source() {
        let mut destination_db = create_test_database();
        destination_db.meta.database_name = Some("meta".into());
        destination_db.meta.database_name_changed = Some(Times::now());

        destination_db.meta.history_max_items = Some(20);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, Times::now());

        destination_db.meta.history_max_size = Some(0);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, Times::now());

        destination_db.meta.custom_data.insert(
            "test".into(),
            CustomDataItem {
                value: Some(CustomDataValue::String("aaa".into())),
                last_modification_time: None,
            },
        );

        let mut source_db = destination_db.clone();

        sleep();

        source_db.meta.custom_data.insert(
            "test".into(),
            CustomDataItem {
                value: Some(CustomDataValue::String("bbb".into())),
                last_modification_time: None,
            },
        );

        source_db.meta.custom_data.insert(
            "test2".into(),
            CustomDataItem {
                value: Some(CustomDataValue::String("aaa".into())),
                last_modification_time: None,
            },
        );

        source_db.meta.database_name = Some("meta2".into());
        source_db.meta.database_name_changed = Some(Times::now());

        source_db.meta.database_description = Some("description".into());
        source_db.meta.database_description_changed = Some(Times::now());

        source_db.meta.default_username = Some("default username".into());
        source_db.meta.default_username_changed = Some(Times::now());

        source_db.meta.maintenance_history_days = Some(33);
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED, Times::now());

        source_db.meta.color = Some(Color::default());
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_COLOR_CHANGED, Times::now());

        source_db.meta.master_key_change_rec = Some(22);
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED, Times::now());

        source_db.meta.memory_protection = Some(MemoryProtection::default());
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_MEMORY_PROTECTION_CHANGED, Times::now());

        source_db.meta.master_key_change_force = Some(11);
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED, Times::now());

        source_db.meta.entry_templates_group = Some(GROUP1_ID.uuid());
        source_db.meta.entry_templates_group_changed = Some(Times::now());

        // Don't consider it yet
        source_db.meta.last_selected_group = Some(GROUP2_ID.uuid());
        source_db.meta.last_top_visible_group = Some(SUBGROUP1_ID.uuid());

        source_db.meta.history_max_items = Some(-1);
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, Times::now());

        source_db.meta.history_max_size = Some(-1);
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, Times::now());

        source_db.meta.settings_changed = Some(Times::now());

        destination_db.merge(&source_db).unwrap();

        assert_eq!(
            destination_db
                .meta
                .custom_data
                .get("test")
                .unwrap()
                .value
                .clone()
                .unwrap(),
            CustomDataValue::String("aaa".into())
        );
        assert_eq!(
            destination_db
                .meta
                .custom_data
                .get("test2")
                .unwrap()
                .value
                .clone()
                .unwrap(),
            CustomDataValue::String("aaa".into())
        );

        assert_eq!(destination_db.meta.database_name, Some("meta2".into()));
        assert_eq!(
            destination_db.meta.database_description,
            Some("description".into())
        );
        assert_eq!(
            destination_db.meta.default_username,
            Some("default username".into())
        );
        assert_eq!(destination_db.meta.maintenance_history_days, Some(33));
        assert_eq!(destination_db.meta.color, Some(Color::default()));
        assert_eq!(destination_db.meta.master_key_change_rec, Some(22));
        assert_eq!(
            destination_db.meta.memory_protection,
            Some(MemoryProtection::default())
        );
        assert_eq!(destination_db.meta.master_key_change_force, Some(11));

        assert_eq!(destination_db.meta.entry_templates_group, Some(GROUP1_ID.uuid()));

        // Currently ignored
        assert_eq!(destination_db.meta.last_selected_group, None);
        assert_eq!(destination_db.meta.last_top_visible_group, None);

        assert_eq!(destination_db.meta.history_max_items, Some(-1));
        assert_eq!(destination_db.meta.history_max_size, Some(-1));
    }

    #[test]
    fn test_meta_updated_in_destination() {
        let mut destination_db = create_test_database();
        destination_db.meta.database_name = Some("meta".into());
        destination_db.meta.database_name_changed = Some(Times::now());

        destination_db.meta.history_max_items = Some(20);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, Times::now());

        destination_db.meta.history_max_size = Some(0);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, Times::now());

        destination_db.meta.custom_data.insert(
            "test".into(),
            CustomDataItem {
                value: Some(CustomDataValue::String("aaa".into())),
                last_modification_time: None,
            },
        );

        let source_db = destination_db.clone();

        sleep();

        destination_db.meta.custom_data.insert(
            "test".into(),
            CustomDataItem {
                value: Some(CustomDataValue::String("bbb".into())),
                last_modification_time: None,
            },
        );

        destination_db.meta.custom_data.insert(
            "test2".into(),
            CustomDataItem {
                value: Some(CustomDataValue::String("aaa".into())),
                last_modification_time: None,
            },
        );

        destination_db.meta.database_name = Some("meta2".into());
        destination_db.meta.database_name_changed = Some(Times::now());

        destination_db.meta.database_description = Some("description".into());
        destination_db.meta.database_description_changed = Some(Times::now());

        destination_db.meta.default_username = Some("default username".into());
        destination_db.meta.default_username_changed = Some(Times::now());

        destination_db.meta.maintenance_history_days = Some(33);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_MAINTENANCE_HISTORY_DAYS_CHANGED, Times::now());

        destination_db.meta.color = Some(Color::default());
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_COLOR_CHANGED, Times::now());

        destination_db.meta.master_key_change_rec = Some(22);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_REC_CHANGED, Times::now());

        destination_db.meta.memory_protection = Some(MemoryProtection::default());
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_MEMORY_PROTECTION_CHANGED, Times::now());

        destination_db.meta.master_key_change_force = Some(11);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_MASTER_KEY_CHANGE_FORCE_CHANGED, Times::now());

        destination_db.meta.entry_templates_group = Some(GROUP1_ID.uuid());
        destination_db.meta.entry_templates_group_changed = Some(Times::now());

        // Don't consider it yet
        destination_db.meta.last_selected_group = Some(GROUP2_ID.uuid());
        destination_db.meta.last_top_visible_group = Some(SUBGROUP1_ID.uuid());

        destination_db.meta.history_max_items = Some(-1);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_ITEMS_CHANGED, Times::now());

        destination_db.meta.history_max_size = Some(-1);
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_HISTORY_MAX_SIZE_CHANGED, Times::now());

        destination_db.meta.settings_changed = Some(Times::now());

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        assert_eq!(
            destination_db
                .meta
                .custom_data
                .get("test")
                .unwrap()
                .value
                .clone()
                .unwrap(),
            CustomDataValue::String("bbb".into())
        );
        assert_eq!(
            destination_db
                .meta
                .custom_data
                .get("test2")
                .unwrap()
                .value
                .clone()
                .unwrap(),
            CustomDataValue::String("aaa".into())
        );

        assert_eq!(destination_db.meta.database_name, Some("meta2".into()));
        assert_eq!(
            destination_db.meta.database_description,
            Some("description".into())
        );
        assert_eq!(
            destination_db.meta.default_username,
            Some("default username".into())
        );
        assert_eq!(destination_db.meta.maintenance_history_days, Some(33));
        assert_eq!(destination_db.meta.color, Some(Color::default()));
        assert_eq!(destination_db.meta.master_key_change_rec, Some(22));
        assert_eq!(
            destination_db.meta.memory_protection,
            Some(MemoryProtection::default())
        );
        assert_eq!(destination_db.meta.master_key_change_force, Some(11));

        assert_eq!(destination_db.meta.entry_templates_group, Some(GROUP1_ID.uuid()));

        // Currently ignored
        assert_eq!(destination_db.meta.last_selected_group, Some(GROUP2_ID.uuid()));
        assert_eq!(
            destination_db.meta.last_top_visible_group,
            Some(SUBGROUP1_ID.uuid())
        );

        assert_eq!(destination_db.meta.history_max_items, Some(-1));
        assert_eq!(destination_db.meta.history_max_size, Some(-1));
    }

    #[test]
    fn test_config_updated_in_source() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();
        sleep();
        let mut config = DatabaseConfig::default();

        config.version = DatabaseVersion::KDB3(3);
        config.compression_config = CompressionConfig::None;
        config.outer_cipher_config = OuterCipherConfig::Twofish;
        config.inner_cipher_config = InnerCipherConfig::Salsa20;
        config.kdf_config = KdfConfig::Aes { rounds: 1 };

        source_db.config = config;
        source_db.meta.settings_changed = Some(Times::now());
        source_db
            .meta
            .set_custom_time_changed(CUSTOM_DATABASE_CONFIG_CHANGED, Times::now());

        destination_db.merge(&source_db).unwrap();

        assert_ne!(destination_db.config.version, DatabaseVersion::KDB3(3));
        assert_eq!(destination_db.config.compression_config, CompressionConfig::None);
        assert_eq!(
            destination_db.config.outer_cipher_config,
            OuterCipherConfig::Twofish
        );
        assert_eq!(
            destination_db.config.inner_cipher_config,
            InnerCipherConfig::Salsa20
        );
        assert_eq!(destination_db.config.kdf_config, KdfConfig::Aes { rounds: 1 });
    }

    #[test]
    fn test_config_updated_in_destination() {
        let mut destination_db = create_test_database();

        let mut config = DatabaseConfig::default();

        config.compression_config = CompressionConfig::None;

        destination_db.config = config;
        destination_db.meta.settings_changed = Some(Times::now());
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_DATABASE_CONFIG_CHANGED, Times::now());

        let source_db = destination_db.clone();

        sleep();
        let mut config = DatabaseConfig::default();

        config.compression_config = CompressionConfig::GZip;
        config.outer_cipher_config = OuterCipherConfig::Twofish;
        config.inner_cipher_config = InnerCipherConfig::Salsa20;
        config.kdf_config = KdfConfig::Aes { rounds: 1 };

        destination_db.config = config;
        destination_db.meta.settings_changed = Some(Times::now());
        destination_db
            .meta
            .set_custom_time_changed(CUSTOM_DATABASE_CONFIG_CHANGED, Times::now());

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        assert_eq!(merge_result.events.len(), 0);

        assert_eq!(destination_db.config.compression_config, CompressionConfig::GZip);
        assert_eq!(
            destination_db.config.outer_cipher_config,
            OuterCipherConfig::Twofish
        );
        assert_eq!(
            destination_db.config.inner_cipher_config,
            InnerCipherConfig::Salsa20
        );
        assert_eq!(destination_db.config.kdf_config, KdfConfig::Aes { rounds: 1 });
    }

    #[test]
    fn test_customicon_updated_in_source() {
        let mut destination_db = create_test_database();

        let mut source_db = destination_db.clone();

        sleep();

        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|entry| {
            entry.set_icon_custom_new(b"1111".to_vec());
        });

        destination_db.merge(&source_db).unwrap();

        assert_eq!(destination_db.custom_icons.len(), 1);

        let entry1 = destination_db.entry(ENTRY1_ID).unwrap();

        assert_eq!(entry1.custom_icon().unwrap().data, b"1111".to_vec());
    }

    #[test]
    fn test_attachments_updated_in_source() {
        let mut destination_db = create_test_database();

        let mut source_db = destination_db.clone();

        sleep();

        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|entry| {
            entry.add_attachment("file.txt", crate::db::Value::unprotected(b"1234"));
        });

        destination_db.merge(&source_db).unwrap();

        assert_eq!(destination_db.num_attachments(), 1);

        assert_eq!(
            destination_db
                .entry(ENTRY1_ID)
                .unwrap()
                .attachment_by_name("file.txt")
                .unwrap()
                .data
                .get(),
            b"1234"
        );
    }

    #[cfg(feature = "save_kdbx4")]
    #[test]
    fn test_attachments_id_changed() {
        const ENTRY3_ID: EntryId = EntryId::from_uuid(uuid!("00000000-0000-0000-0000-000000000008"));
        let mut destination_db = create_test_database();
        sleep();

        destination_db
            .root_mut()
            .add_entry_with_id(ENTRY3_ID)
            .unwrap()
            .edit(|e| e.set_unprotected("Title", "entry3"));

        destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .edit_tracking(|entry| {
                entry.add_attachment("file1.txt", crate::db::Value::unprotected(b"1111"));
            });

        destination_db
            .entry_mut(ENTRY2_ID)
            .unwrap()
            .edit_tracking(|entry| {
                entry.add_attachment("file2.txt", crate::db::Value::unprotected(b"2222"));
            });

        destination_db
            .entry_mut(ENTRY3_ID)
            .unwrap()
            .edit_tracking(|entry| {
                entry.add_attachment("file3.txt", crate::db::Value::unprotected(b"3333"));
            });

        let mut source_db = destination_db.clone();

        destination_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .track_changes()
            .remove();

        destination_db = save_open(&destination_db);

        sleep();
        source_db.entry_mut(ENTRY2_ID).unwrap().edit_tracking(|entry| {
            entry.add_attachment("file4.txt", crate::db::Value::unprotected(b"4444"));
        });

        source_db = save_open(&source_db);

        destination_db.merge(&source_db).unwrap();

        assert_eq!(destination_db.num_attachments(), 3);

        let entry2 = destination_db.entry(ENTRY2_ID).unwrap();

        assert_eq!(entry2.attachment_by_name("file2.txt").unwrap().get(), b"2222");

        assert_eq!(entry2.attachment_by_name("file4.txt").unwrap().get(), b"4444");

        let entry3 = destination_db.entry(ENTRY3_ID).unwrap();

        assert_eq!(entry3.attachment_by_name("file3.txt").unwrap().get(), b"3333");
    }

    #[cfg(feature = "save_kdbx4")]
    #[test]
    fn test_attachments_history_in_source() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        sleep();
        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|entry| {
            entry.add_attachment("file1.txt", crate::db::Value::unprotected(b"1111"));
        });

        sleep();
        source_db.entry_mut(ENTRY1_ID).unwrap().edit_tracking(|entry| {
            entry.edit(|entry| {
                entry.as_mut().remove_attachment_by_name("file1.txt");
            });
        });

        let source_db = save_open(&source_db);

        destination_db.merge(&source_db).unwrap();

        assert_eq!(destination_db.num_attachments(), 1);

        let entry1 = destination_db.entry(ENTRY1_ID).unwrap();

        assert_eq!(entry1.iter_all_historical().count(), 2);

        assert_eq!(entry1.attachments.len(), 0);

        let entry1_history1 = entry1.iter_all_historical().nth(0).unwrap();

        assert_eq!(
            entry1_history1.attachment_by_name("file1.txt").unwrap().get(),
            b"1111"
        );
    }

    #[test]
    fn test_new_entry_attachments_in_source() {
        let mut destination_db = create_test_database();

        let mut source_db = destination_db.clone();

        sleep();

        let id = source_db
            .root_mut()
            .add_entry()
            .edit(|entry| {
                entry.add_attachment("file.txt", crate::db::Value::unprotected(b"1234"));
            })
            .id();

        destination_db.merge(&source_db).unwrap();

        assert_eq!(destination_db.num_attachments(), 1);

        assert_eq!(
            destination_db
                .entry(id)
                .unwrap()
                .attachment_by_name("file.txt")
                .unwrap()
                .data
                .get(),
            b"1234"
        );
    }

    /// A fixed point in time, `secs` seconds after the epoch.
    fn at(secs: i64) -> chrono::NaiveDateTime {
        chrono::DateTime::from_timestamp(secs, 0).unwrap().naive_utc()
    }

    /// Deletion records are copied for objects that the destination never had, keeping the earlier
    /// deletion time for objects deleted on both sides.
    #[test]
    fn test_deleted_objects_are_merged() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        let never_in_dest = uuid!("00000000-0000-0000-0000-0000000000a1");
        let deleted_later_in_source = uuid!("00000000-0000-0000-0000-0000000000a2");
        let deleted_earlier_in_source = uuid!("00000000-0000-0000-0000-0000000000a3");

        destination_db
            .deleted_objects
            .insert(deleted_later_in_source, Some(at(1_000)));
        destination_db
            .deleted_objects
            .insert(deleted_earlier_in_source, Some(at(2_000)));

        source_db.deleted_objects.insert(never_in_dest, Some(at(1_000)));
        source_db
            .deleted_objects
            .insert(deleted_later_in_source, Some(at(2_000)));
        source_db
            .deleted_objects
            .insert(deleted_earlier_in_source, Some(at(1_000)));

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        let events: Vec<_> = merge_result
            .events
            .iter()
            .map(|e| match (&e.target, &e.event_type) {
                (MergeEventTarget::DeletedObject(uuid), MergeEventType::Created) => (*uuid, "created"),
                (MergeEventTarget::DeletedObject(uuid), MergeEventType::Updated) => (*uuid, "updated"),
                _ => panic!("unexpected event {:?}", e),
            })
            .collect();
        assert_eq!(
            events,
            vec![(never_in_dest, "created"), (deleted_earlier_in_source, "updated")]
        );

        let deleted = &destination_db.deleted_objects;
        assert_eq!(deleted.get(&never_in_dest), Some(&Some(at(1_000))));
        assert_eq!(deleted.get(&deleted_later_in_source), Some(&Some(at(1_000))));
        assert_eq!(deleted.get(&deleted_earlier_in_source), Some(&Some(at(1_000))));

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.events.len(), 0);
    }

    /// An entry deleted in destination but changed later in source comes back, and its deletion
    /// record is dropped.
    #[test]
    fn test_deleted_object_record_dropped_when_restored() {
        let mut destination_db = create_test_database();
        let mut source_db = destination_db.clone();

        destination_db.entry_mut(ENTRY1_ID).unwrap().remove();
        destination_db
            .deleted_objects
            .insert(ENTRY1_ID.uuid(), Some(at(1_000)));

        source_db
            .entry_mut(ENTRY1_ID)
            .unwrap()
            .edit_tracking(|e| e.set_unprotected(fields::TITLE, "changed after deletion"));

        let merge_result = destination_db.merge(&source_db).unwrap();
        assert_eq!(merge_result.warnings.len(), 0);
        let deleted_object_events: Vec<_> = merge_result
            .events
            .iter()
            .filter(|e| matches!(e.target, MergeEventTarget::DeletedObject(_)))
            .collect();
        assert_eq!(deleted_object_events.len(), 1);
        assert!(matches!(
            (&deleted_object_events[0].target, &deleted_object_events[0].event_type),
            (MergeEventTarget::DeletedObject(uuid), MergeEventType::Deleted) if *uuid == ENTRY1_ID.uuid()
        ));
        assert!(destination_db.entry(ENTRY1_ID).is_some());
        assert!(!destination_db.deleted_objects.contains_key(&ENTRY1_ID.uuid()));
    }
}
