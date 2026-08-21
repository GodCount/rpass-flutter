abstract class FormatTransform {
  String get name;

  List<Map<String, String>> import(List<Map<String, dynamic>> input);

  List<Map<String, dynamic>> export(List<Map<String, String>> input);
}
