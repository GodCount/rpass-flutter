import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:keepass_core/keepass_core.dart';
import 'package:remote_fs/remote_fs.dart';

import '../../i18n.dart';
import '../../kdbx/kdbx.dart';
import '../../remotes_fs/remote_fs.dart';
import '../../store/index.dart';
import '../../util/route.dart';
import '../../widget/extension_state.dart';
import '../../widget/infinite_rotate.dart';
import '../route.dart';

class _SyncAccountArgs extends PageRouteArgs {
  _SyncAccountArgs({super.key});
}

class SyncAccountRoute extends PageRouteInfo<_SyncAccountArgs> {
  SyncAccountRoute({Key? key}) : super(name, args: _SyncAccountArgs(key: key));

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
  void _setRemoteSyncCycle() {
    final t = I18n.of(context)!;

    final settings = Store.settings;

    GestureTapCallback? autoSavePop(Duration? delay) {
      return () {
        settings.setRemoteSyncCycle(delay);
        context.router.pop();
        setState(() {});
      };
    }

    showBottomSheetList(
      title: t.sync_cycle,
      children: [
        ListTile(
          title: Text(t.each_startup),
          trailing: settings.remoteSyncCycle == null
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(null),
        ),
        ListTile(
          title: Text(t.days(1)),
          trailing: settings.remoteSyncCycle == const Duration(days: 1)
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(const Duration(days: 1)),
        ),
        ListTile(
          title: Text(t.days(7)),
          trailing: settings.remoteSyncCycle == const Duration(days: 7)
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(const Duration(days: 7)),
        ),
        ListTile(
          title: Text(t.days(30)),
          trailing: settings.remoteSyncCycle == const Duration(days: 30)
              ? const Icon(Icons.check)
              : null,
          onTap: autoSavePop(const Duration(days: 30)),
        ),
      ],
    );
  }

  void _setRemoteSyncCilent(RemoteType type) async {
    final t = I18n.of(context)!;

    final result = await context.router.push(
      AuthRemoteFsRoute(
        config: Store.kdbx.syncController.config?.toJson(),
        type: type,
      ),
    );

    if (result == null || result is! RemoteFileConfig) return;

    final result2 = await context.router.push(
      SelectRemoteFileRoute(config: result),
    );

    if (result2 == null || result2 is! RemoteFileConfig) return;

    try {
      await Store.kdbx.syncController.setRemoteFileConfig(context, result2);

      if (Store.kdbx.syncController.lastError == null) {
        final kdbxProvider = Store.kdbx;
        EntryData? entry = await kdbxProvider.getSyncEntryData();

        if (entry != null &&
            Store.kdbx.syncController.config ==
                RemoteFileKdbxEntryField.fromKdbx(entry)) {
          return;
        }

        if (entry != null ||
            await showConfirmDialog(
              title: t.save,
              message: t.save_sync_account_subtitle,
            )) {
          entry ??= kdbxProvider.kdbx!.newEntry()
            ..fields[KdbxKeyCommon.TITLE] = FieldValue.plaintext(t.sync_config);

          for (final item
              in Store.kdbx.syncController.config!.toKdbx().entries) {
            entry.fields[item.key] = item.value;
          }

          await kdbxAction(KdbxAction.updateSyncEntry(entry));
          Store.kdbx.syncController.sync(context);
        }
      }
    } catch (e, s) {
      showError(e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = I18n.of(context)!;

    final remoteSyncCycle = Store.settings.remoteSyncCycle;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: autoBack(),
        title: Text(t.sync_settings),
      ),
      body: ListenableBuilder(
        listenable: Store.kdbx.syncController,
        builder: (context, child) {
          return ListView(
            children: [
              ListTile(
                title: Text(t.sync),
                subtitle: Text(t.close_local_sync_subtitle),
                enabled: !Store.kdbx.syncController.isSyncing,
                onTap: () async {
                  await Store.settings.setEnableRemoteSync(
                    !Store.settings.enableRemoteSync,
                  );
                  setState(() {});
                },
                trailing: Store.settings.enableRemoteSync
                    ? const Icon(Icons.check)
                    : null,
              ),
              ListTile(
                onTap: _setRemoteSyncCycle,
                enabled: Store.settings.enableRemoteSync,
                title: Text(t.sync_cycle),
                trailing: Text(
                  remoteSyncCycle == null
                      ? t.each_startup
                      : t.days(remoteSyncCycle.inDays),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Store.settings.enableRemoteSync
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
              ),
              ListTile(
                title: const Text("WebDAV"),
                subtitle: Text(t.sync_note_subtitle),
                enabled:
                    !Store.kdbx.syncController.isSyncing &&
                    Store.settings.enableRemoteSync,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () => _setRemoteSyncCilent(.webdav),
                trailing: InfiniteRotateWidget(
                  enabled: Store.kdbx.syncController.isSyncing,
                  child: IconButton(
                    onPressed:
                        !Store.kdbx.syncController.isSyncing &&
                            Store.settings.enableRemoteSync &&
                            Store.kdbx.syncController.config != null
                        ? () => Store.kdbx.syncController.sync(context)
                        : null,
                    onLongPress:
                        !Store.kdbx.syncController.isSyncing &&
                            Store.settings.enableRemoteSync &&
                            Store.kdbx.syncController.config != null
                        ? () => Store.kdbx.syncController.sync(
                            context,
                            forceMerge: true,
                          )
                        : null,
                    icon: const Icon(Icons.sync),
                  ),
                ),
              ),
              if (Store.kdbx.syncController.lastError != null)
                ListTile(
                  title: Text(t.sync_error_log),
                  subtitle: Text("${Store.kdbx.syncController.lastError}"),
                  onTap: () {
                    showError(Store.kdbx.syncController.lastError!);
                  },
                ),
              if (Store.kdbx.syncController.lastMergeLog != null)
                Theme(
                  data: ThemeData(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(t.sync_merge_log),
                    children: _buildMergeTile(
                      Store.kdbx.syncController.lastMergeLog!,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildMergeTile(MergeLog mergeLog) {
    final t = I18n.of(context)!;

    final deleted = mergeLog.events.where((item) => item.eventType == .deleted);
    final created = mergeLog.events.where((item) => item.eventType == .created);
    final updated = mergeLog.events.where((item) => item.eventType == .updated);
    final locationUpdated = mergeLog.events.where(
      (item) => item.eventType == .locationUpdated,
    );

    return [
      if (mergeLog.warnings.isNotEmpty)
        ListTile(
          dense: true,
          isThreeLine: true,
          title: Text(t.warn),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mergeLog.warnings.map((item) {
                return Text(
                  item,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(color: Colors.amber),
                );
              }).toList(),
            ),
          ),
        ),

      if (deleted.isNotEmpty)
        ListTile(
          dense: true,
          isThreeLine: true,
          title: Text("Deleted"),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: deleted.map((item) {
                return Text(
                  item.target.toDisplay(),
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(color: Colors.redAccent),
                );
              }).toList(),
            ),
          ),
        ),
      if (created.isNotEmpty)
        ListTile(
          dense: true,
          isThreeLine: true,
          title: Text("Created"),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: created.map((item) {
                return Text(
                  item.target.toDisplay(),
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(color: Colors.greenAccent),
                );
              }).toList(),
            ),
          ),
        ),
      if (updated.isNotEmpty)
        ListTile(
          dense: true,
          isThreeLine: true,
          title: Text("Updated"),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: updated.map((item) {
                return Text(
                  item.target.toDisplay(),
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(color: Colors.amber),
                );
              }).toList(),
            ),
          ),
        ),
      if (locationUpdated.isNotEmpty)
        ListTile(
          dense: true,
          isThreeLine: true,
          title: Text("LocationUpdated"),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              spacing: 6,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: locationUpdated.map((item) {
                return Text(
                  item.target.toDisplay(),
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: TextStyle(color: Colors.amber),
                );
              }).toList(),
            ),
          ),
        ),
    ];
  }
}

extension _MergeEventTargetString on MergeEventTarget {
  String toDisplay() {
    switch (this) {
      case MergeEventTarget_Entry():
        return "Entry($field0)";
      case MergeEventTarget_Group():
        return "Group($field0)";
      case MergeEventTarget_Icon():
        return "Icon($field0)";
    }
  }
}
