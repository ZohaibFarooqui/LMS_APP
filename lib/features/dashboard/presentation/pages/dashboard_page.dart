import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../geofence/presentation/bloc/geofence_bloc.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(const DashboardRequested()),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading) {
            return const LoadingIndicator();
          }
          if (state.summary == null) {
            return const Center(child: Text('No dashboard data yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DashboardBloc>().add(const DashboardRequested()),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _WelcomeCard(summary: state.summary!),
                const SizedBox(height: AppSpacing.lg),
                Text('Leave Balances',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                _LeaveBalanceGrid(summary: state.summary!),
                const SizedBox(height: AppSpacing.lg),
                Text('Leave Distribution',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                _LeavePieChart(summary: state.summary!),
                const SizedBox(height: AppSpacing.lg),
                Text('Geo-Fence Attendance',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                const _GeoFenceCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${summary.userName}',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${summary.designation} • ${summary.department}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _infoChip('Employee Code', summary.employeeCode),
              _infoChip('Cadre', summary.cadre),
              _infoChip('Location', summary.location),
              _infoChip('Card No', summary.cardNumber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LeaveBalanceGrid extends StatelessWidget {
  const _LeaveBalanceGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: summary.balances.length,
      itemBuilder: (context, index) {
        final balance = summary.balances[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(balance.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${balance.balance} days',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(balance.code),
            ],
          ),
        );
      },
    );
  }
}

class _LeavePieChart extends StatelessWidget {
  const _LeavePieChart({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.balances.isEmpty) {
      return const AppCard(child: Center(child: Text('No data to display')));
    }

    final total =
        summary.balances.fold<int>(0, (prev, element) => prev + element.balance);
    final sections = summary.balances.map((balance) {
      final value = total == 0 ? 0.0 : balance.balance / total;
      return PieChartSectionData(
        value: value,
        title: '${(value * 100).toStringAsFixed(0)}%',
        radius: 60,
        color: Colors.primaries[summary.balances.indexOf(balance) %
            Colors.primaries.length],
      );
    }).toList();

    return AppCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            )),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: summary.balances
                .map(
                  (balance) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 10,
                        width: 10,
                        color: Colors.primaries[
                            summary.balances.indexOf(balance) %
                                Colors.primaries.length],
                      ),
                      const SizedBox(width: 6),
                      Text('${balance.code}: ${balance.balance}'),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GeoFenceCard extends StatefulWidget {
  const _GeoFenceCard();

  @override
  State<_GeoFenceCard> createState() => _GeoFenceCardState();
}

class _GeoFenceCardState extends State<_GeoFenceCard> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GeoFenceBloc>()..add(const GeoFenceStarted()),
      child: BlocConsumer<GeoFenceBloc, GeoFenceState>(
        listener: (context, state) {
          if (state.lastMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.lastMessage!)));
          }
        },
        builder: (context, state) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.status?.isInside == true ? 'Inside FTC geo-fence' : 'Outside permitted zone',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Distance: ${state.status?.distanceMeters.toStringAsFixed(2) ?? '--'} m',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Manual override reason',
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Manual Check-in',
                  isLoading: state.isSubmitting,
                  onPressed: () {
                    context.read<GeoFenceBloc>().add(
                          GeoFenceManualOverrideRequested(note: _noteController.text.trim()),
                        );
                  },
                ),
                TextButton(
                  onPressed: () => context.read<GeoFenceBloc>().add(const GeoFenceRefreshRequested()),
                  child: const Text('Refresh status'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

