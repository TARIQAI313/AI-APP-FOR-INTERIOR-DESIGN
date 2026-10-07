import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'models.dart';
import 'theme.dart';

class RoomPage extends StatefulWidget {
  final RoomApi api;
  final Room initial;
  const RoomPage({super.key, required this.api, required this.initial});
  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  late Room room;
  Timer? timer;
  bool polling = false, before = false, pins = true;
  Object? error;
  late Future<Map<String, String>> urls;
  @override
  void initState() {
    super.initState();
    room = widget.initial;
    urls = loadUrls();
    if (room.working) {
      timer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
      refresh();
    }
  }

  Future<Map<String, String>> loadUrls() async {
    final source = await widget.api.imageUrl(room.sourcePath);
    return {
      'source': source,
      if (room.resultPath != null)
        'result': await widget.api.imageUrl(room.resultPath!),
    };
  }

  Future<void> refresh() async {
    if (polling) return;
    polling = true;
    try {
      final updated = await widget.api.status(room.id);
      if (mounted) {
        setState(() {
          final changed = room.resultPath != updated.resultPath;
          room = updated;
          error = null;
          if (changed) urls = loadUrls();
        });
      }
      if (!updated.working) timer?.cancel();
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      polling = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> remove() async {
    if (!await confirm(
      context,
      t('Delete this room?', 'یہ کمرہ حذف کریں؟'),
      t(
        'Its original photo and design will be permanently removed.',
        'اصل تصویر اور ڈیزائن مستقل حذف ہو جائیں گے۔',
      ),
    )) {
      return;
    }
    try {
      await widget.api.delete(room.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void shop(RoomItem item) {
    final future = widget.api.offers(room.id, item.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .67,
        minChildSize: .4,
        maxChildSize: .93,
        builder: (c, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            Text(item.label, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(item.query, style: const TextStyle(color: muted)),
            const SizedBox(height: 16),
            Notice(
              t(
                'Similar finds. Confirm the size, colour, price and seller before purchasing.',
                'ملتی جلتی اشیا۔ خریداری سے پہلے سائز، رنگ، قیمت اور فروخت کنندہ چیک کریں۔',
              ),
              icon: Icons.shopping_bag_outlined,
            ),
            const SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>>(
              future: future,
              builder: (context, s) {
                if (s.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final data = s.data;
                final products = (data?['products'] as List? ?? []).cast<Map>();
                final links =
                    (data?['links'] as List? ??
                            [
                              {
                                'title': 'Google Shopping',
                                'url': Uri.https('www.google.com', '/search', {
                                  'q': item.query,
                                  'tbm': 'shop',
                                  'gl': room.country,
                                }).toString(),
                              },
                              {
                                'title': t(
                                  'Search all stores',
                                  'تمام اسٹورز میں تلاش',
                                ),
                                'url': Uri.https('www.google.com', '/search', {
                                  'q': item.query,
                                }).toString(),
                              },
                            ])
                        .cast<Map>();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (products.isNotEmpty) ...[
                      Text(
                        t('PRODUCT RESULTS', 'اشیا کی تلاش'),
                        style: const TextStyle(
                          color: brass,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...products.map(
                        (p) => Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(p['title'] as String),
                            subtitle: Text(
                              '${p['store'] ?? ''}\n${p['price'] ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.open_in_new, size: 20),
                            onTap: () => openLink(context, p['url'] as String),
                          ),
                        ),
                      ),
                    ] else
                      Text(
                        t(
                          'Explore current listings using these searches.',
                          'ان لنکس سے موجودہ اشیا تلاش کریں۔',
                        ),
                      ),
                    const SizedBox(height: 16),
                    ...links.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              openLink(context, p['url'] as String),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: Text(p['title'] as String),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          onPressed: () {
            refresh();
            setState(() => urls = loadUrls());
          },
          tooltip: t('Refresh', 'تازہ کریں'),
          icon: const Icon(Icons.refresh),
        ),
        if (!room.working)
          IconButton(
            onPressed: remove,
            tooltip: t('Delete', 'حذف کریں'),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(room.style)),
              Chip(label: Text(room.type)),
            ],
          ),
          const SizedBox(height: 12),
          if (room.working) ...[
            Notice(
              room.status == 'tagging'
                  ? t(
                      'Finding the furniture and finishing your shopping hotspots…',
                      'فرنیچر پہچان کر خریداری کے نشانات شامل ہو رہے ہیں…',
                    )
                  : t(
                      'Reimagining your room. This usually takes a minute or two. You can come back from My rooms.',
                      'آپ کے کمرے کا ڈیزائن بن رہا ہے۔ عموماً ایک دو منٹ لگتے ہیں۔ آپ میرے کمرے سے واپس آسکتے ہیں۔',
                    ),
              icon: Icons.auto_awesome,
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (error != null) ...[
            Notice(
              t(
                'Connection interrupted. We’ll keep checking while the design is processing.',
                'کنکشن میں رکاوٹ آئی ہے۔ ڈیزائن بننے کے دوران دوبارہ چیک ہوتا رہے گا۔',
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (room.status == 'failed') ...[
            Notice(
              room.error == 'AI_NOT_CONFIGURED'
                  ? failureMessage(const AppFailure('AI_NOT_CONFIGURED'))
                  : t(
                      'This design could not finish. Start a new design from the studio. If this repeats, the owner should check AI availability and credits.',
                      'یہ ڈیزائن مکمل نہ ہوسکا۔ اسٹوڈیو سے نیا ڈیزائن بنائیں۔ بار بار مسئلہ ہو تو مالک AI کی دستیابی اور کریڈٹ چیک کرے۔',
                    ),
            ),
            const SizedBox(height: 16),
          ],
          if (room.resultPath != null) ...[
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(t('Before', 'پہلے')),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(t('After', 'بعد میں')),
                      ),
                    ],
                    selected: {before},
                    onSelectionChanged: (s) => setState(() => before = s.first),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => pins = !pins),
                  tooltip: t('Show shopping pins', 'خریداری کے نشانات'),
                  isSelected: pins,
                  icon: const Icon(Icons.location_on_outlined),
                  selectedIcon: const Icon(Icons.location_on),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          FutureBuilder<Map<String, String>>(
            future: urls,
            builder: (context, s) {
              if (s.hasError) {
                return Notice(
                  t(
                    'Could not load the photo. Tap refresh above.',
                    'تصویر لوڈ نہیں ہوئی۔ اوپر تازہ کرنے کا بٹن دبائیں۔',
                  ),
                );
              }
              if (!s.hasData) {
                return const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final isResult = !before && s.data!['result'] != null;
              return ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: PhotoStage(
                  key: ValueKey(s.data![isResult ? 'result' : 'source']),
                  url: s.data![isResult ? 'result' : 'source']!,
                  items: isResult ? room.items : [],
                  pins: pins,
                  onTap: shop,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (room.resultPath != null)
            Text(
              t(
                'Tap a numbered detail to shop · Pinch to zoom',
                'خریداری کے لیے نمبر دبائیں • دو انگلیوں سے زوم کریں',
              ),
              style: const TextStyle(color: muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 28),
          if (room.status == 'ready' && room.items.isEmpty) ...[
            Notice(
              t(
                'Your design is ready, but automatic item tagging was unavailable. Try another design to get shopping pins.',
                'ڈیزائن تیار ہے، لیکن اشیا کی خودکار پہچان نہ ہوسکی۔ خریداری کے نشانات کے لیے دوسرا ڈیزائن آزمائیں۔',
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (room.items.isNotEmpty) ...[
            Text(
              t('The details make it yours.', 'وہ تفصیلات جو اسے خاص بنائیں۔'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t(
                '${room.items.length} detected pieces · Similar shopping suggestions',
                '${room.items.length} پہچانی گئی اشیا • ملتی جلتی تجاویز',
              ),
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 16),
            ...room.items.indexed.map(
              (pair) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ink,
                    foregroundColor: paper,
                    child: Text('${pair.$1 + 1}'),
                  ),
                  title: Text(pair.$2.label),
                  subtitle: Text(pair.$2.category),
                  trailing: const Icon(Icons.north_east, color: brass),
                  onTap: () => shop(pair.$2),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            t('YOUR BRIEF', 'آپ کی ہدایات'),
            style: const TextStyle(
              color: brass,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(room.brief),
          const SizedBox(height: 20),
          if (room.resultPath != null)
            Notice(
              t(
                'AI concept only. Verify dimensions and structural changes with a qualified professional before building.',
                'یہ AI کا تصور ہے۔ تعمیر سے پہلے پیمائش اور ساختی تبدیلیاں ماہر سے چیک کروائیں۔',
              ),
            ),
        ],
      ),
    ),
  );
}

Future<void> openLink(BuildContext context, String url) async {
  try {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw const AppFailure('INVALID_LINK');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const AppFailure('LINK_FAILED');
    }
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

/// Points stay within object bounds and keep small, overlapping objects usable.
List<Offset> pinPositions(List<RoomItem> items, Size size) {
  final output = List<Offset>.filled(items.length, Offset.zero);
  final placed = <Offset>[];
  final order = List.generate(items.length, (i) => i)
    ..sort(
      (a, b) => (items[a].width * items[a].height).compareTo(
        items[b].width * items[b].height,
      ),
    );
  for (final index in order) {
    final i = items[index];
    Offset? best;
    double score = -1;
    for (final dy in [0.0, -.25, .25, -.4, .4]) {
      for (final dx in [0.0, -.25, .25, -.4, .4]) {
        final p = Offset(
          ((i.x + i.width * (.5 + dx)) * size.width).clamp(
            17.0,
            math.max(17.0, size.width - 17),
          ),
          ((i.y + i.height * (.5 + dy)) * size.height).clamp(
            17.0,
            math.max(17.0, size.height - 17),
          ),
        );
        final distance = placed.isEmpty
            ? 999.0
            : placed.map((v) => (v - p).distance).reduce(math.min);
        if (distance > score) {
          score = distance;
          best = p;
        }
        if (distance >= 38) break;
      }
      if (score >= 38) break;
    }
    output[index] = best!;
    placed.add(best);
  }
  return output;
}

class PhotoStage extends StatefulWidget {
  final String url;
  final List<RoomItem> items;
  final bool pins;
  final ValueChanged<RoomItem> onTap;
  const PhotoStage({
    super.key,
    required this.url,
    required this.items,
    required this.pins,
    required this.onTap,
  });
  @override
  State<PhotoStage> createState() => _PhotoStageState();
}

class _PhotoStageState extends State<PhotoStage> {
  double ratio = 4 / 3;
  ImageStream? stream;
  ImageStreamListener? listener;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (stream == null) {
      stream = NetworkImage(
        widget.url,
      ).resolve(createLocalImageConfiguration(context));
      listener = ImageStreamListener((info, sync) {
        if (mounted) {
          setState(() => ratio = info.image.width / info.image.height);
        }
      }, onError: (Object error, StackTrace? trace) {});
      stream!.addListener(listener!);
    }
  }

  @override
  void dispose() {
    if (listener != null) stream?.removeListener(listener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: ratio,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final positions = pinPositions(widget.items, size);
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: GestureDetector(
            onTapUp: (details) {
              if (!widget.pins) return;
              final point = details.localPosition;
              final x = point.dx / size.width, y = point.dy / size.height;
              final hits =
                  widget.items
                      .where(
                        (i) =>
                            x >= i.x &&
                            x <= i.x + i.width &&
                            y >= i.y &&
                            y <= i.y + i.height,
                      )
                      .toList()
                    ..sort(
                      (a, b) =>
                          (a.width * a.height).compareTo(b.width * b.height),
                    );
              if (hits.isNotEmpty) widget.onTap(hits.first);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, e, s) => Center(
                    child: Text(t('Photo unavailable', 'تصویر دستیاب نہیں')),
                  ),
                ),
                if (widget.pins)
                  ...widget.items.indexed.map(
                    (pair) => Positioned(
                      left: positions[pair.$1].dx - 17,
                      top: positions[pair.$1].dy - 17,
                      width: 34,
                      height: 34,
                      child: Tooltip(
                        message: pair.$2.label,
                        child: Semantics(
                          button: true,
                          label: pair.$2.label,
                          child: Material(
                            color: paper,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: ink.withValues(alpha: .5),
                              ),
                            ),
                            elevation: 3,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => widget.onTap(pair.$2),
                              child: Center(
                                child: Text(
                                  '${pair.$1 + 1}',
                                  style: const TextStyle(
                                    color: ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
