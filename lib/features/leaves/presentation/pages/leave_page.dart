import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/entities/leave_request.dart';
import '../bloc/leave_application/leave_application_bloc.dart';
import '../bloc/leave_balance/leave_balance_bloc.dart';
import '../bloc/leave_status/leave_status_bloc.dart';

class LeavePage extends StatelessWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: const [
          TabBar(
            tabs: [
              Tab(text: 'Balances'),
              Tab(text: 'Apply'),
              Tab(text: 'Status'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _LeaveBalanceView(),
                _LeaveApplicationView(),
                _LeaveStatusView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveBalanceView extends StatelessWidget {
  const _LeaveBalanceView();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaveBalanceBloc>()..add(const LeaveBalanceRequested()),
      child: BlocBuilder<LeaveBalanceBloc, LeaveBalanceState>(
        builder: (context, state) {
          if (state.status == LeaveBalanceStatus.loading) {
            return const LoadingIndicator();
          }
          if (state.balances.isEmpty) {
            return const Center(child: Text('No balances available'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.balances.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final balance = state.balances[index];
              return AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(balance.name, style: Theme.of(context).textTheme.titleMedium),
                        Text(balance.code, style: Theme.of(context).textTheme.labelMedium),
                      ],
                    ),
                    Text(
                      '${balance.balance} days',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LeaveApplicationView extends StatelessWidget {
  const _LeaveApplicationView();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaveApplicationBloc>(),
      child: BlocConsumer<LeaveApplicationBloc, LeaveApplicationState>(
        listener: (context, state) {
          if (state.status == LeaveApplicationStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Leave submitted successfully')),
            );
          } else if (state.status == LeaveApplicationStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Failed to submit leave')),
            );
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Leave Type'),
                // ignore: deprecated_member_use
                value: state.leaveType,
                items: const ['CL', 'CP', 'EL', 'ML', 'OD', 'WP', 'SL']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => context.read<LeaveApplicationBloc>().add(LeaveTypeChanged(value ?? 'CL')),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _datePicker(context, 'From', state.fromDate, (date) => context.read<LeaveApplicationBloc>().add(LeaveDatesChanged(date, state.toDate)))),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker(context, 'To', state.toDate, (date) => context.read<LeaveApplicationBloc>().add(LeaveDatesChanged(state.fromDate, date)))),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: state.halfDay,
                onChanged: (value) => context.read<LeaveApplicationBloc>().add(LeaveHalfDayToggled(value ?? false)),
                title: const Text('Half Day'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Reason'),
                minLines: 2,
                maxLines: 4,
                initialValue: state.reason,
                onChanged: (value) => context.read<LeaveApplicationBloc>().add(LeaveReasonChanged(value)),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Submit Request',
                isLoading: state.status == LeaveApplicationStatus.submitting,
                onPressed: () => context.read<LeaveApplicationBloc>().add(const LeaveSubmitted()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _datePicker(BuildContext context, String label, DateTime date, ValueChanged<DateTime> onSelected) {
    return TextButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            DateFormatter.formatDate(date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LeaveStatusView extends StatelessWidget {
  const _LeaveStatusView();

  Color _statusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeaveStatusBloc>()..add(const LeaveStatusRequested()),
      child: BlocBuilder<LeaveStatusBloc, LeaveStatusState>(
        builder: (context, state) {
          if (state.status == LeaveStatusEnum.loading) {
            return const LoadingIndicator();
          }
          if (state.requests.isEmpty) {
            return const Center(child: Text('No leave requests found'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = state.requests[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${request.type} ${request.halfDay ? '(Half Day)' : ''}',
                            style: Theme.of(context).textTheme.titleMedium),
                        StatusBadge(label: request.status.name.toUpperCase(), color: _statusColor(request.status)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormatter.formatDate(request.fromDate)} - ${DateFormatter.formatDate(request.toDate)}',
                    ),
                    const SizedBox(height: 8),
                    Text(request.reason),
                    if (request.approverComment != null) ...[
                      const SizedBox(height: 6),
                      Text('Approver: ${request.approverComment}'),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

