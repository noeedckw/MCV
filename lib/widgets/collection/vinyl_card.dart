import 'package:flutter/material.dart';
import '../../storage/vinyl_entry.dart';
import '../cover/cover_image.dart';

const Color _kAccent = Color(0xFFE3B673);

/// A single record in the collection grid: cover art, artist, title, and an
/// optional badge marking a specific pressing (vs. the generic master
/// release).
class VinylCard extends StatelessWidget {
  final VinylEntry entry;
  final VoidCallback onTap;

  const VinylCard({super.key, required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CoverImage(
                    localPath: entry.localCoverPath,
                    bytes: entry.coverBytes,
                  ),
                ),
                if (entry.isSpecificEdition)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _kAccent.withValues(alpha: .5),
                        ),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        size: 12,
                        color: _kAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .85),
            ),
          ),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }
}
