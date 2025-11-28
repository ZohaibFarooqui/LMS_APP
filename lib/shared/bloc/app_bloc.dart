import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(const AppState()) {
    on<AppThemeToggled>(_onThemeToggled);
  }

  void _onThemeToggled(AppThemeToggled event, Emitter<AppState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }
}

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class AppThemeToggled extends AppEvent {
  const AppThemeToggled(this.themeMode);

  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

class AppState extends Equatable {
  const AppState({
    this.themeMode = ThemeMode.system,
  });

  final ThemeMode themeMode;

  AppState copyWith({ThemeMode? themeMode}) {
    return AppState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [themeMode];
}

