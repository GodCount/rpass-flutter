use std::{
    collections::HashSet,
    ops::{Deref, DerefMut},
};

use chrono::NaiveDateTime;
use thiserror::Error;
use uuid::Uuid;

use crate::{
    db::{EntryId, EntryRef, GroupId, GroupRef},
    Database,
};

/// Icon specification for an [Entry][crate::db::Entry] or [Group][crate::db::Group].
#[derive(Debug, Eq, PartialEq, Clone)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub enum Icon {
    /// The icon is a built-in icon specified by an index
    BuiltIn(usize),

    /// The icon is a custom icon specified by a [CustomIconId]
    Custom(CustomIconId),
}

/// A unique identifier for a [CustomIcon]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub struct CustomIconId(Uuid);

impl std::fmt::Display for CustomIconId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl CustomIconId {
    pub(crate) fn new() -> Self {
        Self(Uuid::new_v4())
    }

    /// Build a `CustomIconId` from an existing [Uuid].
    pub const fn from_uuid(uuid: Uuid) -> Self {
        Self(uuid)
    }

    /// Get the Uuid contained inside
    pub fn uuid(&self) -> Uuid {
        self.0
    }
}

/// A custom icon stored in the database, containing raw image data.
#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub struct CustomIcon {
    pub(crate) id: CustomIconId,

    pub(crate) entries: HashSet<(EntryId, Option<NaiveDateTime>)>,
    pub(crate) groups: HashSet<GroupId>,

    /// Filename for the icon
    pub name: Option<String>,

    /// Last modification timestamp
    pub last_modification_time: Option<NaiveDateTime>,

    /// The raw image data
    pub data: Vec<u8>,
}

impl CustomIcon {
    /// Get the ID of this custom icon
    pub fn id(&self) -> CustomIconId {
        self.id
    }

    /// Get entries
    pub fn get_entries(&self) -> &HashSet<(EntryId, Option<NaiveDateTime>)> {
        &self.entries
    }

    /// Get group
    pub fn get_groups(&self) -> &HashSet<GroupId> {
        &self.groups
    }
}

impl Deref for CustomIcon {
    type Target = Vec<u8>;

    fn deref(&self) -> &Self::Target {
        &self.data
    }
}

impl DerefMut for CustomIcon {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.data
    }
}

/// An immutable reference to a [CustomIcon]. Implements [Deref] to [&CustomIcon][CustomIcon]
pub struct CustomIconRef<'a> {
    database: &'a Database,
    id: CustomIconId,
}

impl CustomIconRef<'_> {
    pub(crate) fn new(database: &Database, id: CustomIconId) -> CustomIconRef<'_> {
        CustomIconRef { database, id }
    }

    /// Get an immutable reference to the database that owns this custom icon.
    pub fn database(&self) -> &Database {
        self.database
    }

    /// Get an iterator over the entries that reference this custom icon.
    ///
    /// If `include_historical` is false, only returns entries that currently reference this
    /// icon. If `include_historical` is true, also returns old versions of entries that
    /// reference this icon, even if they have been modified to no longer reference it.
    pub fn entries(&self, include_historical: bool) -> impl Iterator<Item = EntryRef<'_>> {
        self.entries.iter().filter_map(move |&(id, history_id)| {
            if !include_historical && history_id.is_some() {
                return None;
            }

            Some(EntryRef::new_historical(self.database, id, history_id))
        })
    }

    /// Get an iterator over the groups that reference this custom icon.
    pub fn groups(&self) -> impl Iterator<Item = GroupRef<'_>> {
        self.groups
            .iter()
            .map(move |&id| GroupRef::new(self.database, id))
    }
}

impl Deref for CustomIconRef<'_> {
    type Target = CustomIcon;

    #[allow(clippy::expect_used)] // CustomIconRef should only be created with valid CustomIconIds
    fn deref(&self) -> &Self::Target {
        self.database
            .custom_icons
            .get(&self.id)
            .expect("Custom icon ID always valid")
    }
}

/// A mutable reference to a [CustomIcon]. Implements [DerefMut] to [&mut CustomIcon][CustomIcon]
pub struct CustomIconMut<'a> {
    database: &'a mut Database,
    id: CustomIconId,
}

impl CustomIconMut<'_> {
    pub(crate) fn new(database: &mut Database, id: CustomIconId) -> CustomIconMut<'_> {
        CustomIconMut { database, id }
    }

    /// Get an immutable reference to this custom icon.
    pub fn as_ref(&self) -> CustomIconRef<'_> {
        CustomIconRef {
            database: self.database,
            id: self.id,
        }
    }

    /// Edit this custom icon using a closure. The closure is passed a mutable reference to this
    /// custom icon.
    pub fn edit(&mut self, f: impl FnOnce(&mut CustomIconMut<'_>)) -> &mut Self {
        f(self);
        self
    }

    /// Get a mutable reference to the database that owns this custom icon.
    pub fn database_mut(&mut self) -> &mut Database {
        self.database
    }

    /// Remove this custom icon from the database, and all references to it
    pub fn remove(&mut self) -> Result<Option<CustomIcon>, CustomIconNotAllowRemoveError> {
        if self.entries.is_empty() && self.groups.is_empty() {
            Ok(self.database.custom_icons.remove(&self.id))
        } else {
            Err(CustomIconNotAllowRemoveError(self.id))
        }
    }
}

impl Deref for CustomIconMut<'_> {
    type Target = CustomIcon;

    #[allow(clippy::expect_used)] // CustomIconMut should only be created with valid CustomIconIds
    fn deref(&self) -> &Self::Target {
        self.database
            .custom_icons
            .get(&self.id)
            .expect("Custom icon ID always valid")
    }
}

impl DerefMut for CustomIconMut<'_> {
    #[allow(clippy::expect_used)] // CustomIconMut should only be created with valid CustomIconIds
    fn deref_mut(&mut self) -> &mut Self::Target {
        self.database
            .custom_icons
            .get_mut(&self.id)
            .expect("Custom icon ID always valid")
    }
}

/// Error type for when a [CustomIconId] is provided that does not exist in the database
#[derive(Error, Debug)]
#[error("Custom icon {0} not found")]
pub struct CustomIconNotFoundError(pub(crate) CustomIconId);

/// This error type occurs when deleting an custom icon that still has references.
#[derive(Error, Debug)]
#[error("The custom icon {0} cannot be deleted because there are still entries referencing it.")]
pub struct CustomIconNotAllowRemoveError(pub(crate) CustomIconId);
