// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_storage_native.dart';

// ignore_for_file: type=lint
class $VinylsTableTable extends VinylsTable
    with TableInfo<$VinylsTableTable, VinylsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VinylsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _discogsIdMeta = const VerificationMeta(
    'discogsId',
  );
  @override
  late final GeneratedColumn<int> discogsId = GeneratedColumn<int>(
    'discogs_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localCoverPathMeta = const VerificationMeta(
    'localCoverPath',
  );
  @override
  late final GeneratedColumn<String> localCoverPath = GeneratedColumn<String>(
    'local_cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _isWishlistMeta = const VerificationMeta(
    'isWishlist',
  );
  @override
  late final GeneratedColumn<bool> isWishlist = GeneratedColumn<bool>(
    'is_wishlist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_wishlist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _releaseIdMeta = const VerificationMeta(
    'releaseId',
  );
  @override
  late final GeneratedColumn<int> releaseId = GeneratedColumn<int>(
    'release_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseCountryMeta = const VerificationMeta(
    'releaseCountry',
  );
  @override
  late final GeneratedColumn<String> releaseCountry = GeneratedColumn<String>(
    'release_country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stylesMeta = const VerificationMeta('styles');
  @override
  late final GeneratedColumn<String> styles = GeneratedColumn<String>(
    'styles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tracklistMeta = const VerificationMeta(
    'tracklist',
  );
  @override
  late final GeneratedColumn<String> tracklist = GeneratedColumn<String>(
    'tracklist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    discogsId,
    artist,
    title,
    year,
    label,
    format,
    condition,
    localCoverPath,
    dateAdded,
    isWishlist,
    releaseId,
    releaseCountry,
    releaseDate,
    genres,
    styles,
    tracklist,
    notes,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vinyls_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<VinylsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('discogs_id')) {
      context.handle(
        _discogsIdMeta,
        discogsId.isAcceptableOrUnknown(data['discogs_id']!, _discogsIdMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('local_cover_path')) {
      context.handle(
        _localCoverPathMeta,
        localCoverPath.isAcceptableOrUnknown(
          data['local_cover_path']!,
          _localCoverPathMeta,
        ),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    if (data.containsKey('is_wishlist')) {
      context.handle(
        _isWishlistMeta,
        isWishlist.isAcceptableOrUnknown(data['is_wishlist']!, _isWishlistMeta),
      );
    }
    if (data.containsKey('release_id')) {
      context.handle(
        _releaseIdMeta,
        releaseId.isAcceptableOrUnknown(data['release_id']!, _releaseIdMeta),
      );
    }
    if (data.containsKey('release_country')) {
      context.handle(
        _releaseCountryMeta,
        releaseCountry.isAcceptableOrUnknown(
          data['release_country']!,
          _releaseCountryMeta,
        ),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('styles')) {
      context.handle(
        _stylesMeta,
        styles.isAcceptableOrUnknown(data['styles']!, _stylesMeta),
      );
    }
    if (data.containsKey('tracklist')) {
      context.handle(
        _tracklistMeta,
        tracklist.isAcceptableOrUnknown(data['tracklist']!, _tracklistMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VinylsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VinylsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      discogsId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discogs_id'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      localCoverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_cover_path'],
      ),
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
      isWishlist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_wishlist'],
      )!,
      releaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_id'],
      ),
      releaseCountry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_country'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      ),
      styles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}styles'],
      ),
      tracklist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracklist'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $VinylsTableTable createAlias(String alias) {
    return $VinylsTableTable(attachedDatabase, alias);
  }
}

class VinylsTableData extends DataClass implements Insertable<VinylsTableData> {
  final int id;
  final int? discogsId;
  final String artist;
  final String title;
  final int? year;
  final String? label;
  final String? format;
  final String? condition;
  final String? localCoverPath;
  final DateTime dateAdded;
  final bool isWishlist;
  final int? releaseId;
  final String? releaseCountry;
  final String? releaseDate;
  final String? genres;
  final String? styles;
  final String? tracklist;
  final String? notes;
  final bool isFavorite;
  const VinylsTableData({
    required this.id,
    this.discogsId,
    required this.artist,
    required this.title,
    this.year,
    this.label,
    this.format,
    this.condition,
    this.localCoverPath,
    required this.dateAdded,
    required this.isWishlist,
    this.releaseId,
    this.releaseCountry,
    this.releaseDate,
    this.genres,
    this.styles,
    this.tracklist,
    this.notes,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || discogsId != null) {
      map['discogs_id'] = Variable<int>(discogsId);
    }
    map['artist'] = Variable<String>(artist);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || localCoverPath != null) {
      map['local_cover_path'] = Variable<String>(localCoverPath);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    map['is_wishlist'] = Variable<bool>(isWishlist);
    if (!nullToAbsent || releaseId != null) {
      map['release_id'] = Variable<int>(releaseId);
    }
    if (!nullToAbsent || releaseCountry != null) {
      map['release_country'] = Variable<String>(releaseCountry);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    if (!nullToAbsent || genres != null) {
      map['genres'] = Variable<String>(genres);
    }
    if (!nullToAbsent || styles != null) {
      map['styles'] = Variable<String>(styles);
    }
    if (!nullToAbsent || tracklist != null) {
      map['tracklist'] = Variable<String>(tracklist);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    return map;
  }

  VinylsTableCompanion toCompanion(bool nullToAbsent) {
    return VinylsTableCompanion(
      id: Value(id),
      discogsId: discogsId == null && nullToAbsent
          ? const Value.absent()
          : Value(discogsId),
      artist: Value(artist),
      title: Value(title),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      localCoverPath: localCoverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localCoverPath),
      dateAdded: Value(dateAdded),
      isWishlist: Value(isWishlist),
      releaseId: releaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseId),
      releaseCountry: releaseCountry == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseCountry),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      genres: genres == null && nullToAbsent
          ? const Value.absent()
          : Value(genres),
      styles: styles == null && nullToAbsent
          ? const Value.absent()
          : Value(styles),
      tracklist: tracklist == null && nullToAbsent
          ? const Value.absent()
          : Value(tracklist),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isFavorite: Value(isFavorite),
    );
  }

  factory VinylsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VinylsTableData(
      id: serializer.fromJson<int>(json['id']),
      discogsId: serializer.fromJson<int?>(json['discogsId']),
      artist: serializer.fromJson<String>(json['artist']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int?>(json['year']),
      label: serializer.fromJson<String?>(json['label']),
      format: serializer.fromJson<String?>(json['format']),
      condition: serializer.fromJson<String?>(json['condition']),
      localCoverPath: serializer.fromJson<String?>(json['localCoverPath']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      isWishlist: serializer.fromJson<bool>(json['isWishlist']),
      releaseId: serializer.fromJson<int?>(json['releaseId']),
      releaseCountry: serializer.fromJson<String?>(json['releaseCountry']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      genres: serializer.fromJson<String?>(json['genres']),
      styles: serializer.fromJson<String?>(json['styles']),
      tracklist: serializer.fromJson<String?>(json['tracklist']),
      notes: serializer.fromJson<String?>(json['notes']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'discogsId': serializer.toJson<int?>(discogsId),
      'artist': serializer.toJson<String>(artist),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int?>(year),
      'label': serializer.toJson<String?>(label),
      'format': serializer.toJson<String?>(format),
      'condition': serializer.toJson<String?>(condition),
      'localCoverPath': serializer.toJson<String?>(localCoverPath),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'isWishlist': serializer.toJson<bool>(isWishlist),
      'releaseId': serializer.toJson<int?>(releaseId),
      'releaseCountry': serializer.toJson<String?>(releaseCountry),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'genres': serializer.toJson<String?>(genres),
      'styles': serializer.toJson<String?>(styles),
      'tracklist': serializer.toJson<String?>(tracklist),
      'notes': serializer.toJson<String?>(notes),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  VinylsTableData copyWith({
    int? id,
    Value<int?> discogsId = const Value.absent(),
    String? artist,
    String? title,
    Value<int?> year = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<String?> format = const Value.absent(),
    Value<String?> condition = const Value.absent(),
    Value<String?> localCoverPath = const Value.absent(),
    DateTime? dateAdded,
    bool? isWishlist,
    Value<int?> releaseId = const Value.absent(),
    Value<String?> releaseCountry = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
    Value<String?> genres = const Value.absent(),
    Value<String?> styles = const Value.absent(),
    Value<String?> tracklist = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isFavorite,
  }) => VinylsTableData(
    id: id ?? this.id,
    discogsId: discogsId.present ? discogsId.value : this.discogsId,
    artist: artist ?? this.artist,
    title: title ?? this.title,
    year: year.present ? year.value : this.year,
    label: label.present ? label.value : this.label,
    format: format.present ? format.value : this.format,
    condition: condition.present ? condition.value : this.condition,
    localCoverPath: localCoverPath.present
        ? localCoverPath.value
        : this.localCoverPath,
    dateAdded: dateAdded ?? this.dateAdded,
    isWishlist: isWishlist ?? this.isWishlist,
    releaseId: releaseId.present ? releaseId.value : this.releaseId,
    releaseCountry: releaseCountry.present
        ? releaseCountry.value
        : this.releaseCountry,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    genres: genres.present ? genres.value : this.genres,
    styles: styles.present ? styles.value : this.styles,
    tracklist: tracklist.present ? tracklist.value : this.tracklist,
    notes: notes.present ? notes.value : this.notes,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  VinylsTableData copyWithCompanion(VinylsTableCompanion data) {
    return VinylsTableData(
      id: data.id.present ? data.id.value : this.id,
      discogsId: data.discogsId.present ? data.discogsId.value : this.discogsId,
      artist: data.artist.present ? data.artist.value : this.artist,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      label: data.label.present ? data.label.value : this.label,
      format: data.format.present ? data.format.value : this.format,
      condition: data.condition.present ? data.condition.value : this.condition,
      localCoverPath: data.localCoverPath.present
          ? data.localCoverPath.value
          : this.localCoverPath,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      isWishlist: data.isWishlist.present
          ? data.isWishlist.value
          : this.isWishlist,
      releaseId: data.releaseId.present ? data.releaseId.value : this.releaseId,
      releaseCountry: data.releaseCountry.present
          ? data.releaseCountry.value
          : this.releaseCountry,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      genres: data.genres.present ? data.genres.value : this.genres,
      styles: data.styles.present ? data.styles.value : this.styles,
      tracklist: data.tracklist.present ? data.tracklist.value : this.tracklist,
      notes: data.notes.present ? data.notes.value : this.notes,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VinylsTableData(')
          ..write('id: $id, ')
          ..write('discogsId: $discogsId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('label: $label, ')
          ..write('format: $format, ')
          ..write('condition: $condition, ')
          ..write('localCoverPath: $localCoverPath, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('isWishlist: $isWishlist, ')
          ..write('releaseId: $releaseId, ')
          ..write('releaseCountry: $releaseCountry, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('genres: $genres, ')
          ..write('styles: $styles, ')
          ..write('tracklist: $tracklist, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    discogsId,
    artist,
    title,
    year,
    label,
    format,
    condition,
    localCoverPath,
    dateAdded,
    isWishlist,
    releaseId,
    releaseCountry,
    releaseDate,
    genres,
    styles,
    tracklist,
    notes,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VinylsTableData &&
          other.id == this.id &&
          other.discogsId == this.discogsId &&
          other.artist == this.artist &&
          other.title == this.title &&
          other.year == this.year &&
          other.label == this.label &&
          other.format == this.format &&
          other.condition == this.condition &&
          other.localCoverPath == this.localCoverPath &&
          other.dateAdded == this.dateAdded &&
          other.isWishlist == this.isWishlist &&
          other.releaseId == this.releaseId &&
          other.releaseCountry == this.releaseCountry &&
          other.releaseDate == this.releaseDate &&
          other.genres == this.genres &&
          other.styles == this.styles &&
          other.tracklist == this.tracklist &&
          other.notes == this.notes &&
          other.isFavorite == this.isFavorite);
}

class VinylsTableCompanion extends UpdateCompanion<VinylsTableData> {
  final Value<int> id;
  final Value<int?> discogsId;
  final Value<String> artist;
  final Value<String> title;
  final Value<int?> year;
  final Value<String?> label;
  final Value<String?> format;
  final Value<String?> condition;
  final Value<String?> localCoverPath;
  final Value<DateTime> dateAdded;
  final Value<bool> isWishlist;
  final Value<int?> releaseId;
  final Value<String?> releaseCountry;
  final Value<String?> releaseDate;
  final Value<String?> genres;
  final Value<String?> styles;
  final Value<String?> tracklist;
  final Value<String?> notes;
  final Value<bool> isFavorite;
  const VinylsTableCompanion({
    this.id = const Value.absent(),
    this.discogsId = const Value.absent(),
    this.artist = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.label = const Value.absent(),
    this.format = const Value.absent(),
    this.condition = const Value.absent(),
    this.localCoverPath = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.isWishlist = const Value.absent(),
    this.releaseId = const Value.absent(),
    this.releaseCountry = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.genres = const Value.absent(),
    this.styles = const Value.absent(),
    this.tracklist = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  VinylsTableCompanion.insert({
    this.id = const Value.absent(),
    this.discogsId = const Value.absent(),
    required String artist,
    required String title,
    this.year = const Value.absent(),
    this.label = const Value.absent(),
    this.format = const Value.absent(),
    this.condition = const Value.absent(),
    this.localCoverPath = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.isWishlist = const Value.absent(),
    this.releaseId = const Value.absent(),
    this.releaseCountry = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.genres = const Value.absent(),
    this.styles = const Value.absent(),
    this.tracklist = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
  }) : artist = Value(artist),
       title = Value(title);
  static Insertable<VinylsTableData> custom({
    Expression<int>? id,
    Expression<int>? discogsId,
    Expression<String>? artist,
    Expression<String>? title,
    Expression<int>? year,
    Expression<String>? label,
    Expression<String>? format,
    Expression<String>? condition,
    Expression<String>? localCoverPath,
    Expression<DateTime>? dateAdded,
    Expression<bool>? isWishlist,
    Expression<int>? releaseId,
    Expression<String>? releaseCountry,
    Expression<String>? releaseDate,
    Expression<String>? genres,
    Expression<String>? styles,
    Expression<String>? tracklist,
    Expression<String>? notes,
    Expression<bool>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (discogsId != null) 'discogs_id': discogsId,
      if (artist != null) 'artist': artist,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (label != null) 'label': label,
      if (format != null) 'format': format,
      if (condition != null) 'condition': condition,
      if (localCoverPath != null) 'local_cover_path': localCoverPath,
      if (dateAdded != null) 'date_added': dateAdded,
      if (isWishlist != null) 'is_wishlist': isWishlist,
      if (releaseId != null) 'release_id': releaseId,
      if (releaseCountry != null) 'release_country': releaseCountry,
      if (releaseDate != null) 'release_date': releaseDate,
      if (genres != null) 'genres': genres,
      if (styles != null) 'styles': styles,
      if (tracklist != null) 'tracklist': tracklist,
      if (notes != null) 'notes': notes,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  VinylsTableCompanion copyWith({
    Value<int>? id,
    Value<int?>? discogsId,
    Value<String>? artist,
    Value<String>? title,
    Value<int?>? year,
    Value<String?>? label,
    Value<String?>? format,
    Value<String?>? condition,
    Value<String?>? localCoverPath,
    Value<DateTime>? dateAdded,
    Value<bool>? isWishlist,
    Value<int?>? releaseId,
    Value<String?>? releaseCountry,
    Value<String?>? releaseDate,
    Value<String?>? genres,
    Value<String?>? styles,
    Value<String?>? tracklist,
    Value<String?>? notes,
    Value<bool>? isFavorite,
  }) {
    return VinylsTableCompanion(
      id: id ?? this.id,
      discogsId: discogsId ?? this.discogsId,
      artist: artist ?? this.artist,
      title: title ?? this.title,
      year: year ?? this.year,
      label: label ?? this.label,
      format: format ?? this.format,
      condition: condition ?? this.condition,
      localCoverPath: localCoverPath ?? this.localCoverPath,
      dateAdded: dateAdded ?? this.dateAdded,
      isWishlist: isWishlist ?? this.isWishlist,
      releaseId: releaseId ?? this.releaseId,
      releaseCountry: releaseCountry ?? this.releaseCountry,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      styles: styles ?? this.styles,
      tracklist: tracklist ?? this.tracklist,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (discogsId.present) {
      map['discogs_id'] = Variable<int>(discogsId.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (localCoverPath.present) {
      map['local_cover_path'] = Variable<String>(localCoverPath.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (isWishlist.present) {
      map['is_wishlist'] = Variable<bool>(isWishlist.value);
    }
    if (releaseId.present) {
      map['release_id'] = Variable<int>(releaseId.value);
    }
    if (releaseCountry.present) {
      map['release_country'] = Variable<String>(releaseCountry.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (styles.present) {
      map['styles'] = Variable<String>(styles.value);
    }
    if (tracklist.present) {
      map['tracklist'] = Variable<String>(tracklist.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VinylsTableCompanion(')
          ..write('id: $id, ')
          ..write('discogsId: $discogsId, ')
          ..write('artist: $artist, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('label: $label, ')
          ..write('format: $format, ')
          ..write('condition: $condition, ')
          ..write('localCoverPath: $localCoverPath, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('isWishlist: $isWishlist, ')
          ..write('releaseId: $releaseId, ')
          ..write('releaseCountry: $releaseCountry, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('genres: $genres, ')
          ..write('styles: $styles, ')
          ..write('tracklist: $tracklist, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VinylsTableTable vinylsTable = $VinylsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [vinylsTable];
}

typedef $$VinylsTableTableCreateCompanionBuilder =
    VinylsTableCompanion Function({
      Value<int> id,
      Value<int?> discogsId,
      required String artist,
      required String title,
      Value<int?> year,
      Value<String?> label,
      Value<String?> format,
      Value<String?> condition,
      Value<String?> localCoverPath,
      Value<DateTime> dateAdded,
      Value<bool> isWishlist,
      Value<int?> releaseId,
      Value<String?> releaseCountry,
      Value<String?> releaseDate,
      Value<String?> genres,
      Value<String?> styles,
      Value<String?> tracklist,
      Value<String?> notes,
      Value<bool> isFavorite,
    });
typedef $$VinylsTableTableUpdateCompanionBuilder =
    VinylsTableCompanion Function({
      Value<int> id,
      Value<int?> discogsId,
      Value<String> artist,
      Value<String> title,
      Value<int?> year,
      Value<String?> label,
      Value<String?> format,
      Value<String?> condition,
      Value<String?> localCoverPath,
      Value<DateTime> dateAdded,
      Value<bool> isWishlist,
      Value<int?> releaseId,
      Value<String?> releaseCountry,
      Value<String?> releaseDate,
      Value<String?> genres,
      Value<String?> styles,
      Value<String?> tracklist,
      Value<String?> notes,
      Value<bool> isFavorite,
    });

class $$VinylsTableTableFilterComposer
    extends Composer<_$AppDatabase, $VinylsTableTable> {
  $$VinylsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discogsId => $composableBuilder(
    column: $table.discogsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isWishlist => $composableBuilder(
    column: $table.isWishlist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseCountry => $composableBuilder(
    column: $table.releaseCountry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get styles => $composableBuilder(
    column: $table.styles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tracklist => $composableBuilder(
    column: $table.tracklist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VinylsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VinylsTableTable> {
  $$VinylsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discogsId => $composableBuilder(
    column: $table.discogsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isWishlist => $composableBuilder(
    column: $table.isWishlist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseId => $composableBuilder(
    column: $table.releaseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseCountry => $composableBuilder(
    column: $table.releaseCountry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styles => $composableBuilder(
    column: $table.styles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tracklist => $composableBuilder(
    column: $table.tracklist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VinylsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VinylsTableTable> {
  $$VinylsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get discogsId =>
      $composableBuilder(column: $table.discogsId, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get localCoverPath => $composableBuilder(
    column: $table.localCoverPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<bool> get isWishlist => $composableBuilder(
    column: $table.isWishlist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get releaseId =>
      $composableBuilder(column: $table.releaseId, builder: (column) => column);

  GeneratedColumn<String> get releaseCountry => $composableBuilder(
    column: $table.releaseCountry,
    builder: (column) => column,
  );

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get styles =>
      $composableBuilder(column: $table.styles, builder: (column) => column);

  GeneratedColumn<String> get tracklist =>
      $composableBuilder(column: $table.tracklist, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );
}

class $$VinylsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VinylsTableTable,
          VinylsTableData,
          $$VinylsTableTableFilterComposer,
          $$VinylsTableTableOrderingComposer,
          $$VinylsTableTableAnnotationComposer,
          $$VinylsTableTableCreateCompanionBuilder,
          $$VinylsTableTableUpdateCompanionBuilder,
          (
            VinylsTableData,
            BaseReferences<_$AppDatabase, $VinylsTableTable, VinylsTableData>,
          ),
          VinylsTableData,
          PrefetchHooks Function()
        > {
  $$VinylsTableTableTableManager(_$AppDatabase db, $VinylsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VinylsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VinylsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VinylsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> discogsId = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> localCoverPath = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<bool> isWishlist = const Value.absent(),
                Value<int?> releaseId = const Value.absent(),
                Value<String?> releaseCountry = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<String?> genres = const Value.absent(),
                Value<String?> styles = const Value.absent(),
                Value<String?> tracklist = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
              }) => VinylsTableCompanion(
                id: id,
                discogsId: discogsId,
                artist: artist,
                title: title,
                year: year,
                label: label,
                format: format,
                condition: condition,
                localCoverPath: localCoverPath,
                dateAdded: dateAdded,
                isWishlist: isWishlist,
                releaseId: releaseId,
                releaseCountry: releaseCountry,
                releaseDate: releaseDate,
                genres: genres,
                styles: styles,
                tracklist: tracklist,
                notes: notes,
                isFavorite: isFavorite,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> discogsId = const Value.absent(),
                required String artist,
                required String title,
                Value<int?> year = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> localCoverPath = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<bool> isWishlist = const Value.absent(),
                Value<int?> releaseId = const Value.absent(),
                Value<String?> releaseCountry = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<String?> genres = const Value.absent(),
                Value<String?> styles = const Value.absent(),
                Value<String?> tracklist = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
              }) => VinylsTableCompanion.insert(
                id: id,
                discogsId: discogsId,
                artist: artist,
                title: title,
                year: year,
                label: label,
                format: format,
                condition: condition,
                localCoverPath: localCoverPath,
                dateAdded: dateAdded,
                isWishlist: isWishlist,
                releaseId: releaseId,
                releaseCountry: releaseCountry,
                releaseDate: releaseDate,
                genres: genres,
                styles: styles,
                tracklist: tracklist,
                notes: notes,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VinylsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VinylsTableTable,
      VinylsTableData,
      $$VinylsTableTableFilterComposer,
      $$VinylsTableTableOrderingComposer,
      $$VinylsTableTableAnnotationComposer,
      $$VinylsTableTableCreateCompanionBuilder,
      $$VinylsTableTableUpdateCompanionBuilder,
      (
        VinylsTableData,
        BaseReferences<_$AppDatabase, $VinylsTableTable, VinylsTableData>,
      ),
      VinylsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VinylsTableTableTableManager get vinylsTable =>
      $$VinylsTableTableTableManager(_db, _db.vinylsTable);
}
