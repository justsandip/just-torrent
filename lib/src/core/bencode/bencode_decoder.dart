import 'dart:convert';
import 'dart:typed_data';

/// Bencode control bytes used by the BitTorrent protocol.
const integerStart = 0x69; // 'i'
const stringDelimiter = 0x3A; // ':'
const dictionaryStart = 0x64; // 'd'
const listStart = 0x6C; // 'l'
const endOfType = 0x65; // 'e'

/// A minimal Bencode decoder used to parse `.torrent` files.
///
/// Bencode supports four types:
/// - Integer: `i<number>e`
/// - String: `<length>:<data>`
/// - List: `l<item1><item2>e`
/// - Dictionary: `d<key><value>e`
class BencodeDecoder {
  /// Raw byte data being decoded.
  late Uint8List data;

  /// Current reading position in [data].
  int position = 0;

  /// Total bytes available.
  int bytes = 0;

  /// Optional encoding used when decoding strings.
  String? encoding;

  /// Decodes bencoded [input] into Dart objects.
  ///
  /// Returns a combination of:
  /// - `int`
  /// - `Uint8List`
  /// - `List`
  /// - `Map<String, dynamic>`
  dynamic decode(dynamic input, {int? start, int? end, String? encoding}) {
    if (input == null) return null;
    this.encoding = encoding;

    if (input is String) {
      data = Uint8List.fromList(utf8.encode(input));
    } else if (input is Uint8List) {
      data = input.sublist(start ?? 0, end ?? input.length);
    } else {
      throw ArgumentError('Unsupported input type');
    }

    bytes = data.length;
    position = 0;

    if (bytes == 0) return null;
    return next();
  }

  /// Reads the next bencoded value.
  dynamic next() {
    switch (data[position]) {
      case dictionaryStart:
        return dictionary();
      case listStart:
        return list();
      case integerStart:
        return integer();
      default:
        return buffer();
    }
  }

  /// Finds the next occurrence of [chr] starting from the current position.
  int find(int chr) {
    var i = position;

    while (i < data.length) {
      if (data[i] == chr) return i;
      i++;
    }

    throw Exception(
      'Invalid data: Missing delimiter "${String.fromCharCode(chr)}"'
      ' [0x${chr.toRadixString(16)}]',
    );
  }

  /// Decodes a bencoded dictionary.
  Map<String, dynamic> dictionary() {
    position++;
    final dict = <String, dynamic>{};

    while (data[position] != endOfType) {
      final bufferBytes = buffer();
      final key = utf8.decode(bufferBytes, allowMalformed: true);
      dict[key] = next();
    }

    position++;
    return dict;
  }

  /// Decodes a bencoded list.
  List<dynamic> list() {
    position++;
    final list = <dynamic>[];

    while (data[position] != endOfType) {
      list.add(next());
    }

    position++;
    return list;
  }

  /// Decodes a bencoded integer (`i123e`).
  int integer() {
    final end = find(endOfType);
    final number = getIntFromBuffer(data, position + 1, end);
    position = end + 1;
    return number;
  }

  /// Decodes a bencoded byte string (`4:spam`).
  Uint8List buffer() {
    final sep = find(stringDelimiter);
    final length = getIntFromBuffer(data, position, sep);

    final start = sep + 1;
    final end = start + length;

    final result = data.sublist(start, end);
    position = end;

    if (encoding != null) {
      return Uint8List.fromList(utf8.encode(utf8.decode(result)));
    }

    return result;
  }
}

/// Parses an integer directly from a byte buffer.
///
/// This avoids converting the buffer to a string for better performance.
int getIntFromBuffer(Uint8List buffer, int start, int end) {
  var sum = 0;
  var sign = 1;

  for (var i = start; i < end; i++) {
    final num = buffer[i];

    if (num < 58 && num >= 48) {
      sum = sum * 10 + (num - 48);
      continue;
    }

    if (i == start && num == 43) {
      continue;
    }

    if (i == start && num == 45) {
      sign = -1;
      continue;
    }

    if (num == 46) {
      break;
    }

    throw Exception('not a number: buffer[$i] = $num');
  }

  return sum * sign;
}
