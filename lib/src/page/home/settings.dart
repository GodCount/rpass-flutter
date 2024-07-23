import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/rpass_localizations.dart';

import '../../component/toast.dart';
import '../page.dart';
import '../../store/index.dart';
import '../verify/security_question.dart';
import '../../model/question.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});

  final Store store;

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
    );

    final t = RpassLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("设置"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.color_lens),
                  ),
                  Text("主题", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: const Text("系统"),
              trailing: widget.store.settings.themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.system);
              },
            ),
            ListTile(
              title: const Text("亮"),
              trailing: widget.store.settings.themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.light);
              },
            ),
            ListTile(
              shape: shape,
              title: const Text("暗"),
              trailing: widget.store.settings.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.dark);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.translate),
                  ),
                  Text("语言", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(
                  widget.store.settings.locale != null ? t.locale_name : "系统"),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pushNamed(ChangeLocalePage.routeName);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.security),
                  ),
                  Text("安全", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: const Text("修改密码"),
              onTap: _modifyPassword,
            ),
            ListTile(
              shape: shape,
              title: const Text("修改安全问题"),
              onTap: _modifyQuestion,
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.import_export),
                  ),
                  Text("备份", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: const Text("导入"),
              onTap: () {
                Navigator.of(context).pushNamed(ImportAccountPage.routeName);
              },
            ),
            ListTile(
              shape: shape,
              title: const Text("导出"),
              onTap: () {
                Navigator.of(context).pushNamed(ExportAccountPage.routeName);
              },
            ),
          ]),
          _cardColumn([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.touch_app),
                  ),
                  Text("信息", style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: const Text("关于"),
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _cardColumn(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6.0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _modifyPassword() {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formState = GlobalKey<FormState>();

    void onSetPassword() async {
      if (formState.currentState!.validate()) {
        try {
          await widget.store.verify.modifyPassword(controller.text);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          showToast(context, "密码修改异常: ${e.toString()}");
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("修改密码"),
          content: Form(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: "修改密码", border: OutlineInputBorder()),
                  validator: (value) {
                    return value == null || value.trim().isEmpty
                        ? "不能为空"
                        : value.length > 3
                            ? null
                            : "大于3位";
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "确认密码",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      return value == controller.text ? null : "不能为空";
                    },
                    onFieldSubmitted: (value) {
                      if (formState.currentState!.validate()) {
                        onSetPassword();
                      }
                    },
                  ),
                )
              ],
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
              onPressed: onSetPassword,
              child: const Text("修改"),
            ),
          ],
        );
      },
    ).then((value) {
      controller.dispose();
    });
  }

  void _modifyQuestion() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            scrollable: true,
            content: SecurityQuestion(
              initialList: widget.store.verify.questionList
                  .map((item) => QuestionAnswer(item.question, ""))
                  .toList(),
              onSubmit: (questions) async {
                if (questions != null) {
                  try {
                    await widget.store.verify.setQuestionList(questions);
                  } catch (e) {
                    showToast(context, "问题修改异常: ${e.toString()}");
                  }
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          );
        });
  }
}
