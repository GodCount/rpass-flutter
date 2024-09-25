import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../component/label_list.dart';
import '../../component/match_text.dart';
import '../../component/toast.dart';
import '../../component/transition.dart';
import '../../context/store.dart';
import '../../i18n.dart';
import '../../model/rpass/account.dart';
import '../../util/common.dart';
import '../page.dart';
import '../widget/utils.dart';

class EditAccountPage extends StatefulWidget {
  const EditAccountPage({super.key, this.accountId});

  static const routeName = "/edit_account";

  final String? accountId;

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final GlobalKey<ScaleReboundState> _scaleReboundKey = GlobalKey();

  Account _account = Account();

  late final GlobalKey<_ValidatorTextFieldState> _domainGolbalKey;
  late final GlobalKey<_ValidatorDropdownMenuState> _emailGolbalKey;
  late final GlobalKey<_ValidatorTextFieldState> _otPasswordGolbalKey;

  late final TextEditingController _domainController;
  late final TextEditingController _domainNameController;
  late final TextEditingController _accountController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _otPasswordController;
  late final TextEditingController _descriptionController;

  final bool _displayScanner = Platform.isAndroid || Platform.isIOS;

  bool _canClone = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      if (widget.accountId != null) {
        try {
          _account = StoreProvider.of(context)
              .accounts
              .getAccountById(widget.accountId!)
              .clone();
          _canClone = true;
        } catch (e) {
          showToast(
            context,
            I18n.of(context)!.info_read_throw(
              e.toString(),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    });

    _domainGolbalKey = GlobalKey<_ValidatorTextFieldState>();
    _emailGolbalKey = GlobalKey<_ValidatorDropdownMenuState>();
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
        _emailGolbalKey.currentState!.validator() &&
        _otPasswordGolbalKey.currentState!.validator();
  }

  bool _allEmpty() {
    return _domainController.text.isEmpty &&
        _domainNameController.text.isEmpty &&
        _accountController.text.isEmpty &&
        _emailController.text.isEmpty &&
        _passwordController.text.isEmpty &&
        _otPasswordController.text.isEmpty &&
        _descriptionController.text.isEmpty;
  }

  List<LabelItem> _getLabels() {
    return StoreProvider.of(context).accounts.labelSet.map((value) {
      return LabelItem(value: value, select: _account.labels.contains(value));
    }).toList();
  }

  void _cloneAccount() {
    _account.date = DateTime.now();
    _account.id = timeBasedUuid();
    _canClone = false;
    setState(() {
      _scaleReboundKey.currentState!.rebound();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = StoreProvider.of(context);

    double width = MediaQuery.sizeOf(context).width;

    width = (width > 375 ? 375 : width) - 48;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.edit_account),
        actions: [
          IconButton(
            onPressed: _canClone ? _cloneAccount : null,
            icon: const Icon(Icons.copy_rounded),
            tooltip: t.clone,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ScaleRebound(
          key: _scaleReboundKey,
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ValidatorTextField(
                      key: _domainGolbalKey,
                      controller: _domainController,
                      textInputAction: TextInputAction.next,
                      focusNoError: true,
                      decoration: InputDecoration(
                        labelText: t.domain,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value.isNotEmpty &&
                              !CommonRegExp.domain.hasMatch(value)
                          ? t.format_error(CommonRegExp.domain.pattern)
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _domainNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.domain_title,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ValidatorDropdownMenu(
                      controller: _accountController,
                      focusNoError: true,
                      width: width,
                      enableFilter: true,
                      enableSearch: false,
                      label: Text(t.account),
                      menuHeight: 100,
                      requestFocusOnTap: true,
                      dropdownMenuEntries: store.accounts.accountNumSet
                          .map((value) =>
                              DropdownMenuEntry(value: value, label: value))
                          .toList(),
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
                      label: Text(t.email),
                      menuHeight: 100,
                      requestFocusOnTap: true,
                      dropdownMenuEntries: store.accounts.emailSet
                          .map((value) =>
                              DropdownMenuEntry(value: value, label: value))
                          .toList(),
                      validator: (value) => value.isNotEmpty &&
                              !CommonRegExp.email.hasMatch(value)
                          ? t.format_error(CommonRegExp.email.pattern)
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.password,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: _generatePassword,
                          icon: const Icon(Icons.create),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ValidatorTextField(
                      key: _otPasswordGolbalKey,
                      controller: _otPasswordController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.otp,
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
                              !CommonRegExp.oneTimePassword.hasMatch(value)
                          ? t.format_error(CommonRegExp.oneTimePassword.pattern)
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _DescriptionTextField(
                      controller: _descriptionController,
                      hitText: t.description,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: t.label,
                        border: const OutlineInputBorder(),
                      ),
                      child: LabelList(
                        items: _getLabels(),
                        onChange: (labels) {
                          _account.labels = labels;
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    alignment: Alignment.topLeft,
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge,
                        text: "${t.date}: ",
                        children: [
                          TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            text: dateFormat(_account.date),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 2),
                    alignment: Alignment.topLeft,
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge,
                        text: "${t.uuid}: ",
                        children: [
                          TextSpan(
                            style: Theme.of(context).textTheme.bodySmall,
                            text: _account.id,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_allEmpty()) {
            showToast(context, t.cannot_all_empty);
          } else if (_validator()) {
            _account.domain = _domainController.text;
            _account.domainName = _domainNameController.text;
            _account.account = _accountController.text;
            _account.email = _emailController.text;
            _account.password = _passwordController.text;
            _account.oneTimePassword = _otPasswordController.text;
            _account.description = _descriptionController.text;
            store.accounts.setAccount(_account);
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _generatePassword() {
    final GlobalKey<_GeneratePasswordState> generateGlobalKey =
        GlobalKey<_GeneratePasswordState>();

    final t = I18n.of(context)!;

    double width = MediaQuery.sizeOf(context).width;

    width = (width > 375 ? 375 : width) - 48;

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(t.gen_password),
            scrollable: true,
            content: SizedBox(
              width: width,
              child: _GeneratePassword(
                key: generateGlobalKey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    generateGlobalKey.currentState?.updatePassword(),
                child: Text(t.refresh),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(t.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _passwordController.text =
                      generateGlobalKey.currentState!.password;
                },
                child: Text(t.confirm),
              ),
            ],
          );
        });
  }
}

typedef ValidatorCallback = String? Function(String value);

class _ValidatorDropdownMenu extends StatefulWidget {
  const _ValidatorDropdownMenu({
    super.key,
    required this.dropdownMenuEntries,
    required this.controller,
    this.validator,
    this.focusNoError = true,
    this.width,
    this.enableFilter = false,
    this.enableSearch = true,
    this.label,
    this.menuHeight,
    this.requestFocusOnTap,
  });

  final List<DropdownMenuEntry<String>> dropdownMenuEntries;
  final ValidatorCallback? validator;
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
      validator();
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
    if (widget.validator == null) return true;
    final text = widget.validator!(widget.controller.text);
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
    super.key,
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

class _GeneratePasswordState extends State<_GeneratePassword>
    with CommonWidgetUtil {
  bool _letterUppercase = true;
  bool _letterLowercase = true;
  bool _enableNumber = true;
  bool _enableSymbol = true;
  double _length = 10;

  late String password;

  updatePassword() {
    password = randomPassword(
      length: _length.toInt(),
      enableNumber: _enableNumber,
      enableSymbol: _enableSymbol,
      enableLetterLowercase: _letterUppercase,
      enableLetterUppercase: _letterLowercase,
    );
    setState(() {});
  }

  _cahnged({
    bool? enableNumber,
    bool? enableSymbol,
    bool? letterUppercase,
    bool? letterLowercase,
  }) {
    enableNumber ??= _enableNumber;
    enableSymbol ??= _enableSymbol;
    letterUppercase ??= _letterUppercase;
    letterLowercase ??= _letterLowercase;

    if (!enableNumber &&
        !enableSymbol &&
        !letterUppercase &&
        !letterLowercase) {
      return;
    }
    _enableNumber = enableNumber;
    _letterUppercase = letterUppercase;
    _letterLowercase = letterLowercase;
    _enableSymbol = enableSymbol;
    updatePassword();
  }

  @override
  void initState() {
    password = randomPassword(length: _length.toInt());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
          value: _enableNumber,
          title: const Text("0~9"),
          onChanged: (value) => _cahnged(enableNumber: value),
        ),
        CheckboxListTile(
          value: _letterUppercase,
          title: const Text("a~z"),
          onChanged: (value) => _cahnged(letterUppercase: value),
        ),
        CheckboxListTile(
          value: _letterLowercase,
          title: const Text("A~Z"),
          onChanged: (value) => _cahnged(letterLowercase: value),
        ),
        CheckboxListTile(
          value: _enableSymbol,
          title: Text(t.symbol),
          onChanged: (value) => _cahnged(enableSymbol: value),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Slider(
            value: _length,
            label: "${_length.toInt()}",
            divisions: 48,
            min: 4,
            max: 48,
            onChanged: (value) {
              _length = value;
              updatePassword();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GestureDetector(
            onLongPress: () => writeClipboard(password),
            child: MatchText(
              text: password,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Colors.red),
              matchs: [
                MatchHighlight(
                  regExp: RegExp(r"[a-zA-Z]+"),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                MatchHighlight(
                  regExp: RegExp(r"\d+"),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.blue),
                )
              ],
            ),
          ),
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
        labelText: widget.hitText,
      ),
      onTap: _editText,
    );
  }

  void _editText() {
    final t = I18n.of(context)!;

    final String lastValue = widget.controller.text;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.description),
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
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(t.save),
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
