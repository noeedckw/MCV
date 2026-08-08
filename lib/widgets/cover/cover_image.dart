import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'cover_image_native.dart'
    if (dart.library.html) 'cover_image_web.dart'
    as impl;
import '../../utils/cover_url.dart';

class CoverImage extends StatelessWidget {
  final String? localPath;
  final Uint8List? bytes;
  final String? networkUrl;

  const CoverImage({super.key, this.localPath, this.bytes, this.networkUrl});

  static Widget _errorImage() {
    return Image.asset(
      'assets/images/error/loading_error.png',
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return Image.memory(
        bytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorImage(),
      );
    }
    if (localPath != null) return impl.buildFileImage(localPath!);
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return Image.network(
        resolveCoverUrl(networkUrl)!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorImage(),
      );
    }
    return _errorImage();
  }
}