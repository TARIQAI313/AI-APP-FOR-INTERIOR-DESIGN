import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api.dart';

const ink = Color(0xff263c32),
    paper = Color(0xfff5f0e7),
    brass = Color(0xffa57c42),
    muted = Color(0xff706e64);
final urdu = ValueNotifier<bool>(true);
String t(String en, String ur) => urdu.value ? ur : en;
ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ink,
    brightness: Brightness.light,
    surface: paper,
    primary: ink,
    secondary: brass,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    fontFamily: 'Manrope',
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        height: 1.25,
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffddd7cb)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xffddd7cb)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xfffcfaf6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xffe5dece)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: Color(0xffd6d2c4)),
    ),
  );
}

String failureMessage(Object e) {
  if (e is AuthException) {
    return t(
      'Please check your email, password and email confirmation. ${e.message}',
      'ای میل، پاس ورڈ اور ای میل کی تصدیق چیک کریں۔ ${e.message}',
    );
  }
  final code = e is AppFailure ? e.code : '';
  return switch (code) {
    'AI_NOT_CONFIGURED' => t(
      'The studio needs its AI key. Ask the owner to add GEMINI_API_KEY in Supabase Secrets.',
      'AI key ابھی شامل نہیں۔ مالک Supabase Secrets میں GEMINI_API_KEY شامل کرے۔',
    ),
    'ACTIVE_ROOM' => t(
      'A design is already processing. Open it from My rooms.',
      'ایک ڈیزائن پہلے سے بن رہا ہے۔ اسے میرے کمرے سے کھولیں۔',
    ),
    'DAILY_LIMIT' => t(
      'Today’s design limit is reached. Please try tomorrow.',
      'آج کی ڈیزائن حد مکمل ہوگئی ہے۔ کل دوبارہ کوشش کریں۔',
    ),
    'IMAGE_TOO_LARGE' => t(
      'Choose an image smaller than 8 MB.',
      '8 MB سے چھوٹی تصویر منتخب کریں۔',
    ),
    'INVALID_IMAGE' => t(
      'Choose a JPEG, PNG or WebP photo.',
      'JPEG، PNG یا WebP تصویر منتخب کریں۔',
    ),
    'EMAIL_NOT_CONFIRMED' => t(
      'Confirm your email before creating a design.',
      'ڈیزائن بنانے سے پہلے ای میل کی تصدیق کریں۔',
    ),
    'ACCOUNT_DELETING' => t(
      'Account deletion is pending. Retry Delete account from settings.',
      'اکاؤنٹ حذف کرنے کا عمل باقی ہے۔ ترتیبات سے دوبارہ حذف کریں۔',
    ),
    _ => t(
      'Could not complete this request. Check your connection and try again.',
      'درخواست مکمل نہ ہوسکی۔ کنکشن چیک کرکے دوبارہ کوشش کریں۔',
    ),
  };
}

void showError(BuildContext context, Object e) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(failureMessage(e))));

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Text(
    'reverie.',
    textDirection: TextDirection.ltr,
    style: TextStyle(
      fontFamily: 'DMSerifDisplay',
      fontSize: 34,
      letterSpacing: -1,
      color: ink,
    ),
  );
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: urdu,
    builder: (context, value, child) => TextButton(
      onPressed: () => urdu.value = !value,
      child: Text(value ? 'EN' : 'اردو'),
    ),
  );
}

class Notice extends StatelessWidget {
  final String message;
  final IconData icon;
  const Notice(this.message, {this.icon = Icons.info_outline, super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: brass.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: brass, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(t('Cancel', 'منسوخ')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(t('Delete', 'حذف کریں')),
          ),
        ],
      ),
    ) ??
    false;
