import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'localizations_en.dart';
import 'localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of MyLocalizations
/// returned by `MyLocalizations.of(context)`.
///
/// Applications need to include `MyLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: MyLocalizations.localizationsDelegates,
///   supportedLocales: MyLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the MyLocalizations.supportedLocales
/// property.
abstract class MyLocalizations {
  MyLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static MyLocalizations? of(BuildContext context) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations);
  }

  static const LocalizationsDelegate<MyLocalizations> delegate = _MyLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @locale_name.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get locale_name;

  /// No description provided for @app_name.
  ///
  /// In zh, this message translates to:
  /// **'Rpass'**
  String get app_name;

  /// No description provided for @init_main_password.
  ///
  /// In zh, this message translates to:
  /// **'初始化主密码'**
  String get init_main_password;

  /// No description provided for @at_least_4digits.
  ///
  /// In zh, this message translates to:
  /// **'至少4位数'**
  String get at_least_4digits;

  /// No description provided for @confirm_password.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get confirm_password;

  /// No description provided for @password_not_equal.
  ///
  /// In zh, this message translates to:
  /// **'密码不相等！'**
  String get password_not_equal;

  /// No description provided for @init.
  ///
  /// In zh, this message translates to:
  /// **'初始化'**
  String get init;

  /// No description provided for @question.
  ///
  /// In zh, this message translates to:
  /// **'问题'**
  String get question;

  /// No description provided for @answer.
  ///
  /// In zh, this message translates to:
  /// **'答案'**
  String get answer;

  /// No description provided for @cannot_emprty.
  ///
  /// In zh, this message translates to:
  /// **'不能为空！'**
  String get cannot_emprty;

  /// No description provided for @prev.
  ///
  /// In zh, this message translates to:
  /// **'上一条'**
  String get prev;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一条'**
  String get next;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @input_security_qa_hint.
  ///
  /// In zh, this message translates to:
  /// **'回答安全问题以解密数据！'**
  String get input_security_qa_hint;

  /// No description provided for @security_qa_error.
  ///
  /// In zh, this message translates to:
  /// **'不对啊, 再想想！'**
  String get security_qa_error;

  /// No description provided for @verify_password.
  ///
  /// In zh, this message translates to:
  /// **'验证密码'**
  String get verify_password;

  /// No description provided for @forget_password.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码'**
  String get forget_password;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @none_password.
  ///
  /// In zh, this message translates to:
  /// **'无密码'**
  String get none_password;

  /// No description provided for @setting.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get setting;

  /// 带有搜索匹配数的
  ///
  /// In zh, this message translates to:
  /// **'搜索: {matchCount}/{totalCount}'**
  String search_match_count(int matchCount, int totalCount);

  /// ab 是 ab. 表示缩写, 在这里表示首字母
  ///
  /// In zh, this message translates to:
  /// **'A.'**
  String get account_ab;

  /// No description provided for @email_ab.
  ///
  /// In zh, this message translates to:
  /// **'E.'**
  String get email_ab;

  /// No description provided for @label_ab.
  ///
  /// In zh, this message translates to:
  /// **'L.'**
  String get label_ab;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get system;

  /// No description provided for @light.
  ///
  /// In zh, this message translates to:
  /// **'亮'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In zh, this message translates to:
  /// **'暗'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @security.
  ///
  /// In zh, this message translates to:
  /// **'安全'**
  String get security;

  /// No description provided for @modify_password.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get modify_password;

  /// No description provided for @backup.
  ///
  /// In zh, this message translates to:
  /// **'备份'**
  String get backup;

  /// No description provided for @import.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get import;

  /// No description provided for @export.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get export;

  /// No description provided for @info.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get info;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @modify.
  ///
  /// In zh, this message translates to:
  /// **'修改'**
  String get modify;

  /// No description provided for @edit_account.
  ///
  /// In zh, this message translates to:
  /// **'编辑账号'**
  String get edit_account;

  /// No description provided for @clone.
  ///
  /// In zh, this message translates to:
  /// **'克隆'**
  String get clone;

  /// No description provided for @domain.
  ///
  /// In zh, this message translates to:
  /// **'域名'**
  String get domain;

  /// 带有正确格式信息的消息
  ///
  /// In zh, this message translates to:
  /// **'格式错误，应匹配: {pattern}'**
  String format_error(String pattern);

  /// No description provided for @title.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get title;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get account;

  /// No description provided for @email.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get email;

  /// No description provided for @otp.
  ///
  /// In zh, this message translates to:
  /// **'一次性密码(OTP)'**
  String get otp;

  /// No description provided for @label.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get label;

  /// No description provided for @date.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get date;

  /// No description provided for @uuid.
  ///
  /// In zh, this message translates to:
  /// **'标识'**
  String get uuid;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @symbol.
  ///
  /// In zh, this message translates to:
  /// **'符号'**
  String get symbol;

  /// No description provided for @remark.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get remark;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copy_done.
  ///
  /// In zh, this message translates to:
  /// **'复制完成'**
  String get copy_done;

  /// No description provided for @lookup.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get lookup;

  /// No description provided for @source.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get source;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @delete_warn_hit.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除吗？删除后将无法恢复．'**
  String get delete_warn_hit;

  /// No description provided for @description.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get description;

  /// No description provided for @language_setting.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get language_setting;

  /// 带有路径信息的消息
  ///
  /// In zh, this message translates to:
  /// **'导出完成, 地址: {location}'**
  String export_done_location(String location);

  /// No description provided for @import_done.
  ///
  /// In zh, this message translates to:
  /// **'导入完成'**
  String get import_done;

  /// No description provided for @scan_code.
  ///
  /// In zh, this message translates to:
  /// **'扫码'**
  String get scan_code;

  /// No description provided for @new_label.
  ///
  /// In zh, this message translates to:
  /// **'新建标签'**
  String get new_label;

  /// No description provided for @cannot_all_empty.
  ///
  /// In zh, this message translates to:
  /// **'不能全为空！'**
  String get cannot_all_empty;

  /// No description provided for @empty.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get empty;

  /// No description provided for @chrome.
  ///
  /// In zh, this message translates to:
  /// **'谷歌'**
  String get chrome;

  /// No description provided for @firefox.
  ///
  /// In zh, this message translates to:
  /// **'火狐'**
  String get firefox;

  /// No description provided for @other.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get other;

  /// No description provided for @app_description.
  ///
  /// In zh, this message translates to:
  /// **'Rpass 是一款免费的开源应用程序，可让您方便简洁的记录密码信息．'**
  String get app_description;

  /// 带有指向信息的消息
  ///
  /// In zh, this message translates to:
  /// **'源代码 ({location})'**
  String source_code_location(String location);

  /// No description provided for @biometric.
  ///
  /// In zh, this message translates to:
  /// **'生物识别'**
  String get biometric;

  /// No description provided for @biometric_prompt_title.
  ///
  /// In zh, this message translates to:
  /// **'验证您的身份！'**
  String get biometric_prompt_title;

  /// No description provided for @biometric_prompt_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'使用指纹完成验证才能继续．'**
  String get biometric_prompt_subtitle;

  /// No description provided for @throw_message.
  ///
  /// In zh, this message translates to:
  /// **'异常: {message}'**
  String throw_message(String message);

  /// No description provided for @common.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get common;

  /// No description provided for @default_.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get default_;

  /// No description provided for @pass_lib.
  ///
  /// In zh, this message translates to:
  /// **'密码库'**
  String get pass_lib;

  /// No description provided for @pass_lib_setting.
  ///
  /// In zh, this message translates to:
  /// **'密码库设置'**
  String get pass_lib_setting;

  /// No description provided for @history_record.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get history_record;

  /// No description provided for @max_count.
  ///
  /// In zh, this message translates to:
  /// **'最大条数'**
  String get max_count;

  /// No description provided for @max_size.
  ///
  /// In zh, this message translates to:
  /// **'最大大小'**
  String get max_size;

  /// No description provided for @is_move_recycle.
  ///
  /// In zh, this message translates to:
  /// **'是否将项目移动到回收站？'**
  String get is_move_recycle;

  /// No description provided for @man_selected_pass.
  ///
  /// In zh, this message translates to:
  /// **'管理选中密码'**
  String get man_selected_pass;

  /// No description provided for @move.
  ///
  /// In zh, this message translates to:
  /// **'移动'**
  String get move;

  /// No description provided for @man_group_pass.
  ///
  /// In zh, this message translates to:
  /// **'管理组内密码'**
  String get man_group_pass;

  /// No description provided for @empty_group.
  ///
  /// In zh, this message translates to:
  /// **'组是空的！'**
  String get empty_group;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get rename;

  /// No description provided for @new_field.
  ///
  /// In zh, this message translates to:
  /// **'新建字段'**
  String get new_field;

  /// No description provided for @look_notes.
  ///
  /// In zh, this message translates to:
  /// **'查看备注'**
  String get look_notes;

  /// No description provided for @edit_notes.
  ///
  /// In zh, this message translates to:
  /// **'编辑备注'**
  String get edit_notes;

  /// No description provided for @gen_password.
  ///
  /// In zh, this message translates to:
  /// **'密码生成器'**
  String get gen_password;

  /// No description provided for @pass_length.
  ///
  /// In zh, this message translates to:
  /// **'密码长度'**
  String get pass_length;

  /// No description provided for @include_cahr.
  ///
  /// In zh, this message translates to:
  /// **'包含字符'**
  String get include_cahr;

  /// No description provided for @export_n_file.
  ///
  /// In zh, this message translates to:
  /// **'导出 {name} 文件'**
  String export_n_file(String name);

  /// No description provided for @import_n_file.
  ///
  /// In zh, this message translates to:
  /// **'导入 {name} 文件'**
  String import_n_file(String name);

  /// No description provided for @select_group.
  ///
  /// In zh, this message translates to:
  /// **'选择分组'**
  String get select_group;

  /// No description provided for @group.
  ///
  /// In zh, this message translates to:
  /// **'分组'**
  String get group;

  /// No description provided for @data_migrate_done.
  ///
  /// In zh, this message translates to:
  /// **'数据迁移完成.'**
  String get data_migrate_done;

  /// No description provided for @custom_field.
  ///
  /// In zh, this message translates to:
  /// **'自定义字段'**
  String get custom_field;

  /// No description provided for @search_rule.
  ///
  /// In zh, this message translates to:
  /// **'搜索规则:'**
  String get search_rule;

  /// No description provided for @rule_detail.
  ///
  /// In zh, this message translates to:
  /// **'[字段名:][\"]关键句[\"]'**
  String get rule_detail;

  /// No description provided for @field_name.
  ///
  /// In zh, this message translates to:
  /// **'字段名:'**
  String get field_name;

  /// No description provided for @search_eg.
  ///
  /// In zh, this message translates to:
  /// **'例子:'**
  String get search_eg;

  /// No description provided for @search_eg_1.
  ///
  /// In zh, this message translates to:
  /// **'u:小明 note:\"到此一游，小明\"'**
  String get search_eg_1;

  /// No description provided for @search_eg_2.
  ///
  /// In zh, this message translates to:
  /// **'g:邮箱 u:小明'**
  String get search_eg_2;

  /// No description provided for @recycle_bin.
  ///
  /// In zh, this message translates to:
  /// **'回收站'**
  String get recycle_bin;

  /// No description provided for @completely_delete.
  ///
  /// In zh, this message translates to:
  /// **'彻底删除'**
  String get completely_delete;

  /// No description provided for @delete_no_revert.
  ///
  /// In zh, this message translates to:
  /// **'删除项目后将无法恢复！'**
  String get delete_no_revert;

  /// No description provided for @revert.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get revert;

  /// No description provided for @select_icon.
  ///
  /// In zh, this message translates to:
  /// **'选择图标'**
  String get select_icon;

  /// No description provided for @add_field.
  ///
  /// In zh, this message translates to:
  /// **'添加字段'**
  String get add_field;

  /// No description provided for @letter.
  ///
  /// In zh, this message translates to:
  /// **'字母'**
  String get letter;

  /// No description provided for @number.
  ///
  /// In zh, this message translates to:
  /// **'数字'**
  String get number;

  /// No description provided for @special_char.
  ///
  /// In zh, this message translates to:
  /// **'特殊字符'**
  String get special_char;

  /// No description provided for @not_found_entry.
  ///
  /// In zh, this message translates to:
  /// **'未找到项目！'**
  String get not_found_entry;

  /// No description provided for @attachment.
  ///
  /// In zh, this message translates to:
  /// **'附件'**
  String get attachment;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @last_modify.
  ///
  /// In zh, this message translates to:
  /// **'最后修改'**
  String get last_modify;

  /// No description provided for @warn.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get warn;

  /// No description provided for @plaintext_export_warn.
  ///
  /// In zh, this message translates to:
  /// **'确认明文导出数据？\n注意导出的数据只包含对应的关键字段．'**
  String get plaintext_export_warn;

  /// No description provided for @manage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get manage;

  /// No description provided for @timeline.
  ///
  /// In zh, this message translates to:
  /// **'时间线'**
  String get timeline;

  /// No description provided for @not_history_record.
  ///
  /// In zh, this message translates to:
  /// **'没有历史记录！'**
  String get not_history_record;

  /// No description provided for @password_error.
  ///
  /// In zh, this message translates to:
  /// **'密码错误！'**
  String get password_error;

  /// No description provided for @data_migrate_hint.
  ///
  /// In zh, this message translates to:
  /// **'正在进行软件数据迁移升级，解密数据后，将全部迁移到新的数据库 (kdbx) 存储数据，更好，更稳定，更安全，更多功能．'**
  String get data_migrate_hint;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// 带有搜索匹配数的
  ///
  /// In zh, this message translates to:
  /// **'全选 ({matchCount} / {totalCount})'**
  String all_select(int matchCount, int totalCount);

  /// No description provided for @invert_select.
  ///
  /// In zh, this message translates to:
  /// **'反选'**
  String get invert_select;

  /// No description provided for @more_settings.
  ///
  /// In zh, this message translates to:
  /// **'更多设置'**
  String get more_settings;

  /// No description provided for @lock.
  ///
  /// In zh, this message translates to:
  /// **'锁定'**
  String get lock;

  /// No description provided for @lock_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'程序后台运行或者失去焦点（桌面端），一段时间后锁定程序。'**
  String get lock_subtitle;

  /// No description provided for @never.
  ///
  /// In zh, this message translates to:
  /// **'永不'**
  String get never;

  /// 显示秒
  ///
  /// In zh, this message translates to:
  /// **'{sec} 秒'**
  String seconds(int sec);

  /// 显示分钟
  ///
  /// In zh, this message translates to:
  /// **'{min} 分钟'**
  String minutes(int min);

  /// No description provided for @expires_time.
  ///
  /// In zh, this message translates to:
  /// **'过期时间'**
  String get expires_time;

  /// No description provided for @expires.
  ///
  /// In zh, this message translates to:
  /// **'过期'**
  String get expires;

  /// No description provided for @key_file.
  ///
  /// In zh, this message translates to:
  /// **'密钥文件'**
  String get key_file;

  /// No description provided for @record_key_file_path.
  ///
  /// In zh, this message translates to:
  /// **'记录密钥文件路径'**
  String get record_key_file_path;

  /// No description provided for @lack_key_file.
  ///
  /// In zh, this message translates to:
  /// **'缺少密钥文件'**
  String get lack_key_file;

  /// No description provided for @move_selected.
  ///
  /// In zh, this message translates to:
  /// **'移动选中'**
  String get move_selected;

  /// No description provided for @delete_selected.
  ///
  /// In zh, this message translates to:
  /// **'删除选中'**
  String get delete_selected;

  /// No description provided for @revert_selected.
  ///
  /// In zh, this message translates to:
  /// **'恢复选中'**
  String get revert_selected;

  /// No description provided for @completely_delete_selected.
  ///
  /// In zh, this message translates to:
  /// **'彻底删除选中'**
  String get completely_delete_selected;

  /// No description provided for @rename_field.
  ///
  /// In zh, this message translates to:
  /// **'重命名字段'**
  String get rename_field;

  /// No description provided for @delete_field.
  ///
  /// In zh, this message translates to:
  /// **'删除字段'**
  String get delete_field;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @local_import.
  ///
  /// In zh, this message translates to:
  /// **'本地导入'**
  String get local_import;

  /// No description provided for @sync.
  ///
  /// In zh, this message translates to:
  /// **'同步'**
  String get sync;

  /// No description provided for @sync_settings.
  ///
  /// In zh, this message translates to:
  /// **'同步设置'**
  String get sync_settings;

  /// 从哪个远程服务器导入
  ///
  /// In zh, this message translates to:
  /// **'从 {name} 中导入'**
  String from_import(String name);

  /// No description provided for @save_as.
  ///
  /// In zh, this message translates to:
  /// **'保存到'**
  String get save_as;

  /// No description provided for @selected_sync_account_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'从数据库中选择账号'**
  String get selected_sync_account_subtitle;

  /// No description provided for @save_sync_account_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'将登录信息保存到数据库中'**
  String get save_sync_account_subtitle;

  /// No description provided for @logined_sync.
  ///
  /// In zh, this message translates to:
  /// **'登录后同步数据'**
  String get logined_sync;

  /// No description provided for @import_remote_kdbx.
  ///
  /// In zh, this message translates to:
  /// **'导入远程数据库'**
  String get import_remote_kdbx;

  /// No description provided for @close_local_sync_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'关闭当前设备同步功能'**
  String get close_local_sync_subtitle;

  /// No description provided for @sync_note_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'如果远程文件被第三方 kdbx 管理器修改过，则需要长按同步按钮进行强制合并。'**
  String get sync_note_subtitle;

  /// No description provided for @sync_error_log.
  ///
  /// In zh, this message translates to:
  /// **'同步错误日志'**
  String get sync_error_log;

  /// No description provided for @sync_merge_log.
  ///
  /// In zh, this message translates to:
  /// **'同步合并日志'**
  String get sync_merge_log;

  /// No description provided for @change.
  ///
  /// In zh, this message translates to:
  /// **'更改'**
  String get change;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @select_account.
  ///
  /// In zh, this message translates to:
  /// **'选择账号'**
  String get select_account;

  /// No description provided for @custom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get custom;

  /// No description provided for @display.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get display;

  /// No description provided for @enable_display_true_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'包含在主页列表中'**
  String get enable_display_true_subtitle;

  /// No description provided for @enable_display_false_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'排除在主页列表外'**
  String get enable_display_false_subtitle;

  /// No description provided for @enable_display_null_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'继承显示设置'**
  String get enable_display_null_subtitle;

  /// No description provided for @enable_searching_true_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'包含在搜索中'**
  String get enable_searching_true_subtitle;

  /// No description provided for @enable_searching_false_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'排除在搜索外'**
  String get enable_searching_false_subtitle;

  /// No description provided for @enable_searching_null_subtitle.
  ///
  /// In zh, this message translates to:
  /// **'继承搜索设置'**
  String get enable_searching_null_subtitle;

  /// No description provided for @edit_auto_fill_sequence.
  ///
  /// In zh, this message translates to:
  /// **'编辑自动填充序列'**
  String get edit_auto_fill_sequence;

  /// No description provided for @default_field.
  ///
  /// In zh, this message translates to:
  /// **'默认字段'**
  String get default_field;

  /// No description provided for @auto_fill.
  ///
  /// In zh, this message translates to:
  /// **'自动填充'**
  String get auto_fill;

  /// No description provided for @keyboard_key.
  ///
  /// In zh, this message translates to:
  /// **'键盘键'**
  String get keyboard_key;

  /// No description provided for @fill_sequence.
  ///
  /// In zh, this message translates to:
  /// **'填充序列'**
  String get fill_sequence;

  /// No description provided for @sync_cycle.
  ///
  /// In zh, this message translates to:
  /// **'同步周期'**
  String get sync_cycle;

  /// No description provided for @each_startup.
  ///
  /// In zh, this message translates to:
  /// **'每次启动'**
  String get each_startup;

  /// 显示天
  ///
  /// In zh, this message translates to:
  /// **'{day} 天'**
  String days(int day);

  /// No description provided for @auto_fill_specified_field.
  ///
  /// In zh, this message translates to:
  /// **'填充指定字段'**
  String get auto_fill_specified_field;

  /// No description provided for @copy_specified_field.
  ///
  /// In zh, this message translates to:
  /// **'复制指定字段'**
  String get copy_specified_field;
}

class _MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  const _MyLocalizationsDelegate();

  @override
  Future<MyLocalizations> load(Locale locale) {
    return SynchronousFuture<MyLocalizations>(lookupMyLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_MyLocalizationsDelegate old) => false;
}

MyLocalizations lookupMyLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return MyLocalizationsEn();
    case 'zh': return MyLocalizationsZh();
  }

  throw FlutterError(
    'MyLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
