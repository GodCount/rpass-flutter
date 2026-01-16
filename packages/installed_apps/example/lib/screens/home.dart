import 'package:flutter/material.dart';
import 'package:installed_apps_example/screens/app_list.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(title: const Text("Installed Apps Example"));
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      children: [
        _buildListItem(
          context,
          "Installed Apps",
          "Get installed apps on device. With options to exclude system app, get app icon & matching package name prefix.",
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AppListScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String title,
    String subtitle,
    Function() onTap,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: onTap,
        ),
      ),
    );
  }
}
