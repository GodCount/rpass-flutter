import 'package:flutter_test/flutter_test.dart';
import 'package:rpass/src/kdbx/common.dart';

void main() {
  group("解析搜索输入", () {
    final mapFieldTable = {
      "t": "Title",
      "title": "Title",
    };

    test("没有字段的搜索", () {
      String input = "这是个关键字 这还是个关键字";
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 2);
      expect(inputParse.objects[0].field, isNull);
      expect(inputParse.objects[0].value, "这是个关键字");
      expect(inputParse.objects[1].field, isNull);
      expect(inputParse.objects[1].value, "这还是个关键字");

      input = 'aa:"这是个关键字" title :关键字';
      inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 3);
      expect(inputParse.objects[0].field, isNull);
      expect(inputParse.objects[0].value, 'aa:"这是个关键字"');
      expect(inputParse.objects[1].field, isNull);
      expect(inputParse.objects[1].value, 'title');
      expect(inputParse.objects[2].field, isNull);
      expect(inputParse.objects[2].value, ':关键字');
    });

    test("冒号前空格", () {
      String input = "t: 关键字";
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, isNull);
      expect(inputParse.objects[0].value, "关键字");
    });

    test("正常字段搜索", () {
      String input = "  t:关键字        title:关键字   ";
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, mapFieldTable["t"]);
      expect(inputParse.objects[0].value, "关键字");

      input = 't:"关键字"';
      inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, mapFieldTable["t"]);
      expect(inputParse.objects[0].value, "关键字");
    });

    test("字段中包含字段", () {
      String input = "t:关键字title:关键字";
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, mapFieldTable["t"]);
      expect(inputParse.objects[0].value, "关键字title:关键字");
    });

    test("双引号包含空格", () {
      String input = 't:"关键字 关键字"';
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, mapFieldTable["t"]);
      expect(inputParse.objects[0].value, "关键字 关键字");
    });

    test("引号缺失", () {
      String input = 't:"关键字   关键字';
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 2);
      expect(inputParse.objects[0].field, mapFieldTable["t"]);
      expect(inputParse.objects[0].value, '"关键字');
      expect(inputParse.objects[1].field, isNull);
      expect(inputParse.objects[1].value, '关键字');

      input = 'aa t:关键字 "  关键字';
      inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 4);

      expect(inputParse.objects[0].field, isNull);
      expect(inputParse.objects[0].value, 'aa');
      expect(inputParse.objects[1].field, mapFieldTable["t"]);
      expect(inputParse.objects[1].value, '关键字');
      expect(inputParse.objects[2].field, isNull);
      expect(inputParse.objects[2].value, '"');
      expect(inputParse.objects[3].field, isNull);
      expect(inputParse.objects[3].value, '关键字');
    });

    test("被冒号包裹", () {
      String input = ':t:关键字';
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, isNull);
      expect(inputParse.objects[0].value, input);
    });

    test("被引号号包裹", () {
      String input = '" t:关键字 "';
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 1);
      expect(inputParse.objects[0].field, isNull);
      expect(inputParse.objects[0].value, " t:关键字 ");
    });

    test("重复字段", () {
      String input = 't:关键字 title:关键字 t:关键字 关键字 关键字 还是关键字';
      InputParse inputParse = InputParse.parse(input, mapFieldTable);
      expect(inputParse.objects.length, 3);
      expect(inputParse.objects[0].field, mapFieldTable["t"]);
      expect(inputParse.objects[0].value, "关键字");

      expect(inputParse.objects[1].field, isNull);
      expect(inputParse.objects[1].value, "关键字");

      expect(inputParse.objects[2].field, isNull);
      expect(inputParse.objects[2].value, "还是关键字");
    });
  });
}
