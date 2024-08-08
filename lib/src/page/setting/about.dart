import 'package:flutter/material.dart';
import 'package:rpass/src/rpass.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../i18n.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const routeName = "/about";

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.about),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Image(image: AssetImage('assets/icons/logo.png')),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  t.app_name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(RpassInfo.version),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(t.app_description),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextButton(
                  onPressed: () async => await launchUrl(
                      Uri.parse("https://github.com/GodCount/rpass-flutter"),
                      mode: LaunchMode.externalApplication),
                  child: Text(t.source_code_location("Github")),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton(
                  onPressed: () async => await launchUrl(
                      Uri.parse("https://gitee.com/do_yzr/rpass-flutter"),
                      mode: LaunchMode.externalApplication),
                  child: Text(t.source_code_location("Gitee")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
