@echo off
flutter create --platforms=android --project-name nova_trade --org app.novatrade .
powershell -Command "$m='android\app\src\main\AndroidManifest.xml'; $t=Get-Content $m -Raw; if($t -notmatch 'android.permission.INTERNET'){ $t=$t -replace '<application','<uses-permission android:name=\"android.permission.INTERNET\"/>`n    <application' }; $t=$t -replace 'android:label=\"[^\"]*\"','android:label=\"Nova Trade\"'; Set-Content $m $t"
flutter pub get
flutter run
