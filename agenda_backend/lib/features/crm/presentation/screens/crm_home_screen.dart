import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/form_factor_provider.dart';
import '../../../../core/l10n/l10_extension.dart';

class CrmHomeScreen extends ConsumerWidget {
  const CrmHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formFactor = ref.watch(formFactorProvider);
    final isDesktop = formFactor == AppFormFactor.desktop;

    final items = [
      _Entry(
        l10n.crmClientsTitle,
        l10n.crmClientsDescription,
        Icons.people_alt_outlined,
        '/altro/crm/clienti',
        const Color(0xFF009688),
      ),
      _Entry(
        l10n.crmSegmentsTitle,
        l10n.crmSegmentsDescription,
        Icons.filter_alt_outlined,
        '/altro/crm/segmenti',
        const Color(0xFF5C6BC0),
      ),
      _Entry(
        l10n.crmTasksTitle,
        l10n.crmTasksDescription,
        Icons.task_alt_outlined,
        '/altro/crm/task',
        const Color(0xFFEF6C00),
      ),
      _Entry(
        l10n.crmTagsTitle,
        l10n.crmTagsDescription,
        Icons.sell_outlined,
        '/altro/crm/tag',
        const Color(0xFF8E24AA),
      ),
      _Entry(
        l10n.crmImportExportTitle,
        l10n.crmImportExportDescription,
        Icons.import_export_outlined,
        '/altro/crm/import-export',
        const Color(0xFF546E7A),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.crmTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 20,
                isDesktop ? 20 : 14,
                isDesktop ? 32 : 20,
                isDesktop ? 20 : 14,
              ),
              child: Text(
                l10n.crmSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 4,
            ),
            sliver: isDesktop
                ? _buildGrid(context, items)
                : _buildList(items),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<_Entry> items) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1200 ? 4 : (width > 800 ? 3 : 2);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: columns >= 4 ? 1.12 : 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) => _CardDesktop(item: items[i]),
        childCount: items.length,
      ),
    );
  }

  Widget _buildList(List<_Entry> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => Padding(
          padding: EdgeInsets.only(bottom: i < items.length - 1 ? 12 : 0),
          child: _CardMobile(item: items[i]),
        ),
        childCount: items.length,
      ),
    );
  }
}

class _Entry {
  final String title, subtitle, path;
  final IconData icon;
  final Color color;

  const _Entry(this.title, this.subtitle, this.icon, this.path, this.color);
}

class _CardDesktop extends StatefulWidget {
  final _Entry item;

  const _CardDesktop({required this.item});

  @override
  State<_CardDesktop> createState() => _CardDesktopState();
}

class _CardDesktopState extends State<_CardDesktop> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_hovered ? 1.02 : 1.0),
        child: Card(
          elevation: _hovered ? 8 : 2,
          shadowColor: item.color.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _hovered
                  ? item.color.withOpacity(0.5)
                  : cs.outline.withOpacity(0.1),
              width: _hovered ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => context.go(item.path),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, size: 26, color: item.color),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: _hovered ? item.color : cs.outline.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardMobile extends StatelessWidget {
  final _Entry item;

  const _CardMobile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 1,
      shadowColor: item.color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => context.go(item.path),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 24, color: item.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: cs.outline.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
