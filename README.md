# Rpass 2.0

快捷的密码记录程序

---

## 预览

![界面预览](docs/PixPin_2024-10-19_14-48-46.gif)
![界面预览](docs/PixPin_2024-10-19_14-51-35.gif)

## 功能支持

- [CHANGELOG](/CHANGELOG.md)

## 安全

-   采用 kdbx 加密存储
-   https://github.com/authpass/kdbx.dart

## 开发/测试

-   当前环境

```
flutter doctor -v

[√] Flutter (Channel stable, 3.22.2, on Microsoft Windows [版本 10.0.26120.1542], locale zh-CN)
    • Flutter version 3.22.2 on channel stable at E:\flutter\flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 761747bfc5 (5 months ago), 2024-06-05 22:15:13 +0200
    • Engine revision edd8546116
    • Dart version 3.4.3
    • DevTools version 2.34.3

[√] Windows Version (Installed version of Windows is version 10 or higher)

[√] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
    • Android SDK at E:\Android\Sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: C:\Program Files\Android\Android Studio\jbr\bin\java
    • Java version OpenJDK Runtime Environment (build 17.0.10+0--11609105)
    • All Android licenses accepted.

[√] Chrome - develop for the web
    • Chrome at C:\Program Files\Google\Chrome\Application\chrome.exe

[√] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.10.3)
    • Visual Studio at C:\Program Files\Microsoft Visual Studio\2022\Community
    • Visual Studio Community 2022 version 17.10.35013.160
    • Windows 10 SDK version 10.0.22621.0

[√] Android Studio (version 2024.1)
    • Android Studio at C:\Program Files\Android\Android Studio
    • Flutter plugin can be installed from:
       https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin can be installed from:
       https://plugins.jetbrains.com/plugin/6351-dart
    • Java version OpenJDK Runtime Environment (build 17.0.10+0--11609105)

[√] IntelliJ IDEA Community Edition (version 2024.1)
    • IntelliJ at C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2024.1.4
    • Flutter plugin can be installed from:
       https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin version 241.17890.8

[√] VS Code (version 1.94.2)
    • VS Code at C:\Users\<user>\AppData\Local\Programs\Microsoft VS Code
    • Flutter extension version 3.98.0

[√] Connected device (3 available)
    • Windows (desktop) • windows • windows-x64    • Microsoft Windows [版本 10.0.26120.1542]
    • Chrome (web)      • chrome  • web-javascript • Google Chrome 128.0.6613.84
    • Edge (web)        • edge    • web-javascript • Microsoft Edge 130.0.2849.46

[!] Network resources
    X A network error occurred while checking "https://maven.google.com/": 信号灯超时时间已到
```

-   安装依赖

```bash
flutter pub get
```

-   生成 gen_l10n

```bash
flutter gen-l10n
```

-   运行项目

```bash
flutter run
```
