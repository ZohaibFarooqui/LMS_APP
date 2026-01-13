import '../../domain/entities/face_status_response.dart';

class FaceStatusResponseModel extends FaceStatusResponse {
  const FaceStatusResponseModel({
    required super.isRegistered,
    super.cardNo1,
    super.registeredAt,
  });

  factory FaceStatusResponseModel.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>? ?? json;
    return FaceStatusResponseModel(
      isRegistered: body['is_registered'] as bool? ?? false,
      cardNo1: body['card_no1'] as String?,
      registeredAt: body['registered_at'] as String?,
    );
  }

  factory FaceStatusResponseModel.notRegistered() {
    return const FaceStatusResponseModel(isRegistered: false);
  }
}


