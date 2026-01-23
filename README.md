# Rpass

[![GitHub (pre-)release](https://img.shields.io/github/release/GodCount/rpass-flutter/all.svg?style=flat-square)](https://github.com/GodCount/rpass-flutter/releases) [![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

**Rpass** 用 Flutter 实现的快捷密码记录应用。

> "Rpass" Full name is Record Password.

## 平台支持

| Linux | macOS | Windows | IOS | Android |
| :---: | :---: | :-----: | :-: | :-----: |
|  ⏳   |  ✅   |   ✅    | ⏳  |   ✅    |

## 安装

从[发布版本](https://github.com/GodCount/rpass-flutter/releases/latest)页面获取最新的版本。

## 开发

1. 通过 git 克隆代码库：

```
$ git clone --recursive https://github.com/GodCount/rpass-flutter.git
```

2. 切换到 `rpass-flutter` 目录

```
$ cd ~/rpass-flutter
```

3. 你可能需要 [rust](https://rust-lang.org/tools/install/)

    [enigo_flutter](https://github.com/GodCount/rpass-flutter/packages/enigo_flutter)

4. 安装依赖项

```
$ melos bs
```

### 运行应用

```
$ cd apps/rpass
$ flutter run -d macos / windows
```

## 许可证

[MIT](./LICENSE)
