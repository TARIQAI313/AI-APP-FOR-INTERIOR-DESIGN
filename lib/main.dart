import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api.dart';
import 'home.dart';
import 'theme.dart';

const authRedirect = 'com.reverie.reverie://login-callback/';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  String? startupError;
  if (url.isEmpty || key.isEmpty) {
    startupError = 'Build with --dart-define-from-file=config.json';
  } else {
    try {
      await Supabase.initialize(url: url, publishableKey: key);
    } catch (_) {
      startupError =
          'Could not initialize Supabase. Check config.json and your connection.';
    }
  }
  runApp(ReverieApp(startupError: startupError));
}

class ReverieApp extends StatelessWidget {
  final String? startupError;
  const ReverieApp({super.key, this.startupError});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: urdu,
    builder: (context, value, child) => MaterialApp(
      title: 'Reverie',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      locale: Locale(value ? 'ur' : 'en'),
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: startupError != null
          ? Scaffold(
              appBar: AppBar(
                title: const Brand(),
                actions: const [LanguageButton()],
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Notice(startupError!),
                ),
              ),
            )
          : const AuthGate(),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final db = Supabase.instance.client;
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordPage();
        }
        return db.auth.currentSession == null
            ? const AuthPage()
            : HomePage(api: RoomApi(db));
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool signup = false, busy = false, obscure = true;
  String? note;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (signup) {
        await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          emailRedirectTo: authRedirect,
        );
        if (mounted) {
          setState(
            () => note = t(
              'Check your inbox, confirm your email, then sign in.',
              'ای میل میں تصدیقی لنک کھولیں، پھر سائن اِن کریں۔',
            ),
          );
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reset() async {
    if (!email.text.contains('@')) {
      setState(() => note = t('Enter your email first.', 'پہلے ای میل لکھیں۔'));
      return;
    }
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.text.trim(),
        redirectTo: authRedirect,
      );
      if (mounted) {
        setState(
          () => note = t(
            'Open the password reset link from your email on this phone.',
            'اپنی ای میل کا پاس ورڈ ری سیٹ لنک اسی فون پر کھولیں۔',
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Brand(), actions: const [LanguageButton()]),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StudioArt(),
                  const SizedBox(height: 28),
                  Text(
                    t(
                      'A new chapter\nfor your space.',
                      'آپ کی جگہ،\nایک نیا انداز۔',
                    ),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      'Photograph it. Reimagine it. Find the pieces you love.',
                      'تصویر دیں، نیا ڈیزائن بنائیں اور پسندیدہ چیزیں تلاش کریں۔',
                    ),
                    style: const TextStyle(color: muted, fontSize: 16),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: t('Email', 'ای میل'),
                      prefixIcon: const Icon(Icons.alternate_email),
                    ),
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : t('Enter a valid email', 'درست ای میل درج کریں'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: password,
                    obscureText: obscure,
                    textDirection: TextDirection.ltr,
                    autofillHints: [
                      signup
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: t('Password', 'پاس ورڈ'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => v != null && v.length >= 8
                        ? null
                        : t('At least 8 characters', 'کم از کم 8 حروف'),
                  ),
                  const SizedBox(height: 18),
                  if (note != null) ...[
                    Notice(note!),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(
                      busy
                          ? t('Please wait…', 'براہِ کرم انتظار کریں…')
                          : signup
                          ? t('Create account', 'اکاؤنٹ بنائیں')
                          : t('Enter the studio', 'اسٹوڈیو کھولیں'),
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            signup = !signup;
                            note = null;
                          }),
                    child: Text(
                      signup
                          ? t(
                              'Already a member? Sign in',
                              'اکاؤنٹ موجود ہے؟ سائن اِن کریں',
                            )
                          : t(
                              'New here? Create an account',
                              'نئے صارف؟ اکاؤنٹ بنائیں',
                            ),
                    ),
                  ),
                  if (!signup)
                    TextButton(
                      onPressed: busy ? null : reset,
                      child: Text(t('Forgot password?', 'پاس ورڈ بھول گئے؟')),
                    ),
                  TextButton(
                    onPressed: () => showPrivacy(context),
                    child: Text(
                      t('Your photos & privacy', 'آپ کی تصاویر اور رازداری'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (password.text.length < 8) return;
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password.text),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(t('New password', 'نیا پاس ورڈ'))),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: password,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: t('At least 8 characters', 'کم از کم 8 حروف'),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy || password.text.length < 8 ? null : save,
            child: Text(t('Save password', 'پاس ورڈ محفوظ کریں')),
          ),
        ],
      ),
    ),
  );
}

void showPrivacy(BuildContext context) => showDialog<void>(
  context: context,
  builder: (c) => AlertDialog(
    title: Text(t('Your space stays yours', 'آپ کی جگہ، آپ کا اختیار')),
    content: SingleChildScrollView(
      child: Text(
        t(
          'Your original and generated photos are stored in a private Supabase bucket. When you request a design, your photo and preferences are sent to Google Gemini for processing. Product descriptions are sent to SerpAPI when shopping is enabled; search links open Google or a store in your browser. Avoid uploading people or sensitive documents. You can delete individual rooms or your account from the app. Provider retention follows each provider’s own terms. AI renders are visual concepts; dimensions, structure, product matches and prices need independent checking.',
          'آپ کی اصل اور تیار شدہ تصاویر Supabase میں نجی طور پر محفوظ ہوتی ہیں۔ ڈیزائن بنانے پر تصویر اور ہدایات Google Gemini کو بھیجی جاتی ہیں۔ خریداری فعال ہو تو اشیا کی تفصیل SerpAPI کو بھیجی جاتی ہے۔ سرچ لنکس براؤزر میں Google یا اسٹور کھولتے ہیں۔ لوگوں یا حساس دستاویزات والی تصاویر اپ لوڈ نہ کریں۔ آپ کمرہ یا پورا اکاؤنٹ حذف کرسکتے ہیں۔ فراہم کنندہ اپنے ڈیٹا رکھنے کے اصول لاگو کرتا ہے۔ AI ڈیزائن ایک تصور ہے؛ پیمائش، عمارت، اشیا کی مماثلت اور قیمت کی الگ تصدیق کریں۔',
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(c),
        child: Text(t('Close', 'بند کریں')),
      ),
    ],
  ),
);

class StudioArt extends StatelessWidget {
  const StudioArt({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: t('Illustrated vintage sitting room', 'ونٹیج کمرے کی تصویری عکاسی'),
    child: Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xffe6d9c2),
        borderRadius: BorderRadius.circular(90).copyWith(
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
      ),
      child: CustomPaint(
        painter: _StudioPainter(),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _StudioPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint();
    final w = s.width, h = s.height;
    canvas.drawRect(
      Rect.fromLTWH(0, h * .78, w, h * .22),
      p..color = const Color(0xffc7b393),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .49, h * .88),
        width: w * .7,
        height: h * .19,
      ),
      p..color = const Color(0xffe9ddc7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .36, h * .13, w * .22, h * .39),
        const Radius.circular(50),
      ),
      p..color = const Color(0xfffaf5e9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .24, h * .49, w * .46, h * .27),
        const Radius.circular(18),
      ),
      p..color = ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .2, h * .65, w * .54, h * .19),
        const Radius.circular(12),
      ),
      p..color = const Color(0xff4f6552),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .28, h * .55, w * .12, h * .16),
        const Radius.circular(7),
      ),
      p..color = const Color(0xffc39c6c),
    );
    canvas.drawLine(
      Offset(w * .82, h * .79),
      Offset(w * .82, h * .25),
      p
        ..color = brass
        ..strokeWidth = 3,
    );
    final shade = Path()
      ..moveTo(w * .73, h * .4)
      ..lineTo(w * .77, h * .19)
      ..lineTo(w * .88, h * .19)
      ..lineTo(w * .92, h * .4)
      ..close();
    canvas.drawPath(shade, p..color = const Color(0xfff8ecd5));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .56, h * .86),
        width: w * .22,
        height: h * .06,
      ),
      p..color = const Color(0xff8b6445),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
