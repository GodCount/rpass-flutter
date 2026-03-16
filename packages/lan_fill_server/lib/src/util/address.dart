import 'dart:io';

Future<List<InternetAddress>> getLocalInternetAddress() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );

  return interfaces.fold<List<InternetAddress>>(
    [],
    (data, item) => data..addAll(item.addresses),
  );
}

class IPv4Node {
  IPv4Node(this.num);

  String num;

  Map<String, IPv4Node> nodes = {};
}

Future<List<String>> matchSameDomainAddress(List<String> address) async {
  final localAddress = await getLocalInternetAddress();

  final Map<String, IPv4Node> nodes = localAddress.fold({}, (nodes, item) {
    final [a, b, c, d] = item.address.split(".");
    nodes[a] ??= IPv4Node(a);
    nodes[a]!.nodes[b] ??= IPv4Node(b);
    nodes[a]!.nodes[b]!.nodes[c] ??= IPv4Node(c);
    nodes[a]!.nodes[b]!.nodes[c]!.nodes[d] ??= IPv4Node(d);

    return nodes;
  });

  final List<(String, int)> results = address.fold([], (list, item) {
    final [a, b, c, d] = item.split(".");

    if (nodes[a] == null) return list;

    int weight = 0;

    if (nodes[a]!.nodes[b]?.nodes[c] != null) {
      weight = 2;
    } else if (nodes[a]!.nodes[b] != null) {
      weight = 1;
    }

    list.add((item, weight));

    return list;
  })..sort((a, b) => b.$2 - a.$2);

  return results.map((item) => item.$1).toList();
}
