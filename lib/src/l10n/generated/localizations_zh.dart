// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class MyLocalizationsZh extends MyLocalizations {
  MyLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get locale_name => '简体中文';

  @override
  String get app_name => 'Rpass';

  @override
  String get init_main_password => '初始化主密码';

  @override
  String get at_least_4digits => '至少4位数';

  @override
  String get confirm_password => '确认密码';

  @override
  String get password_not_equal => '密码不相等！';

  @override
  String get init => '初始化';

  @override
  String get question => '问题';

  @override
  String get answer => '答案';

  @override
  String get cannot_emprty => '不能为空！';

  @override
  String get prev => '上一条';

  @override
  String get next => '下一条';

  @override
  String get add => '添加';

  @override
  String get confirm => '确认';

  @override
  String get back => '返回';

  @override
  String get input_security_qa_hint => '回答安全问题以解密数据！';

  @override
  String get security_qa_error => '不对啊, 再想想！';

  @override
  String get verify_password => '验证密码';

  @override
  String get forget_password => '忘记密码';

  @override
  String get password => '密码';

  @override
  String get none_password => '无密码';

  @override
  String get setting => '设置';

  @override
  String search_match_count(int matchCount, int totalCount) {
    return '搜索: $matchCount/$totalCount';
  }

  @override
  String get account_ab => 'A.';

  @override
  String get email_ab => 'E.';

  @override
  String get label_ab => 'L.';

  @override
  String get theme => '主题';

  @override
  String get system => '系统';

  @override
  String get light => '亮';

  @override
  String get dark => '暗';

  @override
  String get language => '语言';

  @override
  String get security => '安全';

  @override
  String get modify_password => '修改密码';

  @override
  String get backup => '备份';

  @override
  String get import => '导入';

  @override
  String get export => '导出';

  @override
  String get info => '信息';

  @override
  String get about => '关于';

  @override
  String get cancel => '取消';

  @override
  String get modify => '修改';

  @override
  String get edit_account => '编辑账号';

  @override
  String get clone => '克隆';

  @override
  String get domain => '域名';

  @override
  String format_error(String pattern) {
    return '格式错误，应匹配: $pattern';
  }

  @override
  String get title => '标题';

  @override
  String get account => '账号';

  @override
  String get email => '邮箱';

  @override
  String get otp => '一次性密码(OTP)';

  @override
  String get label => '标签';

  @override
  String get date => '日期';

  @override
  String get uuid => '标识';

  @override
  String get refresh => '刷新';

  @override
  String get symbol => '符号';

  @override
  String get remark => '备注';

  @override
  String get save => '保存';

  @override
  String get copy => '复制';

  @override
  String get copy_done => '复制完成';

  @override
  String get lookup => '查看';

  @override
  String get source => '来源';

  @override
  String get delete => '删除';

  @override
  String get delete_warn_hit => '确定要删除吗？删除后将无法恢复．';

  @override
  String get description => '描述';

  @override
  String get language_setting => '语言设置';

  @override
  String export_done_location(String location) {
    return '导出完成, 地址: $location';
  }

  @override
  String get import_done => '导入完成';

  @override
  String get scan_code => '扫码';

  @override
  String get new_label => '新建标签';

  @override
  String get cannot_all_empty => '不能全为空！';

  @override
  String get empty => '空';

  @override
  String get chrome => '谷歌';

  @override
  String get firefox => '火狐';

  @override
  String get other => '其他';

  @override
  String get app_description => 'Rpass 是一款免费的开源应用程序，可让您方便简洁的记录密码信息．';

  @override
  String source_code_location(String location) {
    return '源代码 ($location)';
  }

  @override
  String get biometric => '生物识别';

  @override
  String get biometric_prompt_title => '验证您的身份！';

  @override
  String get biometric_prompt_subtitle => '使用指纹完成验证才能继续．';

  @override
  String throw_message(String message) {
    return '异常: $message';
  }

  @override
  String get common => '通用';

  @override
  String get default_ => '默认';

  @override
  String get pass_lib => '密码库';

  @override
  String get pass_lib_setting => '密码库设置';

  @override
  String get history_record => '历史记录';

  @override
  String get max_count => '最大条数';

  @override
  String get max_size => '最大大小';

  @override
  String get is_move_recycle => '是否将项目移动到回收站？';

  @override
  String get man_selected_pass => '管理选中密码';

  @override
  String get move => '移动';

  @override
  String get man_group_pass => '管理组内密码';

  @override
  String get empty_group => '组是空的！';

  @override
  String get rename => '重命名';

  @override
  String get new_field => '新建字段';

  @override
  String get look_notes => '查看备注';

  @override
  String get edit_notes => '编辑备注';

  @override
  String get gen_password => '密码生成器';

  @override
  String get pass_length => '密码长度';

  @override
  String get include_cahr => '包含字符';

  @override
  String export_n_file(String name) {
    return '导出 $name 文件';
  }

  @override
  String import_n_file(String name) {
    return '导入 $name 文件';
  }

  @override
  String get select_group => '选择分组';

  @override
  String get group => '分组';

  @override
  String get data_migrate_done => '数据迁移完成.';

  @override
  String get custom_field => '自定义字段';

  @override
  String get search_rule => '搜索规则:';

  @override
  String get rule_detail => '[字段名:][\"]关键句[\"]';

  @override
  String get field_name => '字段名:';

  @override
  String get search_eg => '例子:';

  @override
  String get search_eg_1 => 'u:小明 note:\"到此一游，小明\"';

  @override
  String get search_eg_2 => 'g:邮箱 u:小明';

  @override
  String get recycle_bin => '回收站';

  @override
  String get completely_delete => '彻底删除';

  @override
  String get delete_no_revert => '删除项目后将无法恢复！';

  @override
  String get revert => '恢复';

  @override
  String get select_icon => '选择图标';

  @override
  String get add_field => '添加字段';

  @override
  String get letter => '字母';

  @override
  String get number => '数字';

  @override
  String get special_char => '特殊字符';

  @override
  String get not_found_entry => '未找到项目！';

  @override
  String get attachment => '附件';

  @override
  String get create => '创建';

  @override
  String get last_modify => '最后修改';

  @override
  String get warn => '警告';

  @override
  String get plaintext_export_warn => '确认明文导出数据？\n注意导出的数据只包含对应的关键字段．';

  @override
  String get manage => '管理';

  @override
  String get timeline => '时间线';

  @override
  String get not_history_record => '没有历史记录！';

  @override
  String get password_error => '密码错误！';

  @override
  String get data_migrate_hint =>
      '正在进行软件数据迁移升级，解密数据后，将全部迁移到新的数据库 (kdbx) 存储数据，更好，更稳定，更安全，更多功能．';

  @override
  String get search => '搜索';

  @override
  String all_select(int matchCount, int totalCount) {
    return '全选 ($matchCount / $totalCount)';
  }

  @override
  String get invert_select => '反选';

  @override
  String get more_settings => '更多设置';

  @override
  String get lock => '锁定';

  @override
  String get lock_subtitle => '程序后台运行或者失去焦点（桌面端），一段时间后锁定程序。';

  @override
  String get never => '永不';

  @override
  String seconds(int sec) {
    return '$sec 秒';
  }

  @override
  String minutes(int min) {
    return '$min 分钟';
  }

  @override
  String get expires_time => '过期时间';

  @override
  String get expires => '过期';

  @override
  String get key_file => '密钥文件';

  @override
  String get record_key_file_path => '记录密钥文件路径';

  @override
  String get lack_key_file => '缺少密钥文件';

  @override
  String get move_selected => '移动选中';

  @override
  String get delete_selected => '删除选中';

  @override
  String get revert_selected => '恢复选中';

  @override
  String get completely_delete_selected => '彻底删除选中';

  @override
  String get rename_field => '重命名字段';

  @override
  String get delete_field => '删除字段';

  @override
  String get more => '更多';

  @override
  String get local_import => '本地导入';

  @override
  String get sync => '同步';

  @override
  String get sync_settings => '同步设置';

  @override
  String from_import(String name) {
    return '从 $name 中导入';
  }

  @override
  String get save_as => '保存到';

  @override
  String get selected_sync_account_subtitle => '从数据库中选择账号';

  @override
  String get save_sync_account_subtitle => '将登录信息保存到数据库中';

  @override
  String get logined_sync => '登录后同步数据';

  @override
  String get import_remote_kdbx => '导入远程数据库';

  @override
  String get close_local_sync_subtitle => '关闭当前设备同步功能';

  @override
  String get sync_note_subtitle => '如果远程文件被第三方 kdbx 管理器修改过，则需要长按同步按钮进行强制合并。';

  @override
  String get sync_error_log => '同步错误日志';

  @override
  String get sync_merge_log => '同步合并日志';

  @override
  String get change => '更改';

  @override
  String get remove => '移除';

  @override
  String get select_account => '选择账号';

  @override
  String get custom => '自定义';

  @override
  String get display => '显示';

  @override
  String get enable_display_true_subtitle => '包含在主页列表中';

  @override
  String get enable_display_false_subtitle => '排除在主页列表外';

  @override
  String get enable_display_null_subtitle => '继承显示设置';

  @override
  String get enable_searching_true_subtitle => '包含在搜索中';

  @override
  String get enable_searching_false_subtitle => '排除在搜索外';

  @override
  String get enable_searching_null_subtitle => '继承搜索设置';

  @override
  String get edit_auto_fill_sequence => '编辑自动填充序列';

  @override
  String get default_field => '默认字段';

  @override
  String get auto_fill => '自动填充';

  @override
  String get keyboard_key => '键盘键';

  @override
  String get fill_sequence => '填充序列';

  @override
  String get sync_cycle => '同步周期';

  @override
  String get each_startup => '每次启动';

  @override
  String days(int day) {
    return '$day 天';
  }

  @override
  String get auto_fill_specified_field => '填充指定字段';

  @override
  String get copy_specified_field => '复制指定字段';

  @override
  String get show_system_apps => '显示系统应用';

  @override
  String get hide_system_apps => '隐藏系统应用';

  @override
  String get none => '无';

  @override
  String get auto_fill_apps_none_subtitle => '将根据域名匹配';

  @override
  String get enable_auto_fill_service => '启用自动填充服务';

  @override
  String get manual_select_fill_item => '手动选择填充数据项';

  @override
  String get manual_select_fill_item_subtitle => '当自动匹配填充数据集返回为空时';

  @override
  String get auto_fill_match_app => '自动填充应用';

  @override
  String get start_focus_sreach => '启动时聚焦到搜索框上';

  @override
  String get show_favicon => '显示网站图标';

  @override
  String get show_favicon_sub => '开启后,将尝试从指定的来源服务中请求网站图标并替换显示,自定义图标不会被替换.';

  @override
  String get all => '全部';

  @override
  String get direct_download => '直接下载';
}
