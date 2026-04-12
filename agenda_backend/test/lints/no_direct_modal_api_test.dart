import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'no new direct showDialog/showModalBottomSheet usage in app/features layer',
    () {
      final root = Directory.current;
      final libRoot = Directory('${root.path}/lib');
      final targets = <Directory>[
        Directory('${libRoot.path}/app'),
        Directory('${libRoot.path}/features'),
      ];

      final showDialogPattern = RegExp(
        r'(?<![\w$])showDialog\s*(?:<[^>]+>)?\s*\(',
      );
      final showModalPattern = RegExp(
        r'(?<![\w$])showModalBottomSheet\s*(?:<[^>]+>)?\s*\(',
      );
      final baseline = _readBaseline(root);

      final found = <String, ({int showDialog, int showModalBottomSheet})>{};

      for (final directory in targets) {
        for (final entity in directory.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final relativePath = _toRelativePath(root.path, entity.path);
          final source = entity.readAsStringSync();
          final showDialogCount = showDialogPattern.allMatches(source).length;
          final showModalCount = showModalPattern.allMatches(source).length;
          if (showDialogCount == 0 && showModalCount == 0) continue;
          found[relativePath] = (
            showDialog: showDialogCount,
            showModalBottomSheet: showModalCount,
          );
        }
      }

      final violations = <String>[];

      for (final entry in found.entries) {
        final expected = baseline[entry.key];
        final actual = entry.value;
        if (expected == null) {
          violations.add(
            '${entry.key}: new direct modal usage '
            '(showDialog=${actual.showDialog}, '
            'showModalBottomSheet=${actual.showModalBottomSheet})',
          );
          continue;
        }
        if (actual.showDialog > expected.showDialog ||
            actual.showModalBottomSheet > expected.showModalBottomSheet) {
          violations.add(
            '${entry.key}: baseline exceeded '
            '(showDialog ${actual.showDialog}/${expected.showDialog}, '
            'showModalBottomSheet '
            '${actual.showModalBottomSheet}/${expected.showModalBottomSheet})',
          );
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Use AppForm.show / AppBottomSheet.show wrappers instead of '
            'direct showDialog/showModalBottomSheet in app/features.\n'
            '${violations.join('\n')}',
      );
    },
  );
}

Map<String, ({int showDialog, int showModalBottomSheet})> _readBaseline(
  Directory repoRoot,
) {
  final file = File(
    '${repoRoot.path}/test/lints/baselines/direct_modal_usage_baseline.txt',
  );
  if (!file.existsSync()) {
    fail(
      'Missing baseline file: '
      'test/lints/baselines/direct_modal_usage_baseline.txt',
    );
  }

  final baseline = <String, ({int showDialog, int showModalBottomSheet})>{};
  final lines = file.readAsLinesSync();

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    final parts = line.split('|');
    if (parts.length != 3) {
      fail('Invalid baseline line: $line');
    }

    final path = parts[0].trim();
    final showDialog = _parseCount(parts[1], 'showDialog');
    final showModal = _parseCount(parts[2], 'showModalBottomSheet');

    baseline[path] = (
      showDialog: showDialog,
      showModalBottomSheet: showModal,
    );
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
