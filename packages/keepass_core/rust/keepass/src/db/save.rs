use thiserror::Error;

use crate::{DatabaseKey, config::{DatabaseVersion, InnerCipherConfig}, db::Database, format::xml_db::to_xml};

impl Database {
    /// Saves the database to the given destination, using the provided key for encryption.
    pub fn save(
        &self,
        destination: &mut dyn std::io::Write,
        key: DatabaseKey,
    ) -> Result<(), DatabaseSaveError> {
        use crate::format::kdbx4::dump_kdbx4;

        match self.config.version {
            DatabaseVersion::KDB(_) => Err(DatabaseSaveError::UnsupportedVersion),
            DatabaseVersion::KDB2(_) => Err(DatabaseSaveError::UnsupportedVersion),
            DatabaseVersion::KDB3(_) => Err(DatabaseSaveError::UnsupportedVersion),
            DatabaseVersion::KDB4(_) => dump_kdbx4(self, &key, destination),
        }
    }

    /// database to plain xml
    pub fn to_xml(&self) -> Result<Vec<u8>, DatabaseSaveError> {
        let mut cipher = InnerCipherConfig::Plain.get_cipher(&vec![])?;
        let (xml, ..) = to_xml(self, &mut *cipher)?;
        Ok(xml)
    }
}

/// Errors that can occur during saving of the database to a KDBX file
#[derive(Debug, Error)]
#[non_exhaustive]
pub enum DatabaseSaveError {
    /// I/O errors that can occur while writing the database to the destination, such as file system errors
    #[error(transparent)]
    Io(#[from] std::io::Error),

    /// Errors related to XML serialization of the database
    #[error(transparent)]
    Serialization(#[from] quick_xml::SeError),

    /// Errors related to database key operations
    #[error(transparent)]
    Key(#[from] crate::key::DatabaseKeyError),

    /// Errors related to encryption operations
    #[error(transparent)]
    Cryptography(#[from] crate::crypt::CryptographyError),

    /// Errors related to random number generation
    #[error(transparent)]
    Random(#[from] getrandom::Error),

    /// Attempted to save a database with an unsupported version (e.g., KDB, KDBX2, or KDBX3)
    #[error("Unsupported database version")]
    UnsupportedVersion,
}
