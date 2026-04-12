import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no new manual odd/even row logic in app/features layer', () {
    final root = Directory.current;
    final libRoot = Directory('${root.path}/lib');
    final targets = <Directory>[
      Directory('${libRoot.path}/app'),
      Directory('${libRoot.path}/features'),
    ];

    final parityPattern = RegExp(r'\.isEven\b|\.isOdd\b');
    final baseline = _readBaseline(root);

    final found = <String, int>{};

    for (final directory in targets) {
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relativePath = _toRelativePath(root.path, entity.path);
        final source = entity.readAsStringSync();
        final parityCount = parityPattern.allMatches(source).length;
        if (parityCount == 0) continue;
        found[relativePath] = parityCount;
      }
    }

    final violations = <String>[];

    for (final entry in found.entries) {
      final expected = baseline[entry.key];
      final actual = entry.value;
      if (expected == null) {
        violations.add(
          '${entry.key}: new odd/even logic usage (parityCount=$actual)',
        );
        continue;
      }
      if (actual > expected) {
        violations.add(
          '${entry.key}: baseline exceeded (parityCount $actual/$expected)',
        );
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use AppAlternatingRow for zebra rows instead of manual '
          'odd/even checks in app/features.\n'
          '${violations.join('\n')}',
    );
  });
}

Map<String, int> _readBaseline(Directory repoRoot) {
  final file = File(
    '${repoRoot.path}/test/lints/baselines/manual_alternating_rows_baseline.txt',
  );
  if (!file.existsSync()) {
    fail(
      'Missing baseline file: '
      'test/lints/baselines/manual_alternating_rows_baseline.txt',
    );
  }

  final baseline = <String, int>{};
  final lines = file.readAsLinesSync();

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final parts = line.split('|');
    if (parts.length != 2) {
      fail('Invalid baseline line: $line');
    }

    final path = parts[0].trim();
    final parityCount = _parseCount(parts[1], 'parityCount');
    baseline[path] = parityCount;
  }

  return baseline;
}

int _parseCount(String entry, String key) {
  final expectedPrefix = '$key=';
  if (!entry.startsWith(expectedPrefix)) {
    fail('Invalid baseline entry "$entry", expected "$expectedPrefix..."');
  }
  return int.parse(entry.substring(expectedPrefix.length).trim());
}

String _toRelativePath(String rootPath, String absolutePath) {
  final normalizedRoot = rootPath.replaceAll('\\', '/');
  final normalizedAbsolute = absolutePath.replaceAll('\\', '/');
  final prefix = normalizedRoot.endsWith('/')
      ? normalizedRoot
      : '$normalizedRoot/';
  return normalizedAbsolute.startsWith(prefix)
      ? normalizedAbsolute.substring(prefix.length)
      : normalizedAbsolute;
}
