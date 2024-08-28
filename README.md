# Rpass

极简的密码记录程序

---

## 预览

![界面预览](docs/PixPin_2024-08-03_21-14-40.gif)


## 功能支持

- [x] 安全问题 (遗忘主密码时使用)
- [x] 备注,标签
- [x] 一次性密码(OTP)
- [x] OTP 二维码识别
- [x] 生成密码
- [x] 账号克隆
- [x] 搜索
- [x] 明暗主题
- [x] 多语言 (中文, 英文 (gpt) )
- [x] 修改主密码
- [x] 修改安全问题
- [x] 导入密码 (火狐浏览器, 谷歌浏览器)
- [x] 导出密码 (火狐浏览器, 谷歌浏览器)
- [x] 导出自带格式密码文件(json),支持加密导出
- [ ] 后台遮罩界面
- [X] 指纹解锁
- [ ] 自动填充


## 安全

- 加密流程

![加密流程](docs/PixPin_2024-08-28_23-39-01.png)


## 开发/测试


- 当前 doctor
```bash
flutter doctor -v

[√] Flutter (Channel stable, 3.22.2, on Microsoft Windows [版本 10.0.19045.4170], locale zh-CN)
    • Flutter version 3.22.2 on channel stable at E:\flutter\flutter
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 761747bfc5 (8 weeks ago), 2024-06-05 22:15:13 +0200
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

[√] VS Code (version 1.90.2)
    • VS Code at C:\Users\do_yz\AppData\Local\Programs\Microsoft VS Code
    • Flutter extension version 3.94.0

[√] Connected device (3 available)
    • Windows (desktop) • windows • windows-x64    • Microsoft Windows [版本 10.0.19045.4170]
    • Chrome (web)      • chrome  • web-javascript • Google Chrome 127.0.6533.89
    • Edge (web)        • edge    • web-javascript • Microsoft Edge 126.0.2592.81

[!] Network resources
    X A network error occurred while checking "https://maven.google.com/": 信号灯超时时间已到


! Doctor found issues in 1 category.
```

- 安装依赖
```bash
flutter pub get
```

- 生成 gen_l10n
```bash
flutter gen-l10n
```
- 运行项目
```bash
flutter run
```