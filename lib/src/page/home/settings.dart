import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../component/toast.dart';
import '../../i18n.dart';
import '../page.dart';
import '../../store/index.dart';
import '../verify/security_question.dart';
import '../../model/rpass/question.dart';

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

    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.setting),
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
                  Text(t.theme, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(t.system),
              trailing: widget.store.settings.themeMode == ThemeMode.system
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.system);
              },
            ),
            ListTile(
              title: Text(t.light),
              trailing: widget.store.settings.themeMode == ThemeMode.light
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                widget.store.settings.setThemeMode(ThemeMode.light);
              },
            ),
            ListTile(
              shape: shape,
              title: Text(t.dark),
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
                  Text(t.language,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(widget.store.settings.locale != null
                  ? t.locale_name
                  : t.system),
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
                  Text(t.security,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(t.modify_password),
              onTap: _modifyPassword,
            ),
            ListTile(
              shape: shape,
              title: Text(t.modify_security_qa),
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
                  Text(t.backup, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              title: Text(t.import),
              onTap: () {
                Navigator.of(context).pushNamed(ImportAccountPage.routeName);
              },
            ),
            ListTile(
              shape: shape,
              title: Text(t.export),
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
                  Text(t.info, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            ListTile(
              shape: shape,
              title: Text(t.about),
              onTap: () {
                Navigator.of(context).pushNamed(AboutPage.routeName);
              },
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
    final GlobalKey<FormState> formState = GlobalKey<FormState>();
    String newPassword = "";

    final t = I18n.of(context)!;

    void onSetPassword() async {
      if (formState.currentState!.validate()) {
        try {
          await widget.store.verify.modifyPassword(newPassword);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } catch (e) {
          showToast(context, t.modify_password_throw(e.toString()));
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.modify_password),
          content: Form(
            key: formState,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  onChanged: (text) => newPassword = text,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: t.password,
                    hintText: t.input_num_password,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.length < 4
                      ? t.at_least_4digits
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.confirm_password,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty || value == newPassword
                            ? null
                            : t.password_not_equal,
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
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: onSetPassword,
              child: Text(t.modify),
            ),
          ],
        );
      },
    );
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
                    showToast(
                      context,
                      I18n.of(context)!.modify_security_qa_throw(
                        e.toString(),
                      ),
                    );
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
