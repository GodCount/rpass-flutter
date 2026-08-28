//! Tests for the Entry API

#[allow(missing_docs, clippy::expect_used, clippy::unwrap_used)]
mod entry_tests {
    use keepass::{
        db::{DatabaseOpenError, Value},
        Database, DatabaseKey,
    };
    use std::{collections::HashSet, fs::File, path::Path};
    use uuid::uuid;

    #[test]
    fn kdbx3_entry() -> Result<(), DatabaseOpenError> {
        let path = Path::new("tests/resources/test_db_with_password.kdbx");
        let db = Database::open(
            &mut File::open(path)?,
            DatabaseKey::new().with_password("demopass"),
        )?;

        let root = db.root();

        // get an entry on the root node
        let e = root.entry_by_name("Sample Entry").expect("Expected an entry");

        assert_eq!(e.id().uuid(), uuid!("0ebeddb2-ed4e-5144-bc34-1a309266a513"));
        assert_eq!(e.get_title(), Some("Sample Entry"));
        assert_eq!(e.get_username(), Some("User Name"));
        assert_eq!(e.get_password(), Some("Password"));
        assert_eq!(e.get_url(), Some("http://keepass.info/"));
        assert_eq!(e.get("custom attribute"), Some("data for custom attribute"));
        assert_eq!(e.get("URL"), Some("http://keepass.info/"));
        assert_eq!(e.times.expires, Some(false));

        let et = chrono::NaiveDateTime::parse_from_str("2016-01-06 09:43:01", "%Y-%m-%d %H:%M:%S").unwrap();
        assert_eq!(e.times.expiry.as_ref(), Some(&et));

        if let Some(ref at) = e.autotype {
            if let Some(ref s) = at.default_sequence {
                assert_eq!(s, "{USERNAME}{TAB}{TAB}{PASSWORD}{ENTER}");
            } else {
                panic!("Expected a sequence")
            }
        } else {
            panic!("Expected an AutoType entry");
        }

        // get an entry in a subgroup
        let sg = root
            .group_by_path(&["General", "Subgroup"])
            .expect("Expected a subgroup");

        let e = sg.entry_by_name("test entry").expect("Expected an entry");

        assert_eq!(e.id().uuid(), uuid!("5e4c8ad1-9cd5-394c-9039-1178dc140b4a"));
        assert_eq!(e.get_title(), Some("test entry"));
        assert_eq!(e.get_username(), Some("jdoe"));
        assert_eq!(e.get_password(), Some("nWuu5AtqsxqNhnYgLwoB"));
        assert_eq!(e.get_url(), Some(""));
        assert_eq!(e.times.expires, Some(false));

        if let Some(t) = e.times.expiry {
            assert_eq!(format!("{}", t), "2016-01-28 12:25:36");
        } else {
            panic!("Expected an ExpiryTime");
        }

        Ok(())
    }

    #[test]
    fn kdbx4_entry() -> Result<(), DatabaseOpenError> {
        // KDBX4 database format Base64 encodes ExpiryTime (and all other XML timestamps)
        let path = Path::new("tests/resources/test_db_kdbx4_with_password_aes.kdbx");
        let db = Database::open(
            &mut File::open(path)?,
            DatabaseKey::new().with_password("demopass"),
        )?;

        let root = db.root();

        // get an entry on the root node
        let e = root.entry_by_name("ASDF").expect("Expected an entry");
        assert_eq!(e.id().uuid(), uuid!("4f3816bd83304865879fa108a12f285c"));
        assert_eq!(e.get_title(), Some("ASDF"));
        assert_eq!(e.get_username(), Some("ghj"));
        assert_eq!(e.get_password(), Some("klmno"));
        assert_eq!(e.get_url(), Some("https://example.com"));
        assert_eq!(e.tags, vec!["keepass-rs".to_string(), "test".to_string()]);
        assert_eq!(e.times.expires, Some(true));

        if let Some(t) = e.times.expiry {
            assert_eq!(format!("{}", t), "2021-04-10 16:53:18");
        } else {
            panic!("Expected an ExpiryTime");
        }

        Ok(())
    }

    #[test]
    fn kdbx3_with_chacha20_protected_fields() -> Result<(), DatabaseOpenError> {
        let path = Path::new("tests/resources/test_db_kdbx3_with_chacha20_protected_fields.kdbx");
        let db = Database::open(
            &mut File::open(path)?,
            DatabaseKey::new().with_password("password"),
        )?;

        for e in db.iter_all_entries() {
            assert_eq!(Some("admin"), e.get_password());
        }

        Ok(())
    }

    #[test]
    fn kdbx4_entry_bad_password() -> Result<(), DatabaseOpenError> {
        let path = Path::new("tests/resources/test_db_kdbx4_with_password_aes.kdbx");
        let db = Database::open(
            &mut File::open(path)?,
            DatabaseKey::new().with_password("this password is not correct"),
        );

        assert!(db.is_err());

        Ok(())
    }

    #[test]
    fn back_reference_custom_icon() {
        let mut db = Database::new();
        let (entry_id, icon_id) = {
            let mut root = db.root_mut();
            let mut entry = root.add_entry();
            let mut entry = entry.track_changes();
            let id = entry.id();
            let icon = entry.set_icon_custom_new(vec![1, 0, 0, 8, 6]);
            (id, icon.id())
        };
        let icon = db.custom_icon(icon_id).unwrap();
        assert_eq!(icon.get_entries(), &HashSet::from([(entry_id, None)]));

        let last_modification = {
            let mut entry = db.entry_mut(entry_id).unwrap();
            let mut entry = entry.track_changes();
            let time = entry.times.last_modification;
            entry.set_icon_none();
            time
        };

        let icon = db.custom_icon(icon_id).unwrap();
        assert_eq!(
            icon.get_entries(),
            &HashSet::from([(entry_id, Some(last_modification.unwrap()))])
        );
    }

    #[test]
    fn back_reference_attachment() {
        let mut db = Database::new();
        let (entry_id, attach_id) = {
            let mut root = db.root_mut();
            let mut entry = root.add_entry();
            let mut entry = entry.track_changes();
            let id = entry.id();
            let attach = entry.add_attachment("aa", Value::unprotected(vec![1, 0, 0, 8, 6]));
            (id, attach.id())
        };
        let attach = db.attachment_mut(attach_id).unwrap();
        assert_eq!(attach.get_entries(), &HashSet::from([(entry_id, None)]));

        let last_modification = {
            let mut entry = db.entry_mut(entry_id).unwrap();
            let mut entry = entry.track_changes();
            let time = entry.times.last_modification;
            entry.edit(|entry| {
                entry.as_mut().remove_attachment_by_name("aa");
            });
            time
        };

        let attach = db.attachment_mut(attach_id).unwrap();
        assert_eq!(
            attach.get_entries(),
            &HashSet::from([(entry_id, Some(last_modification.unwrap()))])
        );
    }
}
