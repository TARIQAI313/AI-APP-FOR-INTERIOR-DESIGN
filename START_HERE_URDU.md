# Reverie — ایپ چلانے کا طریقہ

اس پیکیج میں Flutter/Dart ایپ، Supabase backend، Android build فائلیں اور اردو/انگریزی انٹرفیس موجود ہے۔ **APK کامیابی کے ساتھ کلاؤڈ پر بلڈ ہو کر ڈاؤن لوڈ ہو چکی ہے۔**

- **تیار شدہ APK لوکیشن:** `C:\Users\Laptop Valley\Downloads\app-debug.apk` اور `app-debug.apk`
- **GitHub Repository:** https://github.com/TARIQAI313/AI-APP-FOR-INTERIOR-DESIGN
- **لائیو ویب پریویو:** `http://localhost:8080/` (یا فائل: `live_preview.html`)

---

## 1۔ APK چلانے کا طریقہ

تیار شدہ `app-debug.apk` فائل کو اپنے Android فون میں بھیجیں اور انسٹال کریں۔ اگر فون نامعلوم ذرائع سے انسٹالیشن کی اجازت مانگے تو اسے Allow کریں۔
کسی بھی وقت دوبارہ نئی APK بلڈ کرنے کے لیے GitHub Actions ورک فلو خودکار طور پر تیار ہے۔

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
