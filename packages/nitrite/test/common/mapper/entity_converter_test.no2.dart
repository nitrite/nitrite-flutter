// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_converter_test.dart';

// **************************************************************************
// ConverterGenerator
// **************************************************************************

class _AConverter extends EntityConverter<_A> {
  @override
  _A fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var entity = _A();
    entity.l = toList(document['l'], nitriteMapper);
    entity.s = toSet(document['s'], nitriteMapper);
    entity.m = toMap(document['m'], nitriteMapper);
    entity.ms = toMap(document['ms'], nitriteMapper);
    entity.ls = toList(document['ls'], nitriteMapper);
    return entity;
  }

  @override
  Document toDocument(
    _A entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('l', fromList(entity.l, nitriteMapper));
    document.put('s', fromSet(entity.s, nitriteMapper));
    document.put('m', fromMap(entity.m, nitriteMapper));
    document.put('ms', fromMap(entity.ms, nitriteMapper));
    document.put('ls', fromList(entity.ls, nitriteMapper));
    return document;
  }
}

class _BConverter extends EntityConverter<_B> {
  @override
  _B fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var entity = _B();
    entity.s = document['s'];
    return entity;
  }

  @override
  Document toDocument(
    _B entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('s', entity.s);
    return document;
  }
}

class _CConverter extends EntityConverter<_C> {
  @override
  _C fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var entity = _C();
    entity.i = document['i'];
    return entity;
  }

  @override
  Document toDocument(
    _C entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('i', entity.i);
    return document;
  }
}

class _KConverter extends EntityConverter<_K> {
  @override
  _K fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var entity = _K();
    entity.d = document['d'];
    return entity;
  }

  @override
  Document toDocument(
    _K entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('d', entity.d);
    return document;
  }
}

class _VConverter extends EntityConverter<_V> {
  @override
  _V fromDocument(
    Document document,
    NitriteMapper nitriteMapper,
  ) {
    var entity = _V();
    entity.s = document['s'];
    return entity;
  }

  @override
  Document toDocument(
    _V entity,
    NitriteMapper nitriteMapper,
  ) {
    var document = emptyDocument();
    document.put('s', entity.s);
    return document;
  }
}
