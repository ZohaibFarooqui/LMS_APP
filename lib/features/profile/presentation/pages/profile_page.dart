import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/key_value_row.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileRequested()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.profile != null) {
            _emailController.text = state.profile!.email;
            _phoneController.text = state.profile!.phoneNumber;
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.profile == null) {
            return const LoadingIndicator();
          }
          if (state.profile == null) {
            return const Center(child: Text('Profile unavailable'));
          }
          final profile = state.profile!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${profile.designation} • ${profile.department}'),
                    const SizedBox(height: 16),
                    KeyValueRow(label: 'Employee Code', value: profile.employeeCode),
                    KeyValueRow(label: 'Cadre', value: profile.cadre),
                    KeyValueRow(label: 'Joining Date', value: profile.joiningDate),
                    KeyValueRow(label: 'Card Number', value: profile.cardNumber),
                    KeyValueRow(label: 'Location', value: profile.location),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Update Contact',
                      isLoading: state.status == ProfileStatus.updating,
                      onPressed: () {
                        context.read<ProfileBloc>().add(
                              ProfileContactUpdated(
                                email: _emailController.text.trim(),
                                phone: _phoneController.text.trim(),
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

