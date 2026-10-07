# Reverie — ایپ چلانے کا طریقہ

اس پیکیج میں Flutter/Dart ایپ، Supabase backend، Android build فائلیں اور اردو/انگریزی انٹرفیس موجود ہیں۔ **ابھی تیار APK موجود نہیں؛ GitHub build بھی نہیں چلایا گیا۔** یہاں دستیاب ماحول میں Flutter SDK/build مکمل نہیں ہوسکا۔ اصل AI سروس بھی ابھی deploy نہیں ہوئی۔

آپ کا Supabase URL اور public key شامل ہیں۔ 7 اکتوبر 2026 کی جانچ میں Auth کنکشن درست تھا، لیکن ایپ کا ڈیٹابیس اور `design-api` Edge Function موجود نہیں تھے۔ صرف public key سے backend deploy نہیں کیا جاسکتا؛ اس کے لیے project کے مالک کی رسائی درکار ہے۔

## 1۔ APK بنائیں

### GitHub کے ذریعے

1. ZIP کھولیں۔ `reverie` فولڈر کے اندر کی فائلیں GitHub repository کے اصل فولڈر میں ڈالیں۔ `pubspec.yaml` براہ راست root میں ہو۔ `.github` فولڈر بھی ضرور شامل کریں۔
2. GitHub میں **Actions → Build Android APK → Run workflow** دبائیں۔
3. کامیاب build کے بعد اسی صفحے کے **Artifacts** میں `Reverie-Android-Debug` ڈاؤن لوڈ کریں۔
4. اس ZIP کے اندر سے `app-debug.apk` نکال کر Android فون میں انسٹال کریں۔ Android اجازت مانگے تو APK کھولنے والی ایپ کے لیے installation کی اجازت دیں۔

اس طریقے میں GitHub آپ کے لیے Flutter/Android build ماحول تیار کرتا ہے۔ صرف فائلیں اپ لوڈ کرنے سے build شروع نہیں ہوتا؛ Run workflow دبانا ضروری ہے۔ ناکام build کی صورت میں متعلقہ step کا error دیکھیں۔ کوئی تیار APK اس source ZIP میں شامل نہیں۔

### اپنے کمپیوٹر پر

Flutter 3.47.6، Android Studio/SDK اور Java 21 نصب ہوں اور Flutter کمانڈ چلتی ہو تو Windows پر `BUILD_ANDROID.bat` کھولیں۔ Mac/Linux پر `bash BUILD_ANDROID.sh` چلائیں۔ کامیابی پر APK یہاں ہوگا:

`build/app/outputs/flutter-apk/app-debug.apk`

یہ testing کا debug APK ہوگا۔ Play Store کے لیے اپنی signing key اور release build ضروری ہے؛ تفصیل `README.md` میں ہے۔

## 2۔ Supabase backend فعال کریں

Supabase CLI نصب کرنے کے بعد `reverie` فولڈر میں terminal کھولیں اور اپنے project کے مالک والے اکاؤنٹ سے چلائیں:

```sh
supabase login
supabase link --project-ref uwmguhpoxwjpidqoknku
supabase db push --dry-run
supabase db push
```

اگر اسی project میں پہلے سے دوسری ایپ یا انہی ناموں کی tables ہیں تو migration پہلے پڑھیں۔ `--dry-run` مجوزہ migrations دکھاتا ہے؛ اگلی کمانڈ انہیں لاگو کرتی ہے۔ یہ کمانڈز اس handoff کے دوران آپ کے project پر نہیں چلائی گئیں۔

## 3۔ AI key محفوظ کریں اور فنکشن deploy کریں

Google AI Studio کی Gemini API key کو Supabase Dashboard → **Edge Functions → Secrets** میں `GEMINI_API_KEY` کے نام سے محفوظ کریں۔ متعلقہ image model کی رسائی اور billing درکار ہوسکتی ہے۔ key چیٹ میں بھیجنے کی ضرورت نہیں۔ پھر terminal میں چلائیں:

```sh
supabase functions deploy design-api
```

اختیاری `SERPAPI_KEY` شامل کرنے سے API کے ذریعے ملتی جلتی مصنوعات کے cards مل سکتے ہیں۔ اس کے بغیر Google/marketplace search links دستیاب رہتے ہیں۔ AI کی بنائی ہوئی چیز کے عین وہی ماڈل یا قیمت ملنے کی ضمانت نہیں۔ باقی secrets اور model settings کی فہرست `README.md` میں ہے۔

## 4۔ ای میل لنک اور فون پر آزمائش

Supabase → **Authentication → URL Configuration → Redirect URLs** میں یہ شامل کریں:

`com.reverie.reverie://login-callback/`

ای میل تصدیق فعال رکھیں۔ انسٹال شدہ ایپ میں اکاؤنٹ بنائیں، ای میل کی تصدیق کریں، پھر کمرے کی تصویر اور ہدایات دیں۔ ڈیزائن بننے پر پہلے/بعد کی تصویر دیکھی جاسکتی ہے اور تصویر پر نمبر یا چیز کے نام کو دبا کر خریداری کے links کھلتے ہیں۔

پہلا اصل AI ڈیزائن، shopping results، پاس ورڈ reset اور deletion فون پر آزمائیں۔ ابھی یہ live آزمائشیں نہیں ہوئیں۔ مکمل جانچ کی حالت `VALIDATION.md` میں درج ہے۔

`config.public.json` اور `config.json` میں صرف public client configuration ہے۔ Gemini key، Supabase service-role key اور signing keystore ان فائلوں میں شامل نہ کریں۔
