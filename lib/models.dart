import 'dart:typed_data';

class RoomItem {
  final String id, label, category, query;
  final double x, y, width, height;
  const RoomItem({
    required this.id,
    required this.label,
    required this.category,
    required this.query,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  factory RoomItem.fromJson(Map<String, dynamic> j) => RoomItem(
    id: j['id'] as String,
    label: j['label'] as String,
    category: j['category'] as String? ?? '',
    query: j['query'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    width: (j['width'] as num).toDouble(),
    height: (j['height'] as num).toDouble(),
  );
}

class Room {
  final String id, title, type, style, brief, country, sourcePath, status;
  final String? resultPath, error;
  final List<RoomItem> items;
  const Room({
    required this.id,
    required this.title,
    required this.type,
    required this.style,
    required this.brief,
    required this.country,
    required this.sourcePath,
    required this.status,
    required this.resultPath,
    required this.error,
    required this.items,
  });
  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: j['id'],
    title: j['title'],
    type: j['room_type'],
    style: j['style'],
    brief: j['brief'],
    country: j['country'],
    sourcePath: j['source_path'],
    status: j['status'],
    resultPath: j['result_path'],
    error: j['error'],
    items: (j['items'] as List? ?? [])
        .map((v) => RoomItem.fromJson(Map<String, dynamic>.from(v)))
        .toList(),
  );
  bool get working => ['queued', 'rendering', 'tagging'].contains(status);
}

String? imageMime(Uint8List bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) {
    return 'image/jpeg';
  }
  const png = [137, 80, 78, 71, 13, 10, 26, 10];
  if (List.generate(8, (i) => bytes[i] == png[i]).every((b) => b)) {
    return 'image/png';
  }
  if (String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

const roomTypes = [
  'Living room',
  'Bedroom',
  'Gaming studio',
  'Hall',
  'Office',
  'Dining room',
];
const styles = [
  'Modern vintage',
  'Minimal',
  'Japandi',
  'Industrial',
  'Bohemian',
  'Luxury',
];
const countries = {
  'pk': 'Pakistan',
  'in': 'India',
  'us': 'United States',
  'gb': 'United Kingdom',
  'ae': 'UAE',
};
