import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../bloc/attendance_bloc.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceBloc>()..add(const AttendanceRequested()),
      child: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state.status == AttendanceStatus.loading && state.records.isEmpty) {
            return const LoadingIndicator();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<AttendanceBloc>().add(const AttendanceRequested()),
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _DateRangePicker(
                  fromDate: state.fromDate,
                  toDate: state.toDate,
                  onFromDateSelected: (value) =>
                      _onDateChanged(context, value, state.toDate),
                  onToDateSelected: (value) =>
                      _onDateChanged(context, state.fromDate, value),
                ),
                SizedBox(height: 16.h),
                _LoadButton(
                  isLoading: state.status == AttendanceStatus.loading,
                  onPressed: () => context.read<AttendanceBloc>().add(
                        AttendanceRangeChanged(
                          from: state.fromDate,
                          to: state.toDate,
                        ),
                      ),
                ),
                SizedBox(height: 20.h),
                _SectionHeader(
                  title: 'Summary',
                  icon: Icons.analytics_outlined,
                ),
                SizedBox(height: 12.h),
                _SummaryGrid(summary: state.summary),
                SizedBox(height: 20.h),
                _SectionHeader(
                  title: 'Attendance Records',
                  icon: Icons.list_alt_rounded,
                ),
                SizedBox(height: 12.h),
                _AttendanceList(records: state.records),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onDateChanged(BuildContext context, DateTime from, DateTime to) {
    context.read<AttendanceBloc>().add(AttendanceRangeChanged(from: from, to: to));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: theme.primaryColor),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.fromDate,
    required this.toDate,
    required this.onFromDateSelected,
    required this.onToDateSelected,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final ValueChanged<DateTime> onFromDateSelected;
  final ValueChanged<DateTime> onToDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateField(
              label: 'From',
              date: fromDate,
              onDateSelected: onFromDateSelected,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              size: 20.sp,
            ),
          ),
          Expanded(
            child: _DateField(
              label: 'To',
              date: toDate,
              onDateSelected: onToDateSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.white54 : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14.sp,
                  color: theme.primaryColor,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    DateFormatter.formatDate(date),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadButton extends StatelessWidget {
  const _LoadButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(Icons.search_rounded, size: 18.sp),
        label: Text(
          isLoading ? 'Loading...' : 'Load Attendance',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final entries = [
      _SummaryItem('CL', summary.casualLeave, AppColors.primary),
      _SummaryItem('EL', summary.earnedLeave, AppColors.success),
      _SummaryItem('ML', summary.medicalLeave, AppColors.warning),
      _SummaryItem('CP', summary.compensatoryLeave, AppColors.info),
      _SummaryItem('SL', summary.sickLeave, AppColors.secondary),
      _SummaryItem('LWP', summary.lossOfPay, AppColors.error),
      _SummaryItem('ABS', summary.absent, Colors.red),
      _SummaryItem('OD', summary.outdoorDuty, AppColors.accent),
      _SummaryItem('Extra', summary.approvedExtraWork, Colors.purple),
      _SummaryItem('Late', summary.lateCount, Colors.orange),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.9,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final item = entries[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.value}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem {
  final String label;
  final int value;
  final Color color;

  _SummaryItem(this.label, this.value, this.color);
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (records.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48.sp,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                'No attendance data found',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        return _AttendanceCard(record: records[index]);
      },
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});

  final AttendanceRecord record;

  Color _getStatusColor() {
    if (record.isAbsent) return Colors.red;
    if (record.workHours < const Duration(hours: 8, minutes: 30)) {
      return Colors.orange;
    }
    if (record.isLate) return Colors.amber;
    return AppColors.success;
  }

  IconData _getStatusIcon() {
    if (record.isAbsent) return Icons.cancel_rounded;
    if (record.workHours < const Duration(hours: 8, minutes: 30)) {
      return Icons.warning_rounded;
    }
    if (record.isLate) return Icons.schedule_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_getStatusIcon(), color: statusColor, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.formatDate(record.date),
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Shift: ${record.shift}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (record.isLate)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'LATE',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          // Time Info Row
          Row(
            children: [
              _TimeInfo(
                icon: Icons.login_rounded,
                label: 'In',
                value: DateFormatter.formatHours(record.timeIn),
                color: AppColors.success,
              ),
              SizedBox(width: 16.w),
              _TimeInfo(
                icon: Icons.logout_rounded,
                label: 'Out',
                value: DateFormatter.formatHours(record.timeOut),
                color: AppColors.error,
              ),
              SizedBox(width: 16.w),
              _TimeInfo(
                icon: Icons.timer_outlined,
                label: 'Hours',
                value: DateFormatter.formatHours(record.workHours),
                color: theme.primaryColor,
              ),
            ],
          ),
          // Remarks
          if (record.remarks.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 14.sp,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      record.remarks,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                      ),
                    ),
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

class _TimeInfo extends StatelessWidget {
  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: isDark ? Colors.white38 : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
