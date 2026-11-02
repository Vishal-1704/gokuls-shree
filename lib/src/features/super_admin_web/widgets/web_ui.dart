// Desktop building blocks for the super-admin web console. Mobile screens
// never use these — web and mobile share data/logic, not layouts.
import 'package:flutter/material.dart';
import 'package:gokul_shree_app/src/core/theme/app_colors.dart';
import 'package:gokul_shree_app/src/core/theme/app_typography.dart';

// ─── Formatting helpers ─────────────────────────────────────────────────────

String str(dynamic v, [String fallback = '—']) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty || s == 'null' ? fallback : s;
}

String initialsOf(dynamic name) {
  final parts = str(name, '').split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Indian digit grouping: 1234567 → ₹12,34,567
String inr(num? value) {
  final n = (value ?? 0).round();
  final neg = n < 0;
  final digits = n.abs().toString();
  String out;
  if (digits.length <= 3) {
    out = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (rest.length > 2) {
      groups.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) groups.insert(0, rest);
    out = '${groups.join(',')},$last3';
  }
  return '${neg ? '-' : ''}₹$out';
}

String shortDate(dynamic v) {
  final d = DateTime.tryParse(str(v, ''));
  if (d == null) return str(v);
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day.toString().padLeft(2, '0')} ${m[d.month - 1]} ${d.year}';
}

// ─── Feedback ───────────────────────────────────────────────────────────────

void showToast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 440,
        backgroundColor: error ? AppColors.danger : AppColors.textPrimary,
        content: Row(
          children: [
            Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppTypography.bodyMd.copyWith(color: Colors.white))),
          ],
        ),
      ),
    );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool danger = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: AppTypography.headingMd),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? AppColors.danger : AppColors.goldDeep),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}

// ─── Page scaffolding ───────────────────────────────────────────────────────

/// Page header (title, subtitle, actions) above a body. When [fill] is true
/// the body gets the remaining height (for table + detail panel pages);
/// otherwise the whole page scrolls.
class WebPage extends StatelessWidget {
  const WebPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.fill = false,
    this.maxWidth = 1440,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool fill;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.displaySm),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
        for (final a in actions) ...[const SizedBox(width: 10), a],
      ],
    );

    final content = fill
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, const SizedBox(height: 20), Expanded(child: child)],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [header, const SizedBox(height: 20), child],
          );

    final framed = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: const EdgeInsets.fromLTRB(28, 24, 28, 24), child: content),
      ),
    );

    return fill ? framed : SingleChildScrollView(child: framed);
  }
}

/// White bordered surface. Not every block needs one — use for grouped content.
class WebPanel extends StatelessWidget {
  const WebPanel({super.key, required this.child, this.title, this.trailing, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(child: Text(title!, style: AppTypography.headingSm)),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon, this.color = AppColors.goldDeep, this.hint, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.textMuted, letterSpacing: 0.3)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.headingLg.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hint != null)
                      Text(hint!, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, this.color, {super.key});

  final String label;
  final Color color;

  static StatusChip forStudent(dynamic status) {
    switch (status) {
      case 1:
        return const StatusChip('Active', AppColors.success);
      case 0:
        return const StatusChip('Pending', AppColors.warning);
      default:
        return const StatusChip('Inactive', AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelSm.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.size = 32, this.image});

  final dynamic name;
  final double size;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.goldCta.withValues(alpha: 0.12),
      backgroundImage: image,
      onBackgroundImageError: image != null ? (_, __) {} : null,
      child: image == null
          ? Text(initialsOf(name), style: AppTypography.labelMd.copyWith(color: AppColors.goldDeep, fontSize: size * 0.36))
          : null,
    );
  }
}

// ─── Toolbar controls ───────────────────────────────────────────────────────

class WebSearchField extends StatelessWidget {
  const WebSearchField({super.key, required this.hint, required this.onChanged, this.width = 300});

  final String hint;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        onChanged: onChanged,
        style: AppTypography.bodyMd,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.goldCta)),
        ),
      ),
    );
  }
}

class WebDropdown<T> extends StatelessWidget {
  const WebDropdown({super.key, required this.value, required this.items, required this.onChanged, this.width = 190});

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    // Selected by position: DropdownButton treats a null value as "nothing
    // selected", which would hide an "All …" option keyed by null.
    final entries = items.entries.toList();
    final index = entries.indexWhere((e) => e.key == value);
    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: index < 0 ? 0 : index,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.goldCta),
          style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          dropdownColor: AppColors.surfaceCard,
          items: [
            for (var i = 0; i < entries.length; i++)
              DropdownMenuItem<int>(
                value: i,
                child: Text(
                  entries[i].value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
          ],
          onChanged: (i) {
            if (i != null) onChanged(entries[i].key);
          },
        ),
      ),
    );
  }
}

// ─── Data table ─────────────────────────────────────────────────────────────

class WebColumn {
  const WebColumn(this.label, {this.flex = 2, this.alignEnd = false});
  final String label;
  final int flex;
  final bool alignEnd;
}

/// Records table for desktop: sticky header, hoverable rows, optional
/// checkbox selection, a highlighted "open" row for the side inspector, and
/// client-side pagination. Needs a bounded height (put it in an Expanded).
class WebTable<T> extends StatefulWidget {
  const WebTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.cells,
    required this.keyOf,
    this.onRowTap,
    this.openKey,
    this.checked,
    this.onCheckedChanged,
    this.pageSize = 25,
    this.emptyTitle = 'Nothing here',
    this.emptyMessage = 'No records match the current filters.',
  });

  final List<WebColumn> columns;
  final List<T> rows;
  final List<Widget> Function(T row) cells;
  final Object Function(T row) keyOf;
  final ValueChanged<T>? onRowTap;
  final Object? openKey;
  final Set<Object>? checked;
  final ValueChanged<Set<Object>>? onCheckedChanged;
  final int pageSize;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<WebTable<T>> createState() => _WebTableState<T>();
}

class _WebTableState<T> extends State<WebTable<T>> {
  int _page = 0;

  @override
  void didUpdateWidget(covariant WebTable<T> old) {
    super.didUpdateWidget(old);
    if (old.rows.length != widget.rows.length) _page = 0;
  }

  bool get _selectable => widget.checked != null && widget.onCheckedChanged != null;

  @override
  Widget build(BuildContext context) {
    final total = widget.rows.length;
    final pages = total == 0 ? 1 : ((total - 1) ~/ widget.pageSize) + 1;
    final page = _page.clamp(0, pages - 1);
    final start = page * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, total);
    final visible = widget.rows.sublist(start, end);
    final checked = widget.checked ?? const <Object>{};
    final allChecked = total > 0 && widget.rows.every((r) => checked.contains(widget.keyOf(r)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.surfaceElevated,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (_selectable)
                  SizedBox(
                    width: 36,
                    child: Checkbox(
                      value: allChecked,
                      visualDensity: VisualDensity.compact,
                      onChanged: total == 0
                          ? null
                          : (v) => widget.onCheckedChanged!(
                                v == true ? widget.rows.map(widget.keyOf).toSet() : <Object>{},
                              ),
                    ),
                  ),
                for (final c in widget.columns)
                  Expanded(
                    flex: c.flex,
                    child: Text(
                      c.label.toUpperCase(),
                      textAlign: c.alignEnd ? TextAlign.end : TextAlign.start,
                      style: AppTypography.labelSm.copyWith(color: AppColors.textMuted, letterSpacing: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: total == 0
                ? WebEmpty(icon: Icons.inbox_outlined, title: widget.emptyTitle, message: widget.emptyMessage)
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.inkNavy700),
                    itemBuilder: (context, i) {
                      final row = visible[i];
                      final key = widget.keyOf(row);
                      final isOpen = key == widget.openKey;
                      final cells = widget.cells(row);
                      return Material(
                        color: isOpen ? AppColors.goldCta.withValues(alpha: 0.07) : Colors.transparent,
                        child: InkWell(
                          onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(row),
                          hoverColor: AppColors.inkNavy700,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(color: isOpen ? AppColors.goldCta : Colors.transparent, width: 3),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(13, 10, 16, 10),
                            constraints: const BoxConstraints(minHeight: 56),
                            child: Row(
                              children: [
                                if (_selectable)
                                  SizedBox(
                                    width: 36,
                                    child: Checkbox(
                                      value: checked.contains(key),
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (v) {
                                        final next = {...checked};
                                        v == true ? next.add(key) : next.remove(key);
                                        widget.onCheckedChanged!(next);
                                      },
                                    ),
                                  ),
                                for (var c = 0; c < widget.columns.length; c++)
                                  Expanded(
                                    flex: widget.columns[c].flex,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Align(
                                        alignment: widget.columns[c].alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                                        child: c < cells.length ? cells[c] : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (total > widget.pageSize) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text('${start + 1}–$end of $total', style: AppTypography.bodySm),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Previous page',
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: page == 0 ? null : () => setState(() => _page = page - 1),
                  ),
                  Text('${page + 1} / $pages', style: AppTypography.bodySm),
                  IconButton(
                    tooltip: 'Next page',
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: page >= pages - 1 ? null : () => setState(() => _page = page + 1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Two-line cell: bold primary + muted secondary (e.g. name / reg no).
class CellText extends StatelessWidget {
  const CellText(this.primary, {super.key, this.secondary, this.leading});

  final String primary;
  final String? secondary;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(primary, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (secondary != null)
          Text(secondary!, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
    if (leading == null) return text;
    return Row(children: [leading!, const SizedBox(width: 10), Flexible(child: text)]);
  }
}

class PlainCell extends StatelessWidget {
  const PlainCell(this.text, {super.key, this.muted = false, this.alignEnd = false});
  final String text;
  final bool muted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: AppTypography.bodyMd.copyWith(
          color: muted ? AppColors.textMuted : AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

// ─── Detail (inspector) panel ───────────────────────────────────────────────

class DetailPanel extends StatelessWidget {
  const DetailPanel({super.key, required this.header, required this.children, this.actions = const [], this.onClose});

  final Widget header;
  final List<Widget> children;
  final List<Widget> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: header),
                if (onClose != null)
                  IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded, size: 18), onPressed: onClose),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 16), children: children),
          ),
          if (actions.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: actions),
            ),
          ],
        ],
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  const DetailSection(this.title, this.rows, {super.key});
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: AppTypography.labelSm.copyWith(color: AppColors.textMuted, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: Text(label, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted))),
                  Expanded(child: SelectableText(value, style: AppTypography.bodyMd)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class NoSelection extends StatelessWidget {
  const NoSelection({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: WebEmpty(icon: Icons.touch_app_outlined, title: 'No record selected', message: message),
    );
  }
}

class WebEmpty extends StatelessWidget {
  const WebEmpty({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.inkNavy500),
            const SizedBox(height: 12),
            Text(title, style: AppTypography.headingSm),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class WebError extends StatelessWidget {
  const WebError(this.error, {super.key, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('Could not load data', style: AppTypography.headingSm),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SelectableText('$error', textAlign: TextAlign.center, style: AppTypography.bodySm),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

const webLoading = Center(child: CircularProgressIndicator(color: AppColors.goldCta, strokeWidth: 2.5));

/// Primary / secondary buttons sized for desktop toolbars.
ButtonStyle webPrimaryButton([Color color = AppColors.goldDeep]) => FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: AppTypography.labelLg,
    );

ButtonStyle webSecondaryButton([Color color = AppColors.textPrimary]) => OutlinedButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      side: const BorderSide(color: AppColors.divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: AppTypography.labelLg,
    );

// ─── Charts ─────────────────────────────────────────────────────────────────

/// Ranked horizontal bar chart: rank badge, label, bar on a shared scale,
/// value at the end. Replaces the earlier stacked progress-bar list — same
/// data shape (label/value/max), a proper chart layout instead.
class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({super.key, required this.items});

  /// (label, value) pairs, already sorted highest first.
  final List<(String, double)> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('No fee payments recorded yet.', style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted));
    }
    final max = items.map((e) => e.$2).fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) _RevenueBarRow(rank: i + 1, label: items[i].$1, value: items[i].$2, max: max),
      ],
    );
  }
}

class _RevenueBarRow extends StatelessWidget {
  const _RevenueBarRow({required this.rank, required this.label, required this.value, required this.max});
  final int rank;
  final String label;
  final double value;
  final double max;

  @override
  Widget build(BuildContext context) {
    final isTop = rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isTop ? AppColors.goldCta.withValues(alpha: 0.15) : AppColors.inkNavy700,
              shape: BoxShape.circle,
            ),
            child: Text('$rank', style: AppTypography.labelSm.copyWith(color: isTop ? AppColors.goldDeep : AppColors.textMuted)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(label, style: AppTypography.bodyMd, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 18, decoration: BoxDecoration(color: AppColors.inkNavy700, borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: max == 0 ? 0 : (value / max).clamp(0.02, 1.0),
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: isTop ? AppColors.goldCta : AppColors.goldDeep,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text(
              inr(value),
              textAlign: TextAlign.right,
              style: AppTypography.labelMd.copyWith(color: AppColors.goldDeep, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ],
      ),
    );
  }
}
