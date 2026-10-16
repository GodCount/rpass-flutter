use crate::{Database, db::Entry};

/// An entry's history
#[derive(Debug, Default, Eq, PartialEq, Clone)]
#[cfg_attr(feature = "serialization", derive(serde::Serialize))]
pub struct History {
    // 用来做历史记录的唯一ID
    // 使用下标做ID时, 当记录有增删时在附件和自定义图标的反向引用中会出错
    // 使用 NaiveDateTime 做ID时, 不稳定,会有相同的 NaiveDateTime 但内容不同(在合并出现这种情况)
    auto_increment_num: u32,
    entries: Vec<(u32, Entry)>,
}

impl History {
    /// new history
    pub fn new() -> Self {
        History {
            auto_increment_num: 0,
            entries: Vec::new(),
        }
    }

    /// new history from entries
    pub fn from(entries: Vec<Entry>) -> Self {
        let len = entries.len();

        History {
            auto_increment_num: len as u32,
            entries: entries
                .into_iter()
                .enumerate()
                // 让ID顺序和add_entry时一致
                .map(|(index, item)| ((len - index - 1) as u32, item))
                .collect(),
        }
    }

    pub(crate) fn next_id(&self) -> u32 {
        self.auto_increment_num
    }

    /// Add a new entry to the history
    pub fn add_entry(&mut self, mut entry: Entry) {
        // Remove the history from the new history entry to avoid having
        // an exponential number of history entries.
        entry.history.take();
        self.entries.insert(0, (self.auto_increment_num, entry));
        self.auto_increment_num += 1;
    }

    /// Get history entry by auto increment
    pub fn get_entry(&self, id: u32) -> Option<&Entry> {
        for (id1, entry) in &self.entries {
            if *id1 == id {
                return Some(entry);
            }
        }
        None
    }

   #[allow(dead_code)]
    pub(crate) fn get_entry_index(&self, index: usize) -> Option<&Entry> {
        self.entries.get(index).map(|(_, item)| item)
    }

    /// Get the history entries
    pub fn get_entries(&self) -> &Vec<(u32, Entry)> {
        &self.entries
    }

    /// Truncate history entries length
    pub(crate) fn truncate(&mut self, len: usize) -> Vec<(u32, Entry)> {
        if len < self.entries.len() {
            self.entries.drain(len..).collect()
        } else {
            vec![]
        }
    }

    pub(crate) fn calculate_sizes(&self, db: &Database) -> Vec<usize> {
        self.entries
            .iter()
            .map(|(_, item)| item.calculate_size(db))
            .collect::<Vec<usize>>()
    }
}
