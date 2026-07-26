# Releasing

## Signing

Release builds are signed from `android/key.properties`, which is not in version
control. Without it the build still works — it falls back to debug signing — so a
fresh clone is never broken by a missing secret.

To sign your own builds, create a keystore:

```bash
keytool -genkeypair -v \
  -keystore android/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10950 \
  -alias upload
```

Then create `android/key.properties`:

```properties
storePassword=<the password you chose>
keyPassword=<the same password>
keyAlias=upload
storeFile=upload-keystore.jks
```

Write it as plain UTF-8 **without a byte order mark**. Some Windows editors and
`Out-File -Encoding utf8` add one, and Gradle then reads the first key as
`﻿storePassword` and reports `storePassword` as missing.

> **Back up the keystore and its password.** Android will not accept an update
> signed with a different key, so losing them means never being able to update
> an app that is already installed.

## Building

```bash
flutter build apk --release --split-per-abi
```

One APK per CPU architecture, roughly 15–19 MB each, rather than a single 51 MB
file carrying all three.

Output lands in `build/app/outputs/flutter-apk/`.

Verify the signature:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Publishing a release

```bash
gh release create v1.0.0 \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
  build/app/outputs/flutter-apk/app-x86_64-release.apk \
  --title "v1.0.0" --notes-file docs/release-notes/v1.0.0.md
```

Or upload the same three files through the GitHub web interface at
**Releases → Draft a new release**.

## App icon

The launcher icon is derived from the logo mark:

```bash
dart run tool/make_icon.dart
dart run flutter_launcher_icons
```

## Version numbers

Set in `pubspec.yaml` as `version: 1.0.0+1` — the part before `+` is the version
name, the part after is the build number, which must increase with every upload
to the Play Store.
