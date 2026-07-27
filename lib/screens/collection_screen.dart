import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collection_provider.dart';
import '../storage/vinyl_entry.dart';
import '../widgets/cover_image.dart';
import '../widgets/collection/collection_container.dart';
import '../widgets/collection/collection_album_detail_modal.dart';

const Color _kBg = Color.fromARGB(255, 0, 0, 0);

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  void _openDetail(BuildContext context, VinylEntry entry) {
    final provider = context.read<CollectionProvider>();

    showCollectionAlbumDetail(
      context,
      entry: entry,
      cover: CoverImage(localPath: entry.localCoverPath, bytes: entry.coverBytes),
      onRemove: () async {
        await provider.removeEntry(entry);
        if (context.mounted) Navigator.of(context).maybePop();
      },
      onToggleList: () async {
        if (entry.isWantlist) {
          await provider.moveToCollection(entry);
        } else {
          await provider.moveToWantlist(entry);
        }
        if (context.mounted) Navigator.of(context).maybePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CollectionContainer(
          onTapEntry: (entry) => _openDetail(context, entry),
        ),
      ),
    );
  }
}