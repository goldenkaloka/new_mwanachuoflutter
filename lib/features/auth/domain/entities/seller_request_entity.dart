import 'package:equatable/equatable.dart';

class SellerRequestEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String status; // pending, approved, rejected
  final String? reason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewerName;
  final String? reviewNotes;

  const SellerRequestEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.status,
    this.reason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewerName,
    this.reviewNotes,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        userAvatar,
        status,
        reason,
        createdAt,
        reviewedAt,
        reviewedBy,
        reviewerName,
        reviewNotes,
      ];
}






