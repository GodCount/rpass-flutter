import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../component/label_list.dart';
import '../../component/toast.dart';
import '../../store/accounts/contrller.dart';
import '../../model/account.dart';
import '../../util/common.dart';
import '../page.dart';

class AccountRegExp {
  static final RegExp domain = RegExp(r"^(https?:\/\/)?(\w+)\..+");
  static final RegExp email = RegExp(
      r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
      r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
      r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
      r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
      r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
      r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
      r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])');

  static final RegExp oneTimePassword = RegExp(r"^otpauth://totp/.+");
}

class EditAccountPage extends StatefulWidget {
  const EditAccountPage(
      {super.key, required this.accountsContrller, this.accountId});

  static const routeName = "/edit_account";

  final AccountsContrller accountsContrller;

  final String? accountId;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  late final Account _account;

  late final GlobalKey<_ValidatorTextFieldState> _domainGolbalKey;
  late final GlobalKey<_ValidatorTextFieldState> _domainNameGolbalKey;
  late final GlobalKey<_ValidatorDropdownMenuState> _accountGolbalKey;
  late final GlobalKey<_ValidatorDropdownMenuState> _emailGolbalKey;
  late final GlobalKey<_ValidatorTextFieldState> _passwordGolbalKey;
  late final GlobalKey<_ValidatorTextFieldState> _otPasswordGolbalKey;

  late final TextEditingController _domainController;
  late final TextEditingController _domainNameController;
  late final TextEditingController _accountController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _otPasswordController;
  late final TextEditingController _descriptionController;

  final bool _displayScanner = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    if (widget.accountId != null) {
      try {
        _account =
            widget.accountsContrller.getAccountById(widget.accountId!).clone();
      } catch (e) {
        // initState 阶段无法使用 context 延迟一下
        Future.delayed(Duration.zero, () {
          showToast(context, "账号信息获取异常: ${e.toString()}");
          Navigator.of(context).pop();
        });

        // 先赋值为空,让后续代码正常运行
        _account = Account.fromEmpty();
      }
    } else {
      _account = Account.fromEmpty();
    }

    _domainGolbalKey = GlobalKey<_ValidatorTextFieldState>();
    _domainNameGolbalKey = GlobalKey<_ValidatorTextFieldState>();

    _accountGolbalKey = GlobalKey<_ValidatorDropdownMenuState>();
    _emailGolbalKey = GlobalKey<_ValidatorDropdownMenuState>();

    _passwordGolbalKey = GlobalKey<_ValidatorTextFieldState>();
    _otPasswordGolbalKey = GlobalKey<_ValidatorTextFieldState>();

    _domainController = TextEditingController(text: _account.domain);
    _domainNameController = TextEditingController(text: _account.domainName);
    _accountController = TextEditingController(text: _account.account);
    _emailController = TextEditingController(text: _account.email);
    _passwordController = TextEditingController(text: _account.password);
    _otPasswordController =
        TextEditingController(text: _account.oneTimePassword);
    _descriptionController = TextEditingController(text: _account.description);

    super.initState();
  }

  @override
  void dispose() {
    _domainController.dispose();
    _domainNameController.dispose();
    _accountController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otPasswordController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  bool _validator() {
    return _domainGolbalKey.currentState!.validator() &&
        _domainNameGolbalKey.currentState!.validator() &&
        _accountGolbalKey.currentState!.validator() &&
        _emailGolbalKey.currentState!.validator() &&
        _passwordGolbalKey.currentState!.validator();
  }

  List<LabelItem> _getLabels() {
    return widget.accountsContrller.labelSet.map((value) {
      return LabelItem(value: value, select: _account.labels.contains(value));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    width = (width > 375 ? 375 : width) - 48;

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("编辑账号"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
              child: SizedBox(
            width: width,
            child: Column(
              children: [
                _ValidatorTextField(
                  key: _domainGolbalKey,
                  controller: _domainController,
                  textInputAction: TextInputAction.next,
                  focusNoError: true,
                  decoration: const InputDecoration(
                    labelText: "域名",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      !AccountRegExp.domain.hasMatch(value) ? "格式错误" : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ValidatorTextField(
                    key: _domainNameGolbalKey,
                    controller: _domainNameController,
                    textInputAction: TextInputAction.next,
                    focusNoError: true,
                    decoration: const InputDecoration(
                      labelText: "网站名",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value.isEmpty ? "不能为空" : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ValidatorDropdownMenu(
                    key: _accountGolbalKey,
                    controller: _accountController,
                    focusNoError: true,
                    width: width,
                    enableFilter: true,
                    enableSearch: false,
                    label: const Text("账号"),
                    menuHeight: 100,
                    requestFocusOnTap: true,
                    dropdownMenuEntries: widget.accountsContrller.accountNumSet
                        .map((value) =>
                            DropdownMenuEntry(value: value, label: value))
                        .toList(),
                    validator: (value) => value.isEmpty ? "不能为空" : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ValidatorDropdownMenu(
                    key: _emailGolbalKey,
                    controller: _emailController,
                    focusNoError: true,
                    width: width,
                    enableFilter: true,
                    enableSearch: false,
                    label: const Text("邮箱"),
                    menuHeight: 100,
                    requestFocusOnTap: true,
                    dropdownMenuEntries: widget.accountsContrller.emailSet
                        .map((value) =>
                            DropdownMenuEntry(value: value, label: value))
                        .toList(),
                    validator: (value) =>
                        !AccountRegExp.email.hasMatch(value) ? "格式错误" : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ValidatorTextField(
                    key: _passwordGolbalKey,
                    controller: _passwordController,
                    textInputAction: TextInputAction.next,
                    focusNoError: true,
                    decoration: InputDecoration(
                      labelText: "密码",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: _generatePassword,
                        icon: const Icon(Icons.create),
                      ),
                    ),
                    validator: (value) => value.isEmpty ? "不能为空" : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ValidatorTextField(
                    key: _otPasswordGolbalKey,
                    controller: _otPasswordController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: "一次性密码(OTP)",
                      border: const OutlineInputBorder(),
                      suffixIcon: _displayScanner
                          ? IconButton(
                              onPressed: () async {
                                Navigator.of(context)
                                    .pushNamed(QrCodeScannerPage.routeName)
                                    .then((value) {
                                  if (value is String && value.isNotEmpty) {
                                    _otPasswordController.text = value;
                                  }
                                });
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                            )
                          : null,
                    ),
                    validator: (value) => value.isNotEmpty &&
                            !AccountRegExp.oneTimePassword.hasMatch(value)
                        ? "格式错误"
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _DescriptionTextField(
                    controller: _descriptionController,
                    hitText: "备注",
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  width: width,
                  child: LabelList(
                    items: _getLabels(),
                    onChange: (labels) {
                      _account.labels = labels;
                    },
                  ),
                ),
              ],
            ),
          )),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_validator()) {
              _account.domain = _domainController.text;
              _account.domainName = _domainNameController.text;
              _account.account = _accountController.text;
              _account.email = _emailController.text;
              _account.password = _passwordController.text;
              _account.oneTimePassword = _otPasswordController.text;
              _account.description = _descriptionController.text;
              widget.accountsContrller.setAccount(_account);
              Navigator.of(context).pop(_account.id);
            }
          },
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(56 / 2),
            ),
          ),
          child: const Icon(Icons.save),
        ),
        bottomNavigationBar: const SizedBox(
          height: 56,
        ));
  }

  void _generatePassword() {
    final GlobalKey<_GeneratePasswordState> generateGlobalKey =
        GlobalKey<_GeneratePasswordState>();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("生成密码"),
            scrollable: true,
            content: _GeneratePassword(
              key: generateGlobalKey,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    generateGlobalKey.currentState?.updatePassword(),
                child: const Text("刷新"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("取消"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _passwordController.text =
                      generateGlobalKey.currentState!.password;
                },
                child: const Text("确认"),
              ),
            ],
          );
        });
  }
}

typedef ValidatorCallback = String? Function(String value);

class _ValidatorDropdownMenu extends StatefulWidget {
  const _ValidatorDropdownMenu({
    required super.key,
    required this.dropdownMenuEntries,
    required this.validator,
    required this.controller,
    this.focusNoError = true,
    this.width,
    this.enableFilter = false,
    this.enableSearch = true,
    this.label,
    this.menuHeight,
    this.requestFocusOnTap,
  });

  final List<DropdownMenuEntry<String>> dropdownMenuEntries;
  final ValidatorCallback validator;
  final bool focusNoError;
  final TextEditingController controller;

  final double? width;
  final bool enableFilter;
  final bool enableSearch;
  final Widget? label;
  final double? menuHeight;
  final bool? requestFocusOnTap;

  @override
  State<_ValidatorDropdownMenu> createState() => _ValidatorDropdownMenuState();
}

class _ValidatorDropdownMenuState extends State<_ValidatorDropdownMenu> {
  String? _errorText;
  FocusNode? _focusNode;

  @override
  void initState() {
    widget.controller.addListener(() {
      final text = widget.validator(widget.controller.text);
      if (text != _errorText) {
        _errorText = text;
        setState(() {});
      }
    });

    if (widget.focusNoError) {
      _focusNode = FocusNode();
      _focusNode!.addListener(() {
        if (_focusNode!.hasFocus &&
            _errorText != null &&
            widget.controller.text.isEmpty) {
          _errorText = null;
          setState(() {});
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  bool validator() {
    final text = widget.validator(widget.controller.text);
    if (text != _errorText) {
      _errorText = text;
      setState(() {});
    }
    return text == null;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      errorText: _errorText,
      focusNode: _focusNode,
      width: widget.width,
      controller: widget.controller,
      enableFilter: widget.enableFilter,
      enableSearch: widget.enableSearch,
      label: widget.label,
      menuHeight: widget.menuHeight,
      dropdownMenuEntries: widget.dropdownMenuEntries,
      requestFocusOnTap: widget.requestFocusOnTap,
    );
  }
}

class _ValidatorTextField extends StatefulWidget {
  const _ValidatorTextField({
    required super.key,
    required this.validator,
    required this.controller,
    this.focusNoError = true,
    this.decoration,
    this.textInputAction,
  });

  final ValidatorCallback validator;
  final bool focusNoError;
  final TextEditingController controller;

  final InputDecoration? decoration;
  final TextInputAction? textInputAction;

  @override
  State<_ValidatorTextField> createState() => _ValidatorTextFieldState();
}

class _ValidatorTextFieldState extends State<_ValidatorTextField> {
  String? _errorText;
  FocusNode? _focusNode;

  @override
  void initState() {
    widget.controller.addListener(() {
      final text = widget.validator(widget.controller.text);
      if (text != _errorText) {
        _errorText = text;
        setState(() {});
      }
    });

    if (widget.focusNoError) {
      _focusNode = FocusNode();
      _focusNode!.addListener(() {
        if (_focusNode!.hasFocus &&
            _errorText != null &&
            widget.controller.text.isEmpty) {
          _errorText = null;
          setState(() {});
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  bool validator() {
    final text = widget.validator(widget.controller.text);
    if (text != _errorText) {
      _errorText = text;
      setState(() {});
    }
    return text == null;
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration?.copyWith(errorText: _errorText) ??
        InputDecoration(errorText: _errorText);
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      textInputAction: widget.textInputAction,
      decoration: decoration,
    );
  }
}

class _GeneratePassword extends StatefulWidget {
  const _GeneratePassword({super.key});

  @override
  State<_GeneratePassword> createState() => _GeneratePasswordState();
}

class _GeneratePasswordState extends State<_GeneratePassword> {
  bool _letterUppercase = true;
  bool _letterLowercase = true;
  bool _enableNumber = true;
  bool _enableSymbol = true;
  double _length = 10;

  late String password;

  updatePassword() {
    try {
      password = randomPassword(
        length: _length.toInt(),
        enableNumber: _enableNumber,
        enableSymbol: _enableSymbol,
        enableLetterLowercase: _letterUppercase,
        enableLetterUppercase: _letterLowercase,
      );
    } on EmptyError {
      _enableNumber = true;
      return updatePassword();
    }
    setState(() {});
  }

  @override
  void initState() {
    password = randomPassword(length: _length.toInt());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          value: _enableNumber,
          title: const Text("0~9"),
          onChanged: (value) {
            _enableNumber = value!;
            updatePassword();
          },
        ),
        CheckboxListTile(
          value: _letterUppercase,
          title: const Text("a~z"),
          onChanged: (value) {
            _letterUppercase = value!;
            updatePassword();
          },
        ),
        CheckboxListTile(
          value: _letterLowercase,
          title: const Text("A~Z"),
          onChanged: (value) {
            _letterLowercase = value!;
            updatePassword();
          },
        ),
        CheckboxListTile(
          value: _enableSymbol,
          title: const Text("标点符号"),
          onChanged: (value) {
            _enableSymbol = value!;
            updatePassword();
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Slider(
            value: _length,
            label: "${_length.toInt()}",
            divisions: 24,
            min: 4,
            max: 24,
            onChanged: (value) {
              _length = value;
              updatePassword();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SelectableText(password),
        )
      ],
    );
  }
}

class _DescriptionTextField extends StatefulWidget {
  const _DescriptionTextField({
    required this.controller,
    this.hitText,
  });

  final TextEditingController controller;
  final String? hitText;

  @override
  State<_DescriptionTextField> createState() => _DescriptionTextFieldState();
}

class _DescriptionTextFieldState extends State<_DescriptionTextField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      readOnly: true,
      maxLines: 3,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: widget.hitText,
      ),
      onTap: _editText,
    );
  }

  void _editText() {
    final String lastValue = widget.controller.text;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("备注"),
          scrollable: true,
          content: TextField(
            controller: widget.controller,
            maxLines: 10,
            autofocus: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != true) {
        widget.controller.text = lastValue;
      }
    });
  }
}
