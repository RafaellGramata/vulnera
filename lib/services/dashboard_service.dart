import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final CollectionReference _vulnRef =
      FirebaseFirestore.instance.collection('vulnerabilities');

  // counts open vulnerabilities by severity, across a given list of asset ids
  Stream<Map<String, int>> getSeverityCounts(List<String> assetIds) {
    if (assetIds.isEmpty) {
      return Stream.value({'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0});
    }

    // firestore's whereIn only supports up to 30 values at a time,
    // which is plenty for a solo project's asset count
    return _vulnRef.where('assetId', whereIn: assetIds).snapshots().map((snapshot) {
      final counts = {'Critical': 0, 'High': 0, 'Medium': 0, 'Low': 0};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // we only count open/in-progress issues, not resolved ones,
        // same logic as the risk score calculation
        if (data['status'] == 'Resolved') continue;

        final severity = data['severity'] ?? 'Low';
        counts[severity] = (counts[severity] ?? 0) + 1;
      }

      return counts;
    });
  }
}