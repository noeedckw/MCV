import 'dart:typed_data';

/// Une piste de la tracklist, telle que sauvegardée avec l'entrée — pas
/// re-fetchée depuis Discogs à chaque affichage, donc figée au moment de
/// l'ajout (édition précise si choisie, sinon celle du master).
class TrackInfo {
  final String position;
  final String title;
  final String duration;

  const TrackInfo({
    required this.position,
    required this.title,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'position': position,
        'title': title,
        'duration': duration,
      };

  factory TrackInfo.fromJson(Map<String, dynamic> json) => TrackInfo(
        position: json['position'] as String? ?? '',
        title: json['title'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
      );
}

class VinylEntry {
  final int? id;
  final int? discogsId;
  final String artist;
  final String title;
  final int? year;
  final String? label;
  final String? format;
  final String? condition;
  final String? localCoverPath;
  final Uint8List? coverBytes;
  final DateTime dateAdded;
  final bool isWantlist;
  final int? releaseId;
  final String? releaseCountry;
  final String? releaseDate;
  final List<String>? genres;
  final List<String>? styles;

  /// Tracklist figée au moment de l'ajout — celle de l'édition précise si
  /// une a été choisie, sinon celle du master.
  final List<TrackInfo>? tracklist;

  /// Notes du master, nettoyées (même logique que la modal Explorer).
  final String? notes;

  VinylEntry({
    this.id,
    this.discogsId,
    required this.artist,
    required this.title,
    this.year,
    this.label,
    this.format,
    this.condition,
    this.localCoverPath,
    this.coverBytes,
    DateTime? dateAdded,
    this.isWantlist = false,
    this.releaseId,
    this.releaseCountry,
    this.releaseDate,
    this.genres,
    this.styles,
    this.tracklist,
    this.notes,
  }) : dateAdded = dateAdded ?? DateTime.now();

  bool get isSpecificEdition => releaseId != null;

  VinylEntry copyWith({
    int? id,
    int? discogsId,
    String? artist,
    String? title,
    int? year,
    String? label,
    String? format,
    String? condition,
    String? localCoverPath,
    Uint8List? coverBytes,
    DateTime? dateAdded,
    bool? isWantlist,
    int? releaseId,
    String? releaseCountry,
    String? releaseDate,
    List<String>? genres,
    List<String>? styles,
    List<TrackInfo>? tracklist,
    String? notes,
  }) {
    return VinylEntry(
      id: id ?? this.id,
      discogsId: discogsId ?? this.discogsId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      year: year ?? this.year,
      label: label ?? this.label,
      format: format ?? this.format,
      condition: condition ?? this.condition,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      coverBytes: coverBytes ?? this.coverBytes,
      dateAdded: dateAdded ?? this.dateAdded,
      isWantlist: isWantlist ?? this.isWantlist,
      releaseId: releaseId ?? this.releaseId,
      releaseCountry: releaseCountry ?? this.releaseCountry,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      styles: styles ?? this.styles,
      tracklist: tracklist ?? this.tracklist,
      notes: notes ?? this.notes,
    );
  }
}