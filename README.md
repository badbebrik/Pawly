# Pawly

## Установка через APK

Скачайте APK: [pawly.apk](https://drive.google.com/file/d/1GLSQOSY1GK3nfhLFQIqE2IGOlA0oPXmW/view?usp=sharing)

На Android разрешите установку из неизвестных источников, затем откройте APK.

## Сборка из исходников

Установите Flutter SDK по официальной инструкции: https://docs.flutter.dev/get-started/install

```bash
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://pawly-app.ru
```

APK появится здесь:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## iOS

Для сборки на iOS нужен macOS, Xcode, установленный Flutter SDK.

Для симулятора:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://pawly-app.ru
```

Для реального iPhone подключите устройство и запустите release:

```bash
flutter run --release --dart-define=API_BASE_URL=https://pawly-app.ru
```
