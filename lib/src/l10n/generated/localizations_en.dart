// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class MyLocalizationsEn extends MyLocalizations {
  MyLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get locale_name => 'English';

  @override
  String get app_name => 'Rpass';

  @override
  String get init_main_password => 'Initialize main password';

  @override
  String get at_least_4digits => 'At least 4 digits';

  @override
  String get confirm_password => 'Confirm password';

  @override
  String get password_not_equal => 'Passwords do not match!';

  @override
  String get init => 'Initialize';

  @override
  String get question => 'Question';

  @override
  String get answer => 'Answer';

  @override
  String get cannot_emprty => 'Cannot be empty!';

  @override
  String get prev => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get add => 'Add';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get input_security_qa_hint =>
      'Answer security question to decrypt data!';

  @override
  String get security_qa_error => 'That\'s not right, think again!';

  @override
  String get verify_password => 'Verify password';

  @override
  String get forget_password => 'Forgot password';

  @override
  String get password => 'Password';

  @override
  String get none_password => 'None Password';

  @override
  String get setting => 'Settings';

  @override
  String search_match_count(int matchCount, int totalCount) {
    return 'Search: $matchCount/$totalCount';
  }

  @override
  String get account_ab => 'A.';

  @override
  String get email_ab => 'E.';

  @override
  String get label_ab => 'L.';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get security => 'Security';

  @override
  String get modify_password => 'Modify Password';

  @override
  String get backup => 'Backup';

  @override
  String get import => 'Import';

  @override
  String get export => 'Export';

  @override
  String get info => 'Information';

  @override
  String get about => 'About';

  @override
  String get cancel => 'Cancel';

  @override
  String get modify => 'Modify';

  @override
  String get edit_account => 'Edit Account';

  @override
  String get clone => 'Clone';

  @override
  String get domain => 'Domain';

  @override
  String format_error(String pattern) {
    return 'Format error, should match: $pattern';
  }

  @override
  String get title => 'Title';

  @override
  String get account => 'Account';

  @override
  String get email => 'Email';

  @override
  String get otp => 'One-Time Password (OTP)';

  @override
  String get label => 'Label';

  @override
  String get date => 'Date';

  @override
  String get uuid => 'ID';

  @override
  String get refresh => 'Refresh';

  @override
  String get symbol => 'Symbol';

  @override
  String get remark => 'Remark';

  @override
  String get save => 'Save';

  @override
  String get copy => 'Copy';

  @override
  String get copy_done => 'Copy Completed';

  @override
  String get lookup => 'View';

  @override
  String get source => 'Source';

  @override
  String get delete => 'Delete';

  @override
  String get delete_warn_hit =>
      'Are you sure you want to delete? It cannot be recovered after deletion.';

  @override
  String get description => 'Description';

  @override
  String get language_setting => 'Language Setting';

  @override
  String export_done_location(String location) {
    return 'Export completed, location: $location';
  }

  @override
  String get import_done => 'Import Completed';

  @override
  String get scan_code => 'Scan Code';

  @override
  String get new_label => 'New Label';

  @override
  String get cannot_all_empty => 'Cannot be all for empty!';

  @override
  String get empty => 'Empty';

  @override
  String get chrome => 'Chrome';

  @override
  String get firefox => 'Firefox';

  @override
  String get other => 'Other';

  @override
  String get app_description =>
      'Rpass is a free and open-source application that allows you to conveniently and concisely record password information';

  @override
  String source_code_location(String location) {
    return 'Source Code ($location)';
  }

  @override
  String get biometric => 'Biometric';

  @override
  String get biometric_prompt_title => 'Verify your identity!';

  @override
  String get biometric_prompt_subtitle =>
      'Use fingerprint to complete verification before continuing.';

  @override
  String throw_message(String message) {
    return 'exception: $message';
  }

  @override
  String get common => 'Common';

  @override
  String get default_ => 'Default';

  @override
  String get pass_lib => 'Password Library';

  @override
  String get pass_lib_setting => 'Password Library Settings';

  @override
  String get history_record => 'History Record';

  @override
  String get max_count => 'Maximum Count';

  @override
  String get max_size => 'Maximum Size';

  @override
  String get is_move_recycle => 'Move items to the Recycle Bin?';

  @override
  String get man_selected_pass => 'Manage Selected Passwords';

  @override
  String get move => 'Move';

  @override
  String get man_group_pass => 'Manage Group Passwords';

  @override
  String get empty_group => 'The group is empty!';

  @override
  String get rename => 'Rename';

  @override
  String get new_field => 'New Field';

  @override
  String get look_notes => 'View Notes';

  @override
  String get edit_notes => 'Edit Notes';

  @override
  String get gen_password => 'Password Generator';

  @override
  String get pass_length => 'Password Length';

  @override
  String get include_cahr => 'Include Characters';

  @override
  String export_n_file(String name) {
    return 'Export $name file';
  }

  @override
  String import_n_file(String name) {
    return 'Import $name file';
  }

  @override
  String get select_group => 'Select Group';

  @override
  String get group => 'Group';

  @override
  String get data_migrate_done => 'Data Migration Complete.';

  @override
  String get custom_field => 'Custom Field';

  @override
  String get search_rule => 'Search Rule:';

  @override
  String get rule_detail => '[Field Name:][\"]Key Phrase[\"]';

  @override
  String get field_name => 'Field Name:';

  @override
  String get search_eg => 'Example:';

  @override
  String get search_eg_1 => 'u:Xiaoming note:\"Visited here, XiaoMing\"';

  @override
  String get search_eg_2 => 'g:Email u:Xiaoming';

  @override
  String get recycle_bin => 'Recycle Bin';

  @override
  String get completely_delete => 'Completely Delete';

  @override
  String get delete_no_revert => 'Deleting items will be irreversible!';

  @override
  String get revert => 'Revert';

  @override
  String get select_icon => 'Select Icon';

  @override
  String get add_field => 'Add Field';

  @override
  String get letter => 'Letter';

  @override
  String get number => 'Number';

  @override
  String get special_char => 'Special Character';

  @override
  String get not_found_entry => 'No entries found!';

  @override
  String get attachment => 'Attachment';

  @override
  String get create => 'Create';

  @override
  String get last_modify => 'Last Modified';

  @override
  String get warn => 'Warning';

  @override
  String get plaintext_export_warn =>
      'Confirm to export data in plain text?\nNote that the exported data will only contain the corresponding key fields.';

  @override
  String get manage => 'Manage';

  @override
  String get timeline => 'Timeline';

  @override
  String get not_history_record => 'No history records!';

  @override
  String get password_error => 'Password Error!';

  @override
  String get data_migrate_hint =>
      'Data migration and upgrade is currently underway. After decrypting the data, it will be entirely migrated to a new database (kdbx) for storage. This new system offers improved performance, greater stability, enhanced security, and a wider range of features.';

  @override
  String get search => 'Search';

  @override
  String all_select(int matchCount, int totalCount) {
    return 'Select ALL ($matchCount / $totalCount)';
  }

  @override
  String get invert_select => 'Select Invert';

  @override
  String get more_settings => 'More Settings';

  @override
  String get lock => 'Lock';

  @override
  String get lock_subtitle =>
      'The program will lock itself after a period of time when running in the background or losing focus (desktop).';

  @override
  String get never => 'Never';

  @override
  String seconds(int sec) {
    return '$sec seconds';
  }

  @override
  String minutes(int min) {
    return '$min minutes';
  }

  @override
  String get expires_time => 'Expires Time';

  @override
  String get expires => 'Expires';

  @override
  String get key_file => 'Key File';

  @override
  String get record_key_file_path => 'Record Key File Path';

  @override
  String get lack_key_file => 'Lack of key file';

  @override
  String get move_selected => 'Move Selected';

  @override
  String get delete_selected => 'Delete Selected';

  @override
  String get revert_selected => 'Revert Selected';

  @override
  String get completely_delete_selected => 'Completely Delete Selected';

  @override
  String get rename_field => 'Rename Field';

  @override
  String get delete_field => 'Delete Field';

  @override
  String get more => 'More';

  @override
  String get local_import => 'Local Import';

  @override
  String get sync => 'Sync';

  @override
  String get sync_settings => 'Sync Settings';

  @override
  String from_import(String name) {
    return 'Import from $name';
  }

  @override
  String get save_as => 'Save As';

  @override
  String get selected_sync_account_subtitle => 'Select account from database';

  @override
  String get save_sync_account_subtitle => 'Save login info to database';

  @override
  String get logined_sync => 'Sync data after login';

  @override
  String get import_remote_kdbx => 'Import remote database';

  @override
  String get close_local_sync_subtitle => 'Disable sync on this device';

  @override
  String get sync_note_subtitle =>
      'If the remote file is modified by a third-party kdbx manager, long-press the sync button to force a merge.';

  @override
  String get sync_error_log => 'Sync Error Log';

  @override
  String get sync_merge_log => 'Sync Merge Log';

  @override
  String get change => 'Change';

  @override
  String get remove => 'Remove';

  @override
  String get select_account => 'Select Account';

  @override
  String get custom => 'Customize';

  @override
  String get display => 'Display';

  @override
  String get enable_display_true_subtitle => 'Included in the home page list';

  @override
  String get enable_display_false_subtitle =>
      'Excluded from the home page list';

  @override
  String get enable_display_null_subtitle => 'Inherit display settings';

  @override
  String get enable_searching_true_subtitle => 'Included in search';

  @override
  String get enable_searching_false_subtitle => 'Excluded from search';

  @override
  String get enable_searching_null_subtitle => 'Inherit search settings';

  @override
  String get edit_auto_fill_sequence => 'Edit Auto Fill Sequence';

  @override
  String get default_field => 'Default Field';

  @override
  String get auto_fill => 'Auto Fill';

  @override
  String get keyboard_key => 'Keyboard Key';

  @override
  String get fill_sequence => 'Fill Sequence';

  @override
  String get sync_cycle => 'Synchronous Cycle';

  @override
  String get each_startup => 'Each Startup';

  @override
  String days(int day) {
    String _temp0 = intl.Intl.pluralLogic(
      day,
      locale: localeName,
      other: '$day Days',
      one: '1 Day',
    );
    return '$_temp0';
  }

  @override
  String get auto_fill_specified_field => 'Auto-fill Specified Field';

  @override
  String get copy_specified_field => 'Copy Specified Field';

  @override
  String get show_system_apps => 'Show System Apps';

  @override
  String get hide_system_apps => 'Hide System Apps';

  @override
  String get none => 'None';

  @override
  String get auto_fill_apps_none_subtitle =>
      'Will be matched according to the domain name';

  @override
  String get enable_auto_fill_service => 'Enable Auto-fill Service';

  @override
  String get manual_select_fill_item => 'Manually Select Fill Item';

  @override
  String get manual_select_fill_item_subtitle =>
      'When the auto-matched fill dataset returns empty';

  @override
  String get auto_fill_match_app => 'Auto-fill Application';

  @override
  String get start_focus_sreach => 'Focus on the search box on startup';

  @override
  String get show_favicon => 'Display the favicon';

  @override
  String get show_favicon_sub =>
      'When enabled, it will attempt to request the website icon from the specified source service and replace it with the new icon; custom icons will not be replaced.';

  @override
  String get all => 'All';

  @override
  String get direct_download => 'Direct Dwnload';

  @override
  String get select_source_refresh => 'Select the Source refresh icon';

  @override
  String get clear_favicon_cache => 'Clear Favicon Cache';
}
