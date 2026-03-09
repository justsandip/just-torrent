import 'dart:convert';

import 'package:just_torrent/src/core/core.dart';
import 'package:test/test.dart';

void main() {
  group('BencodeDecoder', () {
    late BencodeDecoder bencodeDecoder;

    setUp(() {
      bencodeDecoder = BencodeDecoder();
    });

    test('decode integer', () {
      final result = bencodeDecoder.decode(utf8.encode('i42e'));
      expect(result, 42);
    });

    test('decode string', () {
      final result = bencodeDecoder.decode(utf8.encode('4:spam'));
      expect(utf8.decode(result as List<int>), 'spam');
    });

    test('decode list', () {
      final result = bencodeDecoder.decode(utf8.encode('l4:spam4:eggse'));
      expect(utf8.decode((result as List<dynamic>)[0] as List<int>), 'spam');
      expect(utf8.decode(result[1] as List<int>), 'eggs');
    });

    test('decode dictionary', () {
      final result = bencodeDecoder.decode(
        utf8.encode('d3:cow3:moo4:spam4:eggse'),
      );
      expect(
        utf8.decode((result as Map<String, dynamic>)['cow'] as List<int>),
        'moo',
      );
    });

    test('throws on invalid bencode', () {
      expect(
        () => bencodeDecoder.decode(utf8.encode('i42')),
        throwsException,
      );
    });
  });
}
