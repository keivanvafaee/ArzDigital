#!/usr/bin/env bash
# Generates the Android platform files, patches the manifest and runs the app.
set -e
flutter create --platforms=android --project-name nova_trade --org app.novatrade .
M=android/app/src/main/AndroidManifest.xml
# INTERNET permission (needed for the Vazirmatn font download & opening links in release builds)
if ! grep -q "android.permission.INTERNET" "$M"; then
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
fi
sed -i 's#android:label="[^"]*"#android:label="Nova Trade"#' "$M"
flutter pub get
flutter run
