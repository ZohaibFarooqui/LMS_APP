import 'package:equatable/equatable.dart';

/// Response entity for face verification
class FaceVerifyResponse extends Equatable {
  const FaceVerifyResponse({
    required this.isMatch,
    required this.confidence,
    this.message,
  });

  final bool isMatch;
  final double confidence;
  final String? message;

  @override
  List<Object?> get props => [isMatch, confidence, message];
}


