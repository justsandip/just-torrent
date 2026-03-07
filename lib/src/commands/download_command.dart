import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/command_runner.dart';
import 'package:just_torrent/src/core/core.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template download_command}
///
/// `just_torrent download`
///
/// A [Command] to download content from the BitTorrent network using
/// a .torrent file.
/// {@endtemplate}
class DownloadCommand extends Command<int> {
  /// {@macro download_command}
  DownloadCommand({required Logger logger}) : _logger = logger {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Directory where downloaded files will be saved.',
      valueHelp: 'directory',
      defaultsTo: '.',
    );
  }

  @override
  String get description =>
      'Download content from the BitTorrent '
      'network using a .torrent file.';

  @override
  String get name => 'download';

  final Logger _logger;

  @override
  Future<int> run() async {
    final args = argResults!;

    if (args.rest.isEmpty) {
      _logger.err('A .torrent file must be provided.');
      return 1;
    }

    final torrentFile = args.rest.first;
    final outputDir = args['output'] as String;

    _logger
      ..info('Torrent file: $torrentFile')
      ..info('Output directory: $outputDir');

    final file = File(torrentFile);
    final bytes = file.readAsBytesSync();

    final decoder = BencodeDecoder();
    final result = decoder.decode(bytes);

    debugPrintBencode(result);
    return ExitCode.success.code;
  }

  void debugPrintBencode(dynamic value, [int indent = 0]) {
    final space = ' ' * indent;

    if (value is Map) {
      for (final entry in value.entries) {
        _logger.write('$space${entry.key}:\n');
        debugPrintBencode(entry.value, indent + 2);
      }
    } else if (value is List && value.isNotEmpty && value.first is int) {
      final bytes = Uint8List.fromList(value.cast<int>());
      try {
        _logger.write('$space${utf8.decode(bytes)}\n');
      } on FormatException catch (_) {
        _logger.write('$space<binary ${bytes.length} bytes>\n');
      }
    } else if (value is List) {
      for (final v in value) {
        debugPrintBencode(v, indent + 2);
      }
    } else if (value is Uint8List) {
      try {
        _logger.write('$space${utf8.decode(value)}\n');
      } on FormatException catch (_) {
        _logger.write('$space<binary ${value.length} bytes>\n');
      }
    } else {
      _logger.write('$space$value\n');
    }
  }
}
