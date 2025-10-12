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

[√] Flutter (Channel stable, 3.35.5, on Microsoft Windows [版本 10.0.26100.6584], locale zh-CN) [361ms]
    • Flutter version 3.35.5 on channel stable at E:\flutter\flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision ac4e799d23 (13 days ago), 2025-09-26 12:05:09 -0700
    • Engine revision d3d45dcf25
    • Dart version 3.9.2
    • DevTools version 2.48.0
    • Feature flags: enable-web, enable-linux-desktop, enable-macos-desktop, enable-windows-desktop, enable-android, enable-ios, cli-animations, enable-lldb-debugging

[√] Windows Version (11 专业版 64-bit, 24H2, 2009) [1,281ms]

[√] Android toolchain - develop for Android devices (Android SDK version 35.0.0) [18.4s]
    • Android SDK at E:\Android\Sdk
    • Emulator version 36.1.9.0 (build_id 13823996) (CL:N/A)
    • Platform android-36, build-tools 35.0.0
    • Java binary at: C:\Program Files\Android\Android Studio\jbr\bin\java
      This is the JDK bundled with the latest Android Studio installation on this machine.
      To manually set the JDK path, use: `flutter config --jdk-dir="path/to/jdk"`.
    • Java version OpenJDK Runtime Environment (build 17.0.10+0--11609105)
    • All Android licenses accepted.

[√] Chrome - develop for the web [130ms]
    • Chrome at C:\Program Files\Google\Chrome\Application\chrome.exe

[√] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.10.3) [129ms]
    • Visual Studio at C:\Program Files\Microsoft Visual Studio\2022\Community
    • Visual Studio Community 2022 version 17.10.35013.160
    • Windows 10 SDK version 10.0.22621.0

[√] Android Studio (version 2024.1) [40ms]
    • Android Studio at C:\Program Files\Android\Android Studio
    • Flutter plugin can be installed from:
       https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin can be installed from:
       https://plugins.jetbrains.com/plugin/6351-dart
    • Java version OpenJDK Runtime Environment (build 17.0.10+0--11609105)

[√] IntelliJ IDEA Community Edition (version 2024.1) [38ms]
    • IntelliJ at C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2024.1.4
    • Flutter plugin can be installed from:
       https://plugins.jetbrains.com/plugin/9212-flutter
    • Dart plugin version 241.17890.8

[√] VS Code (version 1.104.3) [8ms]
    • VS Code at C:\Users\<user>\AppData\Local\Programs\Microsoft VS Code
    • Flutter extension version 3.120.0

[√] Connected device (3 available) [269ms]
    • Windows (desktop) • windows • windows-x64    • Microsoft Windows [版本 10.0.26100.6584]
    • Chrome (web)      • chrome  • web-javascript • Google Chrome 138.0.7204.101
    • Edge (web)        • edge    • web-javascript • Microsoft Edge 141.0.3537.57

[√] Network resources [11.8s]
    • All expected network resources are available.

• No issues found!

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
