import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'core/background/background_tasks.dart';
import 'di/service_locator.dart';
import 'shared/bloc/app_bloc_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  Bloc.observer = AppBlocObserver();

  // Initialise WorkManager with the background location callback
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  runApp(const LmsApp());
}
