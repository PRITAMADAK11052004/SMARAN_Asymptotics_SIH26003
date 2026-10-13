# Android setup

The supplied Flutter project already contains the standard Android host. Keep that generated Android folder.

For biometric support, make sure `android/app/src/main/AndroidManifest.xml` contains:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

The `local_auth` plugin handles the biometric prompt. The audio is loaded from Flutter assets through `audioplayers`, so no React Native native module is required.

For production parity with the React Native version, the next native layer should add exact scheduled Android notifications/alarms and boot-reschedule behavior.
