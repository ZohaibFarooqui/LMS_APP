import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
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
            onRefresh: () async => context.read<AttendanceBloc>().add(const AttendanceRequested()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'From',
                        date: state.fromDate,
                        onDateSelected: (value) => _onDateChanged(context, value, state.toDate),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'To',
                        date: state.toDate,
                        onDateSelected: (value) => _onDateChanged(context, state.fromDate, value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Load Attendance',
                  onPressed: () => context.read<AttendanceBloc>().add(
                        AttendanceRangeChanged(from: state.fromDate, to: state.toDate),
                      ),
                  isLoading: state.status == AttendanceStatus.loading,
                ),
                const SizedBox(height: 16),
                _SummaryGrid(summary: state.summary),
                const SizedBox(height: 16),
                _AttendanceTable(records: state.records),
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
    return TextButton(
      onPressed: () async {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(DateFormatter.formatDate(date), style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final AttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final entries = {
      'CL': summary.casualLeave,
      'EL': summary.earnedLeave,
      'ML': summary.medicalLeave,
      'CP': summary.compensatoryLeave,
      'SL': summary.sickLeave,
      'LWP': summary.lossOfPay,
      'ABS': summary.absent,
      'OD': summary.outdoorDuty,
      'Extra Work': summary.approvedExtraWork,
      'Late Count': summary.lateCount,
    };
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final key = entries.keys.elementAt(index);
        final value = entries.values.elementAt(index);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(key, style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const AppCard(child: Center(child: Text('No attendance data found')));
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            child: Row(
              children: const [
                Expanded(child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600))),
                Expanded(child: Text('Shift')),
                Expanded(child: Text('In')),
                Expanded(child: Text('Out')),
                Expanded(child: Text('Hours')),
                Expanded(child: Text('Late')),
                Expanded(child: Text('Remarks')),
              ],
            ),
          ),
          ...records.map((record) => _AttendanceRow(record: record)),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({required this.record});

  final AttendanceRecord record;

  Color _rowColor(BuildContext context) {
    if (record.isAbsent) {
      return Colors.redAccent.withValues(alpha: 0.08);
    }
    if (record.workHours < const Duration(hours: 8, minutes: 30)) {
      return Colors.orangeAccent.withValues(alpha: 0.08);
    }
    if (record.timeIn > const Duration(hours: 9, minutes: 40)) {
      return Colors.yellow.withValues(alpha: 0.08);
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _rowColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(DateFormatter.formatDate(record.date))),
          Expanded(child: Text(record.shift)),
          Expanded(child: Text(DateFormatter.formatHours(record.timeIn))),
          Expanded(child: Text(DateFormatter.formatHours(record.timeOut))),
          Expanded(child: Text(DateFormatter.formatHours(record.workHours))),
          Expanded(child: record.isLate ? const Icon(Icons.warning, color: Colors.orange, size: 16) : const SizedBox()),
          Expanded(child: Text(record.remarks.isEmpty ? '-' : record.remarks)),
        ],
      ),
    );
  }
}

