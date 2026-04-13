import 'dart:io';

import 'package:common_native_channel/common_native_channel.dart';
import 'package:flutter/material.dart';

class InstalledAppsPage extends StatefulWidget {
  const InstalledAppsPage({super.key});

  @override
  State<InstalledAppsPage> createState() => _InstalledAppsPageState();
}

class _InstalledAppsPageState extends State<InstalledAppsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installed Apps')),
      body: FutureBuilder<List<AppInfo>>(
        future: installedApps.getInstalledApps(),
        builder:
            (BuildContext buildContext, AsyncSnapshot<List<AppInfo>> snapshot) {
              return snapshot.connectionState == ConnectionState.done
                  ? snapshot.hasData
                        ? _buildListView(snapshot.data ?? [])
                        : _buildError()
                  : _buildProgressIndicator();
            },
      ),
    );
  }

  Widget _buildListView(List<AppInfo> apps) {
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) => _buildListItem(context, apps[index]),
    );
  }

  Widget _buildListItem(BuildContext context, AppInfo app) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Image.file(File(app.icon)),
        ),
        title: Text(app.name),
        subtitle: Text(app.getVersionInfo()),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(child: Text("Getting installed apps ...."));
  }

  Widget _buildError() {
    return Center(
      child: Text("Error occurred while getting installed apps ...."),
    );
  }
}
