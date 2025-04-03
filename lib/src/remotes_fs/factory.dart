import 'auth_field.dart';
import 'remote_fs.dart';
import 'adapter/webdav.dart';

enum RemoteFsCase { webdav }

Future<RemoteClient> createRemoteFs({
  required RemoteFsCase type,
  required Map<String, AuthField> formData,
}) async {
  return switch (type) {
    RemoteFsCase.webdav => WebdavClient.create(formData),
  };
}

Map<String, AuthField> getRemoteFsAuthField(RemoteFsCase type) {
  return switch (type) {
    RemoteFsCase.webdav => WebdavConfig.authFields.map((key, value) => MapEntry(
          key,
          value.clone(),
        )),
  };
}
