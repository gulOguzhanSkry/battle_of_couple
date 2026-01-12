import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, rejected }

class PartnerRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String receiverId;
  final String receiverEmail;
  final RequestStatus status;
  final DateTime createdAt;

  PartnerRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.receiverId,
    required this.receiverEmail,
    required this.status,
    required this.createdAt,
  });

  // Create from Firestore document
  factory PartnerRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PartnerRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverEmail: data['receiverEmail'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'receiverEmail': receiverEmail,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  PartnerRequest copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? receiverId,
    String? receiverEmail,
    RequestStatus? status,
    DateTime? createdAt,
  }) {
    return PartnerRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
