import 'package:flutter/material.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

class SubmitLeaveRequestUseCase {
  SubmitLeaveRequestUseCase(this._repository);

  final LeaveRepository _repository;

  Future<void> call(LeaveRequest request, {TimeOfDay? fromTime, TimeOfDay? toTime}) => 
      _repository.submitRequest(request, fromTime: fromTime, toTime: toTime);
}

