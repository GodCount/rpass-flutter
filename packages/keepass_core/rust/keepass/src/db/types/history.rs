use chrono::NaiveDateTime;

use crate::{db::Entry, Database};

/// An entry's history
#[derive(Debug, Default, Eq, PartialEq, Clone)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub struct History {
    entries: Vec<Entry>,
}

impl History {
    /// new history
    pub fn new() -> Self {
        History { entries: Vec::new() }
    }

    /// new history from entries
    pub fn from(entries: Vec<Entry>) -> Self {
        History { entries }
    }

    /// Add a new entry to the history
    pub fn add_entry(&mut self, mut entry: Entry) {
        // DISCUSS: should we make sure that the last modification time is not the same
        // or older than the entry at the top of the history?

        // Remove the history from the new history entry to avoid having
        // an exponential number of history entries.
        entry.history.take();

        self.entries.insert(0, entry);
    }

    /// Get history entry by last modification
    pub fn get_entry(&self, id: NaiveDateTime) -> Option<&Entry> {
        self.entries
            .iter()
            .find(|item| item.times.last_modification == Some(id))
    }

    /// Get the history entries
    pub fn get_entries(&self) -> &Vec<Entry> {
        &self.entries
    }

    /// Truncate history entries length
    pub(crate) fn truncate(&mut self, len: usize) {
        self.entries.truncate(len);
    }

    pub(crate) fn calculate_sizes(&self, db: &Database) -> Vec<usize> {
        self.entries
            .iter()
            .map(|item| item.calculate_size(db))
            .collect::<Vec<usize>>()
    }
}
