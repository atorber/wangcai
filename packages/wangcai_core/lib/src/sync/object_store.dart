class ObjectMeta {
  const ObjectMeta({this.etag, this.lastModified, this.contentLength});

  final String? etag;
  final DateTime? lastModified;
  final int? contentLength;
}

/// 统一对象存储抽象；路径由账本目录布局派生（ledger / revision / lock）。
abstract class ObjectStore {
  Future<void> put(String path, List<int> bytes, {String? contentType});

  /// 仅当对象不存在时写入；成功返回 true，已存在返回 false。
  Future<bool> putIfAbsent(
    String path,
    List<int> bytes, {
    String? contentType,
  });

  Future<List<int>?> get(String path);

  Future<ObjectMeta?> head(String path);

  Future<void> delete(String path);
}
