import 'package:mwanachuo/features/auth/domain/entities/seller_request_entity.dart';

class SellerRequestModel extends SellerRequestEntity {
  const SellerRequestModel({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userEmail,
    super.userAvatar,
    required super.status,
    super.reason,
    required super.createdAt,
    super.reviewedAt,
    super.reviewedBy,
    super.reviewerName,
    super.reviewNotes,
  });

  factory SellerRequestModel.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'] as Map<String, dynamic>?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;

    return SellerRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: requester?['full_name'] as String? ?? 'Unknown',
      userEmail: requester?['email'] as String? ?? 'N/A',
      userAvatar: requester?['avatar_url'] as String?,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewerName: reviewer?['full_name'] as String?,
      reviewNotes: json['review_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
    };
  }
}





