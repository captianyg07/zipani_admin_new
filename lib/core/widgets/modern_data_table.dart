import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';
import 'app_card.dart';

/// A column spec for [ModernDataTable]. [flex] sizes the column; [fixed] gives
/// it a fixed width instead.
class TableColumn {
  const TableColumn(this.label, {this.flex = 1, this.fixed, this.align});
  final String label;
  final int flex;
  final double? fixed;
  final TextAlign? align;
}

/// A modern SaaS table: sticky header row, divider rows, hover, optional
/// row tap. Rows are built by the caller as [TableRowData] (cells = widgets),
/// so it stays generic and binds to any state.
class ModernDataTable extends StatelessWidget {
  const ModernDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.footer,
  });

  final List<TableColumn> columns;
  final List<TableRowData> rows;
  final void Function(int index)? onRowTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DS.s20, vertical: DS.s16),
            decoration: const BoxDecoration(
              color: DS.canvasAlt,
              border: Border(bottom: BorderSide(color: DS.line)),
            ),
            child: Row(children: _cells(columns.map((c) {
              return Text(c.label.toUpperCase(),
                  textAlign: c.align ?? TextAlign.left,
                  style: AppType.tableHead);
            }).toList())),
          ),
          // Rows
          for (var i = 0; i < rows.length; i++)
            _Row(
              data: rows[i],
              columns: columns,
              isLast: i == rows.length - 1,
              onTap: onRowTap == null ? null : () => onRowTap!(i),
            ),
          if (footer != null) ...[
            const Divider(height: 1, color: DS.line),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DS.s20, vertical: DS.s12),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _cells(List<Widget> children) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      final col = columns[i];
      final cell = col.fixed != null
          ? SizedBox(width: col.fixed, child: children[i])
          : Expanded(flex: col.flex, child: children[i]);
      out.add(cell);
      if (i < children.length - 1) out.add(const SizedBox(width: DS.s12));
    }
    return out;
  }
}

class TableRowData {
  const TableRowData({required this.cells});
  final List<Widget> cells;
}

class _Row extends StatefulWidget {
  const _Row({
    required this.data,
    required this.columns,
    required this.isLast,
    this.onTap,
  });

  final TableRowData data;
  final List<TableColumn> columns;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < widget.data.cells.length; i++) {
      final col = widget.columns[i];
      final cell = col.fixed != null
          ? SizedBox(width: col.fixed, child: widget.data.cells[i])
          : Expanded(flex: col.flex, child: widget.data.cells[i]);
      cells.add(cell);
      if (i < widget.data.cells.length - 1) {
        cells.add(const SizedBox(width: DS.s12));
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DS.s20, vertical: DS.s16),
          decoration: BoxDecoration(
            color: _hover ? DS.canvasAlt : DS.surface,
            border: widget.isLast
                ? null
                : const Border(bottom: BorderSide(color: DS.line)),
          ),
          child: Row(children: cells),
        ),
      ),
    );
  }
}
