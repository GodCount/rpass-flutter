use std::{convert::TryInto, io::Read};

use base64::{engine::general_purpose as base64_engine, Engine as _};
use hex::FromHexError;
use hybrid_array::{typenum::U32, Array as GenericArray};
use quick_xml::{
    de::{from_str, Deserializer},
    se::to_string,
};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use zeroize::{Zeroize, ZeroizeOnDrop};

use crate::crypt::calculate_sha256;

pub type KeyElement = Vec<u8>;
pub type KeyElements = Vec<KeyElement>;

#[cfg(feature = "challenge_response")]
mod yubikey;

#[cfg(feature = "challenge_response")]
pub use yubikey::{ChallengeResponseKey, ChallengeResponseKeyError};


/// A KeePass keyfile
#[derive(Debug, PartialEq, Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
pub struct KeyFile {
    #[serde(rename = "Meta")]
    meta: Meta,
    #[serde(rename = "Key")]
    key: Key,
}

#[derive(Debug, PartialEq, Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
struct Meta {
    #[serde(rename = "Version")]
    version: String,
}

#[derive(Debug, PartialEq, Serialize, Deserialize, Zeroize, ZeroizeOnDrop)]
struct Key {
    #[serde(rename = "@Hash", skip_serializing_if = "Option::is_none")]
    hash: Option<String>,
    #[serde(rename = "Data")]
    data: String,
}

impl KeyFile {
    /// Parse keyfile from string slice
    pub fn parse<T: AsRef<str>>(value: T) -> Result<Self, KeyFileError> {
        let keyfile: KeyFile = from_str(value.as_ref())?;
        return Ok(keyfile);
    }

    /// Parse keyfile from bytes
    pub fn parse_bytes<T: AsRef<[u8]>>(value: T) -> Result<Self, KeyFileError> {
        let mut de = Deserializer::from_reader(value.as_ref());
        let keyfile: KeyFile = KeyFile::deserialize(&mut de)?;
        return Ok(keyfile);
    }

    /// Create random keyfile
    pub fn random() -> Result<Self, getrandom::Error> {
        let mut bytes = vec![0u8; 32];

        getrandom::fill(&mut bytes)?;

        let hash = hex::encode_upper(&calculate_sha256(&[&bytes])[..4]);

        let data = hex::encode_upper(&bytes)
            .chars()
            .collect::<Vec<_>>()
            .chunks(32)
            .map(|line| {
                line.chunks(8)
                    .map(|group| group.iter().collect::<String>())
                    .collect::<Vec<_>>()
                    .join(" ")
            })
            .collect::<Vec<_>>()
            .join("\n");

        Ok(KeyFile {
            meta: Meta {
                version: String::from("2.0"),
            },
            key: Key {
                hash: Some(hash),
                data,
            },
        })
    }

    /// Get key
    pub fn get_data(&self) -> Result<Vec<u8>, KeyFileError> {
        match self.meta.version.as_str() {
            "2.0" => {
                let data = self
                    .key
                    .data
                    .trim()
                    .replace(" ", "")
                    .replace("\n", "")
                    .replace("\t", "")
                    .replace("\r", "")
                    .as_bytes()
                    .to_vec();

                let bytes = hex::decode(&data)?;

                if let Some(hash) = &self.key.hash {
                    let expect_hash = hash.clone();
                    let current_hash = hex::encode_upper(&calculate_sha256(&[&bytes])[..4]);
                    if current_hash != expect_hash {
                        return Err(KeyFileError::HashMismatch(expect_hash, current_hash));
                    }
                }

                Ok(bytes)
            }
            "1.00" => {
                let bytes = self.key.data.as_bytes().to_vec();
                if let Ok(data) = base64_engine::STANDARD.decode(&bytes) {
                    Ok(data)
                } else {
                    Ok(bytes)
                }
            }
            _ => Err(KeyFileError::Unsupport(self.meta.version.clone())),
        }
    }

    /// to xml
    pub fn to_xml(&self) -> Result<String, quick_xml::SeError> {
        to_string(&self)
    }
}

/// Errors that can occur when parsing an XML keyfile
#[derive(Debug, Error)]
pub enum KeyFileError {
    /// base16 decoding error
    #[error(transparent)]
    FromHexError(#[from] FromHexError),
    /// keyfile version is unsupport
    #[error("unsupport version: {0}")]
    Unsupport(String),
    /// key hash mismatch
    #[error("hash mismatch: expect: {0}, actual: {1}")]
    HashMismatch(String, String),
    /// An error occurred while parsing the XML keyfile
    #[error(transparent)]
    XmlDeError(#[from] quick_xml::DeError),
}

fn parse_xml_keyfile(data: &[u8]) -> Result<Vec<u8>, KeyFileError> {
    let keyfile = KeyFile::parse_bytes(data)?;

    keyfile.get_data()
}

pub fn parse_keyfile(data: &[u8]) -> Result<Vec<u8>, DatabaseKeyError> {
    if let Ok(result) = parse_xml_keyfile(data) {
        return Ok(result);
    }

    if data.len() == 64 {
        if let Ok(result) = hex::decode(data) {
            return Ok(result);
        }
    }

    if data.len() == 32 {
        return Ok(data.to_vec());
    }

    Ok(calculate_sha256(&[data]).as_slice().to_vec())
}

/// A KeePass key, which might consist of a password and/or a keyfile
#[derive(Debug, Clone, Default, PartialEq, Zeroize, ZeroizeOnDrop)]
pub struct DatabaseKey {
    password: Option<String>,
    keyfile: Option<Vec<u8>>,
    composite_key: Option<Vec<u8>>,
    #[cfg(feature = "challenge_response")]
    challenge_response_key: Option<ChallengeResponseKey>,
    #[cfg(feature = "challenge_response")]
    challenge_response_result: Option<KeyElement>,
}

impl DatabaseKey {
    /// Create database key from composite_key
    pub fn form_composite_key(key: Vec<u8>) -> Result<Self, DatabaseKeyError> {
        if key.len() != 32 {
            return Err(DatabaseKeyError::IncorrectKey);
        }

        let mut db_key = Self::new();
        db_key.composite_key = Some(key);
        Ok(db_key)
    }

    /// Modify the database key to include a password
    pub fn with_password(mut self, password: &str) -> Self {
        self.password = Some(password.to_string());
        self
    }

    /// Modify the database key to include a password, which is read from a prompt
    #[cfg(feature = "utilities")]
    pub fn with_password_from_prompt(mut self, prompt_message: &str) -> Result<Self, std::io::Error> {
        self.password = Some(rpassword::prompt_password(prompt_message)?);
        Ok(self)
    }

    /// Modify the database key to include a challenge-response key, where the secret is read from
    /// a prompt
    #[cfg(all(feature = "challenge_response", feature = "utilities"))]
    pub fn with_hmac_sha1_secret_from_prompt(mut self, prompt_message: &str) -> Result<Self, std::io::Error> {
        self.challenge_response_key = Some(ChallengeResponseKey::LocalChallenge(rpassword::prompt_password(
            prompt_message,
        )?));
        Ok(self)
    }

    /// Modify the database key to include a keyfile
    ///
    /// The keyfile is only read as raw data but not parsed until the actual key elements are
    /// requested, so errors with keyfile parsing will only be raised at that point, not when
    /// calling this method.
    pub fn with_keyfile(mut self, keyfile: &mut dyn Read) -> Result<Self, std::io::Error> {
        let mut buf = Vec::new();
        keyfile.read_to_end(&mut buf)?;

        self.keyfile = Some(buf);

        Ok(self)
    }

    /// Modify the database key to include a challenge-response key
    #[cfg(feature = "challenge_response")]
    pub fn with_challenge_response_key(mut self, challenge_response_key: ChallengeResponseKey) -> Self {
        self.challenge_response_key = Some(challenge_response_key);
        self
    }

    /// Perform the challenge-response operation for the database key, if a challenge-response key
    /// is present.
    #[cfg(feature = "challenge_response")]
    pub fn perform_challenge(mut self, kdf_seed: &[u8]) -> Result<Self, DatabaseKeyError> {
        if let Some(challenge_response_key) = &self.challenge_response_key {
            let response = challenge_response_key.perform_challenge(kdf_seed)?;
            self.challenge_response_result = Some(response);
        }

        Ok(self)
    }

    /// Create a new, empty database key
    pub fn new() -> Self {
        Default::default()
    }

    fn get_key_elements(&self) -> Result<KeyElements, DatabaseKeyError> {
        let mut out = Vec::new();

        if let Some(p) = &self.password {
            out.push(calculate_sha256(&[p.as_bytes()]).to_vec());
        }

        if let Some(ref f) = self.keyfile {
            out.push(parse_keyfile(f)?);
        }

        if out.is_empty() {
            return Err(DatabaseKeyError::EmptyKey);
        }

        #[cfg(feature = "challenge_response")]
        if let Some(result) = &self.challenge_response_result {
            out.push(calculate_sha256(&[result]).as_slice().to_vec());
        } else if self.challenge_response_key.is_some() {
            return Err(DatabaseKeyError::ChallengeResponse(
                crate::key::yubikey::ChallengeResponseKeyError::NotPerformed,
            ));
        }

        Ok(out)
    }

    /// Returns composite key
    pub fn get_composite_key(&self) -> Result<GenericArray<u8, U32>, DatabaseKeyError> {
        if let Some(key) = &self.composite_key {
            return Ok(key
                .as_slice()
                .try_into()
                .map_err(|_| DatabaseKeyError::IncorrectKey)?);
        }

        let key_elements = self.get_key_elements()?;
        let key_elements: Vec<&[u8]> = key_elements.iter().map(|v| &v[..]).collect();
        let composite_key = calculate_sha256(&key_elements);

        Ok(composite_key)
    }

    /// Returns true if the database key is not associated with any key component.
    pub fn is_empty(&self) -> bool {
        if self.composite_key.is_some() {
            return false;
        }

        if self.password.is_some() || self.keyfile.is_some() {
            return false;
        }

        #[cfg(feature = "challenge_response")]
        if self.challenge_response_key.is_some() {
            return false;
        }
        true
    }
}

/// Errors that can occur when working with database keys
#[derive(Debug, Error)]
#[non_exhaustive]
pub enum DatabaseKeyError {
    /// The database key contains no components, i.e. no password, keyfile or challenge-response key
    #[error("The key contains no components")]
    EmptyKey,

    /// The database key is incorrect
    #[error("Incorrect key")]
    IncorrectKey,

    /// An I/O error occurred while reading the keyfile
    #[error("I/O error reading keyfile: {0}")]
    Io(#[from] std::io::Error),

    /// An error occurred while parsing the XML keyfile
    #[error("XML error reading keyfile: {0}")]
    Xml(#[from] quick_xml::Error),

    /// An error occurred while parsing the non-XML keyfile
    #[error("Invalid keyfile format")]
    InvalidKeyFile,

    /// An error occurred during challenge-response authentication
    #[cfg(feature = "challenge_response")]
    #[error("Challenge-response key error: {0}")]
    ChallengeResponse(#[from] crate::key::yubikey::ChallengeResponseKeyError),
}

#[cfg(test)]
mod key_tests {

    use super::{KeyFile, DatabaseKey, DatabaseKeyError};

    #[test]
    fn test_key() -> Result<(), DatabaseKeyError> {
        let ke = DatabaseKey::new().with_password("asdf").get_key_elements()?;
        assert_eq!(ke.len(), 1);

        let ke = DatabaseKey::new()
            .with_keyfile(&mut "bare-key-file".as_bytes())?
            .get_key_elements()?;
        assert_eq!(ke.len(), 1);

        let ke = DatabaseKey::new()
            .with_keyfile(&mut "0123456789ABCDEF0123456789ABCDEF".as_bytes())?
            .get_key_elements()?;
        assert_eq!(ke.len(), 1);

        let ke = DatabaseKey::new()
            .with_password("asdf")
            .with_keyfile(&mut "bare-key-file".as_bytes())?
            .get_key_elements()?;
        assert_eq!(ke.len(), 2);

        let ke = DatabaseKey::new()
            .with_keyfile(
                &mut "<KeyFile><Key><Data>0!23456789ABCDEF0123456789ABCDEF</Data></Key></KeyFile>".as_bytes(),
            )?
            .get_key_elements()?;
        assert_eq!(ke.len(), 1);

        let ke = DatabaseKey::new()
            .with_keyfile(
                &mut "<KeyFile><Key><Data>NXyYiJMHg3ls+eBmjbAjWec9lcOToJiofbhNiFMTJMw=</Data></Key></KeyFile>"
                    .as_bytes(),
            )?
            .get_key_elements()?;
        assert_eq!(ke.len(), 1);

        let xml_keyfile_v2 = r###"
            <?xml version="1.0" encoding="utf-8"?>
            <KeyFile>
                <Meta>
                    <Version>2.0</Version>
                </Meta>
                <Key>
                    <Data Hash="A65F0C2D">
                        36057B1C 35037FD9 62257893 C0A22403
                        EE3F8FBB 504D9981 08B821CB 00D28F89
                    </Data>
                </Key>
            </KeyFile>
        "###;
        let ke = DatabaseKey::new()
            .with_keyfile(&mut xml_keyfile_v2.trim().as_bytes())?
            .get_key_elements()?;
        assert_eq!(ke.len(), 1);

        // other XML files will just be hashed as a "bare" keyfile
        let ke = DatabaseKey::new()
            .with_keyfile(&mut "<Not><A><KeyFile></KeyFile></A></Not>".as_bytes())?
            .get_key_elements()?;

        assert_eq!(ke.len(), 1);

        assert!(DatabaseKey {
            password: None,
            keyfile: None,
            composite_key: None,
            #[cfg(feature = "challenge_response")]
            challenge_response_key: None,
            #[cfg(feature = "challenge_response")]
            challenge_response_result: None,
        }
        .get_key_elements()
        .is_err());

        Ok(())
    }

    #[test]
    fn keyfile_random() {
        let keyfile1 = KeyFile::random().unwrap();
        let keyfile2 = KeyFile::random().unwrap();


        assert_ne!(keyfile1.key, keyfile2.key);
    }
}
