import 'dart:io';

import 'package:just_torrent/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('download', () {
    late Logger logger;
    late JustTorrentCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      commandRunner = JustTorrentCommandRunner(logger: logger);
    });

    test('fails when no torrent file is provided', () async {
      final exitCode = await commandRunner.run(['download']);
      expect(exitCode, ExitCode.usage.code);
      verify(() => logger.err('A .torrent file must be provided.')).called(1);
    });

    test('logs torrent file and output directory', () async {
      final file = File('test/sample.torrent');

      // minimal valid bencode
      await file.writeAsBytes('d3:cow3:moo4:spam4:eggse'.codeUnits);

      final exitCode = await commandRunner.run([
        'download',
        file.path,
        '-o',
        'downloads'
      ]);

      expect(exitCode, ExitCode.success.code);

      verify(() => logger.info('Torrent file: ${file.path}')).called(1);
      verify(() => logger.info('Output directory: downloads')).called(1);

      file.deleteSync();
    });

    test('uses default output directory when not provided', () async {
      final file = File('test/sample.torrent');
      await file.writeAsBytes('d3:cow3:moo4:spam4:eggse'.codeUnits);

      final exitCode = await commandRunner.run([
        'download',
        file.path,
      ]);

      expect(exitCode, ExitCode.success.code);

      verify(() => logger.info('Torrent file: ${file.path}')).called(1);
      verify(() => logger.info('Output directory: .')).called(1);

      file.deleteSync();
    });
  });
}
