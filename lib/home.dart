import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'api.dart';
import 'main.dart' show StudioArt, showPrivacy;
import 'models.dart';
import 'room_view.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  final RoomApi api;
  const HomePage({super.key, required this.api});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  List<Room> rooms = [];
  Set<String> saved = {};
  bool loading = true;
  Object? error;
  @override
  void initState() {
    super.initState();
    refresh();
    recoverPhoto();
  }

  Future<void> recoverPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final data = await ImagePicker().retrieveLostData();
      if (mounted && data.files?.isNotEmpty == true) {
        openNew(initial: data.files!.first);
      }
    } catch (_) {
      /* User can pick the photo again. */
    }
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        widget.api.list(),
        widget.api.favourites(),
      ]);
      if (mounted) {
        setState(() {
          rooms = results[0] as List<Room>;
          saved = results[1] as Set<String>;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openNew({XFile? initial}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NewRoomPage(api: widget.api, initial: initial),
      ),
    );
    if (mounted) refresh();
  }

  Future<void> openRoom(Room room) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomPage(api: widget.api, initial: room),
      ),
    );
    if (mounted) refresh();
  }

  Future<void> toggleSave(Room room) async {
    final next = !saved.contains(room.id);
    try {
      await widget.api.favourite(room.id, next);
      if (mounted) {
        setState(() {
          next ? saved.add(room.id) : saved.remove(room.id);
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void account() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('Your studio', 'آپ کا اسٹوڈیو'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              widget.api.db.auth.currentUser?.email ?? '',
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(t('Photos & privacy', 'تصاویر اور رازداری')),
              onTap: () => showPrivacy(c),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(t('Sign out', 'سائن آؤٹ')),
              onTap: () async {
                Navigator.pop(c);
                try {
                  await widget.api.db.auth.signOut();
                } catch (e) {
                  if (mounted) showError(context, e);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(t('Delete account', 'اکاؤنٹ حذف کریں')),
              onTap: () async {
                Navigator.pop(c);
                if (!await confirm(
                  context,
                  t('Delete your account?', 'اکاؤنٹ حذف کریں؟'),
                  t(
                    'This permanently deletes your photos, designs and account.',
                    'آپ کی تمام تصاویر، ڈیزائن اور اکاؤنٹ مستقل حذف ہو جائیں گے۔',
                  ),
                )) {
                  return;
                }
                if (!mounted) return;
                final nav = Navigator.of(context, rootNavigator: true);
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const PopScope(
                    canPop: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
                try {
                  await widget.api.deleteAccount();
                } catch (e) {
                  if (mounted) showError(context, e);
                } finally {
                  if (nav.mounted) nav.pop();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final shown = tab == 2
        ? rooms.where((r) => saved.contains(r.id)).toList()
        : rooms;
    return Scaffold(
      appBar: AppBar(
        title: const Brand(),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: t('Account', 'اکاؤنٹ'),
            onPressed: account,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: t('Studio', 'اسٹوڈیو'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            label: t('My rooms', 'میرے کمرے'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: t('Saved', 'پسندیدہ'),
          ),
        ],
      ),
      floatingActionButton: tab == 0
          ? null
          : FloatingActionButton(
              onPressed: openNew,
              tooltip: t('New room', 'نیا کمرہ'),
              child: const Icon(Icons.add),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
            children: [
              if (tab == 0) ...[
                Text(
                  t('THE INTERIOR STUDIO', 'انٹیریئر ڈیزائن اسٹوڈیو'),
                  style: const TextStyle(
                    color: brass,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t('Make room\nfor possibility.', 'اپنی جگہ کو\nنیا روپ دیں۔'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    'A little inspiration. A space that feels like you.',
                    'آپ کی تصویر سے، آپ کی پسند کا ڈیزائن۔',
                  ),
                  style: const TextStyle(color: muted, fontSize: 16),
                ),
                const SizedBox(height: 24),
                const StudioArt(),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: openNew,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    t('Reimagine my room', 'میرے کمرے کا ڈیزائن بنائیں'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    '01  Add a photo    ·    02  Choose a mood    ·    03  Shop the details',
                    'تصویر دیں  •  انداز منتخب کریں  •  اشیا تلاش کریں',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 32),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tab == 2
                          ? t('Your favourites', 'آپ کی پسند')
                          : t('Your rooms', 'آپ کے کمرے'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text('${shown.length}', style: const TextStyle(color: brass)),
                ],
              ),
              const SizedBox(height: 16),
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (error != null) ...[
                Notice(
                  t(
                    'Rooms could not load. If this is the first setup, deploy the included database migration and Edge Function.',
                    'کمرے لوڈ نہیں ہوئے۔ پہلی بار سیٹ اپ میں ڈیٹابیس اور Edge Function فعال کرنا ضروری ہے۔',
                  ),
                ),
                TextButton(
                  onPressed: refresh,
                  child: Text(t('Try again', 'دوبارہ کوشش')),
                ),
              ] else if (shown.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffd9d2c4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        tab == 2
                            ? Icons.bookmark_outline
                            : Icons.chair_outlined,
                        size: 38,
                        color: brass,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tab == 2
                            ? t(
                                'Save a room to find it here.',
                                'کسی کمرے کو پسندیدہ بنائیں؛ وہ یہاں نظر آئے گا۔',
                              )
                            : t(
                                'Your first transformation starts with a photo.',
                                'پہلا ڈیزائن بنانے کے لیے کمرے کی تصویر دیں۔',
                              ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...shown
                    .take(tab == 0 ? 3 : 100)
                    .map(
                      (room) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => openRoom(room),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 170,
                                  child: RoomThumbnail(
                                    api: widget.api,
                                    path: room.resultPath ?? room.sourcePath,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    8,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              room.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 17,
                                              ),
                                            ),
                                            Text(
                                              room.working
                                                  ? t(
                                                      'Designing…',
                                                      'ڈیزائن بن رہا ہے…',
                                                    )
                                                  : room.status == 'failed'
                                                  ? t(
                                                      'Needs another try',
                                                      'دوبارہ کوشش درکار',
                                                    )
                                                  : room.style,
                                              style: const TextStyle(
                                                color: muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => toggleSave(room),
                                        tooltip: t('Save room', 'پسندیدہ'),
                                        icon: Icon(
                                          saved.contains(room.id)
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: brass,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomThumbnail extends StatefulWidget {
  final RoomApi api;
  final String path;
  const RoomThumbnail({super.key, required this.api, required this.path});
  @override
  State<RoomThumbnail> createState() => _RoomThumbnailState();
}

class _RoomThumbnailState extends State<RoomThumbnail> {
  late Future<String> url;
  @override
  void initState() {
    super.initState();
    url = widget.api.imageUrl(widget.path);
  }

  @override
  void didUpdateWidget(covariant RoomThumbnail old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) url = widget.api.imageUrl(widget.path);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: url,
    builder: (c, s) {
      if (s.hasData) {
        if (s.data!.startsWith('data:')) {
          return Image.memory(
            base64Decode(s.data!.split(',').last),
            fit: BoxFit.cover,
            errorBuilder: (_, e, st) =>
                const Center(child: Icon(Icons.image_not_supported_outlined)),
          );
        }
        return Image.network(
          s.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, e, st) =>
              const Center(child: Icon(Icons.image_not_supported_outlined)),
        );
      }
      return Center(
        child: s.hasError
            ? const Icon(Icons.image_not_supported_outlined)
            : const CircularProgressIndicator(strokeWidth: 2),
      );
    },
  );
}

class NewRoomPage extends StatefulWidget {
  final RoomApi api;
  final XFile? initial;
  const NewRoomPage({super.key, required this.api, this.initial});
  @override
  State<NewRoomPage> createState() => _NewRoomPageState();
}

class _NewRoomPageState extends State<NewRoomPage> {
  final title = TextEditingController(), brief = TextEditingController();
  final form = GlobalKey<FormState>();
  Uint8List? photo;
  String type = roomTypes.first,
      style = styles.first,
      country = 'pk',
      id = const Uuid().v4();
  bool consent = false, busy = false;
  @override
  void initState() {
    super.initState();
    if (widget.initial != null) load(widget.initial!);
  }

  @override
  void dispose() {
    title.dispose();
    brief.dispose();
    super.dispose();
  }

  Future<void> load(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 8 * 1024 * 1024) {
        throw const AppFailure('IMAGE_TOO_LARGE');
      }
      if (imageMime(bytes) == null) throw const AppFailure('INVALID_IMAGE');
      if (mounted) {
        setState(() {
          photo = bytes;
          id = const Uuid().v4();
        });
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (file != null) await load(file);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> create() async {
    if (!form.currentState!.validate() || photo == null || !consent) return;
    setState(() => busy = true);
    try {
      final room = await widget.api.create(
        id: id,
        bytes: photo!,
        title: title.text.trim(),
        type: type,
        style: style,
        brief: brief.text.trim(),
        country: country,
      );
      if (mounted) {
        Navigator.pushReplacement<void, void>(
          context,
          MaterialPageRoute(
            builder: (_) => RoomPage(api: widget.api, initial: room),
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
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(t('A fresh perspective', 'ایک نیا انداز')),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: busy,
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  t('Let’s meet your room.', 'اپنے کمرے سے متعارف کرائیں۔'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  t(
                    'A clear, wide photo works best. Keep windows and walls visible.',
                    'صاف اور کشادہ تصویر لیں۔ دیواریں اور کھڑکیاں نظر آنی چاہئیں۔',
                  ),
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 210,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xffe7e1d4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: photo == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: brass,
                            ),
                            const SizedBox(height: 12),
                            Text(t('Your room, before', 'آپ کا موجودہ کمرہ')),
                            const Text(
                              'JPG · PNG · WebP  /  8 MB',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        )
                      : Image.memory(photo!, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(t('Gallery', 'گیلری')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(t('Camera', 'کیمرہ')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: title,
                  maxLength: 90,
                  decoration: InputDecoration(
                    labelText: t('Name your room', 'کمرے کا نام'),
                    hintText: t('My cosy corner', 'میرا خوبصورت کمرہ'),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? t('Add a room name', 'کمرے کا نام لکھیں')
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  t('ROOM TYPE', 'کمرے کی قسم'),
                  style: const TextStyle(
                    color: brass,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: roomTypes
                      .map(
                        (v) => ChoiceChip(
                          label: Text(v),
                          selected: type == v,
                          onSelected: (_) => setState(() => type = v),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                Text(
                  t('CHOOSE A MOOD', 'پسندیدہ انداز'),
                  style: const TextStyle(
                    color: brass,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: styles
                      .map(
                        (v) => ChoiceChip(
                          label: Text(v),
                          selected: style == v,
                          onSelected: (_) => setState(() => style = v),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: brief,
                  maxLines: 4,
                  maxLength: 1200,
                  decoration: InputDecoration(
                    labelText: t('Your design brief', 'ڈیزائن کی ہدایات'),
                    hintText: t(
                      'Olive sofa, warm lamps, walnut shelves. Keep the window.',
                      'سبز صوفہ، گرم روشنی، لکڑی کی شیلف۔ کھڑکی برقرار رہے۔',
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? t(
                          'Tell us what you want to change',
                          'اپنی پسند کی تبدیلی لکھیں',
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: country,
                  decoration: InputDecoration(
                    labelText: t('Shop in', 'خریداری کا ملک'),
                  ),
                  items: countries.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => country = v!),
                ),
                const SizedBox(height: 18),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: consent,
                  onChanged: (v) => setState(() => consent = v ?? false),
                  title: Text(
                    t(
                      'I own or can use this photo and agree to send it to Gemini to create my design.',
                      'مجھے اس تصویر کے استعمال کا حق ہے اور میں ڈیزائن کے لیے اسے Gemini کو بھیجنے پر رضامند ہوں۔',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: busy || photo == null || !consent ? null : create,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    busy
                        ? t('Uploading your room…', 'تصویر اپ لوڈ ہو رہی ہے…')
                        : t('Create my design', 'میرا ڈیزائن بنائیں'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    'AI concepts may change details. Shopping finds are similar items, not guaranteed exact matches.',
                    'AI ڈیزائن میں کچھ تفصیلات بدل سکتی ہیں۔ خریداری کی تجاویز ملتی جلتی اشیا ہیں؛ عین وہی چیز ملنے کی ضمانت نہیں۔',
                  ),
                  style: const TextStyle(color: muted, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
