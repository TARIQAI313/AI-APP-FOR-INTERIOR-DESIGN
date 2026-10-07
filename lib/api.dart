import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class AppFailure implements Exception {
  final String code;
  const AppFailure(this.code);
}

class RoomApi {
  final SupabaseClient db;
  RoomApi(this.db);
  Future<Map<String, dynamic>> call(Map<String, dynamic> body) async {
    try {
      final result = await db.functions.invoke('design-api', body: body);
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['error'] != null) throw AppFailure(data['error'].toString());
      return data;
    } on FunctionException catch (e) {
      throw AppFailure(
        e.details is Map
            ? (e.details as Map)['error']?.toString() ?? 'REQUEST_FAILED'
            : 'REQUEST_FAILED',
      );
    }
  }

  Future<List<Room>> list() async {
    final data = await db
        .from('rooms')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return data.map(Room.fromJson).toList();
  }

  Future<Set<String>> favourites() async {
    final data = await db.from('favourites').select('room_id');
    return data.map((j) => j['room_id'] as String).toSet();
  }

  Future<void> favourite(String id, bool selected) async {
    if (selected) {
      await db.from('favourites').insert({
        'user_id': db.auth.currentUser!.id,
        'room_id': id,
      });
    } else {
      await db.from('favourites').delete().eq('room_id', id);
    }
  }

  Future<String> imageUrl(String path) =>
      db.storage.from('rooms').createSignedUrl(path, 3600);
  Future<Room> status(String id) async => Room.fromJson(
    Map<String, dynamic>.from(
      (await call({'action': 'status', 'id': id}))['room'],
    ),
  );
  Future<Room> create({
    required String id,
    required Uint8List bytes,
    required String title,
    required String type,
    required String style,
    required String brief,
    required String country,
  }) async {
    final mime = imageMime(bytes);
    if (mime == null) throw const AppFailure('INVALID_IMAGE');
    if (bytes.length > 8 * 1024 * 1024) {
      throw const AppFailure('IMAGE_TOO_LARGE');
    }
    final ext = mime == 'image/png'
        ? 'png'
        : mime == 'image/webp'
        ? 'webp'
        : 'jpg';
    final path = '${db.auth.currentUser!.id}/$id/source.$ext';
    try {
      await db.storage
          .from('rooms')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
    } on StorageException catch (e) {
      if (e.statusCode != '409' && e.error != 'Duplicate') rethrow;
    }
    final data = await call({
      'action': 'create',
      'id': id,
      'title': title,
      'roomType': type,
      'style': style,
      'brief': brief,
      'country': country,
      'sourcePath': path,
      'consent': true,
    });
    return Room.fromJson(Map<String, dynamic>.from(data['room']));
  }

  Future<Map<String, dynamic>> offers(String roomId, String itemId) =>
      call({'action': 'offers', 'id': roomId, 'itemId': itemId});
  Future<void> delete(String id) async {
    await call({'action': 'delete', 'id': id});
  }

  Future<void> deleteAccount() async {
    await call({'action': 'deleteAccount'});
    await db.auth.signOut(scope: SignOutScope.local);
  }
}
