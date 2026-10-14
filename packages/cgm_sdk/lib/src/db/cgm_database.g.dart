// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cgm_database.dart';

// ignore_for_file: type=lint
class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String? value;

  /// UTC epoch millisecond
  final int updatedAt;
  const AppMetaRow({required this.key, this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppMetaRow copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
    int? updatedAt,
  }) => AppMetaRow(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       updatedAt = Value(updatedAt);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BleFrameBufferTable extends BleFrameBuffer
    with TableInfo<$BleFrameBufferTable, BleFrameBufferRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BleFrameBufferTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawFrameMeta = const VerificationMeta(
    'rawFrame',
  );
  @override
  late final GeneratedColumn<Uint8List> rawFrame = GeneratedColumn<Uint8List>(
    'raw_frame',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> measureTime =
      GeneratedColumn<int>(
        'measure_time',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BleFrameBufferTable.$convertermeasureTime);
  static const VerificationMeta _recordSeqMeta = const VerificationMeta(
    'recordSeq',
  );
  @override
  late final GeneratedColumn<int> recordSeq = GeneratedColumn<int>(
    'record_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawCurrentMeta = const VerificationMeta(
    'rawCurrent',
  );
  @override
  late final GeneratedColumn<double> rawCurrent = GeneratedColumn<double>(
    'raw_current',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voltageMeta = const VerificationMeta(
    'voltage',
  );
  @override
  late final GeneratedColumn<double> voltage = GeneratedColumn<double>(
    'voltage',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('RAW'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BleFrameBufferTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wearId,
    rawFrame,
    measureTime,
    recordSeq,
    rawCurrent,
    temperature,
    voltage,
    status,
    retryCount,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ble_frame_buffer';
  @override
  VerificationContext validateIntegrity(
    Insertable<BleFrameBufferRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('raw_frame')) {
      context.handle(
        _rawFrameMeta,
        rawFrame.isAcceptableOrUnknown(data['raw_frame']!, _rawFrameMeta),
      );
    } else if (isInserting) {
      context.missing(_rawFrameMeta);
    }
    if (data.containsKey('record_seq')) {
      context.handle(
        _recordSeqMeta,
        recordSeq.isAcceptableOrUnknown(data['record_seq']!, _recordSeqMeta),
      );
    }
    if (data.containsKey('raw_current')) {
      context.handle(
        _rawCurrentMeta,
        rawCurrent.isAcceptableOrUnknown(data['raw_current']!, _rawCurrentMeta),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('voltage')) {
      context.handle(
        _voltageMeta,
        voltage.isAcceptableOrUnknown(data['voltage']!, _voltageMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BleFrameBufferRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BleFrameBufferRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      rawFrame: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}raw_frame'],
      )!,
      measureTime: $BleFrameBufferTable.$convertermeasureTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}measure_time'],
        )!,
      ),
      recordSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_seq'],
      ),
      rawCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}raw_current'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      ),
      voltage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}voltage'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: $BleFrameBufferTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $BleFrameBufferTable createAlias(String alias) {
    return $BleFrameBufferTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermeasureTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const DateTimeEpochConverter();
}

class BleFrameBufferRow extends DataClass
    implements Insertable<BleFrameBufferRow> {
  /// A natural guide to the order of joining the team（measure_time Same and none record_seq Sort by it）
  final int id;

  /// Change sensor（wear_id change) algorithm to uninit/init Reset history window
  final int? wearId;

  /// one piece 14 Payload of byte record, frame header removed/The verified data segment
  final Uint8List rawFrame;

  /// Sort it in ascending order when consuming
  final DateTime measureTime;

  /// measure_time The secondary sort key when the same, if the device is not given, it will be empty.
  final int? recordSeq;

  /// algorithm dataProc of srcData Add ginseng
  final double? rawCurrent;

  /// algorithm dataProc of temperature Add ginseng
  final double? temperature;

  /// Original voltage, dropped to raw_data.voltage_value Use (without entering the algorithm）
  final double? voltage;

  /// RAW=Pending / DONE=Already placed in inventory / RETRY=Processing failed and needs to be retried
  final String status;

  /// No automatic discarding, medical data does not lose frames
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  const BleFrameBufferRow({
    required this.id,
    this.wearId,
    required this.rawFrame,
    required this.measureTime,
    this.recordSeq,
    this.rawCurrent,
    this.temperature,
    this.voltage,
    required this.status,
    required this.retryCount,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    map['raw_frame'] = Variable<Uint8List>(rawFrame);
    {
      map['measure_time'] = Variable<int>(
        $BleFrameBufferTable.$convertermeasureTime.toSql(measureTime),
      );
    }
    if (!nullToAbsent || recordSeq != null) {
      map['record_seq'] = Variable<int>(recordSeq);
    }
    if (!nullToAbsent || rawCurrent != null) {
      map['raw_current'] = Variable<double>(rawCurrent);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || voltage != null) {
      map['voltage'] = Variable<double>(voltage);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    {
      map['created_at'] = Variable<int>(
        $BleFrameBufferTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  BleFrameBufferCompanion toCompanion(bool nullToAbsent) {
    return BleFrameBufferCompanion(
      id: Value(id),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      rawFrame: Value(rawFrame),
      measureTime: Value(measureTime),
      recordSeq: recordSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(recordSeq),
      rawCurrent: rawCurrent == null && nullToAbsent
          ? const Value.absent()
          : Value(rawCurrent),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      voltage: voltage == null && nullToAbsent
          ? const Value.absent()
          : Value(voltage),
      status: Value(status),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory BleFrameBufferRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BleFrameBufferRow(
      id: serializer.fromJson<int>(json['id']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      rawFrame: serializer.fromJson<Uint8List>(json['rawFrame']),
      measureTime: serializer.fromJson<DateTime>(json['measureTime']),
      recordSeq: serializer.fromJson<int?>(json['recordSeq']),
      rawCurrent: serializer.fromJson<double?>(json['rawCurrent']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      voltage: serializer.fromJson<double?>(json['voltage']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wearId': serializer.toJson<int?>(wearId),
      'rawFrame': serializer.toJson<Uint8List>(rawFrame),
      'measureTime': serializer.toJson<DateTime>(measureTime),
      'recordSeq': serializer.toJson<int?>(recordSeq),
      'rawCurrent': serializer.toJson<double?>(rawCurrent),
      'temperature': serializer.toJson<double?>(temperature),
      'voltage': serializer.toJson<double?>(voltage),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BleFrameBufferRow copyWith({
    int? id,
    Value<int?> wearId = const Value.absent(),
    Uint8List? rawFrame,
    DateTime? measureTime,
    Value<int?> recordSeq = const Value.absent(),
    Value<double?> rawCurrent = const Value.absent(),
    Value<double?> temperature = const Value.absent(),
    Value<double?> voltage = const Value.absent(),
    String? status,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => BleFrameBufferRow(
    id: id ?? this.id,
    wearId: wearId.present ? wearId.value : this.wearId,
    rawFrame: rawFrame ?? this.rawFrame,
    measureTime: measureTime ?? this.measureTime,
    recordSeq: recordSeq.present ? recordSeq.value : this.recordSeq,
    rawCurrent: rawCurrent.present ? rawCurrent.value : this.rawCurrent,
    temperature: temperature.present ? temperature.value : this.temperature,
    voltage: voltage.present ? voltage.value : this.voltage,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  BleFrameBufferRow copyWithCompanion(BleFrameBufferCompanion data) {
    return BleFrameBufferRow(
      id: data.id.present ? data.id.value : this.id,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      rawFrame: data.rawFrame.present ? data.rawFrame.value : this.rawFrame,
      measureTime: data.measureTime.present
          ? data.measureTime.value
          : this.measureTime,
      recordSeq: data.recordSeq.present ? data.recordSeq.value : this.recordSeq,
      rawCurrent: data.rawCurrent.present
          ? data.rawCurrent.value
          : this.rawCurrent,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      voltage: data.voltage.present ? data.voltage.value : this.voltage,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BleFrameBufferRow(')
          ..write('id: $id, ')
          ..write('wearId: $wearId, ')
          ..write('rawFrame: $rawFrame, ')
          ..write('measureTime: $measureTime, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('rawCurrent: $rawCurrent, ')
          ..write('temperature: $temperature, ')
          ..write('voltage: $voltage, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wearId,
    $driftBlobEquality.hash(rawFrame),
    measureTime,
    recordSeq,
    rawCurrent,
    temperature,
    voltage,
    status,
    retryCount,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BleFrameBufferRow &&
          other.id == this.id &&
          other.wearId == this.wearId &&
          $driftBlobEquality.equals(other.rawFrame, this.rawFrame) &&
          other.measureTime == this.measureTime &&
          other.recordSeq == this.recordSeq &&
          other.rawCurrent == this.rawCurrent &&
          other.temperature == this.temperature &&
          other.voltage == this.voltage &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class BleFrameBufferCompanion extends UpdateCompanion<BleFrameBufferRow> {
  final Value<int> id;
  final Value<int?> wearId;
  final Value<Uint8List> rawFrame;
  final Value<DateTime> measureTime;
  final Value<int?> recordSeq;
  final Value<double?> rawCurrent;
  final Value<double?> temperature;
  final Value<double?> voltage;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const BleFrameBufferCompanion({
    this.id = const Value.absent(),
    this.wearId = const Value.absent(),
    this.rawFrame = const Value.absent(),
    this.measureTime = const Value.absent(),
    this.recordSeq = const Value.absent(),
    this.rawCurrent = const Value.absent(),
    this.temperature = const Value.absent(),
    this.voltage = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BleFrameBufferCompanion.insert({
    this.id = const Value.absent(),
    this.wearId = const Value.absent(),
    required Uint8List rawFrame,
    required DateTime measureTime,
    this.recordSeq = const Value.absent(),
    this.rawCurrent = const Value.absent(),
    this.temperature = const Value.absent(),
    this.voltage = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : rawFrame = Value(rawFrame),
       measureTime = Value(measureTime),
       createdAt = Value(createdAt);
  static Insertable<BleFrameBufferRow> custom({
    Expression<int>? id,
    Expression<int>? wearId,
    Expression<Uint8List>? rawFrame,
    Expression<int>? measureTime,
    Expression<int>? recordSeq,
    Expression<double>? rawCurrent,
    Expression<double>? temperature,
    Expression<double>? voltage,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wearId != null) 'wear_id': wearId,
      if (rawFrame != null) 'raw_frame': rawFrame,
      if (measureTime != null) 'measure_time': measureTime,
      if (recordSeq != null) 'record_seq': recordSeq,
      if (rawCurrent != null) 'raw_current': rawCurrent,
      if (temperature != null) 'temperature': temperature,
      if (voltage != null) 'voltage': voltage,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BleFrameBufferCompanion copyWith({
    Value<int>? id,
    Value<int?>? wearId,
    Value<Uint8List>? rawFrame,
    Value<DateTime>? measureTime,
    Value<int?>? recordSeq,
    Value<double?>? rawCurrent,
    Value<double?>? temperature,
    Value<double?>? voltage,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return BleFrameBufferCompanion(
      id: id ?? this.id,
      wearId: wearId ?? this.wearId,
      rawFrame: rawFrame ?? this.rawFrame,
      measureTime: measureTime ?? this.measureTime,
      recordSeq: recordSeq ?? this.recordSeq,
      rawCurrent: rawCurrent ?? this.rawCurrent,
      temperature: temperature ?? this.temperature,
      voltage: voltage ?? this.voltage,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (rawFrame.present) {
      map['raw_frame'] = Variable<Uint8List>(rawFrame.value);
    }
    if (measureTime.present) {
      map['measure_time'] = Variable<int>(
        $BleFrameBufferTable.$convertermeasureTime.toSql(measureTime.value),
      );
    }
    if (recordSeq.present) {
      map['record_seq'] = Variable<int>(recordSeq.value);
    }
    if (rawCurrent.present) {
      map['raw_current'] = Variable<double>(rawCurrent.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (voltage.present) {
      map['voltage'] = Variable<double>(voltage.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $BleFrameBufferTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BleFrameBufferCompanion(')
          ..write('id: $id, ')
          ..write('wearId: $wearId, ')
          ..write('rawFrame: $rawFrame, ')
          ..write('measureTime: $measureTime, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('rawCurrent: $rawCurrent, ')
          ..write('temperature: $temperature, ')
          ..write('voltage: $voltage, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AppDeviceBindTable extends AppDeviceBind
    with TableInfo<$AppDeviceBindTable, AppDeviceBindRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppDeviceBindTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transmitterSnMeta = const VerificationMeta(
    'transmitterSn',
  );
  @override
  late final GeneratedColumn<String> transmitterSn = GeneratedColumn<String>(
    'transmitter_sn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensorSnMeta = const VerificationMeta(
    'sensorSn',
  );
  @override
  late final GeneratedColumn<String> sensorSn = GeneratedColumn<String>(
    'sensor_sn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bluetoothAddrMeta = const VerificationMeta(
    'bluetoothAddr',
  );
  @override
  late final GeneratedColumn<String> bluetoothAddr = GeneratedColumn<String>(
    'bluetooth_addr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceTypeMeta = const VerificationMeta(
    'deviceType',
  );
  @override
  late final GeneratedColumn<String> deviceType = GeneratedColumn<String>(
    'device_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instanceFormMeta = const VerificationMeta(
    'instanceForm',
  );
  @override
  late final GeneratedColumn<String> instanceForm = GeneratedColumn<String>(
    'instance_form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expireDateMeta = const VerificationMeta(
    'expireDate',
  );
  @override
  late final GeneratedColumn<String> expireDate = GeneratedColumn<String>(
    'expire_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firmwareVersionMeta = const VerificationMeta(
    'firmwareVersion',
  );
  @override
  late final GeneratedColumn<String> firmwareVersion = GeneratedColumn<String>(
    'firmware_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _softParamsMeta = const VerificationMeta(
    'softParams',
  );
  @override
  late final GeneratedColumn<String> softParams = GeneratedColumn<String>(
    'soft_params',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firmwareParamsMeta = const VerificationMeta(
    'firmwareParams',
  );
  @override
  late final GeneratedColumn<String> firmwareParams = GeneratedColumn<String>(
    'firmware_params',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bindLatitudeMeta = const VerificationMeta(
    'bindLatitude',
  );
  @override
  late final GeneratedColumn<double> bindLatitude = GeneratedColumn<double>(
    'bind_latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bindLongitudeMeta = const VerificationMeta(
    'bindLongitude',
  );
  @override
  late final GeneratedColumn<double> bindLongitude = GeneratedColumn<double>(
    'bind_longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityCodeMeta = const VerificationMeta(
    'cityCode',
  );
  @override
  late final GeneratedColumn<String> cityCode = GeneratedColumn<String>(
    'city_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _districtCodeMeta = const VerificationMeta(
    'districtCode',
  );
  @override
  late final GeneratedColumn<String> districtCode = GeneratedColumn<String>(
    'district_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadStatusMeta = const VerificationMeta(
    'uploadStatus',
  );
  @override
  late final GeneratedColumn<String> uploadStatus = GeneratedColumn<String>(
    'upload_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceStatusMeta = const VerificationMeta(
    'deviceStatus',
  );
  @override
  late final GeneratedColumn<String> deviceStatus = GeneratedColumn<String>(
    'device_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    wearId,
    transmitterSn,
    sensorSn,
    bluetoothAddr,
    deviceType,
    instanceForm,
    expireDate,
    firmwareVersion,
    softParams,
    firmwareParams,
    bindLatitude,
    bindLongitude,
    cityCode,
    districtCode,
    uploadStatus,
    deviceStatus,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_device_bind';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppDeviceBindRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('transmitter_sn')) {
      context.handle(
        _transmitterSnMeta,
        transmitterSn.isAcceptableOrUnknown(
          data['transmitter_sn']!,
          _transmitterSnMeta,
        ),
      );
    }
    if (data.containsKey('sensor_sn')) {
      context.handle(
        _sensorSnMeta,
        sensorSn.isAcceptableOrUnknown(data['sensor_sn']!, _sensorSnMeta),
      );
    }
    if (data.containsKey('bluetooth_addr')) {
      context.handle(
        _bluetoothAddrMeta,
        bluetoothAddr.isAcceptableOrUnknown(
          data['bluetooth_addr']!,
          _bluetoothAddrMeta,
        ),
      );
    }
    if (data.containsKey('device_type')) {
      context.handle(
        _deviceTypeMeta,
        deviceType.isAcceptableOrUnknown(data['device_type']!, _deviceTypeMeta),
      );
    }
    if (data.containsKey('instance_form')) {
      context.handle(
        _instanceFormMeta,
        instanceForm.isAcceptableOrUnknown(
          data['instance_form']!,
          _instanceFormMeta,
        ),
      );
    }
    if (data.containsKey('expire_date')) {
      context.handle(
        _expireDateMeta,
        expireDate.isAcceptableOrUnknown(data['expire_date']!, _expireDateMeta),
      );
    }
    if (data.containsKey('firmware_version')) {
      context.handle(
        _firmwareVersionMeta,
        firmwareVersion.isAcceptableOrUnknown(
          data['firmware_version']!,
          _firmwareVersionMeta,
        ),
      );
    }
    if (data.containsKey('soft_params')) {
      context.handle(
        _softParamsMeta,
        softParams.isAcceptableOrUnknown(data['soft_params']!, _softParamsMeta),
      );
    }
    if (data.containsKey('firmware_params')) {
      context.handle(
        _firmwareParamsMeta,
        firmwareParams.isAcceptableOrUnknown(
          data['firmware_params']!,
          _firmwareParamsMeta,
        ),
      );
    }
    if (data.containsKey('bind_latitude')) {
      context.handle(
        _bindLatitudeMeta,
        bindLatitude.isAcceptableOrUnknown(
          data['bind_latitude']!,
          _bindLatitudeMeta,
        ),
      );
    }
    if (data.containsKey('bind_longitude')) {
      context.handle(
        _bindLongitudeMeta,
        bindLongitude.isAcceptableOrUnknown(
          data['bind_longitude']!,
          _bindLongitudeMeta,
        ),
      );
    }
    if (data.containsKey('city_code')) {
      context.handle(
        _cityCodeMeta,
        cityCode.isAcceptableOrUnknown(data['city_code']!, _cityCodeMeta),
      );
    }
    if (data.containsKey('district_code')) {
      context.handle(
        _districtCodeMeta,
        districtCode.isAcceptableOrUnknown(
          data['district_code']!,
          _districtCodeMeta,
        ),
      );
    }
    if (data.containsKey('upload_status')) {
      context.handle(
        _uploadStatusMeta,
        uploadStatus.isAcceptableOrUnknown(
          data['upload_status']!,
          _uploadStatusMeta,
        ),
      );
    }
    if (data.containsKey('device_status')) {
      context.handle(
        _deviceStatusMeta,
        deviceStatus.isAcceptableOrUnknown(
          data['device_status']!,
          _deviceStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppDeviceBindRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppDeviceBindRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      transmitterSn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transmitter_sn'],
      ),
      sensorSn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sensor_sn'],
      ),
      bluetoothAddr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bluetooth_addr'],
      ),
      deviceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_type'],
      ),
      instanceForm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_form'],
      ),
      expireDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expire_date'],
      ),
      firmwareVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware_version'],
      ),
      softParams: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}soft_params'],
      ),
      firmwareParams: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firmware_params'],
      ),
      bindLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bind_latitude'],
      ),
      bindLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bind_longitude'],
      ),
      cityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city_code'],
      ),
      districtCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_code'],
      ),
      uploadStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_status'],
      ),
      deviceStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_status'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppDeviceBindTable createAlias(String alias) {
    return $AppDeviceBindTable(attachedDatabase, alias);
  }
}

class AppDeviceBindRow extends DataClass
    implements Insertable<AppDeviceBindRow> {
  final int id;
  final int userId;

  /// Backstage wear record Id（bind The interface returns; the interface is not ready / Leave blank when offline, fill in after writing back）
  final int? wearId;

  /// Transmitter serial number (associated user_wear_cur）
  final String? transmitterSn;

  /// Sensor serial number (associated with user_wear_cur）
  final String? sensorSn;

  /// Bluetooth address（BLE Reuse；CGM There is also a copy）
  final String? bluetoothAddr;

  /// Device type：half=half toss / full=Throw all
  final String? deviceType;

  /// Instance form（scanQrCode original value instanceForm）
  final String? instanceForm;

  /// Factory expiration date (for verification of overdue date)，scanQrCode expireDate Original value string）
  final String? expireDate;

  /// Firmware version (identification code fetched in the background / BLE 0xE7 read）
  final String? firmwareVersion;

  /// Engineering calibration parameters issued by the backend（0xE6 A-E），Leave blank for no hardware period。
  final String? softParams;

  /// Equipment factory parameters（0xE6/E8 BLE Read), leave blank if no hardware period。
  final String? firmwareParams;
  final double? bindLatitude;
  final double? bindLongitude;

  /// Gaode citycode
  final String? cityCode;

  /// Gaode adcode
  final String? districtCode;

  /// 0=To be passed / 1=Sent
  final String? uploadStatus;

  /// warming=Warming up / done=End of warm-up
  final String? deviceStatus;
  final int createdAt;
  final int updatedAt;
  const AppDeviceBindRow({
    required this.id,
    required this.userId,
    this.wearId,
    this.transmitterSn,
    this.sensorSn,
    this.bluetoothAddr,
    this.deviceType,
    this.instanceForm,
    this.expireDate,
    this.firmwareVersion,
    this.softParams,
    this.firmwareParams,
    this.bindLatitude,
    this.bindLongitude,
    this.cityCode,
    this.districtCode,
    this.uploadStatus,
    this.deviceStatus,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    if (!nullToAbsent || transmitterSn != null) {
      map['transmitter_sn'] = Variable<String>(transmitterSn);
    }
    if (!nullToAbsent || sensorSn != null) {
      map['sensor_sn'] = Variable<String>(sensorSn);
    }
    if (!nullToAbsent || bluetoothAddr != null) {
      map['bluetooth_addr'] = Variable<String>(bluetoothAddr);
    }
    if (!nullToAbsent || deviceType != null) {
      map['device_type'] = Variable<String>(deviceType);
    }
    if (!nullToAbsent || instanceForm != null) {
      map['instance_form'] = Variable<String>(instanceForm);
    }
    if (!nullToAbsent || expireDate != null) {
      map['expire_date'] = Variable<String>(expireDate);
    }
    if (!nullToAbsent || firmwareVersion != null) {
      map['firmware_version'] = Variable<String>(firmwareVersion);
    }
    if (!nullToAbsent || softParams != null) {
      map['soft_params'] = Variable<String>(softParams);
    }
    if (!nullToAbsent || firmwareParams != null) {
      map['firmware_params'] = Variable<String>(firmwareParams);
    }
    if (!nullToAbsent || bindLatitude != null) {
      map['bind_latitude'] = Variable<double>(bindLatitude);
    }
    if (!nullToAbsent || bindLongitude != null) {
      map['bind_longitude'] = Variable<double>(bindLongitude);
    }
    if (!nullToAbsent || cityCode != null) {
      map['city_code'] = Variable<String>(cityCode);
    }
    if (!nullToAbsent || districtCode != null) {
      map['district_code'] = Variable<String>(districtCode);
    }
    if (!nullToAbsent || uploadStatus != null) {
      map['upload_status'] = Variable<String>(uploadStatus);
    }
    if (!nullToAbsent || deviceStatus != null) {
      map['device_status'] = Variable<String>(deviceStatus);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppDeviceBindCompanion toCompanion(bool nullToAbsent) {
    return AppDeviceBindCompanion(
      id: Value(id),
      userId: Value(userId),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      transmitterSn: transmitterSn == null && nullToAbsent
          ? const Value.absent()
          : Value(transmitterSn),
      sensorSn: sensorSn == null && nullToAbsent
          ? const Value.absent()
          : Value(sensorSn),
      bluetoothAddr: bluetoothAddr == null && nullToAbsent
          ? const Value.absent()
          : Value(bluetoothAddr),
      deviceType: deviceType == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceType),
      instanceForm: instanceForm == null && nullToAbsent
          ? const Value.absent()
          : Value(instanceForm),
      expireDate: expireDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expireDate),
      firmwareVersion: firmwareVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(firmwareVersion),
      softParams: softParams == null && nullToAbsent
          ? const Value.absent()
          : Value(softParams),
      firmwareParams: firmwareParams == null && nullToAbsent
          ? const Value.absent()
          : Value(firmwareParams),
      bindLatitude: bindLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(bindLatitude),
      bindLongitude: bindLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(bindLongitude),
      cityCode: cityCode == null && nullToAbsent
          ? const Value.absent()
          : Value(cityCode),
      districtCode: districtCode == null && nullToAbsent
          ? const Value.absent()
          : Value(districtCode),
      uploadStatus: uploadStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadStatus),
      deviceStatus: deviceStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceStatus),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppDeviceBindRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppDeviceBindRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      transmitterSn: serializer.fromJson<String?>(json['transmitterSn']),
      sensorSn: serializer.fromJson<String?>(json['sensorSn']),
      bluetoothAddr: serializer.fromJson<String?>(json['bluetoothAddr']),
      deviceType: serializer.fromJson<String?>(json['deviceType']),
      instanceForm: serializer.fromJson<String?>(json['instanceForm']),
      expireDate: serializer.fromJson<String?>(json['expireDate']),
      firmwareVersion: serializer.fromJson<String?>(json['firmwareVersion']),
      softParams: serializer.fromJson<String?>(json['softParams']),
      firmwareParams: serializer.fromJson<String?>(json['firmwareParams']),
      bindLatitude: serializer.fromJson<double?>(json['bindLatitude']),
      bindLongitude: serializer.fromJson<double?>(json['bindLongitude']),
      cityCode: serializer.fromJson<String?>(json['cityCode']),
      districtCode: serializer.fromJson<String?>(json['districtCode']),
      uploadStatus: serializer.fromJson<String?>(json['uploadStatus']),
      deviceStatus: serializer.fromJson<String?>(json['deviceStatus']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'wearId': serializer.toJson<int?>(wearId),
      'transmitterSn': serializer.toJson<String?>(transmitterSn),
      'sensorSn': serializer.toJson<String?>(sensorSn),
      'bluetoothAddr': serializer.toJson<String?>(bluetoothAddr),
      'deviceType': serializer.toJson<String?>(deviceType),
      'instanceForm': serializer.toJson<String?>(instanceForm),
      'expireDate': serializer.toJson<String?>(expireDate),
      'firmwareVersion': serializer.toJson<String?>(firmwareVersion),
      'softParams': serializer.toJson<String?>(softParams),
      'firmwareParams': serializer.toJson<String?>(firmwareParams),
      'bindLatitude': serializer.toJson<double?>(bindLatitude),
      'bindLongitude': serializer.toJson<double?>(bindLongitude),
      'cityCode': serializer.toJson<String?>(cityCode),
      'districtCode': serializer.toJson<String?>(districtCode),
      'uploadStatus': serializer.toJson<String?>(uploadStatus),
      'deviceStatus': serializer.toJson<String?>(deviceStatus),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppDeviceBindRow copyWith({
    int? id,
    int? userId,
    Value<int?> wearId = const Value.absent(),
    Value<String?> transmitterSn = const Value.absent(),
    Value<String?> sensorSn = const Value.absent(),
    Value<String?> bluetoothAddr = const Value.absent(),
    Value<String?> deviceType = const Value.absent(),
    Value<String?> instanceForm = const Value.absent(),
    Value<String?> expireDate = const Value.absent(),
    Value<String?> firmwareVersion = const Value.absent(),
    Value<String?> softParams = const Value.absent(),
    Value<String?> firmwareParams = const Value.absent(),
    Value<double?> bindLatitude = const Value.absent(),
    Value<double?> bindLongitude = const Value.absent(),
    Value<String?> cityCode = const Value.absent(),
    Value<String?> districtCode = const Value.absent(),
    Value<String?> uploadStatus = const Value.absent(),
    Value<String?> deviceStatus = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => AppDeviceBindRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    wearId: wearId.present ? wearId.value : this.wearId,
    transmitterSn: transmitterSn.present
        ? transmitterSn.value
        : this.transmitterSn,
    sensorSn: sensorSn.present ? sensorSn.value : this.sensorSn,
    bluetoothAddr: bluetoothAddr.present
        ? bluetoothAddr.value
        : this.bluetoothAddr,
    deviceType: deviceType.present ? deviceType.value : this.deviceType,
    instanceForm: instanceForm.present ? instanceForm.value : this.instanceForm,
    expireDate: expireDate.present ? expireDate.value : this.expireDate,
    firmwareVersion: firmwareVersion.present
        ? firmwareVersion.value
        : this.firmwareVersion,
    softParams: softParams.present ? softParams.value : this.softParams,
    firmwareParams: firmwareParams.present
        ? firmwareParams.value
        : this.firmwareParams,
    bindLatitude: bindLatitude.present ? bindLatitude.value : this.bindLatitude,
    bindLongitude: bindLongitude.present
        ? bindLongitude.value
        : this.bindLongitude,
    cityCode: cityCode.present ? cityCode.value : this.cityCode,
    districtCode: districtCode.present ? districtCode.value : this.districtCode,
    uploadStatus: uploadStatus.present ? uploadStatus.value : this.uploadStatus,
    deviceStatus: deviceStatus.present ? deviceStatus.value : this.deviceStatus,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppDeviceBindRow copyWithCompanion(AppDeviceBindCompanion data) {
    return AppDeviceBindRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      transmitterSn: data.transmitterSn.present
          ? data.transmitterSn.value
          : this.transmitterSn,
      sensorSn: data.sensorSn.present ? data.sensorSn.value : this.sensorSn,
      bluetoothAddr: data.bluetoothAddr.present
          ? data.bluetoothAddr.value
          : this.bluetoothAddr,
      deviceType: data.deviceType.present
          ? data.deviceType.value
          : this.deviceType,
      instanceForm: data.instanceForm.present
          ? data.instanceForm.value
          : this.instanceForm,
      expireDate: data.expireDate.present
          ? data.expireDate.value
          : this.expireDate,
      firmwareVersion: data.firmwareVersion.present
          ? data.firmwareVersion.value
          : this.firmwareVersion,
      softParams: data.softParams.present
          ? data.softParams.value
          : this.softParams,
      firmwareParams: data.firmwareParams.present
          ? data.firmwareParams.value
          : this.firmwareParams,
      bindLatitude: data.bindLatitude.present
          ? data.bindLatitude.value
          : this.bindLatitude,
      bindLongitude: data.bindLongitude.present
          ? data.bindLongitude.value
          : this.bindLongitude,
      cityCode: data.cityCode.present ? data.cityCode.value : this.cityCode,
      districtCode: data.districtCode.present
          ? data.districtCode.value
          : this.districtCode,
      uploadStatus: data.uploadStatus.present
          ? data.uploadStatus.value
          : this.uploadStatus,
      deviceStatus: data.deviceStatus.present
          ? data.deviceStatus.value
          : this.deviceStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppDeviceBindRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('wearId: $wearId, ')
          ..write('transmitterSn: $transmitterSn, ')
          ..write('sensorSn: $sensorSn, ')
          ..write('bluetoothAddr: $bluetoothAddr, ')
          ..write('deviceType: $deviceType, ')
          ..write('instanceForm: $instanceForm, ')
          ..write('expireDate: $expireDate, ')
          ..write('firmwareVersion: $firmwareVersion, ')
          ..write('softParams: $softParams, ')
          ..write('firmwareParams: $firmwareParams, ')
          ..write('bindLatitude: $bindLatitude, ')
          ..write('bindLongitude: $bindLongitude, ')
          ..write('cityCode: $cityCode, ')
          ..write('districtCode: $districtCode, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('deviceStatus: $deviceStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    wearId,
    transmitterSn,
    sensorSn,
    bluetoothAddr,
    deviceType,
    instanceForm,
    expireDate,
    firmwareVersion,
    softParams,
    firmwareParams,
    bindLatitude,
    bindLongitude,
    cityCode,
    districtCode,
    uploadStatus,
    deviceStatus,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppDeviceBindRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.wearId == this.wearId &&
          other.transmitterSn == this.transmitterSn &&
          other.sensorSn == this.sensorSn &&
          other.bluetoothAddr == this.bluetoothAddr &&
          other.deviceType == this.deviceType &&
          other.instanceForm == this.instanceForm &&
          other.expireDate == this.expireDate &&
          other.firmwareVersion == this.firmwareVersion &&
          other.softParams == this.softParams &&
          other.firmwareParams == this.firmwareParams &&
          other.bindLatitude == this.bindLatitude &&
          other.bindLongitude == this.bindLongitude &&
          other.cityCode == this.cityCode &&
          other.districtCode == this.districtCode &&
          other.uploadStatus == this.uploadStatus &&
          other.deviceStatus == this.deviceStatus &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppDeviceBindCompanion extends UpdateCompanion<AppDeviceBindRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int?> wearId;
  final Value<String?> transmitterSn;
  final Value<String?> sensorSn;
  final Value<String?> bluetoothAddr;
  final Value<String?> deviceType;
  final Value<String?> instanceForm;
  final Value<String?> expireDate;
  final Value<String?> firmwareVersion;
  final Value<String?> softParams;
  final Value<String?> firmwareParams;
  final Value<double?> bindLatitude;
  final Value<double?> bindLongitude;
  final Value<String?> cityCode;
  final Value<String?> districtCode;
  final Value<String?> uploadStatus;
  final Value<String?> deviceStatus;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const AppDeviceBindCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.transmitterSn = const Value.absent(),
    this.sensorSn = const Value.absent(),
    this.bluetoothAddr = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.instanceForm = const Value.absent(),
    this.expireDate = const Value.absent(),
    this.firmwareVersion = const Value.absent(),
    this.softParams = const Value.absent(),
    this.firmwareParams = const Value.absent(),
    this.bindLatitude = const Value.absent(),
    this.bindLongitude = const Value.absent(),
    this.cityCode = const Value.absent(),
    this.districtCode = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.deviceStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppDeviceBindCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.wearId = const Value.absent(),
    this.transmitterSn = const Value.absent(),
    this.sensorSn = const Value.absent(),
    this.bluetoothAddr = const Value.absent(),
    this.deviceType = const Value.absent(),
    this.instanceForm = const Value.absent(),
    this.expireDate = const Value.absent(),
    this.firmwareVersion = const Value.absent(),
    this.softParams = const Value.absent(),
    this.firmwareParams = const Value.absent(),
    this.bindLatitude = const Value.absent(),
    this.bindLongitude = const Value.absent(),
    this.cityCode = const Value.absent(),
    this.districtCode = const Value.absent(),
    this.uploadStatus = const Value.absent(),
    this.deviceStatus = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : userId = Value(userId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AppDeviceBindRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? wearId,
    Expression<String>? transmitterSn,
    Expression<String>? sensorSn,
    Expression<String>? bluetoothAddr,
    Expression<String>? deviceType,
    Expression<String>? instanceForm,
    Expression<String>? expireDate,
    Expression<String>? firmwareVersion,
    Expression<String>? softParams,
    Expression<String>? firmwareParams,
    Expression<double>? bindLatitude,
    Expression<double>? bindLongitude,
    Expression<String>? cityCode,
    Expression<String>? districtCode,
    Expression<String>? uploadStatus,
    Expression<String>? deviceStatus,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (wearId != null) 'wear_id': wearId,
      if (transmitterSn != null) 'transmitter_sn': transmitterSn,
      if (sensorSn != null) 'sensor_sn': sensorSn,
      if (bluetoothAddr != null) 'bluetooth_addr': bluetoothAddr,
      if (deviceType != null) 'device_type': deviceType,
      if (instanceForm != null) 'instance_form': instanceForm,
      if (expireDate != null) 'expire_date': expireDate,
      if (firmwareVersion != null) 'firmware_version': firmwareVersion,
      if (softParams != null) 'soft_params': softParams,
      if (firmwareParams != null) 'firmware_params': firmwareParams,
      if (bindLatitude != null) 'bind_latitude': bindLatitude,
      if (bindLongitude != null) 'bind_longitude': bindLongitude,
      if (cityCode != null) 'city_code': cityCode,
      if (districtCode != null) 'district_code': districtCode,
      if (uploadStatus != null) 'upload_status': uploadStatus,
      if (deviceStatus != null) 'device_status': deviceStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppDeviceBindCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int?>? wearId,
    Value<String?>? transmitterSn,
    Value<String?>? sensorSn,
    Value<String?>? bluetoothAddr,
    Value<String?>? deviceType,
    Value<String?>? instanceForm,
    Value<String?>? expireDate,
    Value<String?>? firmwareVersion,
    Value<String?>? softParams,
    Value<String?>? firmwareParams,
    Value<double?>? bindLatitude,
    Value<double?>? bindLongitude,
    Value<String?>? cityCode,
    Value<String?>? districtCode,
    Value<String?>? uploadStatus,
    Value<String?>? deviceStatus,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return AppDeviceBindCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      wearId: wearId ?? this.wearId,
      transmitterSn: transmitterSn ?? this.transmitterSn,
      sensorSn: sensorSn ?? this.sensorSn,
      bluetoothAddr: bluetoothAddr ?? this.bluetoothAddr,
      deviceType: deviceType ?? this.deviceType,
      instanceForm: instanceForm ?? this.instanceForm,
      expireDate: expireDate ?? this.expireDate,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      softParams: softParams ?? this.softParams,
      firmwareParams: firmwareParams ?? this.firmwareParams,
      bindLatitude: bindLatitude ?? this.bindLatitude,
      bindLongitude: bindLongitude ?? this.bindLongitude,
      cityCode: cityCode ?? this.cityCode,
      districtCode: districtCode ?? this.districtCode,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (transmitterSn.present) {
      map['transmitter_sn'] = Variable<String>(transmitterSn.value);
    }
    if (sensorSn.present) {
      map['sensor_sn'] = Variable<String>(sensorSn.value);
    }
    if (bluetoothAddr.present) {
      map['bluetooth_addr'] = Variable<String>(bluetoothAddr.value);
    }
    if (deviceType.present) {
      map['device_type'] = Variable<String>(deviceType.value);
    }
    if (instanceForm.present) {
      map['instance_form'] = Variable<String>(instanceForm.value);
    }
    if (expireDate.present) {
      map['expire_date'] = Variable<String>(expireDate.value);
    }
    if (firmwareVersion.present) {
      map['firmware_version'] = Variable<String>(firmwareVersion.value);
    }
    if (softParams.present) {
      map['soft_params'] = Variable<String>(softParams.value);
    }
    if (firmwareParams.present) {
      map['firmware_params'] = Variable<String>(firmwareParams.value);
    }
    if (bindLatitude.present) {
      map['bind_latitude'] = Variable<double>(bindLatitude.value);
    }
    if (bindLongitude.present) {
      map['bind_longitude'] = Variable<double>(bindLongitude.value);
    }
    if (cityCode.present) {
      map['city_code'] = Variable<String>(cityCode.value);
    }
    if (districtCode.present) {
      map['district_code'] = Variable<String>(districtCode.value);
    }
    if (uploadStatus.present) {
      map['upload_status'] = Variable<String>(uploadStatus.value);
    }
    if (deviceStatus.present) {
      map['device_status'] = Variable<String>(deviceStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppDeviceBindCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('wearId: $wearId, ')
          ..write('transmitterSn: $transmitterSn, ')
          ..write('sensorSn: $sensorSn, ')
          ..write('bluetoothAddr: $bluetoothAddr, ')
          ..write('deviceType: $deviceType, ')
          ..write('instanceForm: $instanceForm, ')
          ..write('expireDate: $expireDate, ')
          ..write('firmwareVersion: $firmwareVersion, ')
          ..write('softParams: $softParams, ')
          ..write('firmwareParams: $firmwareParams, ')
          ..write('bindLatitude: $bindLatitude, ')
          ..write('bindLongitude: $bindLongitude, ')
          ..write('cityCode: $cityCode, ')
          ..write('districtCode: $districtCode, ')
          ..write('uploadStatus: $uploadStatus, ')
          ..write('deviceStatus: $deviceStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $UserWearCurTable extends UserWearCur
    with TableInfo<$UserWearCurTable, UserWearCurRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWearCurTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> activeTime =
      GeneratedColumn<int>(
        'active_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearCurTable.$converteractiveTimen);
  static const VerificationMeta _transmitterIdMeta = const VerificationMeta(
    'transmitterId',
  );
  @override
  late final GeneratedColumn<int> transmitterId = GeneratedColumn<int>(
    'transmitter_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transmitterSnMeta = const VerificationMeta(
    'transmitterSn',
  );
  @override
  late final GeneratedColumn<String> transmitterSn = GeneratedColumn<String>(
    'transmitter_sn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensorIdMeta = const VerificationMeta(
    'sensorId',
  );
  @override
  late final GeneratedColumn<int> sensorId = GeneratedColumn<int>(
    'sensor_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sensorSnMeta = const VerificationMeta(
    'sensorSn',
  );
  @override
  late final GeneratedColumn<String> sensorSn = GeneratedColumn<String>(
    'sensor_sn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastWearTime =
      GeneratedColumn<int>(
        'last_wear_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearCurTable.$converterlastWearTimen);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastDataUptime =
      GeneratedColumn<int>(
        'last_data_uptime',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearCurTable.$converterlastDataUptimen);
  static const VerificationMeta _lastGlucoseMeta = const VerificationMeta(
    'lastGlucose',
  );
  @override
  late final GeneratedColumn<String> lastGlucose = GeneratedColumn<String>(
    'last_glucose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearCurTable.$convertercreateTimen);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> updateTime =
      GeneratedColumn<int>(
        'update_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearCurTable.$converterupdateTimen);
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    accountId,
    wearId,
    activeTime,
    transmitterId,
    transmitterSn,
    sensorId,
    sensorSn,
    lastWearTime,
    lastDataUptime,
    lastGlucose,
    createTime,
    updateTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_wear_cur';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWearCurRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('transmitter_id')) {
      context.handle(
        _transmitterIdMeta,
        transmitterId.isAcceptableOrUnknown(
          data['transmitter_id']!,
          _transmitterIdMeta,
        ),
      );
    }
    if (data.containsKey('transmitter_sn')) {
      context.handle(
        _transmitterSnMeta,
        transmitterSn.isAcceptableOrUnknown(
          data['transmitter_sn']!,
          _transmitterSnMeta,
        ),
      );
    }
    if (data.containsKey('sensor_id')) {
      context.handle(
        _sensorIdMeta,
        sensorId.isAcceptableOrUnknown(data['sensor_id']!, _sensorIdMeta),
      );
    }
    if (data.containsKey('sensor_sn')) {
      context.handle(
        _sensorSnMeta,
        sensorSn.isAcceptableOrUnknown(data['sensor_sn']!, _sensorSnMeta),
      );
    }
    if (data.containsKey('last_glucose')) {
      context.handle(
        _lastGlucoseMeta,
        lastGlucose.isAcceptableOrUnknown(
          data['last_glucose']!,
          _lastGlucoseMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  UserWearCurRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWearCurRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      activeTime: $UserWearCurTable.$converteractiveTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}active_time'],
        ),
      ),
      transmitterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transmitter_id'],
      ),
      transmitterSn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transmitter_sn'],
      ),
      sensorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sensor_id'],
      ),
      sensorSn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sensor_sn'],
      ),
      lastWearTime: $UserWearCurTable.$converterlastWearTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_wear_time'],
        ),
      ),
      lastDataUptime: $UserWearCurTable.$converterlastDataUptimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_data_uptime'],
        ),
      ),
      lastGlucose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_glucose'],
      ),
      createTime: $UserWearCurTable.$convertercreateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}create_time'],
        ),
      ),
      updateTime: $UserWearCurTable.$converterupdateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}update_time'],
        ),
      ),
    );
  }

  @override
  $UserWearCurTable createAlias(String alias) {
    return $UserWearCurTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converteractiveTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $converteractiveTimen =
      NullAwareTypeConverter.wrap($converteractiveTime);
  static TypeConverter<DateTime, int> $converterlastWearTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $converterlastWearTimen =
      NullAwareTypeConverter.wrap($converterlastWearTime);
  static TypeConverter<DateTime, int> $converterlastDataUptime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $converterlastDataUptimen =
      NullAwareTypeConverter.wrap($converterlastDataUptime);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
  static TypeConverter<DateTime, int> $converterupdateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $converterupdateTimen =
      NullAwareTypeConverter.wrap($converterupdateTime);
}

class UserWearCurRow extends DataClass implements Insertable<UserWearCurRow> {
  final int userId;

  /// Lianxin type incorrectly filled in `biging`（answer bigint），fall int64。
  final int? accountId;
  final int? wearId;
  final DateTime? activeTime;
  final int? transmitterId;
  final String? transmitterSn;
  final int? sensorId;
  final String? sensorSn;
  final DateTime? lastWearTime;
  final DateTime? lastDataUptime;

  /// Latest blood sugar value
  final String? lastGlucose;
  final DateTime? createTime;
  final DateTime? updateTime;
  const UserWearCurRow({
    required this.userId,
    this.accountId,
    this.wearId,
    this.activeTime,
    this.transmitterId,
    this.transmitterSn,
    this.sensorId,
    this.sensorSn,
    this.lastWearTime,
    this.lastDataUptime,
    this.lastGlucose,
    this.createTime,
    this.updateTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    if (!nullToAbsent || activeTime != null) {
      map['active_time'] = Variable<int>(
        $UserWearCurTable.$converteractiveTimen.toSql(activeTime),
      );
    }
    if (!nullToAbsent || transmitterId != null) {
      map['transmitter_id'] = Variable<int>(transmitterId);
    }
    if (!nullToAbsent || transmitterSn != null) {
      map['transmitter_sn'] = Variable<String>(transmitterSn);
    }
    if (!nullToAbsent || sensorId != null) {
      map['sensor_id'] = Variable<int>(sensorId);
    }
    if (!nullToAbsent || sensorSn != null) {
      map['sensor_sn'] = Variable<String>(sensorSn);
    }
    if (!nullToAbsent || lastWearTime != null) {
      map['last_wear_time'] = Variable<int>(
        $UserWearCurTable.$converterlastWearTimen.toSql(lastWearTime),
      );
    }
    if (!nullToAbsent || lastDataUptime != null) {
      map['last_data_uptime'] = Variable<int>(
        $UserWearCurTable.$converterlastDataUptimen.toSql(lastDataUptime),
      );
    }
    if (!nullToAbsent || lastGlucose != null) {
      map['last_glucose'] = Variable<String>(lastGlucose);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserWearCurTable.$convertercreateTimen.toSql(createTime),
      );
    }
    if (!nullToAbsent || updateTime != null) {
      map['update_time'] = Variable<int>(
        $UserWearCurTable.$converterupdateTimen.toSql(updateTime),
      );
    }
    return map;
  }

  UserWearCurCompanion toCompanion(bool nullToAbsent) {
    return UserWearCurCompanion(
      userId: Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      activeTime: activeTime == null && nullToAbsent
          ? const Value.absent()
          : Value(activeTime),
      transmitterId: transmitterId == null && nullToAbsent
          ? const Value.absent()
          : Value(transmitterId),
      transmitterSn: transmitterSn == null && nullToAbsent
          ? const Value.absent()
          : Value(transmitterSn),
      sensorId: sensorId == null && nullToAbsent
          ? const Value.absent()
          : Value(sensorId),
      sensorSn: sensorSn == null && nullToAbsent
          ? const Value.absent()
          : Value(sensorSn),
      lastWearTime: lastWearTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWearTime),
      lastDataUptime: lastDataUptime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDataUptime),
      lastGlucose: lastGlucose == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGlucose),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
      updateTime: updateTime == null && nullToAbsent
          ? const Value.absent()
          : Value(updateTime),
    );
  }

  factory UserWearCurRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWearCurRow(
      userId: serializer.fromJson<int>(json['userId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      activeTime: serializer.fromJson<DateTime?>(json['activeTime']),
      transmitterId: serializer.fromJson<int?>(json['transmitterId']),
      transmitterSn: serializer.fromJson<String?>(json['transmitterSn']),
      sensorId: serializer.fromJson<int?>(json['sensorId']),
      sensorSn: serializer.fromJson<String?>(json['sensorSn']),
      lastWearTime: serializer.fromJson<DateTime?>(json['lastWearTime']),
      lastDataUptime: serializer.fromJson<DateTime?>(json['lastDataUptime']),
      lastGlucose: serializer.fromJson<String?>(json['lastGlucose']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
      updateTime: serializer.fromJson<DateTime?>(json['updateTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<int>(userId),
      'accountId': serializer.toJson<int?>(accountId),
      'wearId': serializer.toJson<int?>(wearId),
      'activeTime': serializer.toJson<DateTime?>(activeTime),
      'transmitterId': serializer.toJson<int?>(transmitterId),
      'transmitterSn': serializer.toJson<String?>(transmitterSn),
      'sensorId': serializer.toJson<int?>(sensorId),
      'sensorSn': serializer.toJson<String?>(sensorSn),
      'lastWearTime': serializer.toJson<DateTime?>(lastWearTime),
      'lastDataUptime': serializer.toJson<DateTime?>(lastDataUptime),
      'lastGlucose': serializer.toJson<String?>(lastGlucose),
      'createTime': serializer.toJson<DateTime?>(createTime),
      'updateTime': serializer.toJson<DateTime?>(updateTime),
    };
  }

  UserWearCurRow copyWith({
    int? userId,
    Value<int?> accountId = const Value.absent(),
    Value<int?> wearId = const Value.absent(),
    Value<DateTime?> activeTime = const Value.absent(),
    Value<int?> transmitterId = const Value.absent(),
    Value<String?> transmitterSn = const Value.absent(),
    Value<int?> sensorId = const Value.absent(),
    Value<String?> sensorSn = const Value.absent(),
    Value<DateTime?> lastWearTime = const Value.absent(),
    Value<DateTime?> lastDataUptime = const Value.absent(),
    Value<String?> lastGlucose = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
    Value<DateTime?> updateTime = const Value.absent(),
  }) => UserWearCurRow(
    userId: userId ?? this.userId,
    accountId: accountId.present ? accountId.value : this.accountId,
    wearId: wearId.present ? wearId.value : this.wearId,
    activeTime: activeTime.present ? activeTime.value : this.activeTime,
    transmitterId: transmitterId.present
        ? transmitterId.value
        : this.transmitterId,
    transmitterSn: transmitterSn.present
        ? transmitterSn.value
        : this.transmitterSn,
    sensorId: sensorId.present ? sensorId.value : this.sensorId,
    sensorSn: sensorSn.present ? sensorSn.value : this.sensorSn,
    lastWearTime: lastWearTime.present ? lastWearTime.value : this.lastWearTime,
    lastDataUptime: lastDataUptime.present
        ? lastDataUptime.value
        : this.lastDataUptime,
    lastGlucose: lastGlucose.present ? lastGlucose.value : this.lastGlucose,
    createTime: createTime.present ? createTime.value : this.createTime,
    updateTime: updateTime.present ? updateTime.value : this.updateTime,
  );
  UserWearCurRow copyWithCompanion(UserWearCurCompanion data) {
    return UserWearCurRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      activeTime: data.activeTime.present
          ? data.activeTime.value
          : this.activeTime,
      transmitterId: data.transmitterId.present
          ? data.transmitterId.value
          : this.transmitterId,
      transmitterSn: data.transmitterSn.present
          ? data.transmitterSn.value
          : this.transmitterSn,
      sensorId: data.sensorId.present ? data.sensorId.value : this.sensorId,
      sensorSn: data.sensorSn.present ? data.sensorSn.value : this.sensorSn,
      lastWearTime: data.lastWearTime.present
          ? data.lastWearTime.value
          : this.lastWearTime,
      lastDataUptime: data.lastDataUptime.present
          ? data.lastDataUptime.value
          : this.lastDataUptime,
      lastGlucose: data.lastGlucose.present
          ? data.lastGlucose.value
          : this.lastGlucose,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      updateTime: data.updateTime.present
          ? data.updateTime.value
          : this.updateTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWearCurRow(')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('activeTime: $activeTime, ')
          ..write('transmitterId: $transmitterId, ')
          ..write('transmitterSn: $transmitterSn, ')
          ..write('sensorId: $sensorId, ')
          ..write('sensorSn: $sensorSn, ')
          ..write('lastWearTime: $lastWearTime, ')
          ..write('lastDataUptime: $lastDataUptime, ')
          ..write('lastGlucose: $lastGlucose, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    accountId,
    wearId,
    activeTime,
    transmitterId,
    transmitterSn,
    sensorId,
    sensorSn,
    lastWearTime,
    lastDataUptime,
    lastGlucose,
    createTime,
    updateTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWearCurRow &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.wearId == this.wearId &&
          other.activeTime == this.activeTime &&
          other.transmitterId == this.transmitterId &&
          other.transmitterSn == this.transmitterSn &&
          other.sensorId == this.sensorId &&
          other.sensorSn == this.sensorSn &&
          other.lastWearTime == this.lastWearTime &&
          other.lastDataUptime == this.lastDataUptime &&
          other.lastGlucose == this.lastGlucose &&
          other.createTime == this.createTime &&
          other.updateTime == this.updateTime);
}

class UserWearCurCompanion extends UpdateCompanion<UserWearCurRow> {
  final Value<int> userId;
  final Value<int?> accountId;
  final Value<int?> wearId;
  final Value<DateTime?> activeTime;
  final Value<int?> transmitterId;
  final Value<String?> transmitterSn;
  final Value<int?> sensorId;
  final Value<String?> sensorSn;
  final Value<DateTime?> lastWearTime;
  final Value<DateTime?> lastDataUptime;
  final Value<String?> lastGlucose;
  final Value<DateTime?> createTime;
  final Value<DateTime?> updateTime;
  const UserWearCurCompanion({
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.activeTime = const Value.absent(),
    this.transmitterId = const Value.absent(),
    this.transmitterSn = const Value.absent(),
    this.sensorId = const Value.absent(),
    this.sensorSn = const Value.absent(),
    this.lastWearTime = const Value.absent(),
    this.lastDataUptime = const Value.absent(),
    this.lastGlucose = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
  });
  UserWearCurCompanion.insert({
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.activeTime = const Value.absent(),
    this.transmitterId = const Value.absent(),
    this.transmitterSn = const Value.absent(),
    this.sensorId = const Value.absent(),
    this.sensorSn = const Value.absent(),
    this.lastWearTime = const Value.absent(),
    this.lastDataUptime = const Value.absent(),
    this.lastGlucose = const Value.absent(),
    this.createTime = const Value.absent(),
    this.updateTime = const Value.absent(),
  });
  static Insertable<UserWearCurRow> custom({
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? wearId,
    Expression<int>? activeTime,
    Expression<int>? transmitterId,
    Expression<String>? transmitterSn,
    Expression<int>? sensorId,
    Expression<String>? sensorSn,
    Expression<int>? lastWearTime,
    Expression<int>? lastDataUptime,
    Expression<String>? lastGlucose,
    Expression<int>? createTime,
    Expression<int>? updateTime,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (wearId != null) 'wear_id': wearId,
      if (activeTime != null) 'active_time': activeTime,
      if (transmitterId != null) 'transmitter_id': transmitterId,
      if (transmitterSn != null) 'transmitter_sn': transmitterSn,
      if (sensorId != null) 'sensor_id': sensorId,
      if (sensorSn != null) 'sensor_sn': sensorSn,
      if (lastWearTime != null) 'last_wear_time': lastWearTime,
      if (lastDataUptime != null) 'last_data_uptime': lastDataUptime,
      if (lastGlucose != null) 'last_glucose': lastGlucose,
      if (createTime != null) 'create_time': createTime,
      if (updateTime != null) 'update_time': updateTime,
    });
  }

  UserWearCurCompanion copyWith({
    Value<int>? userId,
    Value<int?>? accountId,
    Value<int?>? wearId,
    Value<DateTime?>? activeTime,
    Value<int?>? transmitterId,
    Value<String?>? transmitterSn,
    Value<int?>? sensorId,
    Value<String?>? sensorSn,
    Value<DateTime?>? lastWearTime,
    Value<DateTime?>? lastDataUptime,
    Value<String?>? lastGlucose,
    Value<DateTime?>? createTime,
    Value<DateTime?>? updateTime,
  }) {
    return UserWearCurCompanion(
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      wearId: wearId ?? this.wearId,
      activeTime: activeTime ?? this.activeTime,
      transmitterId: transmitterId ?? this.transmitterId,
      transmitterSn: transmitterSn ?? this.transmitterSn,
      sensorId: sensorId ?? this.sensorId,
      sensorSn: sensorSn ?? this.sensorSn,
      lastWearTime: lastWearTime ?? this.lastWearTime,
      lastDataUptime: lastDataUptime ?? this.lastDataUptime,
      lastGlucose: lastGlucose ?? this.lastGlucose,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (activeTime.present) {
      map['active_time'] = Variable<int>(
        $UserWearCurTable.$converteractiveTimen.toSql(activeTime.value),
      );
    }
    if (transmitterId.present) {
      map['transmitter_id'] = Variable<int>(transmitterId.value);
    }
    if (transmitterSn.present) {
      map['transmitter_sn'] = Variable<String>(transmitterSn.value);
    }
    if (sensorId.present) {
      map['sensor_id'] = Variable<int>(sensorId.value);
    }
    if (sensorSn.present) {
      map['sensor_sn'] = Variable<String>(sensorSn.value);
    }
    if (lastWearTime.present) {
      map['last_wear_time'] = Variable<int>(
        $UserWearCurTable.$converterlastWearTimen.toSql(lastWearTime.value),
      );
    }
    if (lastDataUptime.present) {
      map['last_data_uptime'] = Variable<int>(
        $UserWearCurTable.$converterlastDataUptimen.toSql(lastDataUptime.value),
      );
    }
    if (lastGlucose.present) {
      map['last_glucose'] = Variable<String>(lastGlucose.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserWearCurTable.$convertercreateTimen.toSql(createTime.value),
      );
    }
    if (updateTime.present) {
      map['update_time'] = Variable<int>(
        $UserWearCurTable.$converterupdateTimen.toSql(updateTime.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWearCurCompanion(')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('activeTime: $activeTime, ')
          ..write('transmitterId: $transmitterId, ')
          ..write('transmitterSn: $transmitterSn, ')
          ..write('sensorId: $sensorId, ')
          ..write('sensorSn: $sensorSn, ')
          ..write('lastWearTime: $lastWearTime, ')
          ..write('lastDataUptime: $lastDataUptime, ')
          ..write('lastGlucose: $lastGlucose, ')
          ..write('createTime: $createTime, ')
          ..write('updateTime: $updateTime')
          ..write(')'))
        .toString();
  }
}

class $UserWearStatusLogTable extends UserWearStatusLog
    with TableInfo<$UserWearStatusLogTable, UserWearStatusLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserWearStatusLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleStatusMeta = const VerificationMeta(
    'handleStatus',
  );
  @override
  late final GeneratedColumn<String> handleStatus = GeneratedColumn<String>(
    'handle_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> handleTime =
      GeneratedColumn<int>(
        'handle_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearStatusLogTable.$converterhandleTimen);
  static const VerificationMeta _unbindResonMeta = const VerificationMeta(
    'unbindReson',
  );
  @override
  late final GeneratedColumn<String> unbindReson = GeneratedColumn<String>(
    'unbind_reson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($UserWearStatusLogTable.$convertercreateTimen);
  static const VerificationMeta _uploadFlagMeta = const VerificationMeta(
    'uploadFlag',
  );
  @override
  late final GeneratedColumn<String> uploadFlag = GeneratedColumn<String>(
    'upload_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadResultMeta = const VerificationMeta(
    'uploadResult',
  );
  @override
  late final GeneratedColumn<String> uploadResult = GeneratedColumn<String>(
    'upload_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFailResonMeta = const VerificationMeta(
    'uploadFailReson',
  );
  @override
  late final GeneratedColumn<String> uploadFailReson = GeneratedColumn<String>(
    'upload_fail_reson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    accountId,
    wearId,
    handleStatus,
    handleTime,
    unbindReson,
    createTime,
    uploadFlag,
    uploadResult,
    uploadFailReson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_wear_status_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserWearStatusLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wearIdMeta);
    }
    if (data.containsKey('handle_status')) {
      context.handle(
        _handleStatusMeta,
        handleStatus.isAcceptableOrUnknown(
          data['handle_status']!,
          _handleStatusMeta,
        ),
      );
    }
    if (data.containsKey('unbind_reson')) {
      context.handle(
        _unbindResonMeta,
        unbindReson.isAcceptableOrUnknown(
          data['unbind_reson']!,
          _unbindResonMeta,
        ),
      );
    }
    if (data.containsKey('upload_flag')) {
      context.handle(
        _uploadFlagMeta,
        uploadFlag.isAcceptableOrUnknown(data['upload_flag']!, _uploadFlagMeta),
      );
    }
    if (data.containsKey('upload_result')) {
      context.handle(
        _uploadResultMeta,
        uploadResult.isAcceptableOrUnknown(
          data['upload_result']!,
          _uploadResultMeta,
        ),
      );
    }
    if (data.containsKey('upload_fail_reson')) {
      context.handle(
        _uploadFailResonMeta,
        uploadFailReson.isAcceptableOrUnknown(
          data['upload_fail_reson']!,
          _uploadFailResonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserWearStatusLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserWearStatusLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      )!,
      handleStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle_status'],
      ),
      handleTime: $UserWearStatusLogTable.$converterhandleTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}handle_time'],
        ),
      ),
      unbindReson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unbind_reson'],
      ),
      createTime: $UserWearStatusLogTable.$convertercreateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}create_time'],
        ),
      ),
      uploadFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_flag'],
      ),
      uploadResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_result'],
      ),
      uploadFailReson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_fail_reson'],
      ),
    );
  }

  @override
  $UserWearStatusLogTable createAlias(String alias) {
    return $UserWearStatusLogTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterhandleTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $converterhandleTimen =
      NullAwareTypeConverter.wrap($converterhandleTime);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
}

class UserWearStatusLogRow extends DataClass
    implements Insertable<UserWearStatusLogRow> {
  final int id;
  final int userId;
  final int accountId;
  final int wearId;

  /// 1=Binding successful，2=End of warm-up，3=unbundle
  final String? handleStatus;
  final DateTime? handleTime;
  final String? unbindReson;
  final DateTime? createTime;

  /// 1=yes，0=no
  final String? uploadFlag;

  /// 1=success，0=fail
  final String? uploadResult;
  final String? uploadFailReson;
  const UserWearStatusLogRow({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.wearId,
    this.handleStatus,
    this.handleTime,
    this.unbindReson,
    this.createTime,
    this.uploadFlag,
    this.uploadResult,
    this.uploadFailReson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['account_id'] = Variable<int>(accountId);
    map['wear_id'] = Variable<int>(wearId);
    if (!nullToAbsent || handleStatus != null) {
      map['handle_status'] = Variable<String>(handleStatus);
    }
    if (!nullToAbsent || handleTime != null) {
      map['handle_time'] = Variable<int>(
        $UserWearStatusLogTable.$converterhandleTimen.toSql(handleTime),
      );
    }
    if (!nullToAbsent || unbindReson != null) {
      map['unbind_reson'] = Variable<String>(unbindReson);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserWearStatusLogTable.$convertercreateTimen.toSql(createTime),
      );
    }
    if (!nullToAbsent || uploadFlag != null) {
      map['upload_flag'] = Variable<String>(uploadFlag);
    }
    if (!nullToAbsent || uploadResult != null) {
      map['upload_result'] = Variable<String>(uploadResult);
    }
    if (!nullToAbsent || uploadFailReson != null) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson);
    }
    return map;
  }

  UserWearStatusLogCompanion toCompanion(bool nullToAbsent) {
    return UserWearStatusLogCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: Value(accountId),
      wearId: Value(wearId),
      handleStatus: handleStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(handleStatus),
      handleTime: handleTime == null && nullToAbsent
          ? const Value.absent()
          : Value(handleTime),
      unbindReson: unbindReson == null && nullToAbsent
          ? const Value.absent()
          : Value(unbindReson),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
      uploadFlag: uploadFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFlag),
      uploadResult: uploadResult == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadResult),
      uploadFailReson: uploadFailReson == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFailReson),
    );
  }

  factory UserWearStatusLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserWearStatusLogRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      wearId: serializer.fromJson<int>(json['wearId']),
      handleStatus: serializer.fromJson<String?>(json['handleStatus']),
      handleTime: serializer.fromJson<DateTime?>(json['handleTime']),
      unbindReson: serializer.fromJson<String?>(json['unbindReson']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
      uploadFlag: serializer.fromJson<String?>(json['uploadFlag']),
      uploadResult: serializer.fromJson<String?>(json['uploadResult']),
      uploadFailReson: serializer.fromJson<String?>(json['uploadFailReson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'accountId': serializer.toJson<int>(accountId),
      'wearId': serializer.toJson<int>(wearId),
      'handleStatus': serializer.toJson<String?>(handleStatus),
      'handleTime': serializer.toJson<DateTime?>(handleTime),
      'unbindReson': serializer.toJson<String?>(unbindReson),
      'createTime': serializer.toJson<DateTime?>(createTime),
      'uploadFlag': serializer.toJson<String?>(uploadFlag),
      'uploadResult': serializer.toJson<String?>(uploadResult),
      'uploadFailReson': serializer.toJson<String?>(uploadFailReson),
    };
  }

  UserWearStatusLogRow copyWith({
    int? id,
    int? userId,
    int? accountId,
    int? wearId,
    Value<String?> handleStatus = const Value.absent(),
    Value<DateTime?> handleTime = const Value.absent(),
    Value<String?> unbindReson = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
    Value<String?> uploadFlag = const Value.absent(),
    Value<String?> uploadResult = const Value.absent(),
    Value<String?> uploadFailReson = const Value.absent(),
  }) => UserWearStatusLogRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    accountId: accountId ?? this.accountId,
    wearId: wearId ?? this.wearId,
    handleStatus: handleStatus.present ? handleStatus.value : this.handleStatus,
    handleTime: handleTime.present ? handleTime.value : this.handleTime,
    unbindReson: unbindReson.present ? unbindReson.value : this.unbindReson,
    createTime: createTime.present ? createTime.value : this.createTime,
    uploadFlag: uploadFlag.present ? uploadFlag.value : this.uploadFlag,
    uploadResult: uploadResult.present ? uploadResult.value : this.uploadResult,
    uploadFailReson: uploadFailReson.present
        ? uploadFailReson.value
        : this.uploadFailReson,
  );
  UserWearStatusLogRow copyWithCompanion(UserWearStatusLogCompanion data) {
    return UserWearStatusLogRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      handleStatus: data.handleStatus.present
          ? data.handleStatus.value
          : this.handleStatus,
      handleTime: data.handleTime.present
          ? data.handleTime.value
          : this.handleTime,
      unbindReson: data.unbindReson.present
          ? data.unbindReson.value
          : this.unbindReson,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
      uploadFlag: data.uploadFlag.present
          ? data.uploadFlag.value
          : this.uploadFlag,
      uploadResult: data.uploadResult.present
          ? data.uploadResult.value
          : this.uploadResult,
      uploadFailReson: data.uploadFailReson.present
          ? data.uploadFailReson.value
          : this.uploadFailReson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserWearStatusLogRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('handleStatus: $handleStatus, ')
          ..write('handleTime: $handleTime, ')
          ..write('unbindReson: $unbindReson, ')
          ..write('createTime: $createTime, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    accountId,
    wearId,
    handleStatus,
    handleTime,
    unbindReson,
    createTime,
    uploadFlag,
    uploadResult,
    uploadFailReson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserWearStatusLogRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.wearId == this.wearId &&
          other.handleStatus == this.handleStatus &&
          other.handleTime == this.handleTime &&
          other.unbindReson == this.unbindReson &&
          other.createTime == this.createTime &&
          other.uploadFlag == this.uploadFlag &&
          other.uploadResult == this.uploadResult &&
          other.uploadFailReson == this.uploadFailReson);
}

class UserWearStatusLogCompanion extends UpdateCompanion<UserWearStatusLogRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> accountId;
  final Value<int> wearId;
  final Value<String?> handleStatus;
  final Value<DateTime?> handleTime;
  final Value<String?> unbindReson;
  final Value<DateTime?> createTime;
  final Value<String?> uploadFlag;
  final Value<String?> uploadResult;
  final Value<String?> uploadFailReson;
  const UserWearStatusLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.handleStatus = const Value.absent(),
    this.handleTime = const Value.absent(),
    this.unbindReson = const Value.absent(),
    this.createTime = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
  });
  UserWearStatusLogCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int accountId,
    required int wearId,
    this.handleStatus = const Value.absent(),
    this.handleTime = const Value.absent(),
    this.unbindReson = const Value.absent(),
    this.createTime = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
  }) : userId = Value(userId),
       accountId = Value(accountId),
       wearId = Value(wearId);
  static Insertable<UserWearStatusLogRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? wearId,
    Expression<String>? handleStatus,
    Expression<int>? handleTime,
    Expression<String>? unbindReson,
    Expression<int>? createTime,
    Expression<String>? uploadFlag,
    Expression<String>? uploadResult,
    Expression<String>? uploadFailReson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (wearId != null) 'wear_id': wearId,
      if (handleStatus != null) 'handle_status': handleStatus,
      if (handleTime != null) 'handle_time': handleTime,
      if (unbindReson != null) 'unbind_reson': unbindReson,
      if (createTime != null) 'create_time': createTime,
      if (uploadFlag != null) 'upload_flag': uploadFlag,
      if (uploadResult != null) 'upload_result': uploadResult,
      if (uploadFailReson != null) 'upload_fail_reson': uploadFailReson,
    });
  }

  UserWearStatusLogCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? accountId,
    Value<int>? wearId,
    Value<String?>? handleStatus,
    Value<DateTime?>? handleTime,
    Value<String?>? unbindReson,
    Value<DateTime?>? createTime,
    Value<String?>? uploadFlag,
    Value<String?>? uploadResult,
    Value<String?>? uploadFailReson,
  }) {
    return UserWearStatusLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      wearId: wearId ?? this.wearId,
      handleStatus: handleStatus ?? this.handleStatus,
      handleTime: handleTime ?? this.handleTime,
      unbindReson: unbindReson ?? this.unbindReson,
      createTime: createTime ?? this.createTime,
      uploadFlag: uploadFlag ?? this.uploadFlag,
      uploadResult: uploadResult ?? this.uploadResult,
      uploadFailReson: uploadFailReson ?? this.uploadFailReson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (handleStatus.present) {
      map['handle_status'] = Variable<String>(handleStatus.value);
    }
    if (handleTime.present) {
      map['handle_time'] = Variable<int>(
        $UserWearStatusLogTable.$converterhandleTimen.toSql(handleTime.value),
      );
    }
    if (unbindReson.present) {
      map['unbind_reson'] = Variable<String>(unbindReson.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserWearStatusLogTable.$convertercreateTimen.toSql(createTime.value),
      );
    }
    if (uploadFlag.present) {
      map['upload_flag'] = Variable<String>(uploadFlag.value);
    }
    if (uploadResult.present) {
      map['upload_result'] = Variable<String>(uploadResult.value);
    }
    if (uploadFailReson.present) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserWearStatusLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('handleStatus: $handleStatus, ')
          ..write('handleTime: $handleTime, ')
          ..write('unbindReson: $unbindReson, ')
          ..write('createTime: $createTime, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson')
          ..write(')'))
        .toString();
  }
}

class $UserlocalGlucoseDataTable extends UserlocalGlucoseData
    with TableInfo<$UserlocalGlucoseDataTable, UserlocalGlucoseDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserlocalGlucoseDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> measureTime =
      GeneratedColumn<int>(
        'measure_time',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $UserlocalGlucoseDataTable.$convertermeasureTime,
      );
  static const VerificationMeta _recordSeqMeta = const VerificationMeta(
    'recordSeq',
  );
  @override
  late final GeneratedColumn<int> recordSeq = GeneratedColumn<int>(
    'record_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseValue1Meta = const VerificationMeta(
    'glucoseValue1',
  );
  @override
  late final GeneratedColumn<double> glucoseValue1 = GeneratedColumn<double>(
    'glucose_value1',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseValue2Meta = const VerificationMeta(
    'glucoseValue2',
  );
  @override
  late final GeneratedColumn<double> glucoseValue2 = GeneratedColumn<double>(
    'glucose_value2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiveMinFlagMeta = const VerificationMeta(
    'fiveMinFlag',
  );
  @override
  late final GeneratedColumn<String> fiveMinFlag = GeneratedColumn<String>(
    'five_min_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  fiveMinGlucose =
      GeneratedColumn<String>(
        'five_min_glucose',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseDataTable.$converterfiveMinGlucosen,
      );
  static const VerificationMeta _warmupFlagMeta = const VerificationMeta(
    'warmupFlag',
  );
  @override
  late final GeneratedColumn<String> warmupFlag = GeneratedColumn<String>(
    'warmup_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _abnormalFlagMeta = const VerificationMeta(
    'abnormalFlag',
  );
  @override
  late final GeneratedColumn<String> abnormalFlag = GeneratedColumn<String>(
    'abnormal_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedFlagMeta = const VerificationMeta(
    'modifiedFlag',
  );
  @override
  late final GeneratedColumn<String> modifiedFlag = GeneratedColumn<String>(
    'modified_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFlagMeta = const VerificationMeta(
    'uploadFlag',
  );
  @override
  late final GeneratedColumn<String> uploadFlag = GeneratedColumn<String>(
    'upload_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadResultMeta = const VerificationMeta(
    'uploadResult',
  );
  @override
  late final GeneratedColumn<String> uploadResult = GeneratedColumn<String>(
    'upload_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFailResonMeta = const VerificationMeta(
    'uploadFailReson',
  );
  @override
  late final GeneratedColumn<String> uploadFailReson = GeneratedColumn<String>(
    'upload_fail_reson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCloudDataMeta = const VerificationMeta(
    'isCloudData',
  );
  @override
  late final GeneratedColumn<String> isCloudData = GeneratedColumn<String>(
    'is_cloud_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalGlucoseDataTable.$convertercreateTimen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    accountId,
    wearId,
    measureTime,
    recordSeq,
    glucoseValue1,
    glucoseValue2,
    fiveMinFlag,
    fiveMinGlucose,
    warmupFlag,
    abnormalFlag,
    modifiedFlag,
    status,
    uploadFlag,
    uploadResult,
    uploadFailReson,
    isCloudData,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'userlocal_glucose_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserlocalGlucoseDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wearIdMeta);
    }
    if (data.containsKey('record_seq')) {
      context.handle(
        _recordSeqMeta,
        recordSeq.isAcceptableOrUnknown(data['record_seq']!, _recordSeqMeta),
      );
    }
    if (data.containsKey('glucose_value1')) {
      context.handle(
        _glucoseValue1Meta,
        glucoseValue1.isAcceptableOrUnknown(
          data['glucose_value1']!,
          _glucoseValue1Meta,
        ),
      );
    }
    if (data.containsKey('glucose_value2')) {
      context.handle(
        _glucoseValue2Meta,
        glucoseValue2.isAcceptableOrUnknown(
          data['glucose_value2']!,
          _glucoseValue2Meta,
        ),
      );
    }
    if (data.containsKey('five_min_flag')) {
      context.handle(
        _fiveMinFlagMeta,
        fiveMinFlag.isAcceptableOrUnknown(
          data['five_min_flag']!,
          _fiveMinFlagMeta,
        ),
      );
    }
    if (data.containsKey('warmup_flag')) {
      context.handle(
        _warmupFlagMeta,
        warmupFlag.isAcceptableOrUnknown(data['warmup_flag']!, _warmupFlagMeta),
      );
    }
    if (data.containsKey('abnormal_flag')) {
      context.handle(
        _abnormalFlagMeta,
        abnormalFlag.isAcceptableOrUnknown(
          data['abnormal_flag']!,
          _abnormalFlagMeta,
        ),
      );
    }
    if (data.containsKey('modified_flag')) {
      context.handle(
        _modifiedFlagMeta,
        modifiedFlag.isAcceptableOrUnknown(
          data['modified_flag']!,
          _modifiedFlagMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('upload_flag')) {
      context.handle(
        _uploadFlagMeta,
        uploadFlag.isAcceptableOrUnknown(data['upload_flag']!, _uploadFlagMeta),
      );
    }
    if (data.containsKey('upload_result')) {
      context.handle(
        _uploadResultMeta,
        uploadResult.isAcceptableOrUnknown(
          data['upload_result']!,
          _uploadResultMeta,
        ),
      );
    }
    if (data.containsKey('upload_fail_reson')) {
      context.handle(
        _uploadFailResonMeta,
        uploadFailReson.isAcceptableOrUnknown(
          data['upload_fail_reson']!,
          _uploadFailResonMeta,
        ),
      );
    }
    if (data.containsKey('is_cloud_data')) {
      context.handle(
        _isCloudDataMeta,
        isCloudData.isAcceptableOrUnknown(
          data['is_cloud_data']!,
          _isCloudDataMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserlocalGlucoseDataRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserlocalGlucoseDataRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      )!,
      measureTime: $UserlocalGlucoseDataTable.$convertermeasureTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}measure_time'],
        )!,
      ),
      recordSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_seq'],
      ),
      glucoseValue1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_value1'],
      ),
      glucoseValue2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_value2'],
      ),
      fiveMinFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}five_min_flag'],
      ),
      fiveMinGlucose: $UserlocalGlucoseDataTable.$converterfiveMinGlucosen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}five_min_glucose'],
            ),
          ),
      warmupFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warmup_flag'],
      ),
      abnormalFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}abnormal_flag'],
      ),
      modifiedFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_flag'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      uploadFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_flag'],
      ),
      uploadResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_result'],
      ),
      uploadFailReson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_fail_reson'],
      ),
      isCloudData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}is_cloud_data'],
      ),
      createTime: $UserlocalGlucoseDataTable.$convertercreateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}create_time'],
        ),
      ),
    );
  }

  @override
  $UserlocalGlucoseDataTable createAlias(String alias) {
    return $UserlocalGlucoseDataTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermeasureTime =
      const DateTimeEpochConverter();
  static TypeConverter<MedicalDecimal, String> $converterfiveMinGlucose =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterfiveMinGlucosen =
      NullAwareTypeConverter.wrap($converterfiveMinGlucose);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
}

class UserlocalGlucoseDataRow extends DataClass
    implements Insertable<UserlocalGlucoseDataRow> {
  final int id;
  final int userId;
  final int accountId;
  final int wearId;
  final DateTime measureTime;
  final int? recordSeq;

  /// Lianxin double，fall real
  final double? glucoseValue1;
  final double? glucoseValue2;
  final String? fiveMinFlag;

  /// Lianxin decimal(65,30)，TEXT Fixed-point storage, no loss of medical accuracy
  final MedicalDecimal? fiveMinGlucose;
  final String? warmupFlag;
  final String? abnormalFlag;
  final String? modifiedFlag;

  /// data validity char(1)：1=efficient(blood sugar 2.2~27.8) / 0=too low(<2.2) / 2=too high(>27.8)。
  /// 2.2~27.8 is the effective monitoring range of the machine (non-diabetic threshold), only the status='1'。
  final String? status;
  final String? uploadFlag;

  /// 1=success，0=fail
  final String? uploadResult;
  final String? uploadFailReson;

  /// Lianxin did not specify the meaning
  final String? isCloudData;
  final DateTime? createTime;
  const UserlocalGlucoseDataRow({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.wearId,
    required this.measureTime,
    this.recordSeq,
    this.glucoseValue1,
    this.glucoseValue2,
    this.fiveMinFlag,
    this.fiveMinGlucose,
    this.warmupFlag,
    this.abnormalFlag,
    this.modifiedFlag,
    this.status,
    this.uploadFlag,
    this.uploadResult,
    this.uploadFailReson,
    this.isCloudData,
    this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    map['account_id'] = Variable<int>(accountId);
    map['wear_id'] = Variable<int>(wearId);
    {
      map['measure_time'] = Variable<int>(
        $UserlocalGlucoseDataTable.$convertermeasureTime.toSql(measureTime),
      );
    }
    if (!nullToAbsent || recordSeq != null) {
      map['record_seq'] = Variable<int>(recordSeq);
    }
    if (!nullToAbsent || glucoseValue1 != null) {
      map['glucose_value1'] = Variable<double>(glucoseValue1);
    }
    if (!nullToAbsent || glucoseValue2 != null) {
      map['glucose_value2'] = Variable<double>(glucoseValue2);
    }
    if (!nullToAbsent || fiveMinFlag != null) {
      map['five_min_flag'] = Variable<String>(fiveMinFlag);
    }
    if (!nullToAbsent || fiveMinGlucose != null) {
      map['five_min_glucose'] = Variable<String>(
        $UserlocalGlucoseDataTable.$converterfiveMinGlucosen.toSql(
          fiveMinGlucose,
        ),
      );
    }
    if (!nullToAbsent || warmupFlag != null) {
      map['warmup_flag'] = Variable<String>(warmupFlag);
    }
    if (!nullToAbsent || abnormalFlag != null) {
      map['abnormal_flag'] = Variable<String>(abnormalFlag);
    }
    if (!nullToAbsent || modifiedFlag != null) {
      map['modified_flag'] = Variable<String>(modifiedFlag);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || uploadFlag != null) {
      map['upload_flag'] = Variable<String>(uploadFlag);
    }
    if (!nullToAbsent || uploadResult != null) {
      map['upload_result'] = Variable<String>(uploadResult);
    }
    if (!nullToAbsent || uploadFailReson != null) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson);
    }
    if (!nullToAbsent || isCloudData != null) {
      map['is_cloud_data'] = Variable<String>(isCloudData);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserlocalGlucoseDataTable.$convertercreateTimen.toSql(createTime),
      );
    }
    return map;
  }

  UserlocalGlucoseDataCompanion toCompanion(bool nullToAbsent) {
    return UserlocalGlucoseDataCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: Value(accountId),
      wearId: Value(wearId),
      measureTime: Value(measureTime),
      recordSeq: recordSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(recordSeq),
      glucoseValue1: glucoseValue1 == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseValue1),
      glucoseValue2: glucoseValue2 == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseValue2),
      fiveMinFlag: fiveMinFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(fiveMinFlag),
      fiveMinGlucose: fiveMinGlucose == null && nullToAbsent
          ? const Value.absent()
          : Value(fiveMinGlucose),
      warmupFlag: warmupFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(warmupFlag),
      abnormalFlag: abnormalFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(abnormalFlag),
      modifiedFlag: modifiedFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedFlag),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      uploadFlag: uploadFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFlag),
      uploadResult: uploadResult == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadResult),
      uploadFailReson: uploadFailReson == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFailReson),
      isCloudData: isCloudData == null && nullToAbsent
          ? const Value.absent()
          : Value(isCloudData),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
    );
  }

  factory UserlocalGlucoseDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserlocalGlucoseDataRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      wearId: serializer.fromJson<int>(json['wearId']),
      measureTime: serializer.fromJson<DateTime>(json['measureTime']),
      recordSeq: serializer.fromJson<int?>(json['recordSeq']),
      glucoseValue1: serializer.fromJson<double?>(json['glucoseValue1']),
      glucoseValue2: serializer.fromJson<double?>(json['glucoseValue2']),
      fiveMinFlag: serializer.fromJson<String?>(json['fiveMinFlag']),
      fiveMinGlucose: serializer.fromJson<MedicalDecimal?>(
        json['fiveMinGlucose'],
      ),
      warmupFlag: serializer.fromJson<String?>(json['warmupFlag']),
      abnormalFlag: serializer.fromJson<String?>(json['abnormalFlag']),
      modifiedFlag: serializer.fromJson<String?>(json['modifiedFlag']),
      status: serializer.fromJson<String?>(json['status']),
      uploadFlag: serializer.fromJson<String?>(json['uploadFlag']),
      uploadResult: serializer.fromJson<String?>(json['uploadResult']),
      uploadFailReson: serializer.fromJson<String?>(json['uploadFailReson']),
      isCloudData: serializer.fromJson<String?>(json['isCloudData']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'accountId': serializer.toJson<int>(accountId),
      'wearId': serializer.toJson<int>(wearId),
      'measureTime': serializer.toJson<DateTime>(measureTime),
      'recordSeq': serializer.toJson<int?>(recordSeq),
      'glucoseValue1': serializer.toJson<double?>(glucoseValue1),
      'glucoseValue2': serializer.toJson<double?>(glucoseValue2),
      'fiveMinFlag': serializer.toJson<String?>(fiveMinFlag),
      'fiveMinGlucose': serializer.toJson<MedicalDecimal?>(fiveMinGlucose),
      'warmupFlag': serializer.toJson<String?>(warmupFlag),
      'abnormalFlag': serializer.toJson<String?>(abnormalFlag),
      'modifiedFlag': serializer.toJson<String?>(modifiedFlag),
      'status': serializer.toJson<String?>(status),
      'uploadFlag': serializer.toJson<String?>(uploadFlag),
      'uploadResult': serializer.toJson<String?>(uploadResult),
      'uploadFailReson': serializer.toJson<String?>(uploadFailReson),
      'isCloudData': serializer.toJson<String?>(isCloudData),
      'createTime': serializer.toJson<DateTime?>(createTime),
    };
  }

  UserlocalGlucoseDataRow copyWith({
    int? id,
    int? userId,
    int? accountId,
    int? wearId,
    DateTime? measureTime,
    Value<int?> recordSeq = const Value.absent(),
    Value<double?> glucoseValue1 = const Value.absent(),
    Value<double?> glucoseValue2 = const Value.absent(),
    Value<String?> fiveMinFlag = const Value.absent(),
    Value<MedicalDecimal?> fiveMinGlucose = const Value.absent(),
    Value<String?> warmupFlag = const Value.absent(),
    Value<String?> abnormalFlag = const Value.absent(),
    Value<String?> modifiedFlag = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> uploadFlag = const Value.absent(),
    Value<String?> uploadResult = const Value.absent(),
    Value<String?> uploadFailReson = const Value.absent(),
    Value<String?> isCloudData = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
  }) => UserlocalGlucoseDataRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    accountId: accountId ?? this.accountId,
    wearId: wearId ?? this.wearId,
    measureTime: measureTime ?? this.measureTime,
    recordSeq: recordSeq.present ? recordSeq.value : this.recordSeq,
    glucoseValue1: glucoseValue1.present
        ? glucoseValue1.value
        : this.glucoseValue1,
    glucoseValue2: glucoseValue2.present
        ? glucoseValue2.value
        : this.glucoseValue2,
    fiveMinFlag: fiveMinFlag.present ? fiveMinFlag.value : this.fiveMinFlag,
    fiveMinGlucose: fiveMinGlucose.present
        ? fiveMinGlucose.value
        : this.fiveMinGlucose,
    warmupFlag: warmupFlag.present ? warmupFlag.value : this.warmupFlag,
    abnormalFlag: abnormalFlag.present ? abnormalFlag.value : this.abnormalFlag,
    modifiedFlag: modifiedFlag.present ? modifiedFlag.value : this.modifiedFlag,
    status: status.present ? status.value : this.status,
    uploadFlag: uploadFlag.present ? uploadFlag.value : this.uploadFlag,
    uploadResult: uploadResult.present ? uploadResult.value : this.uploadResult,
    uploadFailReson: uploadFailReson.present
        ? uploadFailReson.value
        : this.uploadFailReson,
    isCloudData: isCloudData.present ? isCloudData.value : this.isCloudData,
    createTime: createTime.present ? createTime.value : this.createTime,
  );
  UserlocalGlucoseDataRow copyWithCompanion(
    UserlocalGlucoseDataCompanion data,
  ) {
    return UserlocalGlucoseDataRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      measureTime: data.measureTime.present
          ? data.measureTime.value
          : this.measureTime,
      recordSeq: data.recordSeq.present ? data.recordSeq.value : this.recordSeq,
      glucoseValue1: data.glucoseValue1.present
          ? data.glucoseValue1.value
          : this.glucoseValue1,
      glucoseValue2: data.glucoseValue2.present
          ? data.glucoseValue2.value
          : this.glucoseValue2,
      fiveMinFlag: data.fiveMinFlag.present
          ? data.fiveMinFlag.value
          : this.fiveMinFlag,
      fiveMinGlucose: data.fiveMinGlucose.present
          ? data.fiveMinGlucose.value
          : this.fiveMinGlucose,
      warmupFlag: data.warmupFlag.present
          ? data.warmupFlag.value
          : this.warmupFlag,
      abnormalFlag: data.abnormalFlag.present
          ? data.abnormalFlag.value
          : this.abnormalFlag,
      modifiedFlag: data.modifiedFlag.present
          ? data.modifiedFlag.value
          : this.modifiedFlag,
      status: data.status.present ? data.status.value : this.status,
      uploadFlag: data.uploadFlag.present
          ? data.uploadFlag.value
          : this.uploadFlag,
      uploadResult: data.uploadResult.present
          ? data.uploadResult.value
          : this.uploadResult,
      uploadFailReson: data.uploadFailReson.present
          ? data.uploadFailReson.value
          : this.uploadFailReson,
      isCloudData: data.isCloudData.present
          ? data.isCloudData.value
          : this.isCloudData,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalGlucoseDataRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('measureTime: $measureTime, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('glucoseValue1: $glucoseValue1, ')
          ..write('glucoseValue2: $glucoseValue2, ')
          ..write('fiveMinFlag: $fiveMinFlag, ')
          ..write('fiveMinGlucose: $fiveMinGlucose, ')
          ..write('warmupFlag: $warmupFlag, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('modifiedFlag: $modifiedFlag, ')
          ..write('status: $status, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('isCloudData: $isCloudData, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    accountId,
    wearId,
    measureTime,
    recordSeq,
    glucoseValue1,
    glucoseValue2,
    fiveMinFlag,
    fiveMinGlucose,
    warmupFlag,
    abnormalFlag,
    modifiedFlag,
    status,
    uploadFlag,
    uploadResult,
    uploadFailReson,
    isCloudData,
    createTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserlocalGlucoseDataRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.wearId == this.wearId &&
          other.measureTime == this.measureTime &&
          other.recordSeq == this.recordSeq &&
          other.glucoseValue1 == this.glucoseValue1 &&
          other.glucoseValue2 == this.glucoseValue2 &&
          other.fiveMinFlag == this.fiveMinFlag &&
          other.fiveMinGlucose == this.fiveMinGlucose &&
          other.warmupFlag == this.warmupFlag &&
          other.abnormalFlag == this.abnormalFlag &&
          other.modifiedFlag == this.modifiedFlag &&
          other.status == this.status &&
          other.uploadFlag == this.uploadFlag &&
          other.uploadResult == this.uploadResult &&
          other.uploadFailReson == this.uploadFailReson &&
          other.isCloudData == this.isCloudData &&
          other.createTime == this.createTime);
}

class UserlocalGlucoseDataCompanion
    extends UpdateCompanion<UserlocalGlucoseDataRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int> accountId;
  final Value<int> wearId;
  final Value<DateTime> measureTime;
  final Value<int?> recordSeq;
  final Value<double?> glucoseValue1;
  final Value<double?> glucoseValue2;
  final Value<String?> fiveMinFlag;
  final Value<MedicalDecimal?> fiveMinGlucose;
  final Value<String?> warmupFlag;
  final Value<String?> abnormalFlag;
  final Value<String?> modifiedFlag;
  final Value<String?> status;
  final Value<String?> uploadFlag;
  final Value<String?> uploadResult;
  final Value<String?> uploadFailReson;
  final Value<String?> isCloudData;
  final Value<DateTime?> createTime;
  const UserlocalGlucoseDataCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.measureTime = const Value.absent(),
    this.recordSeq = const Value.absent(),
    this.glucoseValue1 = const Value.absent(),
    this.glucoseValue2 = const Value.absent(),
    this.fiveMinFlag = const Value.absent(),
    this.fiveMinGlucose = const Value.absent(),
    this.warmupFlag = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.modifiedFlag = const Value.absent(),
    this.status = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.isCloudData = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  UserlocalGlucoseDataCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    required int accountId,
    required int wearId,
    required DateTime measureTime,
    this.recordSeq = const Value.absent(),
    this.glucoseValue1 = const Value.absent(),
    this.glucoseValue2 = const Value.absent(),
    this.fiveMinFlag = const Value.absent(),
    this.fiveMinGlucose = const Value.absent(),
    this.warmupFlag = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.modifiedFlag = const Value.absent(),
    this.status = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.isCloudData = const Value.absent(),
    this.createTime = const Value.absent(),
  }) : userId = Value(userId),
       accountId = Value(accountId),
       wearId = Value(wearId),
       measureTime = Value(measureTime);
  static Insertable<UserlocalGlucoseDataRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? wearId,
    Expression<int>? measureTime,
    Expression<int>? recordSeq,
    Expression<double>? glucoseValue1,
    Expression<double>? glucoseValue2,
    Expression<String>? fiveMinFlag,
    Expression<String>? fiveMinGlucose,
    Expression<String>? warmupFlag,
    Expression<String>? abnormalFlag,
    Expression<String>? modifiedFlag,
    Expression<String>? status,
    Expression<String>? uploadFlag,
    Expression<String>? uploadResult,
    Expression<String>? uploadFailReson,
    Expression<String>? isCloudData,
    Expression<int>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (wearId != null) 'wear_id': wearId,
      if (measureTime != null) 'measure_time': measureTime,
      if (recordSeq != null) 'record_seq': recordSeq,
      if (glucoseValue1 != null) 'glucose_value1': glucoseValue1,
      if (glucoseValue2 != null) 'glucose_value2': glucoseValue2,
      if (fiveMinFlag != null) 'five_min_flag': fiveMinFlag,
      if (fiveMinGlucose != null) 'five_min_glucose': fiveMinGlucose,
      if (warmupFlag != null) 'warmup_flag': warmupFlag,
      if (abnormalFlag != null) 'abnormal_flag': abnormalFlag,
      if (modifiedFlag != null) 'modified_flag': modifiedFlag,
      if (status != null) 'status': status,
      if (uploadFlag != null) 'upload_flag': uploadFlag,
      if (uploadResult != null) 'upload_result': uploadResult,
      if (uploadFailReson != null) 'upload_fail_reson': uploadFailReson,
      if (isCloudData != null) 'is_cloud_data': isCloudData,
      if (createTime != null) 'create_time': createTime,
    });
  }

  UserlocalGlucoseDataCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int>? accountId,
    Value<int>? wearId,
    Value<DateTime>? measureTime,
    Value<int?>? recordSeq,
    Value<double?>? glucoseValue1,
    Value<double?>? glucoseValue2,
    Value<String?>? fiveMinFlag,
    Value<MedicalDecimal?>? fiveMinGlucose,
    Value<String?>? warmupFlag,
    Value<String?>? abnormalFlag,
    Value<String?>? modifiedFlag,
    Value<String?>? status,
    Value<String?>? uploadFlag,
    Value<String?>? uploadResult,
    Value<String?>? uploadFailReson,
    Value<String?>? isCloudData,
    Value<DateTime?>? createTime,
  }) {
    return UserlocalGlucoseDataCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      wearId: wearId ?? this.wearId,
      measureTime: measureTime ?? this.measureTime,
      recordSeq: recordSeq ?? this.recordSeq,
      glucoseValue1: glucoseValue1 ?? this.glucoseValue1,
      glucoseValue2: glucoseValue2 ?? this.glucoseValue2,
      fiveMinFlag: fiveMinFlag ?? this.fiveMinFlag,
      fiveMinGlucose: fiveMinGlucose ?? this.fiveMinGlucose,
      warmupFlag: warmupFlag ?? this.warmupFlag,
      abnormalFlag: abnormalFlag ?? this.abnormalFlag,
      modifiedFlag: modifiedFlag ?? this.modifiedFlag,
      status: status ?? this.status,
      uploadFlag: uploadFlag ?? this.uploadFlag,
      uploadResult: uploadResult ?? this.uploadResult,
      uploadFailReson: uploadFailReson ?? this.uploadFailReson,
      isCloudData: isCloudData ?? this.isCloudData,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (measureTime.present) {
      map['measure_time'] = Variable<int>(
        $UserlocalGlucoseDataTable.$convertermeasureTime.toSql(
          measureTime.value,
        ),
      );
    }
    if (recordSeq.present) {
      map['record_seq'] = Variable<int>(recordSeq.value);
    }
    if (glucoseValue1.present) {
      map['glucose_value1'] = Variable<double>(glucoseValue1.value);
    }
    if (glucoseValue2.present) {
      map['glucose_value2'] = Variable<double>(glucoseValue2.value);
    }
    if (fiveMinFlag.present) {
      map['five_min_flag'] = Variable<String>(fiveMinFlag.value);
    }
    if (fiveMinGlucose.present) {
      map['five_min_glucose'] = Variable<String>(
        $UserlocalGlucoseDataTable.$converterfiveMinGlucosen.toSql(
          fiveMinGlucose.value,
        ),
      );
    }
    if (warmupFlag.present) {
      map['warmup_flag'] = Variable<String>(warmupFlag.value);
    }
    if (abnormalFlag.present) {
      map['abnormal_flag'] = Variable<String>(abnormalFlag.value);
    }
    if (modifiedFlag.present) {
      map['modified_flag'] = Variable<String>(modifiedFlag.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (uploadFlag.present) {
      map['upload_flag'] = Variable<String>(uploadFlag.value);
    }
    if (uploadResult.present) {
      map['upload_result'] = Variable<String>(uploadResult.value);
    }
    if (uploadFailReson.present) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson.value);
    }
    if (isCloudData.present) {
      map['is_cloud_data'] = Variable<String>(isCloudData.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserlocalGlucoseDataTable.$convertercreateTimen.toSql(
          createTime.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalGlucoseDataCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('measureTime: $measureTime, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('glucoseValue1: $glucoseValue1, ')
          ..write('glucoseValue2: $glucoseValue2, ')
          ..write('fiveMinFlag: $fiveMinFlag, ')
          ..write('fiveMinGlucose: $fiveMinGlucose, ')
          ..write('warmupFlag: $warmupFlag, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('modifiedFlag: $modifiedFlag, ')
          ..write('status: $status, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('isCloudData: $isCloudData, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

class $UserlocalGlucoseRawDataTable extends UserlocalGlucoseRawData
    with TableInfo<$UserlocalGlucoseRawDataTable, UserlocalGlucoseRawDataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserlocalGlucoseRawDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordSeqMeta = const VerificationMeta(
    'recordSeq',
  );
  @override
  late final GeneratedColumn<int> recordSeq = GeneratedColumn<int>(
    'record_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> measureTime =
      GeneratedColumn<int>(
        'measure_time',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $UserlocalGlucoseRawDataTable.$convertermeasureTime,
      );
  static const VerificationMeta _rawCurrent1Meta = const VerificationMeta(
    'rawCurrent1',
  );
  @override
  late final GeneratedColumn<double> rawCurrent1 = GeneratedColumn<double>(
    'raw_current1',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawCurrent2Meta = const VerificationMeta(
    'rawCurrent2',
  );
  @override
  late final GeneratedColumn<double> rawCurrent2 = GeneratedColumn<double>(
    'raw_current2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperature1Meta = const VerificationMeta(
    'temperature1',
  );
  @override
  late final GeneratedColumn<double> temperature1 = GeneratedColumn<double>(
    'temperature1',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperature2Meta = const VerificationMeta(
    'temperature2',
  );
  @override
  late final GeneratedColumn<double> temperature2 = GeneratedColumn<double>(
    'temperature2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseValue1Meta = const VerificationMeta(
    'glucoseValue1',
  );
  @override
  late final GeneratedColumn<double> glucoseValue1 = GeneratedColumn<double>(
    'glucose_value1',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseValue2Meta = const VerificationMeta(
    'glucoseValue2',
  );
  @override
  late final GeneratedColumn<double> glucoseValue2 = GeneratedColumn<double>(
    'glucose_value2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warmupFlagMeta = const VerificationMeta(
    'warmupFlag',
  );
  @override
  late final GeneratedColumn<String> warmupFlag = GeneratedColumn<String>(
    'warmup_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _abnormalFlagMeta = const VerificationMeta(
    'abnormalFlag',
  );
  @override
  late final GeneratedColumn<String> abnormalFlag = GeneratedColumn<String>(
    'abnormal_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedFlagMeta = const VerificationMeta(
    'modifiedFlag',
  );
  @override
  late final GeneratedColumn<String> modifiedFlag = GeneratedColumn<String>(
    'modified_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentCoefMeta = const VerificationMeta(
    'currentCoef',
  );
  @override
  late final GeneratedColumn<double> currentCoef = GeneratedColumn<double>(
    'current_coef',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _algoKMeta = const VerificationMeta('algoK');
  @override
  late final GeneratedColumn<double> algoK = GeneratedColumn<double>(
    'algo_k',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _algoBMeta = const VerificationMeta('algoB');
  @override
  late final GeneratedColumn<double> algoB = GeneratedColumn<double>(
    'algo_b',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ibaseMeta = const VerificationMeta('ibase');
  @override
  late final GeneratedColumn<double> ibase = GeneratedColumn<double>(
    'ibase',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cgmbaseMeta = const VerificationMeta(
    'cgmbase',
  );
  @override
  late final GeneratedColumn<double> cgmbase = GeneratedColumn<double>(
    'cgmbase',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  voltageValue =
      GeneratedColumn<String>(
        'voltage_value',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseRawDataTable.$convertervoltageValuen,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  reserveValue1 =
      GeneratedColumn<String>(
        'reserve_value1',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue1n,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  reserveValue2 =
      GeneratedColumn<String>(
        'reserve_value2',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue2n,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  reserveValue3 =
      GeneratedColumn<String>(
        'reserve_value3',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue3n,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  reserveValue4 =
      GeneratedColumn<String>(
        'reserve_value4',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue4n,
      );
  static const VerificationMeta _reserveStr1Meta = const VerificationMeta(
    'reserveStr1',
  );
  @override
  late final GeneratedColumn<String> reserveStr1 = GeneratedColumn<String>(
    'reserve_str1',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reserveStr2Meta = const VerificationMeta(
    'reserveStr2',
  );
  @override
  late final GeneratedColumn<String> reserveStr2 = GeneratedColumn<String>(
    'reserve_str2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadResultMeta = const VerificationMeta(
    'uploadResult',
  );
  @override
  late final GeneratedColumn<String> uploadResult = GeneratedColumn<String>(
    'upload_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFailResonMeta = const VerificationMeta(
    'uploadFailReson',
  );
  @override
  late final GeneratedColumn<String> uploadFailReson = GeneratedColumn<String>(
    'upload_fail_reson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalGlucoseRawDataTable.$convertercreateTimen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    accountId,
    wearId,
    recordSeq,
    measureTime,
    rawCurrent1,
    rawCurrent2,
    temperature1,
    temperature2,
    glucoseValue1,
    glucoseValue2,
    warmupFlag,
    abnormalFlag,
    modifiedFlag,
    currentCoef,
    algoK,
    algoB,
    ibase,
    cgmbase,
    voltageValue,
    reserveValue1,
    reserveValue2,
    reserveValue3,
    reserveValue4,
    reserveStr1,
    reserveStr2,
    uploadResult,
    uploadFailReson,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'userlocal_glucose_raw_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserlocalGlucoseRawDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('record_seq')) {
      context.handle(
        _recordSeqMeta,
        recordSeq.isAcceptableOrUnknown(data['record_seq']!, _recordSeqMeta),
      );
    }
    if (data.containsKey('raw_current1')) {
      context.handle(
        _rawCurrent1Meta,
        rawCurrent1.isAcceptableOrUnknown(
          data['raw_current1']!,
          _rawCurrent1Meta,
        ),
      );
    }
    if (data.containsKey('raw_current2')) {
      context.handle(
        _rawCurrent2Meta,
        rawCurrent2.isAcceptableOrUnknown(
          data['raw_current2']!,
          _rawCurrent2Meta,
        ),
      );
    }
    if (data.containsKey('temperature1')) {
      context.handle(
        _temperature1Meta,
        temperature1.isAcceptableOrUnknown(
          data['temperature1']!,
          _temperature1Meta,
        ),
      );
    }
    if (data.containsKey('temperature2')) {
      context.handle(
        _temperature2Meta,
        temperature2.isAcceptableOrUnknown(
          data['temperature2']!,
          _temperature2Meta,
        ),
      );
    }
    if (data.containsKey('glucose_value1')) {
      context.handle(
        _glucoseValue1Meta,
        glucoseValue1.isAcceptableOrUnknown(
          data['glucose_value1']!,
          _glucoseValue1Meta,
        ),
      );
    }
    if (data.containsKey('glucose_value2')) {
      context.handle(
        _glucoseValue2Meta,
        glucoseValue2.isAcceptableOrUnknown(
          data['glucose_value2']!,
          _glucoseValue2Meta,
        ),
      );
    }
    if (data.containsKey('warmup_flag')) {
      context.handle(
        _warmupFlagMeta,
        warmupFlag.isAcceptableOrUnknown(data['warmup_flag']!, _warmupFlagMeta),
      );
    }
    if (data.containsKey('abnormal_flag')) {
      context.handle(
        _abnormalFlagMeta,
        abnormalFlag.isAcceptableOrUnknown(
          data['abnormal_flag']!,
          _abnormalFlagMeta,
        ),
      );
    }
    if (data.containsKey('modified_flag')) {
      context.handle(
        _modifiedFlagMeta,
        modifiedFlag.isAcceptableOrUnknown(
          data['modified_flag']!,
          _modifiedFlagMeta,
        ),
      );
    }
    if (data.containsKey('current_coef')) {
      context.handle(
        _currentCoefMeta,
        currentCoef.isAcceptableOrUnknown(
          data['current_coef']!,
          _currentCoefMeta,
        ),
      );
    }
    if (data.containsKey('algo_k')) {
      context.handle(
        _algoKMeta,
        algoK.isAcceptableOrUnknown(data['algo_k']!, _algoKMeta),
      );
    }
    if (data.containsKey('algo_b')) {
      context.handle(
        _algoBMeta,
        algoB.isAcceptableOrUnknown(data['algo_b']!, _algoBMeta),
      );
    }
    if (data.containsKey('ibase')) {
      context.handle(
        _ibaseMeta,
        ibase.isAcceptableOrUnknown(data['ibase']!, _ibaseMeta),
      );
    }
    if (data.containsKey('cgmbase')) {
      context.handle(
        _cgmbaseMeta,
        cgmbase.isAcceptableOrUnknown(data['cgmbase']!, _cgmbaseMeta),
      );
    }
    if (data.containsKey('reserve_str1')) {
      context.handle(
        _reserveStr1Meta,
        reserveStr1.isAcceptableOrUnknown(
          data['reserve_str1']!,
          _reserveStr1Meta,
        ),
      );
    }
    if (data.containsKey('reserve_str2')) {
      context.handle(
        _reserveStr2Meta,
        reserveStr2.isAcceptableOrUnknown(
          data['reserve_str2']!,
          _reserveStr2Meta,
        ),
      );
    }
    if (data.containsKey('upload_result')) {
      context.handle(
        _uploadResultMeta,
        uploadResult.isAcceptableOrUnknown(
          data['upload_result']!,
          _uploadResultMeta,
        ),
      );
    }
    if (data.containsKey('upload_fail_reson')) {
      context.handle(
        _uploadFailResonMeta,
        uploadFailReson.isAcceptableOrUnknown(
          data['upload_fail_reson']!,
          _uploadFailResonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserlocalGlucoseRawDataRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserlocalGlucoseRawDataRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      recordSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_seq'],
      ),
      measureTime: $UserlocalGlucoseRawDataTable.$convertermeasureTime.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}measure_time'],
        )!,
      ),
      rawCurrent1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}raw_current1'],
      ),
      rawCurrent2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}raw_current2'],
      ),
      temperature1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature1'],
      ),
      temperature2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature2'],
      ),
      glucoseValue1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_value1'],
      ),
      glucoseValue2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_value2'],
      ),
      warmupFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warmup_flag'],
      ),
      abnormalFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}abnormal_flag'],
      ),
      modifiedFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_flag'],
      ),
      currentCoef: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_coef'],
      ),
      algoK: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}algo_k'],
      ),
      algoB: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}algo_b'],
      ),
      ibase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ibase'],
      ),
      cgmbase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cgmbase'],
      ),
      voltageValue: $UserlocalGlucoseRawDataTable.$convertervoltageValuen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}voltage_value'],
            ),
          ),
      reserveValue1: $UserlocalGlucoseRawDataTable.$converterreserveValue1n
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reserve_value1'],
            ),
          ),
      reserveValue2: $UserlocalGlucoseRawDataTable.$converterreserveValue2n
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reserve_value2'],
            ),
          ),
      reserveValue3: $UserlocalGlucoseRawDataTable.$converterreserveValue3n
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reserve_value3'],
            ),
          ),
      reserveValue4: $UserlocalGlucoseRawDataTable.$converterreserveValue4n
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}reserve_value4'],
            ),
          ),
      reserveStr1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reserve_str1'],
      ),
      reserveStr2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reserve_str2'],
      ),
      uploadResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_result'],
      ),
      uploadFailReson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_fail_reson'],
      ),
      createTime: $UserlocalGlucoseRawDataTable.$convertercreateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}create_time'],
        ),
      ),
    );
  }

  @override
  $UserlocalGlucoseRawDataTable createAlias(String alias) {
    return $UserlocalGlucoseRawDataTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermeasureTime =
      const DateTimeEpochConverter();
  static TypeConverter<MedicalDecimal, String> $convertervoltageValue =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $convertervoltageValuen =
      NullAwareTypeConverter.wrap($convertervoltageValue);
  static TypeConverter<MedicalDecimal, String> $converterreserveValue1 =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterreserveValue1n =
      NullAwareTypeConverter.wrap($converterreserveValue1);
  static TypeConverter<MedicalDecimal, String> $converterreserveValue2 =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterreserveValue2n =
      NullAwareTypeConverter.wrap($converterreserveValue2);
  static TypeConverter<MedicalDecimal, String> $converterreserveValue3 =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterreserveValue3n =
      NullAwareTypeConverter.wrap($converterreserveValue3);
  static TypeConverter<MedicalDecimal, String> $converterreserveValue4 =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterreserveValue4n =
      NullAwareTypeConverter.wrap($converterreserveValue4);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
}

class UserlocalGlucoseRawDataRow extends DataClass
    implements Insertable<UserlocalGlucoseRawDataRow> {
  final int id;
  final int? userId;
  final int? accountId;
  final int? wearId;
  final int? recordSeq;
  final DateTime measureTime;
  final double? rawCurrent1;
  final double? rawCurrent2;
  final double? temperature1;
  final double? temperature2;

  /// Lianxin float
  final double? glucoseValue1;
  final double? glucoseValue2;
  final String? warmupFlag;
  final String? abnormalFlag;
  final String? modifiedFlag;

  /// Current coefficient
  final double? currentCoef;

  /// Algorithm sensitivity
  final double? algoK;

  /// algorithm intercept
  final double? algoB;
  final double? ibase;
  final double? cgmbase;
  final MedicalDecimal? voltageValue;
  final MedicalDecimal? reserveValue1;
  final MedicalDecimal? reserveValue2;
  final MedicalDecimal? reserveValue3;
  final MedicalDecimal? reserveValue4;
  final String? reserveStr1;
  final String? reserveStr2;

  /// 1=success，0=fail
  final String? uploadResult;
  final String? uploadFailReson;
  final DateTime? createTime;
  const UserlocalGlucoseRawDataRow({
    required this.id,
    this.userId,
    this.accountId,
    this.wearId,
    this.recordSeq,
    required this.measureTime,
    this.rawCurrent1,
    this.rawCurrent2,
    this.temperature1,
    this.temperature2,
    this.glucoseValue1,
    this.glucoseValue2,
    this.warmupFlag,
    this.abnormalFlag,
    this.modifiedFlag,
    this.currentCoef,
    this.algoK,
    this.algoB,
    this.ibase,
    this.cgmbase,
    this.voltageValue,
    this.reserveValue1,
    this.reserveValue2,
    this.reserveValue3,
    this.reserveValue4,
    this.reserveStr1,
    this.reserveStr2,
    this.uploadResult,
    this.uploadFailReson,
    this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    if (!nullToAbsent || recordSeq != null) {
      map['record_seq'] = Variable<int>(recordSeq);
    }
    {
      map['measure_time'] = Variable<int>(
        $UserlocalGlucoseRawDataTable.$convertermeasureTime.toSql(measureTime),
      );
    }
    if (!nullToAbsent || rawCurrent1 != null) {
      map['raw_current1'] = Variable<double>(rawCurrent1);
    }
    if (!nullToAbsent || rawCurrent2 != null) {
      map['raw_current2'] = Variable<double>(rawCurrent2);
    }
    if (!nullToAbsent || temperature1 != null) {
      map['temperature1'] = Variable<double>(temperature1);
    }
    if (!nullToAbsent || temperature2 != null) {
      map['temperature2'] = Variable<double>(temperature2);
    }
    if (!nullToAbsent || glucoseValue1 != null) {
      map['glucose_value1'] = Variable<double>(glucoseValue1);
    }
    if (!nullToAbsent || glucoseValue2 != null) {
      map['glucose_value2'] = Variable<double>(glucoseValue2);
    }
    if (!nullToAbsent || warmupFlag != null) {
      map['warmup_flag'] = Variable<String>(warmupFlag);
    }
    if (!nullToAbsent || abnormalFlag != null) {
      map['abnormal_flag'] = Variable<String>(abnormalFlag);
    }
    if (!nullToAbsent || modifiedFlag != null) {
      map['modified_flag'] = Variable<String>(modifiedFlag);
    }
    if (!nullToAbsent || currentCoef != null) {
      map['current_coef'] = Variable<double>(currentCoef);
    }
    if (!nullToAbsent || algoK != null) {
      map['algo_k'] = Variable<double>(algoK);
    }
    if (!nullToAbsent || algoB != null) {
      map['algo_b'] = Variable<double>(algoB);
    }
    if (!nullToAbsent || ibase != null) {
      map['ibase'] = Variable<double>(ibase);
    }
    if (!nullToAbsent || cgmbase != null) {
      map['cgmbase'] = Variable<double>(cgmbase);
    }
    if (!nullToAbsent || voltageValue != null) {
      map['voltage_value'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$convertervoltageValuen.toSql(
          voltageValue,
        ),
      );
    }
    if (!nullToAbsent || reserveValue1 != null) {
      map['reserve_value1'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue1n.toSql(
          reserveValue1,
        ),
      );
    }
    if (!nullToAbsent || reserveValue2 != null) {
      map['reserve_value2'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue2n.toSql(
          reserveValue2,
        ),
      );
    }
    if (!nullToAbsent || reserveValue3 != null) {
      map['reserve_value3'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue3n.toSql(
          reserveValue3,
        ),
      );
    }
    if (!nullToAbsent || reserveValue4 != null) {
      map['reserve_value4'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue4n.toSql(
          reserveValue4,
        ),
      );
    }
    if (!nullToAbsent || reserveStr1 != null) {
      map['reserve_str1'] = Variable<String>(reserveStr1);
    }
    if (!nullToAbsent || reserveStr2 != null) {
      map['reserve_str2'] = Variable<String>(reserveStr2);
    }
    if (!nullToAbsent || uploadResult != null) {
      map['upload_result'] = Variable<String>(uploadResult);
    }
    if (!nullToAbsent || uploadFailReson != null) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserlocalGlucoseRawDataTable.$convertercreateTimen.toSql(createTime),
      );
    }
    return map;
  }

  UserlocalGlucoseRawDataCompanion toCompanion(bool nullToAbsent) {
    return UserlocalGlucoseRawDataCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      recordSeq: recordSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(recordSeq),
      measureTime: Value(measureTime),
      rawCurrent1: rawCurrent1 == null && nullToAbsent
          ? const Value.absent()
          : Value(rawCurrent1),
      rawCurrent2: rawCurrent2 == null && nullToAbsent
          ? const Value.absent()
          : Value(rawCurrent2),
      temperature1: temperature1 == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature1),
      temperature2: temperature2 == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature2),
      glucoseValue1: glucoseValue1 == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseValue1),
      glucoseValue2: glucoseValue2 == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseValue2),
      warmupFlag: warmupFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(warmupFlag),
      abnormalFlag: abnormalFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(abnormalFlag),
      modifiedFlag: modifiedFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedFlag),
      currentCoef: currentCoef == null && nullToAbsent
          ? const Value.absent()
          : Value(currentCoef),
      algoK: algoK == null && nullToAbsent
          ? const Value.absent()
          : Value(algoK),
      algoB: algoB == null && nullToAbsent
          ? const Value.absent()
          : Value(algoB),
      ibase: ibase == null && nullToAbsent
          ? const Value.absent()
          : Value(ibase),
      cgmbase: cgmbase == null && nullToAbsent
          ? const Value.absent()
          : Value(cgmbase),
      voltageValue: voltageValue == null && nullToAbsent
          ? const Value.absent()
          : Value(voltageValue),
      reserveValue1: reserveValue1 == null && nullToAbsent
          ? const Value.absent()
          : Value(reserveValue1),
      reserveValue2: reserveValue2 == null && nullToAbsent
          ? const Value.absent()
          : Value(reserveValue2),
      reserveValue3: reserveValue3 == null && nullToAbsent
          ? const Value.absent()
          : Value(reserveValue3),
      reserveValue4: reserveValue4 == null && nullToAbsent
          ? const Value.absent()
          : Value(reserveValue4),
      reserveStr1: reserveStr1 == null && nullToAbsent
          ? const Value.absent()
          : Value(reserveStr1),
      reserveStr2: reserveStr2 == null && nullToAbsent
          ? const Value.absent()
          : Value(reserveStr2),
      uploadResult: uploadResult == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadResult),
      uploadFailReson: uploadFailReson == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFailReson),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
    );
  }

  factory UserlocalGlucoseRawDataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserlocalGlucoseRawDataRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      recordSeq: serializer.fromJson<int?>(json['recordSeq']),
      measureTime: serializer.fromJson<DateTime>(json['measureTime']),
      rawCurrent1: serializer.fromJson<double?>(json['rawCurrent1']),
      rawCurrent2: serializer.fromJson<double?>(json['rawCurrent2']),
      temperature1: serializer.fromJson<double?>(json['temperature1']),
      temperature2: serializer.fromJson<double?>(json['temperature2']),
      glucoseValue1: serializer.fromJson<double?>(json['glucoseValue1']),
      glucoseValue2: serializer.fromJson<double?>(json['glucoseValue2']),
      warmupFlag: serializer.fromJson<String?>(json['warmupFlag']),
      abnormalFlag: serializer.fromJson<String?>(json['abnormalFlag']),
      modifiedFlag: serializer.fromJson<String?>(json['modifiedFlag']),
      currentCoef: serializer.fromJson<double?>(json['currentCoef']),
      algoK: serializer.fromJson<double?>(json['algoK']),
      algoB: serializer.fromJson<double?>(json['algoB']),
      ibase: serializer.fromJson<double?>(json['ibase']),
      cgmbase: serializer.fromJson<double?>(json['cgmbase']),
      voltageValue: serializer.fromJson<MedicalDecimal?>(json['voltageValue']),
      reserveValue1: serializer.fromJson<MedicalDecimal?>(
        json['reserveValue1'],
      ),
      reserveValue2: serializer.fromJson<MedicalDecimal?>(
        json['reserveValue2'],
      ),
      reserveValue3: serializer.fromJson<MedicalDecimal?>(
        json['reserveValue3'],
      ),
      reserveValue4: serializer.fromJson<MedicalDecimal?>(
        json['reserveValue4'],
      ),
      reserveStr1: serializer.fromJson<String?>(json['reserveStr1']),
      reserveStr2: serializer.fromJson<String?>(json['reserveStr2']),
      uploadResult: serializer.fromJson<String?>(json['uploadResult']),
      uploadFailReson: serializer.fromJson<String?>(json['uploadFailReson']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int?>(userId),
      'accountId': serializer.toJson<int?>(accountId),
      'wearId': serializer.toJson<int?>(wearId),
      'recordSeq': serializer.toJson<int?>(recordSeq),
      'measureTime': serializer.toJson<DateTime>(measureTime),
      'rawCurrent1': serializer.toJson<double?>(rawCurrent1),
      'rawCurrent2': serializer.toJson<double?>(rawCurrent2),
      'temperature1': serializer.toJson<double?>(temperature1),
      'temperature2': serializer.toJson<double?>(temperature2),
      'glucoseValue1': serializer.toJson<double?>(glucoseValue1),
      'glucoseValue2': serializer.toJson<double?>(glucoseValue2),
      'warmupFlag': serializer.toJson<String?>(warmupFlag),
      'abnormalFlag': serializer.toJson<String?>(abnormalFlag),
      'modifiedFlag': serializer.toJson<String?>(modifiedFlag),
      'currentCoef': serializer.toJson<double?>(currentCoef),
      'algoK': serializer.toJson<double?>(algoK),
      'algoB': serializer.toJson<double?>(algoB),
      'ibase': serializer.toJson<double?>(ibase),
      'cgmbase': serializer.toJson<double?>(cgmbase),
      'voltageValue': serializer.toJson<MedicalDecimal?>(voltageValue),
      'reserveValue1': serializer.toJson<MedicalDecimal?>(reserveValue1),
      'reserveValue2': serializer.toJson<MedicalDecimal?>(reserveValue2),
      'reserveValue3': serializer.toJson<MedicalDecimal?>(reserveValue3),
      'reserveValue4': serializer.toJson<MedicalDecimal?>(reserveValue4),
      'reserveStr1': serializer.toJson<String?>(reserveStr1),
      'reserveStr2': serializer.toJson<String?>(reserveStr2),
      'uploadResult': serializer.toJson<String?>(uploadResult),
      'uploadFailReson': serializer.toJson<String?>(uploadFailReson),
      'createTime': serializer.toJson<DateTime?>(createTime),
    };
  }

  UserlocalGlucoseRawDataRow copyWith({
    int? id,
    Value<int?> userId = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<int?> wearId = const Value.absent(),
    Value<int?> recordSeq = const Value.absent(),
    DateTime? measureTime,
    Value<double?> rawCurrent1 = const Value.absent(),
    Value<double?> rawCurrent2 = const Value.absent(),
    Value<double?> temperature1 = const Value.absent(),
    Value<double?> temperature2 = const Value.absent(),
    Value<double?> glucoseValue1 = const Value.absent(),
    Value<double?> glucoseValue2 = const Value.absent(),
    Value<String?> warmupFlag = const Value.absent(),
    Value<String?> abnormalFlag = const Value.absent(),
    Value<String?> modifiedFlag = const Value.absent(),
    Value<double?> currentCoef = const Value.absent(),
    Value<double?> algoK = const Value.absent(),
    Value<double?> algoB = const Value.absent(),
    Value<double?> ibase = const Value.absent(),
    Value<double?> cgmbase = const Value.absent(),
    Value<MedicalDecimal?> voltageValue = const Value.absent(),
    Value<MedicalDecimal?> reserveValue1 = const Value.absent(),
    Value<MedicalDecimal?> reserveValue2 = const Value.absent(),
    Value<MedicalDecimal?> reserveValue3 = const Value.absent(),
    Value<MedicalDecimal?> reserveValue4 = const Value.absent(),
    Value<String?> reserveStr1 = const Value.absent(),
    Value<String?> reserveStr2 = const Value.absent(),
    Value<String?> uploadResult = const Value.absent(),
    Value<String?> uploadFailReson = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
  }) => UserlocalGlucoseRawDataRow(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    accountId: accountId.present ? accountId.value : this.accountId,
    wearId: wearId.present ? wearId.value : this.wearId,
    recordSeq: recordSeq.present ? recordSeq.value : this.recordSeq,
    measureTime: measureTime ?? this.measureTime,
    rawCurrent1: rawCurrent1.present ? rawCurrent1.value : this.rawCurrent1,
    rawCurrent2: rawCurrent2.present ? rawCurrent2.value : this.rawCurrent2,
    temperature1: temperature1.present ? temperature1.value : this.temperature1,
    temperature2: temperature2.present ? temperature2.value : this.temperature2,
    glucoseValue1: glucoseValue1.present
        ? glucoseValue1.value
        : this.glucoseValue1,
    glucoseValue2: glucoseValue2.present
        ? glucoseValue2.value
        : this.glucoseValue2,
    warmupFlag: warmupFlag.present ? warmupFlag.value : this.warmupFlag,
    abnormalFlag: abnormalFlag.present ? abnormalFlag.value : this.abnormalFlag,
    modifiedFlag: modifiedFlag.present ? modifiedFlag.value : this.modifiedFlag,
    currentCoef: currentCoef.present ? currentCoef.value : this.currentCoef,
    algoK: algoK.present ? algoK.value : this.algoK,
    algoB: algoB.present ? algoB.value : this.algoB,
    ibase: ibase.present ? ibase.value : this.ibase,
    cgmbase: cgmbase.present ? cgmbase.value : this.cgmbase,
    voltageValue: voltageValue.present ? voltageValue.value : this.voltageValue,
    reserveValue1: reserveValue1.present
        ? reserveValue1.value
        : this.reserveValue1,
    reserveValue2: reserveValue2.present
        ? reserveValue2.value
        : this.reserveValue2,
    reserveValue3: reserveValue3.present
        ? reserveValue3.value
        : this.reserveValue3,
    reserveValue4: reserveValue4.present
        ? reserveValue4.value
        : this.reserveValue4,
    reserveStr1: reserveStr1.present ? reserveStr1.value : this.reserveStr1,
    reserveStr2: reserveStr2.present ? reserveStr2.value : this.reserveStr2,
    uploadResult: uploadResult.present ? uploadResult.value : this.uploadResult,
    uploadFailReson: uploadFailReson.present
        ? uploadFailReson.value
        : this.uploadFailReson,
    createTime: createTime.present ? createTime.value : this.createTime,
  );
  UserlocalGlucoseRawDataRow copyWithCompanion(
    UserlocalGlucoseRawDataCompanion data,
  ) {
    return UserlocalGlucoseRawDataRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      recordSeq: data.recordSeq.present ? data.recordSeq.value : this.recordSeq,
      measureTime: data.measureTime.present
          ? data.measureTime.value
          : this.measureTime,
      rawCurrent1: data.rawCurrent1.present
          ? data.rawCurrent1.value
          : this.rawCurrent1,
      rawCurrent2: data.rawCurrent2.present
          ? data.rawCurrent2.value
          : this.rawCurrent2,
      temperature1: data.temperature1.present
          ? data.temperature1.value
          : this.temperature1,
      temperature2: data.temperature2.present
          ? data.temperature2.value
          : this.temperature2,
      glucoseValue1: data.glucoseValue1.present
          ? data.glucoseValue1.value
          : this.glucoseValue1,
      glucoseValue2: data.glucoseValue2.present
          ? data.glucoseValue2.value
          : this.glucoseValue2,
      warmupFlag: data.warmupFlag.present
          ? data.warmupFlag.value
          : this.warmupFlag,
      abnormalFlag: data.abnormalFlag.present
          ? data.abnormalFlag.value
          : this.abnormalFlag,
      modifiedFlag: data.modifiedFlag.present
          ? data.modifiedFlag.value
          : this.modifiedFlag,
      currentCoef: data.currentCoef.present
          ? data.currentCoef.value
          : this.currentCoef,
      algoK: data.algoK.present ? data.algoK.value : this.algoK,
      algoB: data.algoB.present ? data.algoB.value : this.algoB,
      ibase: data.ibase.present ? data.ibase.value : this.ibase,
      cgmbase: data.cgmbase.present ? data.cgmbase.value : this.cgmbase,
      voltageValue: data.voltageValue.present
          ? data.voltageValue.value
          : this.voltageValue,
      reserveValue1: data.reserveValue1.present
          ? data.reserveValue1.value
          : this.reserveValue1,
      reserveValue2: data.reserveValue2.present
          ? data.reserveValue2.value
          : this.reserveValue2,
      reserveValue3: data.reserveValue3.present
          ? data.reserveValue3.value
          : this.reserveValue3,
      reserveValue4: data.reserveValue4.present
          ? data.reserveValue4.value
          : this.reserveValue4,
      reserveStr1: data.reserveStr1.present
          ? data.reserveStr1.value
          : this.reserveStr1,
      reserveStr2: data.reserveStr2.present
          ? data.reserveStr2.value
          : this.reserveStr2,
      uploadResult: data.uploadResult.present
          ? data.uploadResult.value
          : this.uploadResult,
      uploadFailReson: data.uploadFailReson.present
          ? data.uploadFailReson.value
          : this.uploadFailReson,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalGlucoseRawDataRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('measureTime: $measureTime, ')
          ..write('rawCurrent1: $rawCurrent1, ')
          ..write('rawCurrent2: $rawCurrent2, ')
          ..write('temperature1: $temperature1, ')
          ..write('temperature2: $temperature2, ')
          ..write('glucoseValue1: $glucoseValue1, ')
          ..write('glucoseValue2: $glucoseValue2, ')
          ..write('warmupFlag: $warmupFlag, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('modifiedFlag: $modifiedFlag, ')
          ..write('currentCoef: $currentCoef, ')
          ..write('algoK: $algoK, ')
          ..write('algoB: $algoB, ')
          ..write('ibase: $ibase, ')
          ..write('cgmbase: $cgmbase, ')
          ..write('voltageValue: $voltageValue, ')
          ..write('reserveValue1: $reserveValue1, ')
          ..write('reserveValue2: $reserveValue2, ')
          ..write('reserveValue3: $reserveValue3, ')
          ..write('reserveValue4: $reserveValue4, ')
          ..write('reserveStr1: $reserveStr1, ')
          ..write('reserveStr2: $reserveStr2, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    accountId,
    wearId,
    recordSeq,
    measureTime,
    rawCurrent1,
    rawCurrent2,
    temperature1,
    temperature2,
    glucoseValue1,
    glucoseValue2,
    warmupFlag,
    abnormalFlag,
    modifiedFlag,
    currentCoef,
    algoK,
    algoB,
    ibase,
    cgmbase,
    voltageValue,
    reserveValue1,
    reserveValue2,
    reserveValue3,
    reserveValue4,
    reserveStr1,
    reserveStr2,
    uploadResult,
    uploadFailReson,
    createTime,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserlocalGlucoseRawDataRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.wearId == this.wearId &&
          other.recordSeq == this.recordSeq &&
          other.measureTime == this.measureTime &&
          other.rawCurrent1 == this.rawCurrent1 &&
          other.rawCurrent2 == this.rawCurrent2 &&
          other.temperature1 == this.temperature1 &&
          other.temperature2 == this.temperature2 &&
          other.glucoseValue1 == this.glucoseValue1 &&
          other.glucoseValue2 == this.glucoseValue2 &&
          other.warmupFlag == this.warmupFlag &&
          other.abnormalFlag == this.abnormalFlag &&
          other.modifiedFlag == this.modifiedFlag &&
          other.currentCoef == this.currentCoef &&
          other.algoK == this.algoK &&
          other.algoB == this.algoB &&
          other.ibase == this.ibase &&
          other.cgmbase == this.cgmbase &&
          other.voltageValue == this.voltageValue &&
          other.reserveValue1 == this.reserveValue1 &&
          other.reserveValue2 == this.reserveValue2 &&
          other.reserveValue3 == this.reserveValue3 &&
          other.reserveValue4 == this.reserveValue4 &&
          other.reserveStr1 == this.reserveStr1 &&
          other.reserveStr2 == this.reserveStr2 &&
          other.uploadResult == this.uploadResult &&
          other.uploadFailReson == this.uploadFailReson &&
          other.createTime == this.createTime);
}

class UserlocalGlucoseRawDataCompanion
    extends UpdateCompanion<UserlocalGlucoseRawDataRow> {
  final Value<int> id;
  final Value<int?> userId;
  final Value<int?> accountId;
  final Value<int?> wearId;
  final Value<int?> recordSeq;
  final Value<DateTime> measureTime;
  final Value<double?> rawCurrent1;
  final Value<double?> rawCurrent2;
  final Value<double?> temperature1;
  final Value<double?> temperature2;
  final Value<double?> glucoseValue1;
  final Value<double?> glucoseValue2;
  final Value<String?> warmupFlag;
  final Value<String?> abnormalFlag;
  final Value<String?> modifiedFlag;
  final Value<double?> currentCoef;
  final Value<double?> algoK;
  final Value<double?> algoB;
  final Value<double?> ibase;
  final Value<double?> cgmbase;
  final Value<MedicalDecimal?> voltageValue;
  final Value<MedicalDecimal?> reserveValue1;
  final Value<MedicalDecimal?> reserveValue2;
  final Value<MedicalDecimal?> reserveValue3;
  final Value<MedicalDecimal?> reserveValue4;
  final Value<String?> reserveStr1;
  final Value<String?> reserveStr2;
  final Value<String?> uploadResult;
  final Value<String?> uploadFailReson;
  final Value<DateTime?> createTime;
  const UserlocalGlucoseRawDataCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.recordSeq = const Value.absent(),
    this.measureTime = const Value.absent(),
    this.rawCurrent1 = const Value.absent(),
    this.rawCurrent2 = const Value.absent(),
    this.temperature1 = const Value.absent(),
    this.temperature2 = const Value.absent(),
    this.glucoseValue1 = const Value.absent(),
    this.glucoseValue2 = const Value.absent(),
    this.warmupFlag = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.modifiedFlag = const Value.absent(),
    this.currentCoef = const Value.absent(),
    this.algoK = const Value.absent(),
    this.algoB = const Value.absent(),
    this.ibase = const Value.absent(),
    this.cgmbase = const Value.absent(),
    this.voltageValue = const Value.absent(),
    this.reserveValue1 = const Value.absent(),
    this.reserveValue2 = const Value.absent(),
    this.reserveValue3 = const Value.absent(),
    this.reserveValue4 = const Value.absent(),
    this.reserveStr1 = const Value.absent(),
    this.reserveStr2 = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  UserlocalGlucoseRawDataCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.recordSeq = const Value.absent(),
    required DateTime measureTime,
    this.rawCurrent1 = const Value.absent(),
    this.rawCurrent2 = const Value.absent(),
    this.temperature1 = const Value.absent(),
    this.temperature2 = const Value.absent(),
    this.glucoseValue1 = const Value.absent(),
    this.glucoseValue2 = const Value.absent(),
    this.warmupFlag = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.modifiedFlag = const Value.absent(),
    this.currentCoef = const Value.absent(),
    this.algoK = const Value.absent(),
    this.algoB = const Value.absent(),
    this.ibase = const Value.absent(),
    this.cgmbase = const Value.absent(),
    this.voltageValue = const Value.absent(),
    this.reserveValue1 = const Value.absent(),
    this.reserveValue2 = const Value.absent(),
    this.reserveValue3 = const Value.absent(),
    this.reserveValue4 = const Value.absent(),
    this.reserveStr1 = const Value.absent(),
    this.reserveStr2 = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.createTime = const Value.absent(),
  }) : measureTime = Value(measureTime);
  static Insertable<UserlocalGlucoseRawDataRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? wearId,
    Expression<int>? recordSeq,
    Expression<int>? measureTime,
    Expression<double>? rawCurrent1,
    Expression<double>? rawCurrent2,
    Expression<double>? temperature1,
    Expression<double>? temperature2,
    Expression<double>? glucoseValue1,
    Expression<double>? glucoseValue2,
    Expression<String>? warmupFlag,
    Expression<String>? abnormalFlag,
    Expression<String>? modifiedFlag,
    Expression<double>? currentCoef,
    Expression<double>? algoK,
    Expression<double>? algoB,
    Expression<double>? ibase,
    Expression<double>? cgmbase,
    Expression<String>? voltageValue,
    Expression<String>? reserveValue1,
    Expression<String>? reserveValue2,
    Expression<String>? reserveValue3,
    Expression<String>? reserveValue4,
    Expression<String>? reserveStr1,
    Expression<String>? reserveStr2,
    Expression<String>? uploadResult,
    Expression<String>? uploadFailReson,
    Expression<int>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (wearId != null) 'wear_id': wearId,
      if (recordSeq != null) 'record_seq': recordSeq,
      if (measureTime != null) 'measure_time': measureTime,
      if (rawCurrent1 != null) 'raw_current1': rawCurrent1,
      if (rawCurrent2 != null) 'raw_current2': rawCurrent2,
      if (temperature1 != null) 'temperature1': temperature1,
      if (temperature2 != null) 'temperature2': temperature2,
      if (glucoseValue1 != null) 'glucose_value1': glucoseValue1,
      if (glucoseValue2 != null) 'glucose_value2': glucoseValue2,
      if (warmupFlag != null) 'warmup_flag': warmupFlag,
      if (abnormalFlag != null) 'abnormal_flag': abnormalFlag,
      if (modifiedFlag != null) 'modified_flag': modifiedFlag,
      if (currentCoef != null) 'current_coef': currentCoef,
      if (algoK != null) 'algo_k': algoK,
      if (algoB != null) 'algo_b': algoB,
      if (ibase != null) 'ibase': ibase,
      if (cgmbase != null) 'cgmbase': cgmbase,
      if (voltageValue != null) 'voltage_value': voltageValue,
      if (reserveValue1 != null) 'reserve_value1': reserveValue1,
      if (reserveValue2 != null) 'reserve_value2': reserveValue2,
      if (reserveValue3 != null) 'reserve_value3': reserveValue3,
      if (reserveValue4 != null) 'reserve_value4': reserveValue4,
      if (reserveStr1 != null) 'reserve_str1': reserveStr1,
      if (reserveStr2 != null) 'reserve_str2': reserveStr2,
      if (uploadResult != null) 'upload_result': uploadResult,
      if (uploadFailReson != null) 'upload_fail_reson': uploadFailReson,
      if (createTime != null) 'create_time': createTime,
    });
  }

  UserlocalGlucoseRawDataCompanion copyWith({
    Value<int>? id,
    Value<int?>? userId,
    Value<int?>? accountId,
    Value<int?>? wearId,
    Value<int?>? recordSeq,
    Value<DateTime>? measureTime,
    Value<double?>? rawCurrent1,
    Value<double?>? rawCurrent2,
    Value<double?>? temperature1,
    Value<double?>? temperature2,
    Value<double?>? glucoseValue1,
    Value<double?>? glucoseValue2,
    Value<String?>? warmupFlag,
    Value<String?>? abnormalFlag,
    Value<String?>? modifiedFlag,
    Value<double?>? currentCoef,
    Value<double?>? algoK,
    Value<double?>? algoB,
    Value<double?>? ibase,
    Value<double?>? cgmbase,
    Value<MedicalDecimal?>? voltageValue,
    Value<MedicalDecimal?>? reserveValue1,
    Value<MedicalDecimal?>? reserveValue2,
    Value<MedicalDecimal?>? reserveValue3,
    Value<MedicalDecimal?>? reserveValue4,
    Value<String?>? reserveStr1,
    Value<String?>? reserveStr2,
    Value<String?>? uploadResult,
    Value<String?>? uploadFailReson,
    Value<DateTime?>? createTime,
  }) {
    return UserlocalGlucoseRawDataCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      wearId: wearId ?? this.wearId,
      recordSeq: recordSeq ?? this.recordSeq,
      measureTime: measureTime ?? this.measureTime,
      rawCurrent1: rawCurrent1 ?? this.rawCurrent1,
      rawCurrent2: rawCurrent2 ?? this.rawCurrent2,
      temperature1: temperature1 ?? this.temperature1,
      temperature2: temperature2 ?? this.temperature2,
      glucoseValue1: glucoseValue1 ?? this.glucoseValue1,
      glucoseValue2: glucoseValue2 ?? this.glucoseValue2,
      warmupFlag: warmupFlag ?? this.warmupFlag,
      abnormalFlag: abnormalFlag ?? this.abnormalFlag,
      modifiedFlag: modifiedFlag ?? this.modifiedFlag,
      currentCoef: currentCoef ?? this.currentCoef,
      algoK: algoK ?? this.algoK,
      algoB: algoB ?? this.algoB,
      ibase: ibase ?? this.ibase,
      cgmbase: cgmbase ?? this.cgmbase,
      voltageValue: voltageValue ?? this.voltageValue,
      reserveValue1: reserveValue1 ?? this.reserveValue1,
      reserveValue2: reserveValue2 ?? this.reserveValue2,
      reserveValue3: reserveValue3 ?? this.reserveValue3,
      reserveValue4: reserveValue4 ?? this.reserveValue4,
      reserveStr1: reserveStr1 ?? this.reserveStr1,
      reserveStr2: reserveStr2 ?? this.reserveStr2,
      uploadResult: uploadResult ?? this.uploadResult,
      uploadFailReson: uploadFailReson ?? this.uploadFailReson,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (recordSeq.present) {
      map['record_seq'] = Variable<int>(recordSeq.value);
    }
    if (measureTime.present) {
      map['measure_time'] = Variable<int>(
        $UserlocalGlucoseRawDataTable.$convertermeasureTime.toSql(
          measureTime.value,
        ),
      );
    }
    if (rawCurrent1.present) {
      map['raw_current1'] = Variable<double>(rawCurrent1.value);
    }
    if (rawCurrent2.present) {
      map['raw_current2'] = Variable<double>(rawCurrent2.value);
    }
    if (temperature1.present) {
      map['temperature1'] = Variable<double>(temperature1.value);
    }
    if (temperature2.present) {
      map['temperature2'] = Variable<double>(temperature2.value);
    }
    if (glucoseValue1.present) {
      map['glucose_value1'] = Variable<double>(glucoseValue1.value);
    }
    if (glucoseValue2.present) {
      map['glucose_value2'] = Variable<double>(glucoseValue2.value);
    }
    if (warmupFlag.present) {
      map['warmup_flag'] = Variable<String>(warmupFlag.value);
    }
    if (abnormalFlag.present) {
      map['abnormal_flag'] = Variable<String>(abnormalFlag.value);
    }
    if (modifiedFlag.present) {
      map['modified_flag'] = Variable<String>(modifiedFlag.value);
    }
    if (currentCoef.present) {
      map['current_coef'] = Variable<double>(currentCoef.value);
    }
    if (algoK.present) {
      map['algo_k'] = Variable<double>(algoK.value);
    }
    if (algoB.present) {
      map['algo_b'] = Variable<double>(algoB.value);
    }
    if (ibase.present) {
      map['ibase'] = Variable<double>(ibase.value);
    }
    if (cgmbase.present) {
      map['cgmbase'] = Variable<double>(cgmbase.value);
    }
    if (voltageValue.present) {
      map['voltage_value'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$convertervoltageValuen.toSql(
          voltageValue.value,
        ),
      );
    }
    if (reserveValue1.present) {
      map['reserve_value1'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue1n.toSql(
          reserveValue1.value,
        ),
      );
    }
    if (reserveValue2.present) {
      map['reserve_value2'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue2n.toSql(
          reserveValue2.value,
        ),
      );
    }
    if (reserveValue3.present) {
      map['reserve_value3'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue3n.toSql(
          reserveValue3.value,
        ),
      );
    }
    if (reserveValue4.present) {
      map['reserve_value4'] = Variable<String>(
        $UserlocalGlucoseRawDataTable.$converterreserveValue4n.toSql(
          reserveValue4.value,
        ),
      );
    }
    if (reserveStr1.present) {
      map['reserve_str1'] = Variable<String>(reserveStr1.value);
    }
    if (reserveStr2.present) {
      map['reserve_str2'] = Variable<String>(reserveStr2.value);
    }
    if (uploadResult.present) {
      map['upload_result'] = Variable<String>(uploadResult.value);
    }
    if (uploadFailReson.present) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserlocalGlucoseRawDataTable.$convertercreateTimen.toSql(
          createTime.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalGlucoseRawDataCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('measureTime: $measureTime, ')
          ..write('rawCurrent1: $rawCurrent1, ')
          ..write('rawCurrent2: $rawCurrent2, ')
          ..write('temperature1: $temperature1, ')
          ..write('temperature2: $temperature2, ')
          ..write('glucoseValue1: $glucoseValue1, ')
          ..write('glucoseValue2: $glucoseValue2, ')
          ..write('warmupFlag: $warmupFlag, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('modifiedFlag: $modifiedFlag, ')
          ..write('currentCoef: $currentCoef, ')
          ..write('algoK: $algoK, ')
          ..write('algoB: $algoB, ')
          ..write('ibase: $ibase, ')
          ..write('cgmbase: $cgmbase, ')
          ..write('voltageValue: $voltageValue, ')
          ..write('reserveValue1: $reserveValue1, ')
          ..write('reserveValue2: $reserveValue2, ')
          ..write('reserveValue3: $reserveValue3, ')
          ..write('reserveValue4: $reserveValue4, ')
          ..write('reserveStr1: $reserveStr1, ')
          ..write('reserveStr2: $reserveStr2, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

class $UserlocalGlucoseModifiedLogTable extends UserlocalGlucoseModifiedLog
    with
        TableInfo<
          $UserlocalGlucoseModifiedLogTable,
          UserlocalGlucoseModifiedLogRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserlocalGlucoseModifiedLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordSeqMeta = const VerificationMeta(
    'recordSeq',
  );
  @override
  late final GeneratedColumn<int> recordSeq = GeneratedColumn<int>(
    'record_seq',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  glucoseValue1 =
      GeneratedColumn<String>(
        'glucose_value1',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseModifiedLogTable.$converterglucoseValue1n,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  glucoseValue2 =
      GeneratedColumn<String>(
        'glucose_value2',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseModifiedLogTable.$converterglucoseValue2n,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> measureTime =
      GeneratedColumn<int>(
        'measure_time',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $UserlocalGlucoseModifiedLogTable.$convertermeasureTime,
      );
  static const VerificationMeta _fiveMinFlagMeta = const VerificationMeta(
    'fiveMinFlag',
  );
  @override
  late final GeneratedColumn<String> fiveMinFlag = GeneratedColumn<String>(
    'five_min_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  fiveMinGlucose =
      GeneratedColumn<String>(
        'five_min_glucose',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<MedicalDecimal?>(
        $UserlocalGlucoseModifiedLogTable.$converterfiveMinGlucosen,
      );
  static const VerificationMeta _warmupFlagMeta = const VerificationMeta(
    'warmupFlag',
  );
  @override
  late final GeneratedColumn<String> warmupFlag = GeneratedColumn<String>(
    'warmup_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _abnormalFlagMeta = const VerificationMeta(
    'abnormalFlag',
  );
  @override
  late final GeneratedColumn<String> abnormalFlag = GeneratedColumn<String>(
    'abnormal_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFlagMeta = const VerificationMeta(
    'uploadFlag',
  );
  @override
  late final GeneratedColumn<String> uploadFlag = GeneratedColumn<String>(
    'upload_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadResultMeta = const VerificationMeta(
    'uploadResult',
  );
  @override
  late final GeneratedColumn<String> uploadResult = GeneratedColumn<String>(
    'upload_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFailResonMeta = const VerificationMeta(
    'uploadFailReson',
  );
  @override
  late final GeneratedColumn<String> uploadFailReson = GeneratedColumn<String>(
    'upload_fail_reson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalGlucoseModifiedLogTable.$convertercreateTimen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    accountId,
    wearId,
    recordSeq,
    glucoseValue1,
    glucoseValue2,
    measureTime,
    fiveMinFlag,
    fiveMinGlucose,
    warmupFlag,
    abnormalFlag,
    uploadFlag,
    uploadResult,
    uploadFailReson,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'userlocal_glucose_modified_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserlocalGlucoseModifiedLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('record_seq')) {
      context.handle(
        _recordSeqMeta,
        recordSeq.isAcceptableOrUnknown(data['record_seq']!, _recordSeqMeta),
      );
    }
    if (data.containsKey('five_min_flag')) {
      context.handle(
        _fiveMinFlagMeta,
        fiveMinFlag.isAcceptableOrUnknown(
          data['five_min_flag']!,
          _fiveMinFlagMeta,
        ),
      );
    }
    if (data.containsKey('warmup_flag')) {
      context.handle(
        _warmupFlagMeta,
        warmupFlag.isAcceptableOrUnknown(data['warmup_flag']!, _warmupFlagMeta),
      );
    }
    if (data.containsKey('abnormal_flag')) {
      context.handle(
        _abnormalFlagMeta,
        abnormalFlag.isAcceptableOrUnknown(
          data['abnormal_flag']!,
          _abnormalFlagMeta,
        ),
      );
    }
    if (data.containsKey('upload_flag')) {
      context.handle(
        _uploadFlagMeta,
        uploadFlag.isAcceptableOrUnknown(data['upload_flag']!, _uploadFlagMeta),
      );
    }
    if (data.containsKey('upload_result')) {
      context.handle(
        _uploadResultMeta,
        uploadResult.isAcceptableOrUnknown(
          data['upload_result']!,
          _uploadResultMeta,
        ),
      );
    }
    if (data.containsKey('upload_fail_reson')) {
      context.handle(
        _uploadFailResonMeta,
        uploadFailReson.isAcceptableOrUnknown(
          data['upload_fail_reson']!,
          _uploadFailResonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserlocalGlucoseModifiedLogRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserlocalGlucoseModifiedLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      recordSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}record_seq'],
      ),
      glucoseValue1: $UserlocalGlucoseModifiedLogTable.$converterglucoseValue1n
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}glucose_value1'],
            ),
          ),
      glucoseValue2: $UserlocalGlucoseModifiedLogTable.$converterglucoseValue2n
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}glucose_value2'],
            ),
          ),
      measureTime: $UserlocalGlucoseModifiedLogTable.$convertermeasureTime
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}measure_time'],
            )!,
          ),
      fiveMinFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}five_min_flag'],
      ),
      fiveMinGlucose: $UserlocalGlucoseModifiedLogTable
          .$converterfiveMinGlucosen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}five_min_glucose'],
            ),
          ),
      warmupFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warmup_flag'],
      ),
      abnormalFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}abnormal_flag'],
      ),
      uploadFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_flag'],
      ),
      uploadResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_result'],
      ),
      uploadFailReson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_fail_reson'],
      ),
      createTime: $UserlocalGlucoseModifiedLogTable.$convertercreateTimen
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}create_time'],
            ),
          ),
    );
  }

  @override
  $UserlocalGlucoseModifiedLogTable createAlias(String alias) {
    return $UserlocalGlucoseModifiedLogTable(attachedDatabase, alias);
  }

  static TypeConverter<MedicalDecimal, String> $converterglucoseValue1 =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterglucoseValue1n =
      NullAwareTypeConverter.wrap($converterglucoseValue1);
  static TypeConverter<MedicalDecimal, String> $converterglucoseValue2 =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterglucoseValue2n =
      NullAwareTypeConverter.wrap($converterglucoseValue2);
  static TypeConverter<DateTime, int> $convertermeasureTime =
      const DateTimeEpochConverter();
  static TypeConverter<MedicalDecimal, String> $converterfiveMinGlucose =
      const MedicalDecimalConverter();
  static TypeConverter<MedicalDecimal?, String?> $converterfiveMinGlucosen =
      NullAwareTypeConverter.wrap($converterfiveMinGlucose);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
}

class UserlocalGlucoseModifiedLogRow extends DataClass
    implements Insertable<UserlocalGlucoseModifiedLogRow> {
  final int id;
  final int userId;

  /// Lianxin’s annotation is suspected to be misplaced (original text"app wear Id"）
  final int? accountId;
  final int? wearId;
  final int? recordSeq;

  /// Lianxin decimal(65,30)，TEXT Fixed deposit
  final MedicalDecimal? glucoseValue1;

  /// Lianxin decimal(65,30)，TEXT Fixed deposit
  final MedicalDecimal? glucoseValue2;
  final DateTime measureTime;
  final String? fiveMinFlag;

  /// Lianxin decimal(65,30)，TEXT Fixed deposit
  final MedicalDecimal? fiveMinGlucose;
  final String? warmupFlag;
  final String? abnormalFlag;
  final String? uploadFlag;

  /// 1=success，0=fail
  final String? uploadResult;
  final String? uploadFailReson;

  /// Lianxin built date No datetime
  final DateTime? createTime;
  const UserlocalGlucoseModifiedLogRow({
    required this.id,
    required this.userId,
    this.accountId,
    this.wearId,
    this.recordSeq,
    this.glucoseValue1,
    this.glucoseValue2,
    required this.measureTime,
    this.fiveMinFlag,
    this.fiveMinGlucose,
    this.warmupFlag,
    this.abnormalFlag,
    this.uploadFlag,
    this.uploadResult,
    this.uploadFailReson,
    this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<int>(userId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    if (!nullToAbsent || recordSeq != null) {
      map['record_seq'] = Variable<int>(recordSeq);
    }
    if (!nullToAbsent || glucoseValue1 != null) {
      map['glucose_value1'] = Variable<String>(
        $UserlocalGlucoseModifiedLogTable.$converterglucoseValue1n.toSql(
          glucoseValue1,
        ),
      );
    }
    if (!nullToAbsent || glucoseValue2 != null) {
      map['glucose_value2'] = Variable<String>(
        $UserlocalGlucoseModifiedLogTable.$converterglucoseValue2n.toSql(
          glucoseValue2,
        ),
      );
    }
    {
      map['measure_time'] = Variable<int>(
        $UserlocalGlucoseModifiedLogTable.$convertermeasureTime.toSql(
          measureTime,
        ),
      );
    }
    if (!nullToAbsent || fiveMinFlag != null) {
      map['five_min_flag'] = Variable<String>(fiveMinFlag);
    }
    if (!nullToAbsent || fiveMinGlucose != null) {
      map['five_min_glucose'] = Variable<String>(
        $UserlocalGlucoseModifiedLogTable.$converterfiveMinGlucosen.toSql(
          fiveMinGlucose,
        ),
      );
    }
    if (!nullToAbsent || warmupFlag != null) {
      map['warmup_flag'] = Variable<String>(warmupFlag);
    }
    if (!nullToAbsent || abnormalFlag != null) {
      map['abnormal_flag'] = Variable<String>(abnormalFlag);
    }
    if (!nullToAbsent || uploadFlag != null) {
      map['upload_flag'] = Variable<String>(uploadFlag);
    }
    if (!nullToAbsent || uploadResult != null) {
      map['upload_result'] = Variable<String>(uploadResult);
    }
    if (!nullToAbsent || uploadFailReson != null) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserlocalGlucoseModifiedLogTable.$convertercreateTimen.toSql(
          createTime,
        ),
      );
    }
    return map;
  }

  UserlocalGlucoseModifiedLogCompanion toCompanion(bool nullToAbsent) {
    return UserlocalGlucoseModifiedLogCompanion(
      id: Value(id),
      userId: Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      recordSeq: recordSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(recordSeq),
      glucoseValue1: glucoseValue1 == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseValue1),
      glucoseValue2: glucoseValue2 == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseValue2),
      measureTime: Value(measureTime),
      fiveMinFlag: fiveMinFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(fiveMinFlag),
      fiveMinGlucose: fiveMinGlucose == null && nullToAbsent
          ? const Value.absent()
          : Value(fiveMinGlucose),
      warmupFlag: warmupFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(warmupFlag),
      abnormalFlag: abnormalFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(abnormalFlag),
      uploadFlag: uploadFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFlag),
      uploadResult: uploadResult == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadResult),
      uploadFailReson: uploadFailReson == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFailReson),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
    );
  }

  factory UserlocalGlucoseModifiedLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserlocalGlucoseModifiedLogRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int>(json['userId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      recordSeq: serializer.fromJson<int?>(json['recordSeq']),
      glucoseValue1: serializer.fromJson<MedicalDecimal?>(
        json['glucoseValue1'],
      ),
      glucoseValue2: serializer.fromJson<MedicalDecimal?>(
        json['glucoseValue2'],
      ),
      measureTime: serializer.fromJson<DateTime>(json['measureTime']),
      fiveMinFlag: serializer.fromJson<String?>(json['fiveMinFlag']),
      fiveMinGlucose: serializer.fromJson<MedicalDecimal?>(
        json['fiveMinGlucose'],
      ),
      warmupFlag: serializer.fromJson<String?>(json['warmupFlag']),
      abnormalFlag: serializer.fromJson<String?>(json['abnormalFlag']),
      uploadFlag: serializer.fromJson<String?>(json['uploadFlag']),
      uploadResult: serializer.fromJson<String?>(json['uploadResult']),
      uploadFailReson: serializer.fromJson<String?>(json['uploadFailReson']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int>(userId),
      'accountId': serializer.toJson<int?>(accountId),
      'wearId': serializer.toJson<int?>(wearId),
      'recordSeq': serializer.toJson<int?>(recordSeq),
      'glucoseValue1': serializer.toJson<MedicalDecimal?>(glucoseValue1),
      'glucoseValue2': serializer.toJson<MedicalDecimal?>(glucoseValue2),
      'measureTime': serializer.toJson<DateTime>(measureTime),
      'fiveMinFlag': serializer.toJson<String?>(fiveMinFlag),
      'fiveMinGlucose': serializer.toJson<MedicalDecimal?>(fiveMinGlucose),
      'warmupFlag': serializer.toJson<String?>(warmupFlag),
      'abnormalFlag': serializer.toJson<String?>(abnormalFlag),
      'uploadFlag': serializer.toJson<String?>(uploadFlag),
      'uploadResult': serializer.toJson<String?>(uploadResult),
      'uploadFailReson': serializer.toJson<String?>(uploadFailReson),
      'createTime': serializer.toJson<DateTime?>(createTime),
    };
  }

  UserlocalGlucoseModifiedLogRow copyWith({
    int? id,
    int? userId,
    Value<int?> accountId = const Value.absent(),
    Value<int?> wearId = const Value.absent(),
    Value<int?> recordSeq = const Value.absent(),
    Value<MedicalDecimal?> glucoseValue1 = const Value.absent(),
    Value<MedicalDecimal?> glucoseValue2 = const Value.absent(),
    DateTime? measureTime,
    Value<String?> fiveMinFlag = const Value.absent(),
    Value<MedicalDecimal?> fiveMinGlucose = const Value.absent(),
    Value<String?> warmupFlag = const Value.absent(),
    Value<String?> abnormalFlag = const Value.absent(),
    Value<String?> uploadFlag = const Value.absent(),
    Value<String?> uploadResult = const Value.absent(),
    Value<String?> uploadFailReson = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
  }) => UserlocalGlucoseModifiedLogRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    accountId: accountId.present ? accountId.value : this.accountId,
    wearId: wearId.present ? wearId.value : this.wearId,
    recordSeq: recordSeq.present ? recordSeq.value : this.recordSeq,
    glucoseValue1: glucoseValue1.present
        ? glucoseValue1.value
        : this.glucoseValue1,
    glucoseValue2: glucoseValue2.present
        ? glucoseValue2.value
        : this.glucoseValue2,
    measureTime: measureTime ?? this.measureTime,
    fiveMinFlag: fiveMinFlag.present ? fiveMinFlag.value : this.fiveMinFlag,
    fiveMinGlucose: fiveMinGlucose.present
        ? fiveMinGlucose.value
        : this.fiveMinGlucose,
    warmupFlag: warmupFlag.present ? warmupFlag.value : this.warmupFlag,
    abnormalFlag: abnormalFlag.present ? abnormalFlag.value : this.abnormalFlag,
    uploadFlag: uploadFlag.present ? uploadFlag.value : this.uploadFlag,
    uploadResult: uploadResult.present ? uploadResult.value : this.uploadResult,
    uploadFailReson: uploadFailReson.present
        ? uploadFailReson.value
        : this.uploadFailReson,
    createTime: createTime.present ? createTime.value : this.createTime,
  );
  UserlocalGlucoseModifiedLogRow copyWithCompanion(
    UserlocalGlucoseModifiedLogCompanion data,
  ) {
    return UserlocalGlucoseModifiedLogRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      recordSeq: data.recordSeq.present ? data.recordSeq.value : this.recordSeq,
      glucoseValue1: data.glucoseValue1.present
          ? data.glucoseValue1.value
          : this.glucoseValue1,
      glucoseValue2: data.glucoseValue2.present
          ? data.glucoseValue2.value
          : this.glucoseValue2,
      measureTime: data.measureTime.present
          ? data.measureTime.value
          : this.measureTime,
      fiveMinFlag: data.fiveMinFlag.present
          ? data.fiveMinFlag.value
          : this.fiveMinFlag,
      fiveMinGlucose: data.fiveMinGlucose.present
          ? data.fiveMinGlucose.value
          : this.fiveMinGlucose,
      warmupFlag: data.warmupFlag.present
          ? data.warmupFlag.value
          : this.warmupFlag,
      abnormalFlag: data.abnormalFlag.present
          ? data.abnormalFlag.value
          : this.abnormalFlag,
      uploadFlag: data.uploadFlag.present
          ? data.uploadFlag.value
          : this.uploadFlag,
      uploadResult: data.uploadResult.present
          ? data.uploadResult.value
          : this.uploadResult,
      uploadFailReson: data.uploadFailReson.present
          ? data.uploadFailReson.value
          : this.uploadFailReson,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalGlucoseModifiedLogRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('glucoseValue1: $glucoseValue1, ')
          ..write('glucoseValue2: $glucoseValue2, ')
          ..write('measureTime: $measureTime, ')
          ..write('fiveMinFlag: $fiveMinFlag, ')
          ..write('fiveMinGlucose: $fiveMinGlucose, ')
          ..write('warmupFlag: $warmupFlag, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    accountId,
    wearId,
    recordSeq,
    glucoseValue1,
    glucoseValue2,
    measureTime,
    fiveMinFlag,
    fiveMinGlucose,
    warmupFlag,
    abnormalFlag,
    uploadFlag,
    uploadResult,
    uploadFailReson,
    createTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserlocalGlucoseModifiedLogRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.wearId == this.wearId &&
          other.recordSeq == this.recordSeq &&
          other.glucoseValue1 == this.glucoseValue1 &&
          other.glucoseValue2 == this.glucoseValue2 &&
          other.measureTime == this.measureTime &&
          other.fiveMinFlag == this.fiveMinFlag &&
          other.fiveMinGlucose == this.fiveMinGlucose &&
          other.warmupFlag == this.warmupFlag &&
          other.abnormalFlag == this.abnormalFlag &&
          other.uploadFlag == this.uploadFlag &&
          other.uploadResult == this.uploadResult &&
          other.uploadFailReson == this.uploadFailReson &&
          other.createTime == this.createTime);
}

class UserlocalGlucoseModifiedLogCompanion
    extends UpdateCompanion<UserlocalGlucoseModifiedLogRow> {
  final Value<int> id;
  final Value<int> userId;
  final Value<int?> accountId;
  final Value<int?> wearId;
  final Value<int?> recordSeq;
  final Value<MedicalDecimal?> glucoseValue1;
  final Value<MedicalDecimal?> glucoseValue2;
  final Value<DateTime> measureTime;
  final Value<String?> fiveMinFlag;
  final Value<MedicalDecimal?> fiveMinGlucose;
  final Value<String?> warmupFlag;
  final Value<String?> abnormalFlag;
  final Value<String?> uploadFlag;
  final Value<String?> uploadResult;
  final Value<String?> uploadFailReson;
  final Value<DateTime?> createTime;
  const UserlocalGlucoseModifiedLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.recordSeq = const Value.absent(),
    this.glucoseValue1 = const Value.absent(),
    this.glucoseValue2 = const Value.absent(),
    this.measureTime = const Value.absent(),
    this.fiveMinFlag = const Value.absent(),
    this.fiveMinGlucose = const Value.absent(),
    this.warmupFlag = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  UserlocalGlucoseModifiedLogCompanion.insert({
    this.id = const Value.absent(),
    required int userId,
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.recordSeq = const Value.absent(),
    this.glucoseValue1 = const Value.absent(),
    this.glucoseValue2 = const Value.absent(),
    required DateTime measureTime,
    this.fiveMinFlag = const Value.absent(),
    this.fiveMinGlucose = const Value.absent(),
    this.warmupFlag = const Value.absent(),
    this.abnormalFlag = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.createTime = const Value.absent(),
  }) : userId = Value(userId),
       measureTime = Value(measureTime);
  static Insertable<UserlocalGlucoseModifiedLogRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? wearId,
    Expression<int>? recordSeq,
    Expression<String>? glucoseValue1,
    Expression<String>? glucoseValue2,
    Expression<int>? measureTime,
    Expression<String>? fiveMinFlag,
    Expression<String>? fiveMinGlucose,
    Expression<String>? warmupFlag,
    Expression<String>? abnormalFlag,
    Expression<String>? uploadFlag,
    Expression<String>? uploadResult,
    Expression<String>? uploadFailReson,
    Expression<int>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (wearId != null) 'wear_id': wearId,
      if (recordSeq != null) 'record_seq': recordSeq,
      if (glucoseValue1 != null) 'glucose_value1': glucoseValue1,
      if (glucoseValue2 != null) 'glucose_value2': glucoseValue2,
      if (measureTime != null) 'measure_time': measureTime,
      if (fiveMinFlag != null) 'five_min_flag': fiveMinFlag,
      if (fiveMinGlucose != null) 'five_min_glucose': fiveMinGlucose,
      if (warmupFlag != null) 'warmup_flag': warmupFlag,
      if (abnormalFlag != null) 'abnormal_flag': abnormalFlag,
      if (uploadFlag != null) 'upload_flag': uploadFlag,
      if (uploadResult != null) 'upload_result': uploadResult,
      if (uploadFailReson != null) 'upload_fail_reson': uploadFailReson,
      if (createTime != null) 'create_time': createTime,
    });
  }

  UserlocalGlucoseModifiedLogCompanion copyWith({
    Value<int>? id,
    Value<int>? userId,
    Value<int?>? accountId,
    Value<int?>? wearId,
    Value<int?>? recordSeq,
    Value<MedicalDecimal?>? glucoseValue1,
    Value<MedicalDecimal?>? glucoseValue2,
    Value<DateTime>? measureTime,
    Value<String?>? fiveMinFlag,
    Value<MedicalDecimal?>? fiveMinGlucose,
    Value<String?>? warmupFlag,
    Value<String?>? abnormalFlag,
    Value<String?>? uploadFlag,
    Value<String?>? uploadResult,
    Value<String?>? uploadFailReson,
    Value<DateTime?>? createTime,
  }) {
    return UserlocalGlucoseModifiedLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      wearId: wearId ?? this.wearId,
      recordSeq: recordSeq ?? this.recordSeq,
      glucoseValue1: glucoseValue1 ?? this.glucoseValue1,
      glucoseValue2: glucoseValue2 ?? this.glucoseValue2,
      measureTime: measureTime ?? this.measureTime,
      fiveMinFlag: fiveMinFlag ?? this.fiveMinFlag,
      fiveMinGlucose: fiveMinGlucose ?? this.fiveMinGlucose,
      warmupFlag: warmupFlag ?? this.warmupFlag,
      abnormalFlag: abnormalFlag ?? this.abnormalFlag,
      uploadFlag: uploadFlag ?? this.uploadFlag,
      uploadResult: uploadResult ?? this.uploadResult,
      uploadFailReson: uploadFailReson ?? this.uploadFailReson,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (recordSeq.present) {
      map['record_seq'] = Variable<int>(recordSeq.value);
    }
    if (glucoseValue1.present) {
      map['glucose_value1'] = Variable<String>(
        $UserlocalGlucoseModifiedLogTable.$converterglucoseValue1n.toSql(
          glucoseValue1.value,
        ),
      );
    }
    if (glucoseValue2.present) {
      map['glucose_value2'] = Variable<String>(
        $UserlocalGlucoseModifiedLogTable.$converterglucoseValue2n.toSql(
          glucoseValue2.value,
        ),
      );
    }
    if (measureTime.present) {
      map['measure_time'] = Variable<int>(
        $UserlocalGlucoseModifiedLogTable.$convertermeasureTime.toSql(
          measureTime.value,
        ),
      );
    }
    if (fiveMinFlag.present) {
      map['five_min_flag'] = Variable<String>(fiveMinFlag.value);
    }
    if (fiveMinGlucose.present) {
      map['five_min_glucose'] = Variable<String>(
        $UserlocalGlucoseModifiedLogTable.$converterfiveMinGlucosen.toSql(
          fiveMinGlucose.value,
        ),
      );
    }
    if (warmupFlag.present) {
      map['warmup_flag'] = Variable<String>(warmupFlag.value);
    }
    if (abnormalFlag.present) {
      map['abnormal_flag'] = Variable<String>(abnormalFlag.value);
    }
    if (uploadFlag.present) {
      map['upload_flag'] = Variable<String>(uploadFlag.value);
    }
    if (uploadResult.present) {
      map['upload_result'] = Variable<String>(uploadResult.value);
    }
    if (uploadFailReson.present) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserlocalGlucoseModifiedLogTable.$convertercreateTimen.toSql(
          createTime.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalGlucoseModifiedLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('recordSeq: $recordSeq, ')
          ..write('glucoseValue1: $glucoseValue1, ')
          ..write('glucoseValue2: $glucoseValue2, ')
          ..write('measureTime: $measureTime, ')
          ..write('fiveMinFlag: $fiveMinFlag, ')
          ..write('fiveMinGlucose: $fiveMinGlucose, ')
          ..write('warmupFlag: $warmupFlag, ')
          ..write('abnormalFlag: $abnormalFlag, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

class $UserlocalWearErrorLogTable extends UserlocalWearErrorLog
    with TableInfo<$UserlocalWearErrorLogTable, UserlocalWearErrorLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserlocalWearErrorLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorContentMeta = const VerificationMeta(
    'errorContent',
  );
  @override
  late final GeneratedColumn<String> errorContent = GeneratedColumn<String>(
    'error_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> errorTime =
      GeneratedColumn<int>(
        'error_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalWearErrorLogTable.$convertererrorTimen,
      );
  static const VerificationMeta _userPhoneIdMeta = const VerificationMeta(
    'userPhoneId',
  );
  @override
  late final GeneratedColumn<int> userPhoneId = GeneratedColumn<int>(
    'user_phone_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFlagMeta = const VerificationMeta(
    'uploadFlag',
  );
  @override
  late final GeneratedColumn<String> uploadFlag = GeneratedColumn<String>(
    'upload_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadResultMeta = const VerificationMeta(
    'uploadResult',
  );
  @override
  late final GeneratedColumn<String> uploadResult = GeneratedColumn<String>(
    'upload_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadFailResonMeta = const VerificationMeta(
    'uploadFailReson',
  );
  @override
  late final GeneratedColumn<String> uploadFailReson = GeneratedColumn<String>(
    'upload_fail_reson',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalWearErrorLogTable.$convertercreateTimen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    accountId,
    wearId,
    errorContent,
    errorTime,
    userPhoneId,
    uploadFlag,
    uploadResult,
    uploadFailReson,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'userlocal_wear_error_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserlocalWearErrorLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('error_content')) {
      context.handle(
        _errorContentMeta,
        errorContent.isAcceptableOrUnknown(
          data['error_content']!,
          _errorContentMeta,
        ),
      );
    }
    if (data.containsKey('user_phone_id')) {
      context.handle(
        _userPhoneIdMeta,
        userPhoneId.isAcceptableOrUnknown(
          data['user_phone_id']!,
          _userPhoneIdMeta,
        ),
      );
    }
    if (data.containsKey('upload_flag')) {
      context.handle(
        _uploadFlagMeta,
        uploadFlag.isAcceptableOrUnknown(data['upload_flag']!, _uploadFlagMeta),
      );
    }
    if (data.containsKey('upload_result')) {
      context.handle(
        _uploadResultMeta,
        uploadResult.isAcceptableOrUnknown(
          data['upload_result']!,
          _uploadResultMeta,
        ),
      );
    }
    if (data.containsKey('upload_fail_reson')) {
      context.handle(
        _uploadFailResonMeta,
        uploadFailReson.isAcceptableOrUnknown(
          data['upload_fail_reson']!,
          _uploadFailResonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserlocalWearErrorLogRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserlocalWearErrorLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      errorContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_content'],
      ),
      errorTime: $UserlocalWearErrorLogTable.$convertererrorTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}error_time'],
        ),
      ),
      userPhoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_phone_id'],
      ),
      uploadFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_flag'],
      ),
      uploadResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_result'],
      ),
      uploadFailReson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_fail_reson'],
      ),
      createTime: $UserlocalWearErrorLogTable.$convertercreateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}create_time'],
        ),
      ),
    );
  }

  @override
  $UserlocalWearErrorLogTable createAlias(String alias) {
    return $UserlocalWearErrorLogTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertererrorTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertererrorTimen =
      NullAwareTypeConverter.wrap($convertererrorTime);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
}

class UserlocalWearErrorLogRow extends DataClass
    implements Insertable<UserlocalWearErrorLogRow> {
  final int id;
  final int? userId;
  final int? accountId;

  /// Lianxin’s annotation is suspected to be misplaced (original text"transmitter id"）
  final int? wearId;
  final String? errorContent;
  final DateTime? errorTime;
  final int? userPhoneId;
  final String? uploadFlag;

  /// 1=success，0=fail
  final String? uploadResult;
  final String? uploadFailReson;
  final DateTime? createTime;
  const UserlocalWearErrorLogRow({
    required this.id,
    this.userId,
    this.accountId,
    this.wearId,
    this.errorContent,
    this.errorTime,
    this.userPhoneId,
    this.uploadFlag,
    this.uploadResult,
    this.uploadFailReson,
    this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    if (!nullToAbsent || errorContent != null) {
      map['error_content'] = Variable<String>(errorContent);
    }
    if (!nullToAbsent || errorTime != null) {
      map['error_time'] = Variable<int>(
        $UserlocalWearErrorLogTable.$convertererrorTimen.toSql(errorTime),
      );
    }
    if (!nullToAbsent || userPhoneId != null) {
      map['user_phone_id'] = Variable<int>(userPhoneId);
    }
    if (!nullToAbsent || uploadFlag != null) {
      map['upload_flag'] = Variable<String>(uploadFlag);
    }
    if (!nullToAbsent || uploadResult != null) {
      map['upload_result'] = Variable<String>(uploadResult);
    }
    if (!nullToAbsent || uploadFailReson != null) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserlocalWearErrorLogTable.$convertercreateTimen.toSql(createTime),
      );
    }
    return map;
  }

  UserlocalWearErrorLogCompanion toCompanion(bool nullToAbsent) {
    return UserlocalWearErrorLogCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      errorContent: errorContent == null && nullToAbsent
          ? const Value.absent()
          : Value(errorContent),
      errorTime: errorTime == null && nullToAbsent
          ? const Value.absent()
          : Value(errorTime),
      userPhoneId: userPhoneId == null && nullToAbsent
          ? const Value.absent()
          : Value(userPhoneId),
      uploadFlag: uploadFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFlag),
      uploadResult: uploadResult == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadResult),
      uploadFailReson: uploadFailReson == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadFailReson),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
    );
  }

  factory UserlocalWearErrorLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserlocalWearErrorLogRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<int?>(json['userId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      errorContent: serializer.fromJson<String?>(json['errorContent']),
      errorTime: serializer.fromJson<DateTime?>(json['errorTime']),
      userPhoneId: serializer.fromJson<int?>(json['userPhoneId']),
      uploadFlag: serializer.fromJson<String?>(json['uploadFlag']),
      uploadResult: serializer.fromJson<String?>(json['uploadResult']),
      uploadFailReson: serializer.fromJson<String?>(json['uploadFailReson']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<int?>(userId),
      'accountId': serializer.toJson<int?>(accountId),
      'wearId': serializer.toJson<int?>(wearId),
      'errorContent': serializer.toJson<String?>(errorContent),
      'errorTime': serializer.toJson<DateTime?>(errorTime),
      'userPhoneId': serializer.toJson<int?>(userPhoneId),
      'uploadFlag': serializer.toJson<String?>(uploadFlag),
      'uploadResult': serializer.toJson<String?>(uploadResult),
      'uploadFailReson': serializer.toJson<String?>(uploadFailReson),
      'createTime': serializer.toJson<DateTime?>(createTime),
    };
  }

  UserlocalWearErrorLogRow copyWith({
    int? id,
    Value<int?> userId = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<int?> wearId = const Value.absent(),
    Value<String?> errorContent = const Value.absent(),
    Value<DateTime?> errorTime = const Value.absent(),
    Value<int?> userPhoneId = const Value.absent(),
    Value<String?> uploadFlag = const Value.absent(),
    Value<String?> uploadResult = const Value.absent(),
    Value<String?> uploadFailReson = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
  }) => UserlocalWearErrorLogRow(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    accountId: accountId.present ? accountId.value : this.accountId,
    wearId: wearId.present ? wearId.value : this.wearId,
    errorContent: errorContent.present ? errorContent.value : this.errorContent,
    errorTime: errorTime.present ? errorTime.value : this.errorTime,
    userPhoneId: userPhoneId.present ? userPhoneId.value : this.userPhoneId,
    uploadFlag: uploadFlag.present ? uploadFlag.value : this.uploadFlag,
    uploadResult: uploadResult.present ? uploadResult.value : this.uploadResult,
    uploadFailReson: uploadFailReson.present
        ? uploadFailReson.value
        : this.uploadFailReson,
    createTime: createTime.present ? createTime.value : this.createTime,
  );
  UserlocalWearErrorLogRow copyWithCompanion(
    UserlocalWearErrorLogCompanion data,
  ) {
    return UserlocalWearErrorLogRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      errorContent: data.errorContent.present
          ? data.errorContent.value
          : this.errorContent,
      errorTime: data.errorTime.present ? data.errorTime.value : this.errorTime,
      userPhoneId: data.userPhoneId.present
          ? data.userPhoneId.value
          : this.userPhoneId,
      uploadFlag: data.uploadFlag.present
          ? data.uploadFlag.value
          : this.uploadFlag,
      uploadResult: data.uploadResult.present
          ? data.uploadResult.value
          : this.uploadResult,
      uploadFailReson: data.uploadFailReson.present
          ? data.uploadFailReson.value
          : this.uploadFailReson,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalWearErrorLogRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('errorContent: $errorContent, ')
          ..write('errorTime: $errorTime, ')
          ..write('userPhoneId: $userPhoneId, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    accountId,
    wearId,
    errorContent,
    errorTime,
    userPhoneId,
    uploadFlag,
    uploadResult,
    uploadFailReson,
    createTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserlocalWearErrorLogRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.wearId == this.wearId &&
          other.errorContent == this.errorContent &&
          other.errorTime == this.errorTime &&
          other.userPhoneId == this.userPhoneId &&
          other.uploadFlag == this.uploadFlag &&
          other.uploadResult == this.uploadResult &&
          other.uploadFailReson == this.uploadFailReson &&
          other.createTime == this.createTime);
}

class UserlocalWearErrorLogCompanion
    extends UpdateCompanion<UserlocalWearErrorLogRow> {
  final Value<int> id;
  final Value<int?> userId;
  final Value<int?> accountId;
  final Value<int?> wearId;
  final Value<String?> errorContent;
  final Value<DateTime?> errorTime;
  final Value<int?> userPhoneId;
  final Value<String?> uploadFlag;
  final Value<String?> uploadResult;
  final Value<String?> uploadFailReson;
  final Value<DateTime?> createTime;
  const UserlocalWearErrorLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.errorContent = const Value.absent(),
    this.errorTime = const Value.absent(),
    this.userPhoneId = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  UserlocalWearErrorLogCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.wearId = const Value.absent(),
    this.errorContent = const Value.absent(),
    this.errorTime = const Value.absent(),
    this.userPhoneId = const Value.absent(),
    this.uploadFlag = const Value.absent(),
    this.uploadResult = const Value.absent(),
    this.uploadFailReson = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  static Insertable<UserlocalWearErrorLogRow> custom({
    Expression<int>? id,
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? wearId,
    Expression<String>? errorContent,
    Expression<int>? errorTime,
    Expression<int>? userPhoneId,
    Expression<String>? uploadFlag,
    Expression<String>? uploadResult,
    Expression<String>? uploadFailReson,
    Expression<int>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (wearId != null) 'wear_id': wearId,
      if (errorContent != null) 'error_content': errorContent,
      if (errorTime != null) 'error_time': errorTime,
      if (userPhoneId != null) 'user_phone_id': userPhoneId,
      if (uploadFlag != null) 'upload_flag': uploadFlag,
      if (uploadResult != null) 'upload_result': uploadResult,
      if (uploadFailReson != null) 'upload_fail_reson': uploadFailReson,
      if (createTime != null) 'create_time': createTime,
    });
  }

  UserlocalWearErrorLogCompanion copyWith({
    Value<int>? id,
    Value<int?>? userId,
    Value<int?>? accountId,
    Value<int?>? wearId,
    Value<String?>? errorContent,
    Value<DateTime?>? errorTime,
    Value<int?>? userPhoneId,
    Value<String?>? uploadFlag,
    Value<String?>? uploadResult,
    Value<String?>? uploadFailReson,
    Value<DateTime?>? createTime,
  }) {
    return UserlocalWearErrorLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      wearId: wearId ?? this.wearId,
      errorContent: errorContent ?? this.errorContent,
      errorTime: errorTime ?? this.errorTime,
      userPhoneId: userPhoneId ?? this.userPhoneId,
      uploadFlag: uploadFlag ?? this.uploadFlag,
      uploadResult: uploadResult ?? this.uploadResult,
      uploadFailReson: uploadFailReson ?? this.uploadFailReson,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (errorContent.present) {
      map['error_content'] = Variable<String>(errorContent.value);
    }
    if (errorTime.present) {
      map['error_time'] = Variable<int>(
        $UserlocalWearErrorLogTable.$convertererrorTimen.toSql(errorTime.value),
      );
    }
    if (userPhoneId.present) {
      map['user_phone_id'] = Variable<int>(userPhoneId.value);
    }
    if (uploadFlag.present) {
      map['upload_flag'] = Variable<String>(uploadFlag.value);
    }
    if (uploadResult.present) {
      map['upload_result'] = Variable<String>(uploadResult.value);
    }
    if (uploadFailReson.present) {
      map['upload_fail_reson'] = Variable<String>(uploadFailReson.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserlocalWearErrorLogTable.$convertercreateTimen.toSql(
          createTime.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalWearErrorLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('wearId: $wearId, ')
          ..write('errorContent: $errorContent, ')
          ..write('errorTime: $errorTime, ')
          ..write('userPhoneId: $userPhoneId, ')
          ..write('uploadFlag: $uploadFlag, ')
          ..write('uploadResult: $uploadResult, ')
          ..write('uploadFailReson: $uploadFailReson, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

class $UserlocalCollectionDaycntTable extends UserlocalCollectionDaycnt
    with
        TableInfo<
          $UserlocalCollectionDaycntTable,
          UserlocalCollectionDaycntRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserlocalCollectionDaycntTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wearIdMeta = const VerificationMeta('wearId');
  @override
  late final GeneratedColumn<int> wearId = GeneratedColumn<int>(
    'wear_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> day =
      GeneratedColumn<int>(
        'day',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalCollectionDaycntTable.$converterdayn,
      );
  static const VerificationMeta _isComplateMeta = const VerificationMeta(
    'isComplate',
  );
  @override
  late final GeneratedColumn<String> isComplate = GeneratedColumn<String>(
    'is_complate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _collectCntMeta = const VerificationMeta(
    'collectCnt',
  );
  @override
  late final GeneratedColumn<int> collectCnt = GeneratedColumn<int>(
    'collect_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effCntMeta = const VerificationMeta('effCnt');
  @override
  late final GeneratedColumn<int> effCnt = GeneratedColumn<int>(
    'eff_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseTotalValMeta = const VerificationMeta(
    'glucoseTotalVal',
  );
  @override
  late final GeneratedColumn<double> glucoseTotalVal = GeneratedColumn<double>(
    'glucose_total_val',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiCntMeta = const VerificationMeta('hiCnt');
  @override
  late final GeneratedColumn<int> hiCnt = GeneratedColumn<int>(
    'hi_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lowCntMeta = const VerificationMeta('lowCnt');
  @override
  late final GeneratedColumn<int> lowCnt = GeneratedColumn<int>(
    'low_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extHiCntMeta = const VerificationMeta(
    'extHiCnt',
  );
  @override
  late final GeneratedColumn<int> extHiCnt = GeneratedColumn<int>(
    'ext_hi_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extLoCntMeta = const VerificationMeta(
    'extLoCnt',
  );
  @override
  late final GeneratedColumn<int> extLoCnt = GeneratedColumn<int>(
    'ext_lo_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tirCntMeta = const VerificationMeta('tirCnt');
  @override
  late final GeneratedColumn<int> tirCnt = GeneratedColumn<int>(
    'tir_cnt',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> createTime =
      GeneratedColumn<int>(
        'create_time',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $UserlocalCollectionDaycntTable.$convertercreateTimen,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wearId,
    userId,
    accountId,
    day,
    isComplate,
    collectCnt,
    effCnt,
    glucoseTotalVal,
    hiCnt,
    lowCnt,
    extHiCnt,
    extLoCnt,
    tirCnt,
    createTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'userlocal_collection_daycnt';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserlocalCollectionDaycntRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wear_id')) {
      context.handle(
        _wearIdMeta,
        wearId.isAcceptableOrUnknown(data['wear_id']!, _wearIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('is_complate')) {
      context.handle(
        _isComplateMeta,
        isComplate.isAcceptableOrUnknown(data['is_complate']!, _isComplateMeta),
      );
    }
    if (data.containsKey('collect_cnt')) {
      context.handle(
        _collectCntMeta,
        collectCnt.isAcceptableOrUnknown(data['collect_cnt']!, _collectCntMeta),
      );
    }
    if (data.containsKey('eff_cnt')) {
      context.handle(
        _effCntMeta,
        effCnt.isAcceptableOrUnknown(data['eff_cnt']!, _effCntMeta),
      );
    }
    if (data.containsKey('glucose_total_val')) {
      context.handle(
        _glucoseTotalValMeta,
        glucoseTotalVal.isAcceptableOrUnknown(
          data['glucose_total_val']!,
          _glucoseTotalValMeta,
        ),
      );
    }
    if (data.containsKey('hi_cnt')) {
      context.handle(
        _hiCntMeta,
        hiCnt.isAcceptableOrUnknown(data['hi_cnt']!, _hiCntMeta),
      );
    }
    if (data.containsKey('low_cnt')) {
      context.handle(
        _lowCntMeta,
        lowCnt.isAcceptableOrUnknown(data['low_cnt']!, _lowCntMeta),
      );
    }
    if (data.containsKey('ext_hi_cnt')) {
      context.handle(
        _extHiCntMeta,
        extHiCnt.isAcceptableOrUnknown(data['ext_hi_cnt']!, _extHiCntMeta),
      );
    }
    if (data.containsKey('ext_lo_cnt')) {
      context.handle(
        _extLoCntMeta,
        extLoCnt.isAcceptableOrUnknown(data['ext_lo_cnt']!, _extLoCntMeta),
      );
    }
    if (data.containsKey('tir_cnt')) {
      context.handle(
        _tirCntMeta,
        tirCnt.isAcceptableOrUnknown(data['tir_cnt']!, _tirCntMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserlocalCollectionDaycntRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserlocalCollectionDaycntRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wearId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      day: $UserlocalCollectionDaycntTable.$converterdayn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}day'],
        ),
      ),
      isComplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}is_complate'],
      ),
      collectCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}collect_cnt'],
      ),
      effCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}eff_cnt'],
      ),
      glucoseTotalVal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_total_val'],
      ),
      hiCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hi_cnt'],
      ),
      lowCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_cnt'],
      ),
      extHiCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ext_hi_cnt'],
      ),
      extLoCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ext_lo_cnt'],
      ),
      tirCnt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tir_cnt'],
      ),
      createTime: $UserlocalCollectionDaycntTable.$convertercreateTimen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}create_time'],
        ),
      ),
    );
  }

  @override
  $UserlocalCollectionDaycntTable createAlias(String alias) {
    return $UserlocalCollectionDaycntTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterday =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $converterdayn =
      NullAwareTypeConverter.wrap($converterday);
  static TypeConverter<DateTime, int> $convertercreateTime =
      const DateTimeEpochConverter();
  static TypeConverter<DateTime?, int?> $convertercreateTimen =
      NullAwareTypeConverter.wrap($convertercreateTime);
}

class UserlocalCollectionDaycntRow extends DataClass
    implements Insertable<UserlocalCollectionDaycntRow> {
  final int id;
  final int? wearId;
  final int? userId;
  final int? accountId;
  final DateTime? day;
  final String? isComplate;
  final int? collectCnt;

  /// Total amount of valid data（status='1'）
  final int? effCnt;

  /// Collect the total blood glucose concentration on the day
  final double? glucoseTotalVal;

  /// hi/low/ext/tir = high/Low/extremum/Amount of blood glucose data that meets the standard
  final int? hiCnt;
  final int? lowCnt;
  final int? extHiCnt;
  final int? extLoCnt;
  final int? tirCnt;
  final DateTime? createTime;
  const UserlocalCollectionDaycntRow({
    required this.id,
    this.wearId,
    this.userId,
    this.accountId,
    this.day,
    this.isComplate,
    this.collectCnt,
    this.effCnt,
    this.glucoseTotalVal,
    this.hiCnt,
    this.lowCnt,
    this.extHiCnt,
    this.extLoCnt,
    this.tirCnt,
    this.createTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || wearId != null) {
      map['wear_id'] = Variable<int>(wearId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<int>(userId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || day != null) {
      map['day'] = Variable<int>(
        $UserlocalCollectionDaycntTable.$converterdayn.toSql(day),
      );
    }
    if (!nullToAbsent || isComplate != null) {
      map['is_complate'] = Variable<String>(isComplate);
    }
    if (!nullToAbsent || collectCnt != null) {
      map['collect_cnt'] = Variable<int>(collectCnt);
    }
    if (!nullToAbsent || effCnt != null) {
      map['eff_cnt'] = Variable<int>(effCnt);
    }
    if (!nullToAbsent || glucoseTotalVal != null) {
      map['glucose_total_val'] = Variable<double>(glucoseTotalVal);
    }
    if (!nullToAbsent || hiCnt != null) {
      map['hi_cnt'] = Variable<int>(hiCnt);
    }
    if (!nullToAbsent || lowCnt != null) {
      map['low_cnt'] = Variable<int>(lowCnt);
    }
    if (!nullToAbsent || extHiCnt != null) {
      map['ext_hi_cnt'] = Variable<int>(extHiCnt);
    }
    if (!nullToAbsent || extLoCnt != null) {
      map['ext_lo_cnt'] = Variable<int>(extLoCnt);
    }
    if (!nullToAbsent || tirCnt != null) {
      map['tir_cnt'] = Variable<int>(tirCnt);
    }
    if (!nullToAbsent || createTime != null) {
      map['create_time'] = Variable<int>(
        $UserlocalCollectionDaycntTable.$convertercreateTimen.toSql(createTime),
      );
    }
    return map;
  }

  UserlocalCollectionDaycntCompanion toCompanion(bool nullToAbsent) {
    return UserlocalCollectionDaycntCompanion(
      id: Value(id),
      wearId: wearId == null && nullToAbsent
          ? const Value.absent()
          : Value(wearId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      day: day == null && nullToAbsent ? const Value.absent() : Value(day),
      isComplate: isComplate == null && nullToAbsent
          ? const Value.absent()
          : Value(isComplate),
      collectCnt: collectCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(collectCnt),
      effCnt: effCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(effCnt),
      glucoseTotalVal: glucoseTotalVal == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseTotalVal),
      hiCnt: hiCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(hiCnt),
      lowCnt: lowCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(lowCnt),
      extHiCnt: extHiCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(extHiCnt),
      extLoCnt: extLoCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(extLoCnt),
      tirCnt: tirCnt == null && nullToAbsent
          ? const Value.absent()
          : Value(tirCnt),
      createTime: createTime == null && nullToAbsent
          ? const Value.absent()
          : Value(createTime),
    );
  }

  factory UserlocalCollectionDaycntRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserlocalCollectionDaycntRow(
      id: serializer.fromJson<int>(json['id']),
      wearId: serializer.fromJson<int?>(json['wearId']),
      userId: serializer.fromJson<int?>(json['userId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      day: serializer.fromJson<DateTime?>(json['day']),
      isComplate: serializer.fromJson<String?>(json['isComplate']),
      collectCnt: serializer.fromJson<int?>(json['collectCnt']),
      effCnt: serializer.fromJson<int?>(json['effCnt']),
      glucoseTotalVal: serializer.fromJson<double?>(json['glucoseTotalVal']),
      hiCnt: serializer.fromJson<int?>(json['hiCnt']),
      lowCnt: serializer.fromJson<int?>(json['lowCnt']),
      extHiCnt: serializer.fromJson<int?>(json['extHiCnt']),
      extLoCnt: serializer.fromJson<int?>(json['extLoCnt']),
      tirCnt: serializer.fromJson<int?>(json['tirCnt']),
      createTime: serializer.fromJson<DateTime?>(json['createTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wearId': serializer.toJson<int?>(wearId),
      'userId': serializer.toJson<int?>(userId),
      'accountId': serializer.toJson<int?>(accountId),
      'day': serializer.toJson<DateTime?>(day),
      'isComplate': serializer.toJson<String?>(isComplate),
      'collectCnt': serializer.toJson<int?>(collectCnt),
      'effCnt': serializer.toJson<int?>(effCnt),
      'glucoseTotalVal': serializer.toJson<double?>(glucoseTotalVal),
      'hiCnt': serializer.toJson<int?>(hiCnt),
      'lowCnt': serializer.toJson<int?>(lowCnt),
      'extHiCnt': serializer.toJson<int?>(extHiCnt),
      'extLoCnt': serializer.toJson<int?>(extLoCnt),
      'tirCnt': serializer.toJson<int?>(tirCnt),
      'createTime': serializer.toJson<DateTime?>(createTime),
    };
  }

  UserlocalCollectionDaycntRow copyWith({
    int? id,
    Value<int?> wearId = const Value.absent(),
    Value<int?> userId = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<DateTime?> day = const Value.absent(),
    Value<String?> isComplate = const Value.absent(),
    Value<int?> collectCnt = const Value.absent(),
    Value<int?> effCnt = const Value.absent(),
    Value<double?> glucoseTotalVal = const Value.absent(),
    Value<int?> hiCnt = const Value.absent(),
    Value<int?> lowCnt = const Value.absent(),
    Value<int?> extHiCnt = const Value.absent(),
    Value<int?> extLoCnt = const Value.absent(),
    Value<int?> tirCnt = const Value.absent(),
    Value<DateTime?> createTime = const Value.absent(),
  }) => UserlocalCollectionDaycntRow(
    id: id ?? this.id,
    wearId: wearId.present ? wearId.value : this.wearId,
    userId: userId.present ? userId.value : this.userId,
    accountId: accountId.present ? accountId.value : this.accountId,
    day: day.present ? day.value : this.day,
    isComplate: isComplate.present ? isComplate.value : this.isComplate,
    collectCnt: collectCnt.present ? collectCnt.value : this.collectCnt,
    effCnt: effCnt.present ? effCnt.value : this.effCnt,
    glucoseTotalVal: glucoseTotalVal.present
        ? glucoseTotalVal.value
        : this.glucoseTotalVal,
    hiCnt: hiCnt.present ? hiCnt.value : this.hiCnt,
    lowCnt: lowCnt.present ? lowCnt.value : this.lowCnt,
    extHiCnt: extHiCnt.present ? extHiCnt.value : this.extHiCnt,
    extLoCnt: extLoCnt.present ? extLoCnt.value : this.extLoCnt,
    tirCnt: tirCnt.present ? tirCnt.value : this.tirCnt,
    createTime: createTime.present ? createTime.value : this.createTime,
  );
  UserlocalCollectionDaycntRow copyWithCompanion(
    UserlocalCollectionDaycntCompanion data,
  ) {
    return UserlocalCollectionDaycntRow(
      id: data.id.present ? data.id.value : this.id,
      wearId: data.wearId.present ? data.wearId.value : this.wearId,
      userId: data.userId.present ? data.userId.value : this.userId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      day: data.day.present ? data.day.value : this.day,
      isComplate: data.isComplate.present
          ? data.isComplate.value
          : this.isComplate,
      collectCnt: data.collectCnt.present
          ? data.collectCnt.value
          : this.collectCnt,
      effCnt: data.effCnt.present ? data.effCnt.value : this.effCnt,
      glucoseTotalVal: data.glucoseTotalVal.present
          ? data.glucoseTotalVal.value
          : this.glucoseTotalVal,
      hiCnt: data.hiCnt.present ? data.hiCnt.value : this.hiCnt,
      lowCnt: data.lowCnt.present ? data.lowCnt.value : this.lowCnt,
      extHiCnt: data.extHiCnt.present ? data.extHiCnt.value : this.extHiCnt,
      extLoCnt: data.extLoCnt.present ? data.extLoCnt.value : this.extLoCnt,
      tirCnt: data.tirCnt.present ? data.tirCnt.value : this.tirCnt,
      createTime: data.createTime.present
          ? data.createTime.value
          : this.createTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalCollectionDaycntRow(')
          ..write('id: $id, ')
          ..write('wearId: $wearId, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('day: $day, ')
          ..write('isComplate: $isComplate, ')
          ..write('collectCnt: $collectCnt, ')
          ..write('effCnt: $effCnt, ')
          ..write('glucoseTotalVal: $glucoseTotalVal, ')
          ..write('hiCnt: $hiCnt, ')
          ..write('lowCnt: $lowCnt, ')
          ..write('extHiCnt: $extHiCnt, ')
          ..write('extLoCnt: $extLoCnt, ')
          ..write('tirCnt: $tirCnt, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wearId,
    userId,
    accountId,
    day,
    isComplate,
    collectCnt,
    effCnt,
    glucoseTotalVal,
    hiCnt,
    lowCnt,
    extHiCnt,
    extLoCnt,
    tirCnt,
    createTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserlocalCollectionDaycntRow &&
          other.id == this.id &&
          other.wearId == this.wearId &&
          other.userId == this.userId &&
          other.accountId == this.accountId &&
          other.day == this.day &&
          other.isComplate == this.isComplate &&
          other.collectCnt == this.collectCnt &&
          other.effCnt == this.effCnt &&
          other.glucoseTotalVal == this.glucoseTotalVal &&
          other.hiCnt == this.hiCnt &&
          other.lowCnt == this.lowCnt &&
          other.extHiCnt == this.extHiCnt &&
          other.extLoCnt == this.extLoCnt &&
          other.tirCnt == this.tirCnt &&
          other.createTime == this.createTime);
}

class UserlocalCollectionDaycntCompanion
    extends UpdateCompanion<UserlocalCollectionDaycntRow> {
  final Value<int> id;
  final Value<int?> wearId;
  final Value<int?> userId;
  final Value<int?> accountId;
  final Value<DateTime?> day;
  final Value<String?> isComplate;
  final Value<int?> collectCnt;
  final Value<int?> effCnt;
  final Value<double?> glucoseTotalVal;
  final Value<int?> hiCnt;
  final Value<int?> lowCnt;
  final Value<int?> extHiCnt;
  final Value<int?> extLoCnt;
  final Value<int?> tirCnt;
  final Value<DateTime?> createTime;
  const UserlocalCollectionDaycntCompanion({
    this.id = const Value.absent(),
    this.wearId = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.day = const Value.absent(),
    this.isComplate = const Value.absent(),
    this.collectCnt = const Value.absent(),
    this.effCnt = const Value.absent(),
    this.glucoseTotalVal = const Value.absent(),
    this.hiCnt = const Value.absent(),
    this.lowCnt = const Value.absent(),
    this.extHiCnt = const Value.absent(),
    this.extLoCnt = const Value.absent(),
    this.tirCnt = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  UserlocalCollectionDaycntCompanion.insert({
    this.id = const Value.absent(),
    this.wearId = const Value.absent(),
    this.userId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.day = const Value.absent(),
    this.isComplate = const Value.absent(),
    this.collectCnt = const Value.absent(),
    this.effCnt = const Value.absent(),
    this.glucoseTotalVal = const Value.absent(),
    this.hiCnt = const Value.absent(),
    this.lowCnt = const Value.absent(),
    this.extHiCnt = const Value.absent(),
    this.extLoCnt = const Value.absent(),
    this.tirCnt = const Value.absent(),
    this.createTime = const Value.absent(),
  });
  static Insertable<UserlocalCollectionDaycntRow> custom({
    Expression<int>? id,
    Expression<int>? wearId,
    Expression<int>? userId,
    Expression<int>? accountId,
    Expression<int>? day,
    Expression<String>? isComplate,
    Expression<int>? collectCnt,
    Expression<int>? effCnt,
    Expression<double>? glucoseTotalVal,
    Expression<int>? hiCnt,
    Expression<int>? lowCnt,
    Expression<int>? extHiCnt,
    Expression<int>? extLoCnt,
    Expression<int>? tirCnt,
    Expression<int>? createTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wearId != null) 'wear_id': wearId,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (day != null) 'day': day,
      if (isComplate != null) 'is_complate': isComplate,
      if (collectCnt != null) 'collect_cnt': collectCnt,
      if (effCnt != null) 'eff_cnt': effCnt,
      if (glucoseTotalVal != null) 'glucose_total_val': glucoseTotalVal,
      if (hiCnt != null) 'hi_cnt': hiCnt,
      if (lowCnt != null) 'low_cnt': lowCnt,
      if (extHiCnt != null) 'ext_hi_cnt': extHiCnt,
      if (extLoCnt != null) 'ext_lo_cnt': extLoCnt,
      if (tirCnt != null) 'tir_cnt': tirCnt,
      if (createTime != null) 'create_time': createTime,
    });
  }

  UserlocalCollectionDaycntCompanion copyWith({
    Value<int>? id,
    Value<int?>? wearId,
    Value<int?>? userId,
    Value<int?>? accountId,
    Value<DateTime?>? day,
    Value<String?>? isComplate,
    Value<int?>? collectCnt,
    Value<int?>? effCnt,
    Value<double?>? glucoseTotalVal,
    Value<int?>? hiCnt,
    Value<int?>? lowCnt,
    Value<int?>? extHiCnt,
    Value<int?>? extLoCnt,
    Value<int?>? tirCnt,
    Value<DateTime?>? createTime,
  }) {
    return UserlocalCollectionDaycntCompanion(
      id: id ?? this.id,
      wearId: wearId ?? this.wearId,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      day: day ?? this.day,
      isComplate: isComplate ?? this.isComplate,
      collectCnt: collectCnt ?? this.collectCnt,
      effCnt: effCnt ?? this.effCnt,
      glucoseTotalVal: glucoseTotalVal ?? this.glucoseTotalVal,
      hiCnt: hiCnt ?? this.hiCnt,
      lowCnt: lowCnt ?? this.lowCnt,
      extHiCnt: extHiCnt ?? this.extHiCnt,
      extLoCnt: extLoCnt ?? this.extLoCnt,
      tirCnt: tirCnt ?? this.tirCnt,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wearId.present) {
      map['wear_id'] = Variable<int>(wearId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(
        $UserlocalCollectionDaycntTable.$converterdayn.toSql(day.value),
      );
    }
    if (isComplate.present) {
      map['is_complate'] = Variable<String>(isComplate.value);
    }
    if (collectCnt.present) {
      map['collect_cnt'] = Variable<int>(collectCnt.value);
    }
    if (effCnt.present) {
      map['eff_cnt'] = Variable<int>(effCnt.value);
    }
    if (glucoseTotalVal.present) {
      map['glucose_total_val'] = Variable<double>(glucoseTotalVal.value);
    }
    if (hiCnt.present) {
      map['hi_cnt'] = Variable<int>(hiCnt.value);
    }
    if (lowCnt.present) {
      map['low_cnt'] = Variable<int>(lowCnt.value);
    }
    if (extHiCnt.present) {
      map['ext_hi_cnt'] = Variable<int>(extHiCnt.value);
    }
    if (extLoCnt.present) {
      map['ext_lo_cnt'] = Variable<int>(extLoCnt.value);
    }
    if (tirCnt.present) {
      map['tir_cnt'] = Variable<int>(tirCnt.value);
    }
    if (createTime.present) {
      map['create_time'] = Variable<int>(
        $UserlocalCollectionDaycntTable.$convertercreateTimen.toSql(
          createTime.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserlocalCollectionDaycntCompanion(')
          ..write('id: $id, ')
          ..write('wearId: $wearId, ')
          ..write('userId: $userId, ')
          ..write('accountId: $accountId, ')
          ..write('day: $day, ')
          ..write('isComplate: $isComplate, ')
          ..write('collectCnt: $collectCnt, ')
          ..write('effCnt: $effCnt, ')
          ..write('glucoseTotalVal: $glucoseTotalVal, ')
          ..write('hiCnt: $hiCnt, ')
          ..write('lowCnt: $lowCnt, ')
          ..write('extHiCnt: $extHiCnt, ')
          ..write('extLoCnt: $extLoCnt, ')
          ..write('tirCnt: $tirCnt, ')
          ..write('createTime: $createTime')
          ..write(')'))
        .toString();
  }
}

abstract class _$CgmDatabase extends GeneratedDatabase {
  _$CgmDatabase(QueryExecutor e) : super(e);
  $CgmDatabaseManager get managers => $CgmDatabaseManager(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $BleFrameBufferTable bleFrameBuffer = $BleFrameBufferTable(this);
  late final $AppDeviceBindTable appDeviceBind = $AppDeviceBindTable(this);
  late final $UserWearCurTable userWearCur = $UserWearCurTable(this);
  late final $UserWearStatusLogTable userWearStatusLog =
      $UserWearStatusLogTable(this);
  late final $UserlocalGlucoseDataTable userlocalGlucoseData =
      $UserlocalGlucoseDataTable(this);
  late final $UserlocalGlucoseRawDataTable userlocalGlucoseRawData =
      $UserlocalGlucoseRawDataTable(this);
  late final $UserlocalGlucoseModifiedLogTable userlocalGlucoseModifiedLog =
      $UserlocalGlucoseModifiedLogTable(this);
  late final $UserlocalWearErrorLogTable userlocalWearErrorLog =
      $UserlocalWearErrorLogTable(this);
  late final $UserlocalCollectionDaycntTable userlocalCollectionDaycnt =
      $UserlocalCollectionDaycntTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMeta,
    bleFrameBuffer,
    appDeviceBind,
    userWearCur,
    userWearStatusLog,
    userlocalGlucoseData,
    userlocalGlucoseRawData,
    userlocalGlucoseModifiedLog,
    userlocalWearErrorLog,
    userlocalCollectionDaycnt,
  ];
}

typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      Value<String?> value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$CgmDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$CgmDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$CgmDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$CgmDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$CgmDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$CgmDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;
typedef $$BleFrameBufferTableCreateCompanionBuilder =
    BleFrameBufferCompanion Function({
      Value<int> id,
      Value<int?> wearId,
      required Uint8List rawFrame,
      required DateTime measureTime,
      Value<int?> recordSeq,
      Value<double?> rawCurrent,
      Value<double?> temperature,
      Value<double?> voltage,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$BleFrameBufferTableUpdateCompanionBuilder =
    BleFrameBufferCompanion Function({
      Value<int> id,
      Value<int?> wearId,
      Value<Uint8List> rawFrame,
      Value<DateTime> measureTime,
      Value<int?> recordSeq,
      Value<double?> rawCurrent,
      Value<double?> temperature,
      Value<double?> voltage,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$BleFrameBufferTableFilterComposer
    extends Composer<_$CgmDatabase, $BleFrameBufferTable> {
  $$BleFrameBufferTableFilterComposer({
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

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get rawFrame => $composableBuilder(
    column: $table.rawFrame,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rawCurrent => $composableBuilder(
    column: $table.rawCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voltage => $composableBuilder(
    column: $table.voltage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$BleFrameBufferTableOrderingComposer
    extends Composer<_$CgmDatabase, $BleFrameBufferTable> {
  $$BleFrameBufferTableOrderingComposer({
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

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get rawFrame => $composableBuilder(
    column: $table.rawFrame,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measureTime => $composableBuilder(
    column: $table.measureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rawCurrent => $composableBuilder(
    column: $table.rawCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voltage => $composableBuilder(
    column: $table.voltage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BleFrameBufferTableAnnotationComposer
    extends Composer<_$CgmDatabase, $BleFrameBufferTable> {
  $$BleFrameBufferTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<Uint8List> get rawFrame =>
      $composableBuilder(column: $table.rawFrame, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => column,
      );

  GeneratedColumn<int> get recordSeq =>
      $composableBuilder(column: $table.recordSeq, builder: (column) => column);

  GeneratedColumn<double> get rawCurrent => $composableBuilder(
    column: $table.rawCurrent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voltage =>
      $composableBuilder(column: $table.voltage, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BleFrameBufferTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $BleFrameBufferTable,
          BleFrameBufferRow,
          $$BleFrameBufferTableFilterComposer,
          $$BleFrameBufferTableOrderingComposer,
          $$BleFrameBufferTableAnnotationComposer,
          $$BleFrameBufferTableCreateCompanionBuilder,
          $$BleFrameBufferTableUpdateCompanionBuilder,
          (
            BleFrameBufferRow,
            BaseReferences<
              _$CgmDatabase,
              $BleFrameBufferTable,
              BleFrameBufferRow
            >,
          ),
          BleFrameBufferRow,
          PrefetchHooks Function()
        > {
  $$BleFrameBufferTableTableManager(
    _$CgmDatabase db,
    $BleFrameBufferTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BleFrameBufferTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BleFrameBufferTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BleFrameBufferTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<Uint8List> rawFrame = const Value.absent(),
                Value<DateTime> measureTime = const Value.absent(),
                Value<int?> recordSeq = const Value.absent(),
                Value<double?> rawCurrent = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> voltage = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BleFrameBufferCompanion(
                id: id,
                wearId: wearId,
                rawFrame: rawFrame,
                measureTime: measureTime,
                recordSeq: recordSeq,
                rawCurrent: rawCurrent,
                temperature: temperature,
                voltage: voltage,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                required Uint8List rawFrame,
                required DateTime measureTime,
                Value<int?> recordSeq = const Value.absent(),
                Value<double?> rawCurrent = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> voltage = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => BleFrameBufferCompanion.insert(
                id: id,
                wearId: wearId,
                rawFrame: rawFrame,
                measureTime: measureTime,
                recordSeq: recordSeq,
                rawCurrent: rawCurrent,
                temperature: temperature,
                voltage: voltage,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BleFrameBufferTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $BleFrameBufferTable,
      BleFrameBufferRow,
      $$BleFrameBufferTableFilterComposer,
      $$BleFrameBufferTableOrderingComposer,
      $$BleFrameBufferTableAnnotationComposer,
      $$BleFrameBufferTableCreateCompanionBuilder,
      $$BleFrameBufferTableUpdateCompanionBuilder,
      (
        BleFrameBufferRow,
        BaseReferences<_$CgmDatabase, $BleFrameBufferTable, BleFrameBufferRow>,
      ),
      BleFrameBufferRow,
      PrefetchHooks Function()
    >;
typedef $$AppDeviceBindTableCreateCompanionBuilder =
    AppDeviceBindCompanion Function({
      Value<int> id,
      required int userId,
      Value<int?> wearId,
      Value<String?> transmitterSn,
      Value<String?> sensorSn,
      Value<String?> bluetoothAddr,
      Value<String?> deviceType,
      Value<String?> instanceForm,
      Value<String?> expireDate,
      Value<String?> firmwareVersion,
      Value<String?> softParams,
      Value<String?> firmwareParams,
      Value<double?> bindLatitude,
      Value<double?> bindLongitude,
      Value<String?> cityCode,
      Value<String?> districtCode,
      Value<String?> uploadStatus,
      Value<String?> deviceStatus,
      required int createdAt,
      required int updatedAt,
    });
typedef $$AppDeviceBindTableUpdateCompanionBuilder =
    AppDeviceBindCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int?> wearId,
      Value<String?> transmitterSn,
      Value<String?> sensorSn,
      Value<String?> bluetoothAddr,
      Value<String?> deviceType,
      Value<String?> instanceForm,
      Value<String?> expireDate,
      Value<String?> firmwareVersion,
      Value<String?> softParams,
      Value<String?> firmwareParams,
      Value<double?> bindLatitude,
      Value<double?> bindLongitude,
      Value<String?> cityCode,
      Value<String?> districtCode,
      Value<String?> uploadStatus,
      Value<String?> deviceStatus,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$AppDeviceBindTableFilterComposer
    extends Composer<_$CgmDatabase, $AppDeviceBindTable> {
  $$AppDeviceBindTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transmitterSn => $composableBuilder(
    column: $table.transmitterSn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensorSn => $composableBuilder(
    column: $table.sensorSn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bluetoothAddr => $composableBuilder(
    column: $table.bluetoothAddr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceForm => $composableBuilder(
    column: $table.instanceForm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expireDate => $composableBuilder(
    column: $table.expireDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firmwareVersion => $composableBuilder(
    column: $table.firmwareVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get softParams => $composableBuilder(
    column: $table.softParams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firmwareParams => $composableBuilder(
    column: $table.firmwareParams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bindLatitude => $composableBuilder(
    column: $table.bindLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bindLongitude => $composableBuilder(
    column: $table.bindLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cityCode => $composableBuilder(
    column: $table.cityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceStatus => $composableBuilder(
    column: $table.deviceStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppDeviceBindTableOrderingComposer
    extends Composer<_$CgmDatabase, $AppDeviceBindTable> {
  $$AppDeviceBindTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transmitterSn => $composableBuilder(
    column: $table.transmitterSn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensorSn => $composableBuilder(
    column: $table.sensorSn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bluetoothAddr => $composableBuilder(
    column: $table.bluetoothAddr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceForm => $composableBuilder(
    column: $table.instanceForm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expireDate => $composableBuilder(
    column: $table.expireDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firmwareVersion => $composableBuilder(
    column: $table.firmwareVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get softParams => $composableBuilder(
    column: $table.softParams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firmwareParams => $composableBuilder(
    column: $table.firmwareParams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bindLatitude => $composableBuilder(
    column: $table.bindLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bindLongitude => $composableBuilder(
    column: $table.bindLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cityCode => $composableBuilder(
    column: $table.cityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceStatus => $composableBuilder(
    column: $table.deviceStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppDeviceBindTableAnnotationComposer
    extends Composer<_$CgmDatabase, $AppDeviceBindTable> {
  $$AppDeviceBindTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<String> get transmitterSn => $composableBuilder(
    column: $table.transmitterSn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sensorSn =>
      $composableBuilder(column: $table.sensorSn, builder: (column) => column);

  GeneratedColumn<String> get bluetoothAddr => $composableBuilder(
    column: $table.bluetoothAddr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceType => $composableBuilder(
    column: $table.deviceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instanceForm => $composableBuilder(
    column: $table.instanceForm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expireDate => $composableBuilder(
    column: $table.expireDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firmwareVersion => $composableBuilder(
    column: $table.firmwareVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get softParams => $composableBuilder(
    column: $table.softParams,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firmwareParams => $composableBuilder(
    column: $table.firmwareParams,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bindLatitude => $composableBuilder(
    column: $table.bindLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bindLongitude => $composableBuilder(
    column: $table.bindLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cityCode =>
      $composableBuilder(column: $table.cityCode, builder: (column) => column);

  GeneratedColumn<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadStatus => $composableBuilder(
    column: $table.uploadStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceStatus => $composableBuilder(
    column: $table.deviceStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppDeviceBindTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $AppDeviceBindTable,
          AppDeviceBindRow,
          $$AppDeviceBindTableFilterComposer,
          $$AppDeviceBindTableOrderingComposer,
          $$AppDeviceBindTableAnnotationComposer,
          $$AppDeviceBindTableCreateCompanionBuilder,
          $$AppDeviceBindTableUpdateCompanionBuilder,
          (
            AppDeviceBindRow,
            BaseReferences<
              _$CgmDatabase,
              $AppDeviceBindTable,
              AppDeviceBindRow
            >,
          ),
          AppDeviceBindRow,
          PrefetchHooks Function()
        > {
  $$AppDeviceBindTableTableManager(_$CgmDatabase db, $AppDeviceBindTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppDeviceBindTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppDeviceBindTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppDeviceBindTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<String?> transmitterSn = const Value.absent(),
                Value<String?> sensorSn = const Value.absent(),
                Value<String?> bluetoothAddr = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<String?> instanceForm = const Value.absent(),
                Value<String?> expireDate = const Value.absent(),
                Value<String?> firmwareVersion = const Value.absent(),
                Value<String?> softParams = const Value.absent(),
                Value<String?> firmwareParams = const Value.absent(),
                Value<double?> bindLatitude = const Value.absent(),
                Value<double?> bindLongitude = const Value.absent(),
                Value<String?> cityCode = const Value.absent(),
                Value<String?> districtCode = const Value.absent(),
                Value<String?> uploadStatus = const Value.absent(),
                Value<String?> deviceStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => AppDeviceBindCompanion(
                id: id,
                userId: userId,
                wearId: wearId,
                transmitterSn: transmitterSn,
                sensorSn: sensorSn,
                bluetoothAddr: bluetoothAddr,
                deviceType: deviceType,
                instanceForm: instanceForm,
                expireDate: expireDate,
                firmwareVersion: firmwareVersion,
                softParams: softParams,
                firmwareParams: firmwareParams,
                bindLatitude: bindLatitude,
                bindLongitude: bindLongitude,
                cityCode: cityCode,
                districtCode: districtCode,
                uploadStatus: uploadStatus,
                deviceStatus: deviceStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                Value<int?> wearId = const Value.absent(),
                Value<String?> transmitterSn = const Value.absent(),
                Value<String?> sensorSn = const Value.absent(),
                Value<String?> bluetoothAddr = const Value.absent(),
                Value<String?> deviceType = const Value.absent(),
                Value<String?> instanceForm = const Value.absent(),
                Value<String?> expireDate = const Value.absent(),
                Value<String?> firmwareVersion = const Value.absent(),
                Value<String?> softParams = const Value.absent(),
                Value<String?> firmwareParams = const Value.absent(),
                Value<double?> bindLatitude = const Value.absent(),
                Value<double?> bindLongitude = const Value.absent(),
                Value<String?> cityCode = const Value.absent(),
                Value<String?> districtCode = const Value.absent(),
                Value<String?> uploadStatus = const Value.absent(),
                Value<String?> deviceStatus = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => AppDeviceBindCompanion.insert(
                id: id,
                userId: userId,
                wearId: wearId,
                transmitterSn: transmitterSn,
                sensorSn: sensorSn,
                bluetoothAddr: bluetoothAddr,
                deviceType: deviceType,
                instanceForm: instanceForm,
                expireDate: expireDate,
                firmwareVersion: firmwareVersion,
                softParams: softParams,
                firmwareParams: firmwareParams,
                bindLatitude: bindLatitude,
                bindLongitude: bindLongitude,
                cityCode: cityCode,
                districtCode: districtCode,
                uploadStatus: uploadStatus,
                deviceStatus: deviceStatus,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppDeviceBindTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $AppDeviceBindTable,
      AppDeviceBindRow,
      $$AppDeviceBindTableFilterComposer,
      $$AppDeviceBindTableOrderingComposer,
      $$AppDeviceBindTableAnnotationComposer,
      $$AppDeviceBindTableCreateCompanionBuilder,
      $$AppDeviceBindTableUpdateCompanionBuilder,
      (
        AppDeviceBindRow,
        BaseReferences<_$CgmDatabase, $AppDeviceBindTable, AppDeviceBindRow>,
      ),
      AppDeviceBindRow,
      PrefetchHooks Function()
    >;
typedef $$UserWearCurTableCreateCompanionBuilder =
    UserWearCurCompanion Function({
      Value<int> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<DateTime?> activeTime,
      Value<int?> transmitterId,
      Value<String?> transmitterSn,
      Value<int?> sensorId,
      Value<String?> sensorSn,
      Value<DateTime?> lastWearTime,
      Value<DateTime?> lastDataUptime,
      Value<String?> lastGlucose,
      Value<DateTime?> createTime,
      Value<DateTime?> updateTime,
    });
typedef $$UserWearCurTableUpdateCompanionBuilder =
    UserWearCurCompanion Function({
      Value<int> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<DateTime?> activeTime,
      Value<int?> transmitterId,
      Value<String?> transmitterSn,
      Value<int?> sensorId,
      Value<String?> sensorSn,
      Value<DateTime?> lastWearTime,
      Value<DateTime?> lastDataUptime,
      Value<String?> lastGlucose,
      Value<DateTime?> createTime,
      Value<DateTime?> updateTime,
    });

class $$UserWearCurTableFilterComposer
    extends Composer<_$CgmDatabase, $UserWearCurTable> {
  $$UserWearCurTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get activeTime =>
      $composableBuilder(
        column: $table.activeTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get transmitterId => $composableBuilder(
    column: $table.transmitterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transmitterSn => $composableBuilder(
    column: $table.transmitterSn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sensorId => $composableBuilder(
    column: $table.sensorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sensorSn => $composableBuilder(
    column: $table.sensorSn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastWearTime =>
      $composableBuilder(
        column: $table.lastWearTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastDataUptime =>
      $composableBuilder(
        column: $table.lastDataUptime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get lastGlucose => $composableBuilder(
    column: $table.lastGlucose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get updateTime =>
      $composableBuilder(
        column: $table.updateTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserWearCurTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserWearCurTable> {
  $$UserWearCurTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeTime => $composableBuilder(
    column: $table.activeTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transmitterId => $composableBuilder(
    column: $table.transmitterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transmitterSn => $composableBuilder(
    column: $table.transmitterSn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sensorId => $composableBuilder(
    column: $table.sensorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sensorSn => $composableBuilder(
    column: $table.sensorSn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastWearTime => $composableBuilder(
    column: $table.lastWearTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastDataUptime => $composableBuilder(
    column: $table.lastDataUptime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastGlucose => $composableBuilder(
    column: $table.lastGlucose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateTime => $composableBuilder(
    column: $table.updateTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserWearCurTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserWearCurTable> {
  $$UserWearCurTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get activeTime =>
      $composableBuilder(
        column: $table.activeTime,
        builder: (column) => column,
      );

  GeneratedColumn<int> get transmitterId => $composableBuilder(
    column: $table.transmitterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transmitterSn => $composableBuilder(
    column: $table.transmitterSn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sensorId =>
      $composableBuilder(column: $table.sensorId, builder: (column) => column);

  GeneratedColumn<String> get sensorSn =>
      $composableBuilder(column: $table.sensorSn, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastWearTime =>
      $composableBuilder(
        column: $table.lastWearTime,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastDataUptime =>
      $composableBuilder(
        column: $table.lastDataUptime,
        builder: (column) => column,
      );

  GeneratedColumn<String> get lastGlucose => $composableBuilder(
    column: $table.lastGlucose,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime?, int> get updateTime =>
      $composableBuilder(
        column: $table.updateTime,
        builder: (column) => column,
      );
}

class $$UserWearCurTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserWearCurTable,
          UserWearCurRow,
          $$UserWearCurTableFilterComposer,
          $$UserWearCurTableOrderingComposer,
          $$UserWearCurTableAnnotationComposer,
          $$UserWearCurTableCreateCompanionBuilder,
          $$UserWearCurTableUpdateCompanionBuilder,
          (
            UserWearCurRow,
            BaseReferences<_$CgmDatabase, $UserWearCurTable, UserWearCurRow>,
          ),
          UserWearCurRow,
          PrefetchHooks Function()
        > {
  $$UserWearCurTableTableManager(_$CgmDatabase db, $UserWearCurTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWearCurTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWearCurTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWearCurTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<DateTime?> activeTime = const Value.absent(),
                Value<int?> transmitterId = const Value.absent(),
                Value<String?> transmitterSn = const Value.absent(),
                Value<int?> sensorId = const Value.absent(),
                Value<String?> sensorSn = const Value.absent(),
                Value<DateTime?> lastWearTime = const Value.absent(),
                Value<DateTime?> lastDataUptime = const Value.absent(),
                Value<String?> lastGlucose = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
                Value<DateTime?> updateTime = const Value.absent(),
              }) => UserWearCurCompanion(
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                activeTime: activeTime,
                transmitterId: transmitterId,
                transmitterSn: transmitterSn,
                sensorId: sensorId,
                sensorSn: sensorSn,
                lastWearTime: lastWearTime,
                lastDataUptime: lastDataUptime,
                lastGlucose: lastGlucose,
                createTime: createTime,
                updateTime: updateTime,
              ),
          createCompanionCallback:
              ({
                Value<int> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<DateTime?> activeTime = const Value.absent(),
                Value<int?> transmitterId = const Value.absent(),
                Value<String?> transmitterSn = const Value.absent(),
                Value<int?> sensorId = const Value.absent(),
                Value<String?> sensorSn = const Value.absent(),
                Value<DateTime?> lastWearTime = const Value.absent(),
                Value<DateTime?> lastDataUptime = const Value.absent(),
                Value<String?> lastGlucose = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
                Value<DateTime?> updateTime = const Value.absent(),
              }) => UserWearCurCompanion.insert(
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                activeTime: activeTime,
                transmitterId: transmitterId,
                transmitterSn: transmitterSn,
                sensorId: sensorId,
                sensorSn: sensorSn,
                lastWearTime: lastWearTime,
                lastDataUptime: lastDataUptime,
                lastGlucose: lastGlucose,
                createTime: createTime,
                updateTime: updateTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserWearCurTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserWearCurTable,
      UserWearCurRow,
      $$UserWearCurTableFilterComposer,
      $$UserWearCurTableOrderingComposer,
      $$UserWearCurTableAnnotationComposer,
      $$UserWearCurTableCreateCompanionBuilder,
      $$UserWearCurTableUpdateCompanionBuilder,
      (
        UserWearCurRow,
        BaseReferences<_$CgmDatabase, $UserWearCurTable, UserWearCurRow>,
      ),
      UserWearCurRow,
      PrefetchHooks Function()
    >;
typedef $$UserWearStatusLogTableCreateCompanionBuilder =
    UserWearStatusLogCompanion Function({
      Value<int> id,
      required int userId,
      required int accountId,
      required int wearId,
      Value<String?> handleStatus,
      Value<DateTime?> handleTime,
      Value<String?> unbindReson,
      Value<DateTime?> createTime,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
    });
typedef $$UserWearStatusLogTableUpdateCompanionBuilder =
    UserWearStatusLogCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> accountId,
      Value<int> wearId,
      Value<String?> handleStatus,
      Value<DateTime?> handleTime,
      Value<String?> unbindReson,
      Value<DateTime?> createTime,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
    });

class $$UserWearStatusLogTableFilterComposer
    extends Composer<_$CgmDatabase, $UserWearStatusLogTable> {
  $$UserWearStatusLogTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handleStatus => $composableBuilder(
    column: $table.handleStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get handleTime =>
      $composableBuilder(
        column: $table.handleTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get unbindReson => $composableBuilder(
    column: $table.unbindReson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserWearStatusLogTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserWearStatusLogTable> {
  $$UserWearStatusLogTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handleStatus => $composableBuilder(
    column: $table.handleStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get handleTime => $composableBuilder(
    column: $table.handleTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unbindReson => $composableBuilder(
    column: $table.unbindReson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserWearStatusLogTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserWearStatusLogTable> {
  $$UserWearStatusLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<String> get handleStatus => $composableBuilder(
    column: $table.handleStatus,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get handleTime =>
      $composableBuilder(
        column: $table.handleTime,
        builder: (column) => column,
      );

  GeneratedColumn<String> get unbindReson => $composableBuilder(
    column: $table.unbindReson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );

  GeneratedColumn<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => column,
  );
}

class $$UserWearStatusLogTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserWearStatusLogTable,
          UserWearStatusLogRow,
          $$UserWearStatusLogTableFilterComposer,
          $$UserWearStatusLogTableOrderingComposer,
          $$UserWearStatusLogTableAnnotationComposer,
          $$UserWearStatusLogTableCreateCompanionBuilder,
          $$UserWearStatusLogTableUpdateCompanionBuilder,
          (
            UserWearStatusLogRow,
            BaseReferences<
              _$CgmDatabase,
              $UserWearStatusLogTable,
              UserWearStatusLogRow
            >,
          ),
          UserWearStatusLogRow,
          PrefetchHooks Function()
        > {
  $$UserWearStatusLogTableTableManager(
    _$CgmDatabase db,
    $UserWearStatusLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserWearStatusLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserWearStatusLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserWearStatusLogTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int> wearId = const Value.absent(),
                Value<String?> handleStatus = const Value.absent(),
                Value<DateTime?> handleTime = const Value.absent(),
                Value<String?> unbindReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
              }) => UserWearStatusLogCompanion(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                handleStatus: handleStatus,
                handleTime: handleTime,
                unbindReson: unbindReson,
                createTime: createTime,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int accountId,
                required int wearId,
                Value<String?> handleStatus = const Value.absent(),
                Value<DateTime?> handleTime = const Value.absent(),
                Value<String?> unbindReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
              }) => UserWearStatusLogCompanion.insert(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                handleStatus: handleStatus,
                handleTime: handleTime,
                unbindReson: unbindReson,
                createTime: createTime,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserWearStatusLogTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserWearStatusLogTable,
      UserWearStatusLogRow,
      $$UserWearStatusLogTableFilterComposer,
      $$UserWearStatusLogTableOrderingComposer,
      $$UserWearStatusLogTableAnnotationComposer,
      $$UserWearStatusLogTableCreateCompanionBuilder,
      $$UserWearStatusLogTableUpdateCompanionBuilder,
      (
        UserWearStatusLogRow,
        BaseReferences<
          _$CgmDatabase,
          $UserWearStatusLogTable,
          UserWearStatusLogRow
        >,
      ),
      UserWearStatusLogRow,
      PrefetchHooks Function()
    >;
typedef $$UserlocalGlucoseDataTableCreateCompanionBuilder =
    UserlocalGlucoseDataCompanion Function({
      Value<int> id,
      required int userId,
      required int accountId,
      required int wearId,
      required DateTime measureTime,
      Value<int?> recordSeq,
      Value<double?> glucoseValue1,
      Value<double?> glucoseValue2,
      Value<String?> fiveMinFlag,
      Value<MedicalDecimal?> fiveMinGlucose,
      Value<String?> warmupFlag,
      Value<String?> abnormalFlag,
      Value<String?> modifiedFlag,
      Value<String?> status,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<String?> isCloudData,
      Value<DateTime?> createTime,
    });
typedef $$UserlocalGlucoseDataTableUpdateCompanionBuilder =
    UserlocalGlucoseDataCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int> accountId,
      Value<int> wearId,
      Value<DateTime> measureTime,
      Value<int?> recordSeq,
      Value<double?> glucoseValue1,
      Value<double?> glucoseValue2,
      Value<String?> fiveMinFlag,
      Value<MedicalDecimal?> fiveMinGlucose,
      Value<String?> warmupFlag,
      Value<String?> abnormalFlag,
      Value<String?> modifiedFlag,
      Value<String?> status,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<String?> isCloudData,
      Value<DateTime?> createTime,
    });

class $$UserlocalGlucoseDataTableFilterComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseDataTable> {
  $$UserlocalGlucoseDataTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fiveMinFlag => $composableBuilder(
    column: $table.fiveMinFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get fiveMinGlucose => $composableBuilder(
    column: $table.fiveMinGlucose,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedFlag => $composableBuilder(
    column: $table.modifiedFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isCloudData => $composableBuilder(
    column: $table.isCloudData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserlocalGlucoseDataTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseDataTable> {
  $$UserlocalGlucoseDataTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measureTime => $composableBuilder(
    column: $table.measureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiveMinFlag => $composableBuilder(
    column: $table.fiveMinFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiveMinGlucose => $composableBuilder(
    column: $table.fiveMinGlucose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedFlag => $composableBuilder(
    column: $table.modifiedFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isCloudData => $composableBuilder(
    column: $table.isCloudData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserlocalGlucoseDataTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseDataTable> {
  $$UserlocalGlucoseDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => column,
      );

  GeneratedColumn<int> get recordSeq =>
      $composableBuilder(column: $table.recordSeq, builder: (column) => column);

  GeneratedColumn<double> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => column,
  );

  GeneratedColumn<double> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fiveMinFlag => $composableBuilder(
    column: $table.fiveMinFlag,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  get fiveMinGlucose => $composableBuilder(
    column: $table.fiveMinGlucose,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedFlag => $composableBuilder(
    column: $table.modifiedFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isCloudData => $composableBuilder(
    column: $table.isCloudData,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );
}

class $$UserlocalGlucoseDataTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserlocalGlucoseDataTable,
          UserlocalGlucoseDataRow,
          $$UserlocalGlucoseDataTableFilterComposer,
          $$UserlocalGlucoseDataTableOrderingComposer,
          $$UserlocalGlucoseDataTableAnnotationComposer,
          $$UserlocalGlucoseDataTableCreateCompanionBuilder,
          $$UserlocalGlucoseDataTableUpdateCompanionBuilder,
          (
            UserlocalGlucoseDataRow,
            BaseReferences<
              _$CgmDatabase,
              $UserlocalGlucoseDataTable,
              UserlocalGlucoseDataRow
            >,
          ),
          UserlocalGlucoseDataRow,
          PrefetchHooks Function()
        > {
  $$UserlocalGlucoseDataTableTableManager(
    _$CgmDatabase db,
    $UserlocalGlucoseDataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserlocalGlucoseDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserlocalGlucoseDataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserlocalGlucoseDataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<int> wearId = const Value.absent(),
                Value<DateTime> measureTime = const Value.absent(),
                Value<int?> recordSeq = const Value.absent(),
                Value<double?> glucoseValue1 = const Value.absent(),
                Value<double?> glucoseValue2 = const Value.absent(),
                Value<String?> fiveMinFlag = const Value.absent(),
                Value<MedicalDecimal?> fiveMinGlucose = const Value.absent(),
                Value<String?> warmupFlag = const Value.absent(),
                Value<String?> abnormalFlag = const Value.absent(),
                Value<String?> modifiedFlag = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<String?> isCloudData = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalGlucoseDataCompanion(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                measureTime: measureTime,
                recordSeq: recordSeq,
                glucoseValue1: glucoseValue1,
                glucoseValue2: glucoseValue2,
                fiveMinFlag: fiveMinFlag,
                fiveMinGlucose: fiveMinGlucose,
                warmupFlag: warmupFlag,
                abnormalFlag: abnormalFlag,
                modifiedFlag: modifiedFlag,
                status: status,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                isCloudData: isCloudData,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                required int accountId,
                required int wearId,
                required DateTime measureTime,
                Value<int?> recordSeq = const Value.absent(),
                Value<double?> glucoseValue1 = const Value.absent(),
                Value<double?> glucoseValue2 = const Value.absent(),
                Value<String?> fiveMinFlag = const Value.absent(),
                Value<MedicalDecimal?> fiveMinGlucose = const Value.absent(),
                Value<String?> warmupFlag = const Value.absent(),
                Value<String?> abnormalFlag = const Value.absent(),
                Value<String?> modifiedFlag = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<String?> isCloudData = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalGlucoseDataCompanion.insert(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                measureTime: measureTime,
                recordSeq: recordSeq,
                glucoseValue1: glucoseValue1,
                glucoseValue2: glucoseValue2,
                fiveMinFlag: fiveMinFlag,
                fiveMinGlucose: fiveMinGlucose,
                warmupFlag: warmupFlag,
                abnormalFlag: abnormalFlag,
                modifiedFlag: modifiedFlag,
                status: status,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                isCloudData: isCloudData,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserlocalGlucoseDataTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserlocalGlucoseDataTable,
      UserlocalGlucoseDataRow,
      $$UserlocalGlucoseDataTableFilterComposer,
      $$UserlocalGlucoseDataTableOrderingComposer,
      $$UserlocalGlucoseDataTableAnnotationComposer,
      $$UserlocalGlucoseDataTableCreateCompanionBuilder,
      $$UserlocalGlucoseDataTableUpdateCompanionBuilder,
      (
        UserlocalGlucoseDataRow,
        BaseReferences<
          _$CgmDatabase,
          $UserlocalGlucoseDataTable,
          UserlocalGlucoseDataRow
        >,
      ),
      UserlocalGlucoseDataRow,
      PrefetchHooks Function()
    >;
typedef $$UserlocalGlucoseRawDataTableCreateCompanionBuilder =
    UserlocalGlucoseRawDataCompanion Function({
      Value<int> id,
      Value<int?> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<int?> recordSeq,
      required DateTime measureTime,
      Value<double?> rawCurrent1,
      Value<double?> rawCurrent2,
      Value<double?> temperature1,
      Value<double?> temperature2,
      Value<double?> glucoseValue1,
      Value<double?> glucoseValue2,
      Value<String?> warmupFlag,
      Value<String?> abnormalFlag,
      Value<String?> modifiedFlag,
      Value<double?> currentCoef,
      Value<double?> algoK,
      Value<double?> algoB,
      Value<double?> ibase,
      Value<double?> cgmbase,
      Value<MedicalDecimal?> voltageValue,
      Value<MedicalDecimal?> reserveValue1,
      Value<MedicalDecimal?> reserveValue2,
      Value<MedicalDecimal?> reserveValue3,
      Value<MedicalDecimal?> reserveValue4,
      Value<String?> reserveStr1,
      Value<String?> reserveStr2,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<DateTime?> createTime,
    });
typedef $$UserlocalGlucoseRawDataTableUpdateCompanionBuilder =
    UserlocalGlucoseRawDataCompanion Function({
      Value<int> id,
      Value<int?> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<int?> recordSeq,
      Value<DateTime> measureTime,
      Value<double?> rawCurrent1,
      Value<double?> rawCurrent2,
      Value<double?> temperature1,
      Value<double?> temperature2,
      Value<double?> glucoseValue1,
      Value<double?> glucoseValue2,
      Value<String?> warmupFlag,
      Value<String?> abnormalFlag,
      Value<String?> modifiedFlag,
      Value<double?> currentCoef,
      Value<double?> algoK,
      Value<double?> algoB,
      Value<double?> ibase,
      Value<double?> cgmbase,
      Value<MedicalDecimal?> voltageValue,
      Value<MedicalDecimal?> reserveValue1,
      Value<MedicalDecimal?> reserveValue2,
      Value<MedicalDecimal?> reserveValue3,
      Value<MedicalDecimal?> reserveValue4,
      Value<String?> reserveStr1,
      Value<String?> reserveStr2,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<DateTime?> createTime,
    });

class $$UserlocalGlucoseRawDataTableFilterComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseRawDataTable> {
  $$UserlocalGlucoseRawDataTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get rawCurrent1 => $composableBuilder(
    column: $table.rawCurrent1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rawCurrent2 => $composableBuilder(
    column: $table.rawCurrent2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature1 => $composableBuilder(
    column: $table.temperature1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature2 => $composableBuilder(
    column: $table.temperature2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedFlag => $composableBuilder(
    column: $table.modifiedFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentCoef => $composableBuilder(
    column: $table.currentCoef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get algoK => $composableBuilder(
    column: $table.algoK,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get algoB => $composableBuilder(
    column: $table.algoB,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ibase => $composableBuilder(
    column: $table.ibase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cgmbase => $composableBuilder(
    column: $table.cgmbase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get voltageValue => $composableBuilder(
    column: $table.voltageValue,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get reserveValue1 => $composableBuilder(
    column: $table.reserveValue1,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get reserveValue2 => $composableBuilder(
    column: $table.reserveValue2,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get reserveValue3 => $composableBuilder(
    column: $table.reserveValue3,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get reserveValue4 => $composableBuilder(
    column: $table.reserveValue4,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get reserveStr1 => $composableBuilder(
    column: $table.reserveStr1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reserveStr2 => $composableBuilder(
    column: $table.reserveStr2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserlocalGlucoseRawDataTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseRawDataTable> {
  $$UserlocalGlucoseRawDataTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measureTime => $composableBuilder(
    column: $table.measureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rawCurrent1 => $composableBuilder(
    column: $table.rawCurrent1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rawCurrent2 => $composableBuilder(
    column: $table.rawCurrent2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature1 => $composableBuilder(
    column: $table.temperature1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature2 => $composableBuilder(
    column: $table.temperature2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedFlag => $composableBuilder(
    column: $table.modifiedFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentCoef => $composableBuilder(
    column: $table.currentCoef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get algoK => $composableBuilder(
    column: $table.algoK,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get algoB => $composableBuilder(
    column: $table.algoB,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ibase => $composableBuilder(
    column: $table.ibase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cgmbase => $composableBuilder(
    column: $table.cgmbase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voltageValue => $composableBuilder(
    column: $table.voltageValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reserveValue1 => $composableBuilder(
    column: $table.reserveValue1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reserveValue2 => $composableBuilder(
    column: $table.reserveValue2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reserveValue3 => $composableBuilder(
    column: $table.reserveValue3,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reserveValue4 => $composableBuilder(
    column: $table.reserveValue4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reserveStr1 => $composableBuilder(
    column: $table.reserveStr1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reserveStr2 => $composableBuilder(
    column: $table.reserveStr2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserlocalGlucoseRawDataTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseRawDataTable> {
  $$UserlocalGlucoseRawDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<int> get recordSeq =>
      $composableBuilder(column: $table.recordSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => column,
      );

  GeneratedColumn<double> get rawCurrent1 => $composableBuilder(
    column: $table.rawCurrent1,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rawCurrent2 => $composableBuilder(
    column: $table.rawCurrent2,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature1 => $composableBuilder(
    column: $table.temperature1,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperature2 => $composableBuilder(
    column: $table.temperature2,
    builder: (column) => column,
  );

  GeneratedColumn<double> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => column,
  );

  GeneratedColumn<double> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedFlag => $composableBuilder(
    column: $table.modifiedFlag,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentCoef => $composableBuilder(
    column: $table.currentCoef,
    builder: (column) => column,
  );

  GeneratedColumn<double> get algoK =>
      $composableBuilder(column: $table.algoK, builder: (column) => column);

  GeneratedColumn<double> get algoB =>
      $composableBuilder(column: $table.algoB, builder: (column) => column);

  GeneratedColumn<double> get ibase =>
      $composableBuilder(column: $table.ibase, builder: (column) => column);

  GeneratedColumn<double> get cgmbase =>
      $composableBuilder(column: $table.cgmbase, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get voltageValue =>
      $composableBuilder(
        column: $table.voltageValue,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get reserveValue1 =>
      $composableBuilder(
        column: $table.reserveValue1,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get reserveValue2 =>
      $composableBuilder(
        column: $table.reserveValue2,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get reserveValue3 =>
      $composableBuilder(
        column: $table.reserveValue3,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get reserveValue4 =>
      $composableBuilder(
        column: $table.reserveValue4,
        builder: (column) => column,
      );

  GeneratedColumn<String> get reserveStr1 => $composableBuilder(
    column: $table.reserveStr1,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reserveStr2 => $composableBuilder(
    column: $table.reserveStr2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );
}

class $$UserlocalGlucoseRawDataTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserlocalGlucoseRawDataTable,
          UserlocalGlucoseRawDataRow,
          $$UserlocalGlucoseRawDataTableFilterComposer,
          $$UserlocalGlucoseRawDataTableOrderingComposer,
          $$UserlocalGlucoseRawDataTableAnnotationComposer,
          $$UserlocalGlucoseRawDataTableCreateCompanionBuilder,
          $$UserlocalGlucoseRawDataTableUpdateCompanionBuilder,
          (
            UserlocalGlucoseRawDataRow,
            BaseReferences<
              _$CgmDatabase,
              $UserlocalGlucoseRawDataTable,
              UserlocalGlucoseRawDataRow
            >,
          ),
          UserlocalGlucoseRawDataRow,
          PrefetchHooks Function()
        > {
  $$UserlocalGlucoseRawDataTableTableManager(
    _$CgmDatabase db,
    $UserlocalGlucoseRawDataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserlocalGlucoseRawDataTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserlocalGlucoseRawDataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserlocalGlucoseRawDataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<int?> recordSeq = const Value.absent(),
                Value<DateTime> measureTime = const Value.absent(),
                Value<double?> rawCurrent1 = const Value.absent(),
                Value<double?> rawCurrent2 = const Value.absent(),
                Value<double?> temperature1 = const Value.absent(),
                Value<double?> temperature2 = const Value.absent(),
                Value<double?> glucoseValue1 = const Value.absent(),
                Value<double?> glucoseValue2 = const Value.absent(),
                Value<String?> warmupFlag = const Value.absent(),
                Value<String?> abnormalFlag = const Value.absent(),
                Value<String?> modifiedFlag = const Value.absent(),
                Value<double?> currentCoef = const Value.absent(),
                Value<double?> algoK = const Value.absent(),
                Value<double?> algoB = const Value.absent(),
                Value<double?> ibase = const Value.absent(),
                Value<double?> cgmbase = const Value.absent(),
                Value<MedicalDecimal?> voltageValue = const Value.absent(),
                Value<MedicalDecimal?> reserveValue1 = const Value.absent(),
                Value<MedicalDecimal?> reserveValue2 = const Value.absent(),
                Value<MedicalDecimal?> reserveValue3 = const Value.absent(),
                Value<MedicalDecimal?> reserveValue4 = const Value.absent(),
                Value<String?> reserveStr1 = const Value.absent(),
                Value<String?> reserveStr2 = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalGlucoseRawDataCompanion(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                recordSeq: recordSeq,
                measureTime: measureTime,
                rawCurrent1: rawCurrent1,
                rawCurrent2: rawCurrent2,
                temperature1: temperature1,
                temperature2: temperature2,
                glucoseValue1: glucoseValue1,
                glucoseValue2: glucoseValue2,
                warmupFlag: warmupFlag,
                abnormalFlag: abnormalFlag,
                modifiedFlag: modifiedFlag,
                currentCoef: currentCoef,
                algoK: algoK,
                algoB: algoB,
                ibase: ibase,
                cgmbase: cgmbase,
                voltageValue: voltageValue,
                reserveValue1: reserveValue1,
                reserveValue2: reserveValue2,
                reserveValue3: reserveValue3,
                reserveValue4: reserveValue4,
                reserveStr1: reserveStr1,
                reserveStr2: reserveStr2,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<int?> recordSeq = const Value.absent(),
                required DateTime measureTime,
                Value<double?> rawCurrent1 = const Value.absent(),
                Value<double?> rawCurrent2 = const Value.absent(),
                Value<double?> temperature1 = const Value.absent(),
                Value<double?> temperature2 = const Value.absent(),
                Value<double?> glucoseValue1 = const Value.absent(),
                Value<double?> glucoseValue2 = const Value.absent(),
                Value<String?> warmupFlag = const Value.absent(),
                Value<String?> abnormalFlag = const Value.absent(),
                Value<String?> modifiedFlag = const Value.absent(),
                Value<double?> currentCoef = const Value.absent(),
                Value<double?> algoK = const Value.absent(),
                Value<double?> algoB = const Value.absent(),
                Value<double?> ibase = const Value.absent(),
                Value<double?> cgmbase = const Value.absent(),
                Value<MedicalDecimal?> voltageValue = const Value.absent(),
                Value<MedicalDecimal?> reserveValue1 = const Value.absent(),
                Value<MedicalDecimal?> reserveValue2 = const Value.absent(),
                Value<MedicalDecimal?> reserveValue3 = const Value.absent(),
                Value<MedicalDecimal?> reserveValue4 = const Value.absent(),
                Value<String?> reserveStr1 = const Value.absent(),
                Value<String?> reserveStr2 = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalGlucoseRawDataCompanion.insert(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                recordSeq: recordSeq,
                measureTime: measureTime,
                rawCurrent1: rawCurrent1,
                rawCurrent2: rawCurrent2,
                temperature1: temperature1,
                temperature2: temperature2,
                glucoseValue1: glucoseValue1,
                glucoseValue2: glucoseValue2,
                warmupFlag: warmupFlag,
                abnormalFlag: abnormalFlag,
                modifiedFlag: modifiedFlag,
                currentCoef: currentCoef,
                algoK: algoK,
                algoB: algoB,
                ibase: ibase,
                cgmbase: cgmbase,
                voltageValue: voltageValue,
                reserveValue1: reserveValue1,
                reserveValue2: reserveValue2,
                reserveValue3: reserveValue3,
                reserveValue4: reserveValue4,
                reserveStr1: reserveStr1,
                reserveStr2: reserveStr2,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserlocalGlucoseRawDataTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserlocalGlucoseRawDataTable,
      UserlocalGlucoseRawDataRow,
      $$UserlocalGlucoseRawDataTableFilterComposer,
      $$UserlocalGlucoseRawDataTableOrderingComposer,
      $$UserlocalGlucoseRawDataTableAnnotationComposer,
      $$UserlocalGlucoseRawDataTableCreateCompanionBuilder,
      $$UserlocalGlucoseRawDataTableUpdateCompanionBuilder,
      (
        UserlocalGlucoseRawDataRow,
        BaseReferences<
          _$CgmDatabase,
          $UserlocalGlucoseRawDataTable,
          UserlocalGlucoseRawDataRow
        >,
      ),
      UserlocalGlucoseRawDataRow,
      PrefetchHooks Function()
    >;
typedef $$UserlocalGlucoseModifiedLogTableCreateCompanionBuilder =
    UserlocalGlucoseModifiedLogCompanion Function({
      Value<int> id,
      required int userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<int?> recordSeq,
      Value<MedicalDecimal?> glucoseValue1,
      Value<MedicalDecimal?> glucoseValue2,
      required DateTime measureTime,
      Value<String?> fiveMinFlag,
      Value<MedicalDecimal?> fiveMinGlucose,
      Value<String?> warmupFlag,
      Value<String?> abnormalFlag,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<DateTime?> createTime,
    });
typedef $$UserlocalGlucoseModifiedLogTableUpdateCompanionBuilder =
    UserlocalGlucoseModifiedLogCompanion Function({
      Value<int> id,
      Value<int> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<int?> recordSeq,
      Value<MedicalDecimal?> glucoseValue1,
      Value<MedicalDecimal?> glucoseValue2,
      Value<DateTime> measureTime,
      Value<String?> fiveMinFlag,
      Value<MedicalDecimal?> fiveMinGlucose,
      Value<String?> warmupFlag,
      Value<String?> abnormalFlag,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<DateTime?> createTime,
    });

class $$UserlocalGlucoseModifiedLogTableFilterComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseModifiedLogTable> {
  $$UserlocalGlucoseModifiedLogTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get fiveMinFlag => $composableBuilder(
    column: $table.fiveMinFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MedicalDecimal?, MedicalDecimal, String>
  get fiveMinGlucose => $composableBuilder(
    column: $table.fiveMinGlucose,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserlocalGlucoseModifiedLogTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseModifiedLogTable> {
  $$UserlocalGlucoseModifiedLogTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordSeq => $composableBuilder(
    column: $table.recordSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glucoseValue1 => $composableBuilder(
    column: $table.glucoseValue1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get glucoseValue2 => $composableBuilder(
    column: $table.glucoseValue2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get measureTime => $composableBuilder(
    column: $table.measureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiveMinFlag => $composableBuilder(
    column: $table.fiveMinFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fiveMinGlucose => $composableBuilder(
    column: $table.fiveMinGlucose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserlocalGlucoseModifiedLogTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserlocalGlucoseModifiedLogTable> {
  $$UserlocalGlucoseModifiedLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<int> get recordSeq =>
      $composableBuilder(column: $table.recordSeq, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get glucoseValue1 =>
      $composableBuilder(
        column: $table.glucoseValue1,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String> get glucoseValue2 =>
      $composableBuilder(
        column: $table.glucoseValue2,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get measureTime =>
      $composableBuilder(
        column: $table.measureTime,
        builder: (column) => column,
      );

  GeneratedColumn<String> get fiveMinFlag => $composableBuilder(
    column: $table.fiveMinFlag,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MedicalDecimal?, String>
  get fiveMinGlucose => $composableBuilder(
    column: $table.fiveMinGlucose,
    builder: (column) => column,
  );

  GeneratedColumn<String> get warmupFlag => $composableBuilder(
    column: $table.warmupFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get abnormalFlag => $composableBuilder(
    column: $table.abnormalFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );
}

class $$UserlocalGlucoseModifiedLogTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserlocalGlucoseModifiedLogTable,
          UserlocalGlucoseModifiedLogRow,
          $$UserlocalGlucoseModifiedLogTableFilterComposer,
          $$UserlocalGlucoseModifiedLogTableOrderingComposer,
          $$UserlocalGlucoseModifiedLogTableAnnotationComposer,
          $$UserlocalGlucoseModifiedLogTableCreateCompanionBuilder,
          $$UserlocalGlucoseModifiedLogTableUpdateCompanionBuilder,
          (
            UserlocalGlucoseModifiedLogRow,
            BaseReferences<
              _$CgmDatabase,
              $UserlocalGlucoseModifiedLogTable,
              UserlocalGlucoseModifiedLogRow
            >,
          ),
          UserlocalGlucoseModifiedLogRow,
          PrefetchHooks Function()
        > {
  $$UserlocalGlucoseModifiedLogTableTableManager(
    _$CgmDatabase db,
    $UserlocalGlucoseModifiedLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserlocalGlucoseModifiedLogTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserlocalGlucoseModifiedLogTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserlocalGlucoseModifiedLogTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<int?> recordSeq = const Value.absent(),
                Value<MedicalDecimal?> glucoseValue1 = const Value.absent(),
                Value<MedicalDecimal?> glucoseValue2 = const Value.absent(),
                Value<DateTime> measureTime = const Value.absent(),
                Value<String?> fiveMinFlag = const Value.absent(),
                Value<MedicalDecimal?> fiveMinGlucose = const Value.absent(),
                Value<String?> warmupFlag = const Value.absent(),
                Value<String?> abnormalFlag = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalGlucoseModifiedLogCompanion(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                recordSeq: recordSeq,
                glucoseValue1: glucoseValue1,
                glucoseValue2: glucoseValue2,
                measureTime: measureTime,
                fiveMinFlag: fiveMinFlag,
                fiveMinGlucose: fiveMinGlucose,
                warmupFlag: warmupFlag,
                abnormalFlag: abnormalFlag,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int userId,
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<int?> recordSeq = const Value.absent(),
                Value<MedicalDecimal?> glucoseValue1 = const Value.absent(),
                Value<MedicalDecimal?> glucoseValue2 = const Value.absent(),
                required DateTime measureTime,
                Value<String?> fiveMinFlag = const Value.absent(),
                Value<MedicalDecimal?> fiveMinGlucose = const Value.absent(),
                Value<String?> warmupFlag = const Value.absent(),
                Value<String?> abnormalFlag = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalGlucoseModifiedLogCompanion.insert(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                recordSeq: recordSeq,
                glucoseValue1: glucoseValue1,
                glucoseValue2: glucoseValue2,
                measureTime: measureTime,
                fiveMinFlag: fiveMinFlag,
                fiveMinGlucose: fiveMinGlucose,
                warmupFlag: warmupFlag,
                abnormalFlag: abnormalFlag,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserlocalGlucoseModifiedLogTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserlocalGlucoseModifiedLogTable,
      UserlocalGlucoseModifiedLogRow,
      $$UserlocalGlucoseModifiedLogTableFilterComposer,
      $$UserlocalGlucoseModifiedLogTableOrderingComposer,
      $$UserlocalGlucoseModifiedLogTableAnnotationComposer,
      $$UserlocalGlucoseModifiedLogTableCreateCompanionBuilder,
      $$UserlocalGlucoseModifiedLogTableUpdateCompanionBuilder,
      (
        UserlocalGlucoseModifiedLogRow,
        BaseReferences<
          _$CgmDatabase,
          $UserlocalGlucoseModifiedLogTable,
          UserlocalGlucoseModifiedLogRow
        >,
      ),
      UserlocalGlucoseModifiedLogRow,
      PrefetchHooks Function()
    >;
typedef $$UserlocalWearErrorLogTableCreateCompanionBuilder =
    UserlocalWearErrorLogCompanion Function({
      Value<int> id,
      Value<int?> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<String?> errorContent,
      Value<DateTime?> errorTime,
      Value<int?> userPhoneId,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<DateTime?> createTime,
    });
typedef $$UserlocalWearErrorLogTableUpdateCompanionBuilder =
    UserlocalWearErrorLogCompanion Function({
      Value<int> id,
      Value<int?> userId,
      Value<int?> accountId,
      Value<int?> wearId,
      Value<String?> errorContent,
      Value<DateTime?> errorTime,
      Value<int?> userPhoneId,
      Value<String?> uploadFlag,
      Value<String?> uploadResult,
      Value<String?> uploadFailReson,
      Value<DateTime?> createTime,
    });

class $$UserlocalWearErrorLogTableFilterComposer
    extends Composer<_$CgmDatabase, $UserlocalWearErrorLogTable> {
  $$UserlocalWearErrorLogTableFilterComposer({
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

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorContent => $composableBuilder(
    column: $table.errorContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get errorTime =>
      $composableBuilder(
        column: $table.errorTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get userPhoneId => $composableBuilder(
    column: $table.userPhoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserlocalWearErrorLogTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserlocalWearErrorLogTable> {
  $$UserlocalWearErrorLogTableOrderingComposer({
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

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorContent => $composableBuilder(
    column: $table.errorContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get errorTime => $composableBuilder(
    column: $table.errorTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userPhoneId => $composableBuilder(
    column: $table.userPhoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserlocalWearErrorLogTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserlocalWearErrorLogTable> {
  $$UserlocalWearErrorLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<String> get errorContent => $composableBuilder(
    column: $table.errorContent,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get errorTime =>
      $composableBuilder(column: $table.errorTime, builder: (column) => column);

  GeneratedColumn<int> get userPhoneId => $composableBuilder(
    column: $table.userPhoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFlag => $composableBuilder(
    column: $table.uploadFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadResult => $composableBuilder(
    column: $table.uploadResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uploadFailReson => $composableBuilder(
    column: $table.uploadFailReson,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );
}

class $$UserlocalWearErrorLogTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserlocalWearErrorLogTable,
          UserlocalWearErrorLogRow,
          $$UserlocalWearErrorLogTableFilterComposer,
          $$UserlocalWearErrorLogTableOrderingComposer,
          $$UserlocalWearErrorLogTableAnnotationComposer,
          $$UserlocalWearErrorLogTableCreateCompanionBuilder,
          $$UserlocalWearErrorLogTableUpdateCompanionBuilder,
          (
            UserlocalWearErrorLogRow,
            BaseReferences<
              _$CgmDatabase,
              $UserlocalWearErrorLogTable,
              UserlocalWearErrorLogRow
            >,
          ),
          UserlocalWearErrorLogRow,
          PrefetchHooks Function()
        > {
  $$UserlocalWearErrorLogTableTableManager(
    _$CgmDatabase db,
    $UserlocalWearErrorLogTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserlocalWearErrorLogTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserlocalWearErrorLogTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserlocalWearErrorLogTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<String?> errorContent = const Value.absent(),
                Value<DateTime?> errorTime = const Value.absent(),
                Value<int?> userPhoneId = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalWearErrorLogCompanion(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                errorContent: errorContent,
                errorTime: errorTime,
                userPhoneId: userPhoneId,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<String?> errorContent = const Value.absent(),
                Value<DateTime?> errorTime = const Value.absent(),
                Value<int?> userPhoneId = const Value.absent(),
                Value<String?> uploadFlag = const Value.absent(),
                Value<String?> uploadResult = const Value.absent(),
                Value<String?> uploadFailReson = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalWearErrorLogCompanion.insert(
                id: id,
                userId: userId,
                accountId: accountId,
                wearId: wearId,
                errorContent: errorContent,
                errorTime: errorTime,
                userPhoneId: userPhoneId,
                uploadFlag: uploadFlag,
                uploadResult: uploadResult,
                uploadFailReson: uploadFailReson,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserlocalWearErrorLogTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserlocalWearErrorLogTable,
      UserlocalWearErrorLogRow,
      $$UserlocalWearErrorLogTableFilterComposer,
      $$UserlocalWearErrorLogTableOrderingComposer,
      $$UserlocalWearErrorLogTableAnnotationComposer,
      $$UserlocalWearErrorLogTableCreateCompanionBuilder,
      $$UserlocalWearErrorLogTableUpdateCompanionBuilder,
      (
        UserlocalWearErrorLogRow,
        BaseReferences<
          _$CgmDatabase,
          $UserlocalWearErrorLogTable,
          UserlocalWearErrorLogRow
        >,
      ),
      UserlocalWearErrorLogRow,
      PrefetchHooks Function()
    >;
typedef $$UserlocalCollectionDaycntTableCreateCompanionBuilder =
    UserlocalCollectionDaycntCompanion Function({
      Value<int> id,
      Value<int?> wearId,
      Value<int?> userId,
      Value<int?> accountId,
      Value<DateTime?> day,
      Value<String?> isComplate,
      Value<int?> collectCnt,
      Value<int?> effCnt,
      Value<double?> glucoseTotalVal,
      Value<int?> hiCnt,
      Value<int?> lowCnt,
      Value<int?> extHiCnt,
      Value<int?> extLoCnt,
      Value<int?> tirCnt,
      Value<DateTime?> createTime,
    });
typedef $$UserlocalCollectionDaycntTableUpdateCompanionBuilder =
    UserlocalCollectionDaycntCompanion Function({
      Value<int> id,
      Value<int?> wearId,
      Value<int?> userId,
      Value<int?> accountId,
      Value<DateTime?> day,
      Value<String?> isComplate,
      Value<int?> collectCnt,
      Value<int?> effCnt,
      Value<double?> glucoseTotalVal,
      Value<int?> hiCnt,
      Value<int?> lowCnt,
      Value<int?> extHiCnt,
      Value<int?> extLoCnt,
      Value<int?> tirCnt,
      Value<DateTime?> createTime,
    });

class $$UserlocalCollectionDaycntTableFilterComposer
    extends Composer<_$CgmDatabase, $UserlocalCollectionDaycntTable> {
  $$UserlocalCollectionDaycntTableFilterComposer({
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

  ColumnFilters<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get day =>
      $composableBuilder(
        column: $table.day,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get isComplate => $composableBuilder(
    column: $table.isComplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get collectCnt => $composableBuilder(
    column: $table.collectCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effCnt => $composableBuilder(
    column: $table.effCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseTotalVal => $composableBuilder(
    column: $table.glucoseTotalVal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hiCnt => $composableBuilder(
    column: $table.hiCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowCnt => $composableBuilder(
    column: $table.lowCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extHiCnt => $composableBuilder(
    column: $table.extHiCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extLoCnt => $composableBuilder(
    column: $table.extLoCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tirCnt => $composableBuilder(
    column: $table.tirCnt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserlocalCollectionDaycntTableOrderingComposer
    extends Composer<_$CgmDatabase, $UserlocalCollectionDaycntTable> {
  $$UserlocalCollectionDaycntTableOrderingComposer({
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

  ColumnOrderings<int> get wearId => $composableBuilder(
    column: $table.wearId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isComplate => $composableBuilder(
    column: $table.isComplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get collectCnt => $composableBuilder(
    column: $table.collectCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effCnt => $composableBuilder(
    column: $table.effCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseTotalVal => $composableBuilder(
    column: $table.glucoseTotalVal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hiCnt => $composableBuilder(
    column: $table.hiCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowCnt => $composableBuilder(
    column: $table.lowCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extHiCnt => $composableBuilder(
    column: $table.extHiCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extLoCnt => $composableBuilder(
    column: $table.extLoCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tirCnt => $composableBuilder(
    column: $table.tirCnt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createTime => $composableBuilder(
    column: $table.createTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserlocalCollectionDaycntTableAnnotationComposer
    extends Composer<_$CgmDatabase, $UserlocalCollectionDaycntTable> {
  $$UserlocalCollectionDaycntTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wearId =>
      $composableBuilder(column: $table.wearId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get isComplate => $composableBuilder(
    column: $table.isComplate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get collectCnt => $composableBuilder(
    column: $table.collectCnt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get effCnt =>
      $composableBuilder(column: $table.effCnt, builder: (column) => column);

  GeneratedColumn<double> get glucoseTotalVal => $composableBuilder(
    column: $table.glucoseTotalVal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hiCnt =>
      $composableBuilder(column: $table.hiCnt, builder: (column) => column);

  GeneratedColumn<int> get lowCnt =>
      $composableBuilder(column: $table.lowCnt, builder: (column) => column);

  GeneratedColumn<int> get extHiCnt =>
      $composableBuilder(column: $table.extHiCnt, builder: (column) => column);

  GeneratedColumn<int> get extLoCnt =>
      $composableBuilder(column: $table.extLoCnt, builder: (column) => column);

  GeneratedColumn<int> get tirCnt =>
      $composableBuilder(column: $table.tirCnt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get createTime =>
      $composableBuilder(
        column: $table.createTime,
        builder: (column) => column,
      );
}

class $$UserlocalCollectionDaycntTableTableManager
    extends
        RootTableManager<
          _$CgmDatabase,
          $UserlocalCollectionDaycntTable,
          UserlocalCollectionDaycntRow,
          $$UserlocalCollectionDaycntTableFilterComposer,
          $$UserlocalCollectionDaycntTableOrderingComposer,
          $$UserlocalCollectionDaycntTableAnnotationComposer,
          $$UserlocalCollectionDaycntTableCreateCompanionBuilder,
          $$UserlocalCollectionDaycntTableUpdateCompanionBuilder,
          (
            UserlocalCollectionDaycntRow,
            BaseReferences<
              _$CgmDatabase,
              $UserlocalCollectionDaycntTable,
              UserlocalCollectionDaycntRow
            >,
          ),
          UserlocalCollectionDaycntRow,
          PrefetchHooks Function()
        > {
  $$UserlocalCollectionDaycntTableTableManager(
    _$CgmDatabase db,
    $UserlocalCollectionDaycntTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserlocalCollectionDaycntTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$UserlocalCollectionDaycntTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserlocalCollectionDaycntTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<DateTime?> day = const Value.absent(),
                Value<String?> isComplate = const Value.absent(),
                Value<int?> collectCnt = const Value.absent(),
                Value<int?> effCnt = const Value.absent(),
                Value<double?> glucoseTotalVal = const Value.absent(),
                Value<int?> hiCnt = const Value.absent(),
                Value<int?> lowCnt = const Value.absent(),
                Value<int?> extHiCnt = const Value.absent(),
                Value<int?> extLoCnt = const Value.absent(),
                Value<int?> tirCnt = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalCollectionDaycntCompanion(
                id: id,
                wearId: wearId,
                userId: userId,
                accountId: accountId,
                day: day,
                isComplate: isComplate,
                collectCnt: collectCnt,
                effCnt: effCnt,
                glucoseTotalVal: glucoseTotalVal,
                hiCnt: hiCnt,
                lowCnt: lowCnt,
                extHiCnt: extHiCnt,
                extLoCnt: extLoCnt,
                tirCnt: tirCnt,
                createTime: createTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wearId = const Value.absent(),
                Value<int?> userId = const Value.absent(),
                Value<int?> accountId = const Value.absent(),
                Value<DateTime?> day = const Value.absent(),
                Value<String?> isComplate = const Value.absent(),
                Value<int?> collectCnt = const Value.absent(),
                Value<int?> effCnt = const Value.absent(),
                Value<double?> glucoseTotalVal = const Value.absent(),
                Value<int?> hiCnt = const Value.absent(),
                Value<int?> lowCnt = const Value.absent(),
                Value<int?> extHiCnt = const Value.absent(),
                Value<int?> extLoCnt = const Value.absent(),
                Value<int?> tirCnt = const Value.absent(),
                Value<DateTime?> createTime = const Value.absent(),
              }) => UserlocalCollectionDaycntCompanion.insert(
                id: id,
                wearId: wearId,
                userId: userId,
                accountId: accountId,
                day: day,
                isComplate: isComplate,
                collectCnt: collectCnt,
                effCnt: effCnt,
                glucoseTotalVal: glucoseTotalVal,
                hiCnt: hiCnt,
                lowCnt: lowCnt,
                extHiCnt: extHiCnt,
                extLoCnt: extLoCnt,
                tirCnt: tirCnt,
                createTime: createTime,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserlocalCollectionDaycntTableProcessedTableManager =
    ProcessedTableManager<
      _$CgmDatabase,
      $UserlocalCollectionDaycntTable,
      UserlocalCollectionDaycntRow,
      $$UserlocalCollectionDaycntTableFilterComposer,
      $$UserlocalCollectionDaycntTableOrderingComposer,
      $$UserlocalCollectionDaycntTableAnnotationComposer,
      $$UserlocalCollectionDaycntTableCreateCompanionBuilder,
      $$UserlocalCollectionDaycntTableUpdateCompanionBuilder,
      (
        UserlocalCollectionDaycntRow,
        BaseReferences<
          _$CgmDatabase,
          $UserlocalCollectionDaycntTable,
          UserlocalCollectionDaycntRow
        >,
      ),
      UserlocalCollectionDaycntRow,
      PrefetchHooks Function()
    >;

class $CgmDatabaseManager {
  final _$CgmDatabase _db;
  $CgmDatabaseManager(this._db);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$BleFrameBufferTableTableManager get bleFrameBuffer =>
      $$BleFrameBufferTableTableManager(_db, _db.bleFrameBuffer);
  $$AppDeviceBindTableTableManager get appDeviceBind =>
      $$AppDeviceBindTableTableManager(_db, _db.appDeviceBind);
  $$UserWearCurTableTableManager get userWearCur =>
      $$UserWearCurTableTableManager(_db, _db.userWearCur);
  $$UserWearStatusLogTableTableManager get userWearStatusLog =>
      $$UserWearStatusLogTableTableManager(_db, _db.userWearStatusLog);
  $$UserlocalGlucoseDataTableTableManager get userlocalGlucoseData =>
      $$UserlocalGlucoseDataTableTableManager(_db, _db.userlocalGlucoseData);
  $$UserlocalGlucoseRawDataTableTableManager get userlocalGlucoseRawData =>
      $$UserlocalGlucoseRawDataTableTableManager(
        _db,
        _db.userlocalGlucoseRawData,
      );
  $$UserlocalGlucoseModifiedLogTableTableManager
  get userlocalGlucoseModifiedLog =>
      $$UserlocalGlucoseModifiedLogTableTableManager(
        _db,
        _db.userlocalGlucoseModifiedLog,
      );
  $$UserlocalWearErrorLogTableTableManager get userlocalWearErrorLog =>
      $$UserlocalWearErrorLogTableTableManager(_db, _db.userlocalWearErrorLog);
  $$UserlocalCollectionDaycntTableTableManager get userlocalCollectionDaycnt =>
      $$UserlocalCollectionDaycntTableTableManager(
        _db,
        _db.userlocalCollectionDaycnt,
      );
}
