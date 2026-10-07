# Reverie — Android interior design studio

Flutter/Dart app with Supabase Auth, Postgres, private Storage and Edge Functions; Gemini image editing and object detection; optional SerpAPI shopping results. Modern vintage cream/olive/brass UI, bundled typography, Urdu/English and RTL support.

## Included

- Email signup/confirmation, sign-in and password recovery via Android deep links.
- Camera/gallery upload and lost-photo recovery, 8 MB limit and image-signature checks.
- Room type, style, natural-language brief, shopping country and upload consent.
- Real asynchronous generation: original photo → redesigned room → detected furniture/decor → clickable image regions and numbered pins.
- Uncropped before/after view, zoom, item list, similar product suggestions and Google/regional marketplace search links.
- History, favourites, room deletion and account/data deletion.
- Private images, database RLS, bearer authentication, idempotent requests, per-user quotas and one active job per user.

## Handoff status

This is a source-code handoff. **An APK has not been successfully compiled, and the included GitHub Actions workflow has not been run.** The Flutter SDK bootstrap/build could not be completed in the available workspace. Use the local or GitHub build route below; both stop if checks fail.

Your Supabase URL and public publishable key are configured in `config.json` and the tracked `config.public.json`. The read-only connection check on 7 October 2026 returned HTTP 200; email signup is enabled and confirmation required. This validates the URL/key pair, not a deployed backend. The rooms table and Edge Function were still absent at that check.

**The SQL migration and Edge Function still require deployment, and GEMINI_API_KEY must be added as a Supabase secret.** A publishable key cannot deploy database schemas, functions or secrets. No admin/provider secret is included. Read `VALIDATION.md` for actual test results and APK status. Live AI generation has not been tested with a funded provider account.

## Supabase setup

Install the Supabase CLI, then run from this folder:

```sh
supabase login
supabase link --project-ref uwmguhpoxwjpidqoknku
supabase db push --dry-run
supabase db push
```

Review the migration if your project already has a `rooms` bucket or these table names. This is an initial schema, not an automatic merge with another app. No remote migration has been run during this handoff.

In Supabase Dashboard → Edge Functions → Secrets add:

| Secret | Value |
| --- | --- |
| `GEMINI_API_KEY` | Your Google AI Studio key with image-generation access/billing |
| `IMAGE_MODEL` | `gemini-3.1-flash-image` |
| `VISION_MODEL` | `gemini-3.8-flash` |
| `DAILY_DESIGN_LIMIT` | `5` by default, UTC day |
| `SERPAPI_KEY` | Optional: enables current product cards; omit for search links only |

If you entered the secrets in the Dashboard, deploy the function with `supabase functions deploy design-api`. Alternatively copy `supabase/.env.example` to `supabase/.env.local`, enter secrets locally and run:

```sh
supabase secrets set --env-file supabase/.env.local
supabase functions deploy design-api
```

Supabase supplies `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` inside the hosted function. Never place the service-role, Gemini or SerpAPI secrets in Flutter, `config.json`, chat or version control.

Gateway JWT verification is disabled in `supabase/config.toml` for the publishable-key flow. **Every request still validates its bearer token with `admin.auth.getUser()` and requires a confirmed, non-anonymous account.** Do not remove that authentication check.

Under Supabase Authentication:

1. Enable email provider and confirmation.
2. Add `com.reverie.reverie://login-callback/` to URL Configuration → Redirect URLs for signup/recovery links.
3. Configure your Site URL and production email/SMTP. Test links on a phone with the app installed. For public release, upgrade to verified HTTPS App Links.

## Run and build

Developed with Flutter 3.47.6 / Dart 3.13.5. Packages require Dart 3.11 or newer. Install Android Studio, Platform 36, Build Tools 36.0.0, NDK 28.2.13676358 and JDK 21, then accept the Android SDK licenses. Flutter may install additional components.

```sh
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=config.json
flutter build apk --debug --dart-define-from-file=config.json
```

Connect a phone with USB debugging or start an emulator. Expected APK output: `build/app/outputs/flutter-apk/app-debug.apk`. On Windows double-click `BUILD_ANDROID.bat`; on Linux/macOS run `bash BUILD_ANDROID.sh`. These run dependency installation, analysis, tests and a debug APK build. Flutter must already be on PATH. Debug APKs are for testing, not Play Store release.

`config.json` contains only public project configuration and is ignored by Git. Build scripts restore it from `config.public.json` when absent. Replace both fields in both files when changing projects. No private provider or administrator secret belongs in either file.

### Build using GitHub Actions

1. Put the **contents of the `reverie` folder** in your GitHub repository root. `pubspec.yaml` and `.github/workflows/android-apk.yml` must be at the root, not nested inside another `reverie` folder. Include the `.github` directory when uploading.
2. Open the repository's **Actions → Build Android APK → Run workflow**. This is a manual-only workflow; uploading the source does not run it automatically.
3. Wait for a successful run. Download **Reverie-Android-Debug** from the run's Artifacts section, extract the download and install `app-debug.apk` on an Android test phone. Allow installation from the app you use to open the APK if Android asks.

The workflow installs pinned Flutter and Java, accepts Android SDK licenses, checks the app and uploads the APK only on success. It does not deploy Supabase. No Gemini, Supabase admin or signing secret is required for this debug build. You can override the two public settings with repository Actions variables named `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. An unsuccessful run produces no APK; its failing step supplies the build error. This workflow has been checked as source, not executed on a runner during this handoff.

CI debug builds may use a different development signing key on each run. If Android refuses an update because the signature changed, uninstall the earlier test build first. This removes its local app data.

### Play Store release

Create your upload keystore and configure `android/key.properties` using the example:

```sh
flutter build appbundle --release --dart-define-from-file=config.json
```

Release tasks stop without signing configuration. No private signing key/password is provided. Keep your keystore private and backed up.

## API

Signed-in clients invoke `design-api`. A publishable key is not a user access token.

| Action | Input | Result |
| --- | --- | --- |
| `create` | UUID `id`, `title`, `roomType`, `style`, `brief`, `country`, owner-scoped `sourcePath`, `consent:true` | HTTP 202 + room; same UUID is idempotent |
| `status` | `id` | Owner's current room, state, result path and items |
| `offers` | `id`, `itemId` | Similar listings when available and search links |
| `delete` | `id` | Deletes photos/record; blocks active jobs |
| `deleteAccount` | — | Blocks new jobs/uploads, removes images and user/cascading records |

States: queued → rendering → tagging → ready, or failed. Vision boxes are normalized `x,y,width,height` in 0..1 against the generated image. The photo is not cropped; pin positions scale with it. The numbered list also exposes overlapping objects.

## Practical limits

- Uses `EdgeRuntime.waitUntil`, not a durable queue. Image requests time out at 85 seconds, tagging at 30 seconds. Three-minute stale jobs recover on status/new-create requests. Move production/high-volume processing to durable workers with retries; respect the Edge plan's runtime limits.
- A tagging failure keeps the generated photo and shows a notice. AI does not reliably recognize every component or preserve every architectural detail.
- Suggested furniture is **similar**, not a verified exact match. SerpAPI may return Google product pages. Prices are provider listings and can change. Fallback links are searches, not fabricated products or purchase guarantees.
- No checkout/payment, affiliate contract, CAD export or room-measurement system is included. Check structure/dimensions with a professional before construction.
- Interrupted uploads before room creation can leave originals in Storage. Account deletion removes them too; add an age-based orphan cleanup job for production.
- Per-user quotas are included; billing/subscriptions and global spending caps are not. Set provider budgets for launch.
- Add your business/support details, hosted privacy policy and Play Console data declarations before public release.

## Tests

```sh
flutter analyze
flutter test
deno check supabase/functions/design-api/index.ts
deno test supabase/functions/design-api/core_test.ts
npm install --no-save @electric-sql/pglite@0.5.8
node scripts/check_database.mjs
```

The SQL harness uses isolated mock auth/storage schemas; it is not a deployed Supabase smoke test. Before inviting users, test two real users, private photos, confirmation/recovery, live generation/shopping and deletion on Android.

Run `python3 scripts/check_setup.py` to repeat the read-only public connection/deployment check.

Source: `lib/`, `android/`, `supabase/migrations/`, `supabase/functions/design-api/`. Font licenses: `assets/fonts/`.

Official references: [Flutter Android](https://docs.flutter.dev/deployment/android), [Supabase Flutter](https://supabase.com/docs/guides/getting-started/quickstarts/flutter), [Supabase secrets](https://supabase.com/docs/guides/functions/secrets), [Gemini image generation](https://ai.google.dev/gemini-api/docs/image-generation), [Gemini image understanding](https://ai.google.dev/gemini-api/docs/image-understanding), [SerpAPI shopping](https://serpapi.com/google-shopping-api).
