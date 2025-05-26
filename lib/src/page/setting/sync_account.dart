import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/adapter/webdav.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/infinite_rotate.dart';
import '../route.dart';

class _SyncAccountArgs extends PageRouteArgs {
  _SyncAccountArgs({super.key});
}

class SyncAccountRoute extends PageRouteInfo<_SyncAccountArgs> {
  SyncAccountRoute({
    Key? key,
  }) : super(
          name,
          args: _SyncAccountArgs(key: key),
        );

  static const name = "SyncAccountRoute";

  static final PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<_SyncAccountArgs>(
        orElse: () => _SyncAccountArgs(),
      );
      return SyncAccountPage(key: args.key);
    },
  );
}

class SyncAccountPage extends StatefulWidget {
  const SyncAccountPage({super.key});

  @override
  State<SyncAccountPage> createState() => _SyncAccountPageState();
}

class _SyncAccountPageState extends State<SyncAccountPage>
    with SecondLevelPageAutoBack<SyncAccountPage> {
  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;
    final store = Store.instance;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.sync_settings),
      ),
      body: ListenableBuilder(
        listenable: store.syncKdbx,
        builder: (context, child) {
          return ListView(
            children: [
              ListTile(
                title: Text(t.sync),
                subtitle: Text(t.close_local_sync_subtitle),
                enabled: !store.syncKdbx.isSyncing,
                onTap: () async {
                  await store.settings.setEnableRemoteSync(
                    !store.settings.enableRemoteSync,
                  );
                  setState(() {});
                },
                trailing: store.settings.enableRemoteSync
                    ? const Icon(Icons.check)
                    : null,
              ),
              ListTile(
                title: const Text("WebDAV"),
                subtitle: Text(t.sync_note_subtitle),
                enabled: !store.syncKdbx.isSyncing &&
                    store.settings.enableRemoteSync,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () async {
                  final result = await context.router.push(
                    AuthRemoteFsRoute(
                      config: store.syncKdbx.config ?? WebdavConfig(),
                    ),
                  );

                  if (result != null && result is WebdavClient) {
                    await store.syncKdbx.setWebdavClient(context, result);
                  }
                },
                trailing: InfiniteRotateWidget(
                  enabled: store.syncKdbx.isSyncing,
                  child: IconButton(
                    onPressed: !store.syncKdbx.isSyncing &&
                            store.settings.enableRemoteSync &&
                            store.syncKdbx.config != null
                        ? () => store.syncKdbx.sync(context)
                        : null,
                    onLongPress: !store.syncKdbx.isSyncing &&
                            store.settings.enableRemoteSync &&
                            store.syncKdbx.config != null
                        ? () => store.syncKdbx.sync(context, forceMerge: true)
                        : null,
                    icon: const Icon(Icons.sync),
                  ),
                ),
              ),
              if (store.syncKdbx.lastError != null)
                ListTile(
                  title: Text(t.sync_error_log),
                  subtitle: Text("${store.syncKdbx.lastError}"),
                  onTap: () {
                    showError(store.syncKdbx.lastError);
                  },
                ),
              if (store.syncKdbx.lastMergeContext != null)
                Theme(
                  data: ThemeData(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    title: Text(t.sync_merge_log),
                    children: _buildMergeTile(store.syncKdbx.lastMergeContext!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildMergeTile(MergeContext merge) {
    final t = I18n.of(context)!;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(merge.debugSummary()),
      ),
      if (merge.changes.isNotEmpty)
        ListTile(
          isThreeLine: true,
          title: Text(t.change),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: merge.changes.map((item) {
                return Text("[${item.debug}] ${item.object}");
              }).toList(),
            ),
          ),
        ),
      if (merge.warnings.isNotEmpty)
        ListTile(
          textColor: Colors.amber,
          isThreeLine: true,
          title: Text(t.warn),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: merge.warnings.map((item) {
                return Text(item.debug);
              }).toList(),
            ),
          ),
        ),
      if (merge.deletedObjects.isNotEmpty)
        ListTile(
          textColor: Theme.of(context).colorScheme.error,
          isThreeLine: true,
          title: Text(t.remove),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: merge.deletedObjects.entries.map((item) {
                return Text("${item.key}");
              }).toList(),
            ),
          ),
        ),
    ];
  }
}
