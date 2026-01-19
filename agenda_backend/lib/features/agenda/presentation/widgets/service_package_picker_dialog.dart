import 'package:flutter/material.dart';

import '../../../../core/l10n/l10_extension.dart';
import '../../../../core/models/service_package.dart';

Future<ServicePackage?> showServicePackagePickerDialog(
  BuildContext context, {
  required List<ServicePackage> packages,
}) {
  return showDialog<ServicePackage>(
    context: context,
    builder: (ctx) => _ServicePackagePickerDialog(packages: packages),
  );
}

class _ServicePackagePickerDialog extends StatelessWidget {
  const _ServicePackagePickerDialog({required this.packages});

  final List<ServicePackage> packages;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.servicePackagesTitle),
      content: SizedBox(
        width: 420,
        child: packages.isEmpty
            ? Text(l10n.servicePackagesEmptyState)
            : ListView.separated(
                shrinkWrap: true,
                itemCount: packages.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final pkg = packages[index];
                  final disabled = !pkg.isActive || pkg.isBroken;
                  final subtitleParts = <String>[
                    '${pkg.serviceCount} ${l10n.servicesLabel}',
                    '${pkg.effectiveDurationMinutes} ${l10n.minutesLabel}',
                  ];
                  return ListTile(
                    enabled: !disabled,
                    title: Text(pkg.name),
                    subtitle: Text(subtitleParts.join(' · ')),
                    trailing: disabled
                        ? Icon(
                            pkg.isBroken
                                ? Icons.warning_amber_rounded
                                : Icons.block,
                            color: Theme.of(context).colorScheme.error,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: disabled
                        ? null
                        : () => Navigator.of(context).pop(pkg),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  }
}
