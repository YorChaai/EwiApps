import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../utils/context_extensions.dart';
import '../../widgets/user_detail_dialog.dart';

String formatNumber(dynamic num) {
  if (num == null) return '0';
  final n = num is int ? num.toDouble() : (num as double);
  return n
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isMobile;
  final VoidCallback onTap;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.isMobile = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final borderColor = isDark ? AppTheme.divider : AppTheme.lightDivider;
    final textColor = isDark
        ? AppTheme.textSecondary
        : AppTheme.lightTextSecondary;

    // Responsive sizing
    final isCompact = isMobile || ResponsiveLayout.isCompactPhone(context);
    final horizontalPadding = isCompact ? 10.0 : 14.0;
    final verticalPadding = isCompact ? 6.0 : 8.0;
    final fontSize = isCompact ? 11.5 : 13.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppTheme.primary : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.primary : textColor,
          ),
        ),
      ),
    );
  }
}

class YearFilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool useCompact;
  final VoidCallback onTap;
  final Function(int) onYearChanged;
  final int selectedYear;
  final bool showModeIcon;

  const YearFilterButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.useCompact,
    required this.onTap,
    required this.onYearChanged,
    required this.selectedYear,
    this.showModeIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          isDark ? AppTheme.surface : Colors.white,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      ),
      builder: (context, controller, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
              onTap();
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isActive ? 1.0 : 0.7,
              child: Container(
                height: useCompact ? 36 : 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : (isDark ? AppTheme.card : AppTheme.lightCard),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primary
                        : (isDark ? AppTheme.divider : AppTheme.lightDivider),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showModeIcon) ...[
                      Icon(
                        label.contains('Laporan')
                            ? Icons.account_balance_rounded
                            : Icons.calendar_month_rounded,
                        size: 18,
                        color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isActive
                            ? AppTheme.primary
                            : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                        fontSize: useCompact ? 12 : 14,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 24,
                      color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () => onYearChanged(0),
          style: MenuItemButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Semua Tahun',
            style: TextStyle(
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              fontWeight: selectedYear == 0 ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
        ...List.generate(21, (i) => 2020 + i).map((y) {
          final isSelected = selectedYear == y;
          return MenuItemButton(
            onPressed: () => onYearChanged(y),
            style: MenuItemButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : null,
            ),
            child: Text(
              y.toString(),
              style: TextStyle(
                color: isSelected
                    ? AppTheme.primary
                    : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class CascadingYearFilter extends StatelessWidget {
  final String label;
  final int selectedYear;
  final String currentMode; // 'report', 'actual', 'range'
  final bool useCompact;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(int year, String mode) onSelected;
  final VoidCallback onRangeTap;

  const CascadingYearFilter({
    super.key,
    this.label = 'Periode Data',
    required this.selectedYear,
    required this.currentMode,
    required this.useCompact,
    this.startDate,
    this.endDate,
    required this.onSelected,
    required this.onRangeTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String displayLabel = label;
    if (currentMode == 'report') {
      displayLabel = 'Laporan $selectedYear';
    } else if (currentMode == 'actual') {
      displayLabel = 'Year $selectedYear';
    } else if (currentMode == 'range') {
      if (startDate != null && endDate != null) {
        String sDay = startDate!.day.toString().padLeft(2, '0');
        String sMonth = startDate!.month.toString().padLeft(2, '0');
        String sYear = startDate!.year.toString().substring(2);

        String eDay = endDate!.day.toString().padLeft(2, '0');
        String eMonth = endDate!.month.toString().padLeft(2, '0');
        String eYear = endDate!.year.toString().substring(2);

        displayLabel = '$sDay/$sMonth/$sYear - $eDay/$eMonth/$eYear';
      } else {
        displayLabel = 'Custom Range';
      }
    }
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(isDark ? AppTheme.surface : Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: const WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: useCompact ? 36 : 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.card : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppTheme.divider : AppTheme.lightDivider,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayLabel,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                      fontSize: useCompact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        SubmenuButton(
          menuChildren: _buildYearList(context, 'report'),
          style: MenuItemButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _MenuItemLabel(
            icon: Icons.account_balance_rounded,
            label: 'Laporan',
            isDark: isDark,
            showArrow: false, // Biar tidak double panah dengan SubmenuButton
          ),
        ),
        SubmenuButton(
          menuChildren: _buildYearList(context, 'actual'),
          style: MenuItemButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _MenuItemLabel(
            icon: Icons.calendar_month_rounded,
            label: 'Year',
            isDark: isDark,
            showArrow: false, // Biar tidak double panah dengan SubmenuButton
          ),
        ),
        MenuItemButton(
          onPressed: onRangeTap,
          style: MenuItemButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: _MenuItemLabel(
            icon: Icons.date_range_rounded,
            label: 'Range',
            isDark: isDark,
            showArrow: false,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildYearList(BuildContext context, String mode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Buat list item tahun (2020 - 2040)
    final yearItems = List.generate(21, (i) => 2020 + i).map((year) {
      final isSelected = selectedYear == year && currentMode == mode;
      return MenuItemButton(
        onPressed: () => onSelected(year, mode),
        style: MenuItemButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : null,
        ),
        child: SizedBox(
          width: 80, // Lebar kotak tahun agar rapi
          child: Text(
            year.toString(),
            style: TextStyle(
              color: isSelected
                  ? AppTheme.primary
                  : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      );
    }).toList();

    // 2. Bungkus dalam Container Scrollable dengan tinggi terbatas
    return [
      ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280), // Tinggi maksimal menu
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: yearItems,
          ),
        ),
      )
    ];
  }
}

// Dialog Range Picker Kustom dengan fitur Fast Jump (Tahun & Bulan)
class AppDateRangePicker {
  static Future<DateTimeRange?> show(
    BuildContext context, {
    DateTimeRange? initialRange,
  }) async {
    return await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _FastRangePickerDialog(initialRange: initialRange),
    );
  }
}

class _FastRangePickerDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _FastRangePickerDialog({this.initialRange});

  @override
  State<_FastRangePickerDialog> createState() => _FastRangePickerDialogState();
}

class _FastRangePickerDialogState extends State<_FastRangePickerDialog> {
  DateTime? _start;
  DateTime? _end;
  bool _pickingStart = true;

  // View states: 0 = Days, 1 = Months, 2 = Years
  int _viewMode = 0;
  late DateTime _viewDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _start = widget.initialRange!.start;
      _end = widget.initialRange!.end;
      _viewDate = _start!;
    } else {
      _viewDate = DateTime.now();
    }
  }

  void _onMonthSelected(int month) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, month, 1);
      _viewMode = 0; // Selesai pilih bulan, kembali ke hari
    });
  }

  void _onYearSelected(int year) {
    setState(() {
      _viewDate = DateTime(year, _viewDate.month, 1);
      _viewMode = 1; // Setelah pilih tahun, lanjut pilih bulan
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _start != null && _end != null;

    return Dialog(
      backgroundColor: isDark ? AppTheme.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Judul & Simpan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Rentang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: canSave
                      ? () => Navigator.pop(context, DateTimeRange(start: _start!, end: _end!))
                      : null,
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: canSave ? AppTheme.primary : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Mulai - Selesai
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.card : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabButton('Mulai', _start, _pickingStart, () {
                    setState(() {
                      _pickingStart = true;
                      if (_start != null) _viewDate = _start!;
                      _viewMode = 0;
                    });
                  }),
                  _buildTabButton('Selesai', _end, !_pickingStart, () {
                    setState(() {
                      _pickingStart = false;
                      if (_end != null) _viewDate = _end!;
                      _viewMode = 0;
                    });
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kalender Area
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildPickerContent(isDark),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerContent(bool isDark) {
    if (_viewMode == 0) {
      // MODE HARI (GRID KUSTOM)
      return Column(
        key: const ValueKey('day_view'),
        children: [
          _buildHeaderWithNav(isDark),
          const SizedBox(height: 8),
          _buildDayGrid(isDark),
        ],
      );
    } else if (_viewMode == 1) {
      // MODE BULAN
      return Column(
        key: const ValueKey('month_view'),
        children: [
          _buildHeader(() => setState(() => _viewMode = 2), _viewDate.year.toString(), isDark),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
              final isSelected = _viewDate.month == i + 1;
              return Center(
                child: TextButton(
                  onPressed: () => _onMonthSelected(i + 1),
                  style: TextButton.styleFrom(
                    backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : null,
                  ),
                  child: Text(months[i], style: TextStyle(
                    color: isSelected ? AppTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              );
            },
          ),
        ],
      );
    } else {
      // MODE TAHUN
      return Column(
        key: const ValueKey('year_view'),
        children: [
          _buildHeader(() => setState(() => _viewMode = 1), 'Pilih Tahun', isDark),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
              ),
              itemCount: 21,
              itemBuilder: (context, i) {
                final year = 2020 + i;
                final isSelected = _viewDate.year == year;
                return Center(
                  child: TextButton(
                    onPressed: () => _onYearSelected(year),
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : null,
                    ),
                    child: Text(year.toString(), style: TextStyle(
                      color: isSelected ? AppTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildHeaderWithNav(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => setState(() {
            _viewDate = DateTime(_viewDate.year, _viewDate.month - 1);
          }),
        ),
        _buildHeader(
          () => setState(() => _viewMode = 2),
          _viewDate.year.toString(),
          isDark
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => setState(() {
            _viewDate = DateTime(_viewDate.year, _viewDate.month + 1);
          }),
        ),
      ],
    );
  }

  Widget _buildDayGrid(bool isDark) {
    final daysInMonth = DateUtils.getDaysInMonth(_viewDate.year, _viewDate.month);
    final firstDayOffset = DateTime(_viewDate.year, _viewDate.month, 1).weekday % 7;
    final totalCells = daysInMonth + firstDayOffset;

    final weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Weekday labels
        Row(
          children: weekDays.map((d) => Expanded(
            child: Center(child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemCount: totalCells,
          itemBuilder: (context, i) {
            if (i < firstDayOffset) return const SizedBox();

            final day = i - firstDayOffset + 1;
            final date = DateTime(_viewDate.year, _viewDate.month, day);

            // Check if date is in range
            bool isStart = _start != null && DateUtils.isSameDay(date, _start!);
            bool isEnd = _end != null && DateUtils.isSameDay(date, _end!);
            bool isInRange = _start != null && _end != null && date.isAfter(_start!) && date.isBefore(_end!);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_pickingStart) {
                    _start = date;
                    if (_end != null && _start!.isAfter(_end!)) {
                      _end = null;
                    }
                    _pickingStart = false; // Auto switch ke selesai
                  } else {
                    _end = date;
                    if (_start != null && _end!.isBefore(_start!)) {
                      _start = _end;
                      _end = null;
                    }
                  }
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Range Fill Background (diperhalus)
                  if (isInRange || isStart || isEnd)
                    Container(
                      margin: EdgeInsets.only(
                        left: isStart ? 18 : 0,
                        right: isEnd ? 18 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.horizontal(
                          left: isStart ? const Radius.circular(20) : Radius.zero,
                          right: isEnd ? const Radius.circular(20) : Radius.zero,
                        ),
                      ),
                    ),

                  // Circle for start/end
                  if (isStart || isEnd)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  Text(
                    day.toString(),
                    style: TextStyle(
                      color: (isStart || isEnd)
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                      fontWeight: (isStart || isEnd) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(VoidCallback onTap, String label, bool isDark) {
    String subLabel = '';
    if (_viewMode == 0) subLabel = '${_getMonthName(_viewDate.month)} ';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$subLabel$label',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    return ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][month - 1];
  }

  Widget _buildTabButton(String label, DateTime? date, bool active, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white70 : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                ),
              ),
              Text(
                date != null ? "${date.day}/${date.month}/${date.year}" : "-- / -- / --",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool showArrow;

  const _MenuItemLabel({
    required this.icon,
    required this.label,
    required this.isDark,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, // Sedikit lebih lebar agar panah sejajar manis di kanan
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Icon(
            icon,
            size: 20, // Sedikit lebih besar agar ikon lebih tegas
            color: AppTheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500, // Medium weight agar lebih terbaca
              ),
            ),
          ),
          if (showArrow)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)
                    .withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class CascadingStatusFilter extends StatelessWidget {
  final String? selectedStatus;
  final bool useCompact;
  final Function(String?) onSelected;
  final bool isManager;

  const CascadingStatusFilter({
    super.key,
    required this.selectedStatus,
    required this.useCompact,
    required this.onSelected,
    this.isManager = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String displayLabel = 'Semua Status';
    if (selectedStatus != null) {
      displayLabel = selectedStatus![0].toUpperCase() + selectedStatus!.substring(1);
    }

    final statuses = [
      {'label': 'Semua Status', 'value': null, 'color': AppTheme.textSecondary},
      {'label': 'Draft', 'value': 'draft', 'color': AppTheme.textSecondary},
      {'label': 'Submitted', 'value': 'submitted', 'color': AppTheme.warning},
      {'label': 'Approved', 'value': 'approved', 'color': AppTheme.success},
      if (isManager) {'label': 'Rejected', 'value': 'rejected', 'color': AppTheme.danger},
    ];

    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(isDark ? AppTheme.surface : Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevation: const WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.isOpen ? controller.close() : controller.open(),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: useCompact ? 36 : 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.card : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppTheme.divider : AppTheme.lightDivider,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayLabel,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                      fontSize: useCompact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: statuses.map((status) {
        final isSelected = selectedStatus == status['value'];
        final color = status['color'] as Color;

        return MenuItemButton(
          onPressed: () => onSelected(status['value'] as String?),
          style: MenuItemButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: isSelected ? color.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                status['label'] as String,
                style: TextStyle(
                  color: isSelected ? color : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}



class SettlementCard extends StatefulWidget {
  final Map<String, dynamic> settlement;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isManager;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool canSelect;

  const SettlementCard({
    super.key,
    required this.settlement,
    required this.onTap,
    this.onDelete,
    this.isManager = false,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.canSelect = false,
  });

  @override
  State<SettlementCard> createState() => _SettlementCardState();
}

class _SettlementCardState extends State<SettlementCard> {
  bool _hovering = false;
  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  Color _cardColor(BuildContext context) =>
      _isDark(context) ? AppTheme.card : AppTheme.lightCard;
  Color _hoverColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cardHover : AppTheme.lightCardHover;
  Color _dividerColor(BuildContext context) =>
      _isDark(context) ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      _isDark(context) ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _primaryText(BuildContext context) =>
      _isDark(context) ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyText(BuildContext context) =>
      _isDark(context) ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  String _getDisplayTitle(Map<String, dynamic> s) {
    final type = (s['settlement_type'] ?? 'single').toString().toLowerCase();
    final title = s['title'] ?? '';

    if (type == 'single') {
      final firstDesc = s['first_expense_description'] as String?;
      if (firstDesc != null && firstDesc.isNotEmpty) return firstDesc;

      final expenses = s['expenses'] as List? ?? [];
      if (expenses.isNotEmpty) {
        final firstExp = Map<String, dynamic>.from(expenses.first);
        final desc = firstExp['description'] as String?;
        if (desc != null && desc.isNotEmpty) return desc;
      }
    }
    return title.isEmpty ? 'Settlement' : title;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft': return AppTheme.textSecondary;
      case 'submitted': return AppTheme.warning;
      case 'completed':
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.danger;
      default: return _bodyText(context);
    }
  }

  bool _isSettlementApproved(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'approved' || normalized == 'completed';
  }

  Color _advanceWalletColor(String status) {
    return _isSettlementApproved(status) ? AppTheme.success : AppTheme.danger;
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'manager': return 'Manager';
      case 'staff': return 'Staff';
      case 'mitra_eks': return 'Mitra';
      case 'unknown': return 'User dihapus';
      default: return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settlement;
    final status = (s['status'] ?? 'draft').toString();
    final rejectedCount = s['rejected_count'] as int? ?? 0;

    Color statusColor = _statusColor(status);
    String displayStatus = status;

    if (rejectedCount > 0 &&
        status != 'rejected' &&
        status != 'approved' &&
        status != 'completed') {
      statusColor = AppTheme.warning;
      displayStatus = 'revision';
    }

    final walletColor = _advanceWalletColor(status);
    final isMobile = ResponsiveLayout.isMobile(context);
    final supportsHover = !isMobile;

    return MouseRegion(
      onEnter: supportsHover ? (_) => setState(() => _hovering = true) : null,
      onExit: supportsHover ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        onTap: widget.selectionMode
            ? (widget.canSelect
                ? () => widget.onSelectionChanged?.call(!widget.selected)
                : null)
            : widget.onTap,
        onLongPress: () {
          if (!widget.selectionMode && widget.onSelectionChanged != null) {
            widget.onSelectionChanged!(true);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: supportsHover && _hovering
                ? _hoverColor(context)
                : _cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: supportsHover && _hovering
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : _dividerColor(context),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 300;

              return Row(
                children: [
                  Container(
                    width: 4,
                    height: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _getDisplayTitle(s),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: _titleColor(context),
                                ),
                              ),
                            ),
                            if (!isVeryNarrow) ...[
                              const SizedBox(width: 8),
                              if (s['advance_id'] != null && s['advance_id'] != 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: EdgeInsets.all(isMobile ? 3 : 4),
                                  decoration: BoxDecoration(
                                    color: walletColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: isMobile ? 14 : 16,
                                    color: walletColor,
                                  ),
                                ),
                              Text(
                                'Rp ${formatNumber(s['total_amount'] ?? 0)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_getRoleName(s['creator_role'])} • ${s['expense_count'] ?? 0} item',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: _bodyText(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: displayStatus,
                              color: statusColor,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            final creatorId = s['creator_id'];
                            if (creatorId != null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => UserDetailDialog(userId: creatorId),
                              );
                            }
                          },
                          child: Text(
                            s['creator_name'] ?? '-',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.selectionMode)
                    IgnorePointer(
                      ignoring: !widget.canSelect,
                      child: Opacity(
                        opacity: widget.canSelect ? 1 : 0.45,
                        child: Checkbox(
                          value: widget.selected,
                          onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
                          activeColor: AppTheme.primary,
                          side: BorderSide(color: _dividerColor(context)),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: isMobile ? 18 : 20,
                      color: _bodyText(context),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdvanceCard extends StatefulWidget {
  final Map<String, dynamic> advance;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isManager;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectionChanged;
  final bool canSelect;

  const AdvanceCard({
    super.key,
    required this.advance,
    required this.onTap,
    this.onDelete,
    this.isManager = false,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
    this.canSelect = false,
  });

  @override
  State<AdvanceCard> createState() => _AdvanceCardState();
}

class _AdvanceCardState extends State<AdvanceCard> {
  bool _hovering = false;
  Color _cardColor(BuildContext context) =>
      context.isDark ? AppTheme.card : AppTheme.lightCard;
  Color _hoverColor(BuildContext context) =>
      context.isDark ? AppTheme.cardHover : AppTheme.lightCardHover;
  Color _dividerColor(BuildContext context) =>
      context.isDark ? AppTheme.divider : AppTheme.lightDivider;
  Color _titleColor(BuildContext context) =>
      context.isDark ? AppTheme.cream : AppTheme.lightTextPrimary;
  Color _primaryText(BuildContext context) =>
      context.isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
  Color _bodyText(BuildContext context) =>
      context.isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

  Color _advanceStatusColor(Map<String, dynamic> advance) {
    final status = (advance['status'] ?? 'draft').toString().toLowerCase();
    if (status == 'in_settlement') {
      final settlementStatus = (advance['settlement_status'] ?? '').toString().toLowerCase();
      final isSettlementApproved = settlementStatus == 'approved' || settlementStatus == 'completed';
      return isSettlementApproved ? AppTheme.success : AppTheme.danger;
    }
    return _statusColor(status);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'draft': return AppTheme.textSecondary;
      case 'submitted': return AppTheme.warning;
      case 'approved': return AppTheme.success;
      case 'revision_draft': return AppTheme.accent;
      case 'revision_submitted': return AppTheme.warning;
      case 'revision_rejected': return AppTheme.danger;
      case 'in_settlement':
      case 'settled':
      case 'completed': return AppTheme.primary;
      case 'rejected': return AppTheme.danger;
      default: return _bodyText(context);
    }
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'manager': return 'Manager';
      case 'staff': return 'Staff';
      case 'mitra_eks': return 'Mitra';
      case 'unknown': return 'User dihapus';
      default: return role ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.advance;
    final status = (a['status'] ?? 'draft').toString().toLowerCase();
    final rejectedCount = a['rejected_count'] as int? ?? 0;

    Color statusColor = _advanceStatusColor(a);
    String displayStatus = status;

    if (rejectedCount > 0 &&
        status != 'rejected' &&
        status != 'revision_rejected' &&
        status != 'approved' &&
        status != 'in_settlement') {
      statusColor = AppTheme.warning;
      displayStatus = 'revision';
    }

    final isMobile = ResponsiveLayout.isMobile(context);
    final supportsHover = !isMobile;
    final type = (a['advance_type'] ?? 'single').toString().toLowerCase();
    final displayTitle = type == 'single'
        ? (a['first_item_description']?.toString() ?? (a['title'] ?? 'Kasbon Mandiri').toString())
        : (a['title'] ?? '').toString();

    return MouseRegion(
      onEnter: supportsHover ? (_) => setState(() => _hovering = true) : null,
      onExit: supportsHover ? (_) => setState(() => _hovering = false) : null,
      child: GestureDetector(
        onTap: widget.selectionMode
            ? (widget.canSelect
                ? () => widget.onSelectionChanged?.call(!widget.selected)
                : null)
            : widget.onTap,
        onLongPress: () {
          if (!widget.selectionMode && widget.onSelectionChanged != null) {
            widget.onSelectionChanged!(true);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: supportsHover && _hovering
                ? _hoverColor(context)
                : _cardColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: supportsHover && _hovering
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : _dividerColor(context),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 300;

              return Row(
                children: [
                  Container(
                    width: 4,
                    height: isMobile ? 32 : 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: isMobile ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                  color: _titleColor(context),
                                ),
                              ),
                            ),
                            if (!isVeryNarrow) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Rp ${formatNumber(a['total_amount'] ?? 0)}',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryText(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_getRoleName(a['requester_role'])} • ${a['item_count'] ?? 0} item',
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: _bodyText(context),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              status: displayStatus,
                              color: statusColor,
                              isMobile: isMobile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            final creatorId = a['requester_id'];
                            if (creatorId != null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => UserDetailDialog(userId: creatorId),
                              );
                            }
                          },
                          child: Text(
                            a['requester_name'] ?? '-',
                            style: TextStyle(
                              fontSize: isMobile ? 11 : 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.selectionMode)
                    IgnorePointer(
                      ignoring: !widget.canSelect,
                      child: Opacity(
                        opacity: widget.canSelect ? 1 : 0.45,
                        child: Checkbox(
                          value: widget.selected,
                          onChanged: (value) => widget.onSelectionChanged?.call(value ?? false),
                          activeColor: AppTheme.primary,
                          side: BorderSide(color: _dividerColor(context)),
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: isMobile ? 18 : 20,
                      color: _bodyText(context),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final bool isMobile;

  const StatusBadge({super.key, required this.status, required this.color, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final displayStatus = status == 'completed' ? 'approved' : status;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: isMobile ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayStatus.toUpperCase(),
        style: TextStyle(
          fontSize: isMobile ? 9 : 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class AppRadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;
  const AppRadioGroup({super.key, required this.groupValue, required this.onChanged, required this.child});

  @override
  Widget build(BuildContext context) {
    return _AppRadioGroupScope(
      groupValue: groupValue,
      onChanged: (val) => onChanged(val as T?),
      child: child,
    );
  }
}

class _AppRadioGroupScope extends InheritedWidget {
  final dynamic groupValue;
  final ValueChanged<dynamic> onChanged;
  const _AppRadioGroupScope({required this.groupValue, required this.onChanged, required super.child});

  static _AppRadioGroupScope? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_AppRadioGroupScope>();

  @override
  bool updateShouldNotify(_AppRadioGroupScope oldWidget) => groupValue != oldWidget.groupValue;
}

class AppRadioItem<T> extends StatelessWidget {
  final T value;
  final Widget label;
  const AppRadioItem({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scope = _AppRadioGroupScope.of(context);
    final selected = scope?.groupValue == value;
    return InkWell(
      onTap: () => scope?.onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<T>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: scope?.groupValue as T?,
            // ignore: deprecated_member_use
            onChanged: (v) => scope?.onChanged(v),
            activeColor: AppTheme.primary,
          ),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 14,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: label,
          ),
        ],
      ),
    );
  }
}
