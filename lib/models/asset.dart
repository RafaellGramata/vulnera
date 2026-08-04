import 'package:cloud_firestore/cloud_firestore.dart';

class Asset {
  final String id;
  final String name;
  final String type;
  final String ownerId;
  final double riskScore;
  final int openIssueCount;
  final DateTime createdAt;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.riskScore,
    required this.openIssueCount,
    required this.createdAt,
  });

  factory Asset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Asset(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      ownerId: data['ownerId'] ?? '',
      riskScore: (data['riskScore'] ?? 0).toDouble(),
      openIssueCount: (data['openIssueCount'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'ownerId': ownerId,
      'riskScore': riskScore,
      'openIssueCount': openIssueCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
