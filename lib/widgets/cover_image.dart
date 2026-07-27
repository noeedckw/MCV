import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'cover_image_native.dart'
    if (dart.library.html) 'cover_image_web.dart'
    as impl;

class CoverImage extends StatelessWidget {
  final String? localPath;
  final Uint8List? bytes;
  final String? networkUrl;

  const CoverImage({super.key, this.localPath, this.bytes, this.networkUrl});

  @override
  Widget build(BuildContext context) {
    if (bytes != null) return Image.memory(bytes!, fit: BoxFit.cover);
    if (localPath != null) return impl.buildFileImage(localPath!);
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: Colors.grey[300], child: const Icon(Icons.album)),
      );
    }
    return Container(color: Colors.grey[300], child: const Icon(Icons.album));
  }
}
