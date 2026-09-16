//! Ensure `Database::to_xml` is stable when a KDBX is opened with no edits.
//!
//! Opening the same file repeatedly (or calling `to_xml` multiple times on
//! the same in-memory database) must produce identical XML bytes. This
//! guards against non-deterministic serialization (e.g. unordered maps).

#![cfg(feature = "save_kdbx4")]
#![forbid(unsafe_code)]
#![allow(clippy::expect_used, clippy::unwrap_used)]

mod common;

use std::{fs::File, io::Read, path::Path};

use common::{baseline_combo, DEMO_PASSWORD};
use keepass::{Database, DatabaseKey};

struct Fixture {
    path: &'static str,
    password: Option<&'static str>,
    keyfile: Option<&'static str>,
}

const FIXTURES: &[Fixture] = &[
    Fixture {
        path: "tests/resources/test_db_with_password.kdbx",
        password: Some(DEMO_PASSWORD),
        keyfile: None,
    },
    Fixture {
        path: "tests/resources/test_db_kdbx4_with_password_argon2.kdbx",
        password: Some(DEMO_PASSWORD),
        keyfile: None,
    },
    Fixture {
        path: "tests/resources/test_db_kdbx4_with_password_argon2id.kdbx",
        password: Some(DEMO_PASSWORD),
        keyfile: None,
    },
    Fixture {
        path: "tests/resources/test_db_kdbx41_features.kdbx",
        password: Some(DEMO_PASSWORD),
        keyfile: None,
    },
    Fixture {
        path: "tests/resources/test_db_kdbx4_with_keyfile.kdbx",
        password: None,
        keyfile: Some("tests/resources/test_key.key"),
    },
];

fn fixture_key(fixture: &Fixture) -> DatabaseKey {
    let mut key = DatabaseKey::new();
    if let Some(password) = fixture.password {
        key = key.with_password(password);
    }
    if let Some(kf) = fixture.keyfile {
        key = key
            .with_keyfile(&mut File::open(Path::new(kf)).expect("open keyfile"))
            .expect("read keyfile");
    }
    key
}

fn open_fixture(fixture: &Fixture) -> Database {
    let mut file = File::open(Path::new(fixture.path)).unwrap_or_else(|e| panic!("open {}: {e}", fixture.path));
    Database::open(&mut file, fixture_key(fixture)).unwrap_or_else(|e| panic!("parse {}: {e:?}", fixture.path))
}

fn xml_of(db: &Database) -> Vec<u8> {
    db.to_xml().expect("to_xml")
}

#[test]
fn to_xml_is_stable_across_repeated_calls_on_same_database() {
    for fixture in FIXTURES {
        let db = open_fixture(fixture);
        let first = xml_of(&db);
        assert!(!first.is_empty(), "{}: empty xml", fixture.path);

        for i in 1..=5 {
            let again = xml_of(&db);
            assert_eq!(
                again, first,
                "{}: to_xml call {} differs from first (no mutations)",
                fixture.path, i
            );
        }
    }
}

#[test]
fn to_xml_is_stable_across_independent_opens() {
    for fixture in FIXTURES {
        let mut xmls = Vec::new();
        for _ in 0..5 {
            let db = open_fixture(fixture);
            xmls.push(xml_of(&db));
        }

        let first = &xmls[0];
        assert!(!first.is_empty(), "{}: empty xml", fixture.path);
        for (i, xml) in xmls.iter().enumerate().skip(1) {
            assert_eq!(
                xml, first,
                "{}: open #{} to_xml differs from open #0 (no mutations)",
                fixture.path, i
            );
        }
    }
}

#[test]
fn to_xml_is_stable_for_saved_rich_database_without_edits() {
    let combo = baseline_combo();
    let db = combo.rich_database();
    let bytes = common::save_to_vec(&db, combo.get_key());

    let mut xmls = Vec::new();
    for _ in 0..5 {
        let opened = Database::open(&mut bytes.as_slice(), combo.get_key()).expect("reopen");
        xmls.push(xml_of(&opened));
    }

    let first = &xmls[0];
    assert!(!first.is_empty());
    for (i, xml) in xmls.iter().enumerate().skip(1) {
        assert_eq!(
            xml, first,
            "rich fixture: open #{} to_xml differs from open #0",
            i
        );
    }
}

#[test]
fn to_xml_matches_across_fixture_bytes_reload() {
    // Same on-disk bytes reloaded via Cursor must produce identical XML.
    for fixture in FIXTURES {
        let mut raw = Vec::new();
        File::open(Path::new(fixture.path))
            .expect("open fixture")
            .read_to_end(&mut raw)
            .expect("read fixture");

        let key = fixture_key(fixture);
        let db_a = Database::open(&mut raw.as_slice(), key.clone()).expect("open a");
        let db_b = Database::open(&mut raw.as_slice(), key).expect("open b");

        assert_eq!(
            xml_of(&db_a),
            xml_of(&db_b),
            "{}: to_xml differs between two opens of identical bytes",
            fixture.path
        );
    }
}
