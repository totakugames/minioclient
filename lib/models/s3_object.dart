class S3Object {
  final String key;
  final String name;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;
  final String? etag;

  const S3Object({
    required this.key,
    required this.name,
    required this.isDirectory,
    this.size,
    this.lastModified,
    this.etag,
  });

  String get extension {
    if (isDirectory) return '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  bool get isImage => const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'tga', 'psd']
      .contains(extension);

  bool get isAudio => const ['wav', 'mp3', 'ogg', 'flac', 'aiff']
      .contains(extension);

  bool get isModel => const ['fbx', 'obj', 'blend', 'gltf', 'glb']
      .contains(extension);

  bool get isUnityAsset => const ['unity', 'prefab', 'asset', 'mat', 'controller', 'anim']
      .contains(extension);
}
