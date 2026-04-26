# Fix Google Sign-In Configuration

The Google Sign-In functionality on Android is currently failing because the app is not properly configured with Google Services and the SHA-1 fingerprint is likely missing from the Google Cloud Console.

## User Review Required

> [!IMPORTANT]
> To complete the fix, you **MUST** perform these manual steps in the [Google Cloud Console](https://console.cloud.google.com/apis/credentials) or [Firebase Console](https://console.firebase.google.com/):
> 1. **Register SHA-1 Fingerprint**: Get your SHA-1 using `keytool` (see below) and add it to your Android Client ID in the console.
> 2. **Download `google-services.json`**: After registering the SHA-1, download this file and place it in `frontend/android/app/`.
> 3. **Get Web Client ID**: Copy the "Web Client ID" (usually ends in `.apps.googleusercontent.com`) and provide it to the backend and frontend.

## Proposed Changes

### Frontend (Android Configuration)

#### [MODIFY] [settings.gradle.kts](file:///d:/2.%20Organize/1.%20Projects/MiniProjectKPI_EWI/frontend/android/settings.gradle.kts)
- Add the Google Services plugin to the `plugins` block.

#### [MODIFY] [build.gradle.kts](file:///d:/2.%20Organize/1.%20Projects/MiniProjectKPI_EWI/frontend/android/app/build.gradle.kts)
- Apply the `com.google.gms.google-services` plugin.

### Frontend (Dart Code)

#### [MODIFY] [auth_provider.dart](file:///d:/2.%20Organize/1.%20Projects/MiniProjectKPI_EWI/frontend/lib/providers/auth_provider.dart)
- Update `GoogleSignIn` initialization to include `serverClientId` (Web Client ID) to ensure the backend can verify the ID token.

### Backend

#### [MODIFY] [.env](file:///d:/2.%20Organize/1.%20Projects/MiniProjectKPI_EWI/backend/.env) [NEW FIELD]
- Add `GOOGLE_CLIENT_ID` (Web Client ID) if not already present.

## Verification Plan

### Automated Tests
- Build the app again: `flutter build apk --release`.
- Verify if the `google-services.json` is detected during build.

### Manual Verification
1. Run `flutter run --release` on a physical device.
2. Attempt Google Login.
3. Check if the Google Sign-In dialog stays open and allows account selection.
4. Verify that the backend successfully validates the token and logs the user in.
