import 'package:flutter/material.dart';
import 'package:filesize/filesize.dart';
import '../models/models.dart';

class FileTypeHelper {
  static IconData getIcon(S3Object obj) {
    if (obj.isDirectory) return Icons.folder;

    switch (obj.extension) {
      // Images
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
      case 'bmp':
      case 'tga':
      case 'psd':
        return Icons.image;

      // Audio
      case 'wav':
      case 'mp3':
      case 'ogg':
      case 'flac':
      case 'aiff':
        return Icons.audio_file;

      // 3D Models
      case 'fbx':
      case 'obj':
      case 'blend':
      case 'gltf':
      case 'glb':
        return Icons.view_in_ar;

      // Unity
      case 'unity':
      case 'prefab':
      case 'asset':
      case 'mat':
      case 'controller':
      case 'anim':
        return Icons.videogame_asset;

      // Code / Config
      case 'cs':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'shader':
      case 'hlsl':
      case 'glsl':
        return Icons.code;

      // Video
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'webm':
        return Icons.video_file;

      // Documents
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
        return Icons.description;

      // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.archive;

      default:
        return Icons.insert_drive_file;
    }
  }

  static Color getColor(S3Object obj) {
    if (obj.isDirectory) return const Color(0xFFFFCA28);
    if (obj.isImage) return const Color(0xFF66BB6A);
    if (obj.isAudio) return const Color(0xFF42A5F5);
    if (obj.isModel) return const Color(0xFFAB47BC);
    if (obj.isUnityAsset) return const Color(0xFFEF5350);
    return Colors.white54;
  }

  static String formatSize(int? bytes) {
    if (bytes == null || bytes == 0) return '';
    return filesize(bytes);
  }
}
