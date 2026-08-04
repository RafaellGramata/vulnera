import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset.dart';
import 'event_service.dart';

class AssetService {
  final EventService _eventService = EventService();
  final CollectionReference _assetsRef = FirebaseFirestore.instance.collection(
    'assets',
  );

  Stream<List<Asset>> getAssets() {
    return _assetsRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Asset.fromFirestore(doc)).toList();
    });
  }

  Future<void> addAsset(String name, String type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await _assetsRef.add({
      'name': name,
      'type': type,
      'ownerId': userId,
      'riskScore': 0.0,
      'openIssueCount': 0,
      'createdAt': Timestamp.now(),
    });

    await _eventService.logEvent('added a new asset: "$name"');
  }

  Future<String> addAssetAndReturnId(String name, String type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final docRef = await _assetsRef.add({
      'name': name,
      'type': type,
      'ownerId': userId,
      'riskScore': 0.0,
      'openIssueCount': 0,
      'createdAt': Timestamp.now(),
    });

    await _eventService.logEvent('added a new asset: "$name"');

    return docRef.id;
  }

  Future<void> updateAsset(String assetId, String name, String type) async {
    await _assetsRef.doc(assetId).update({'name': name, 'type': type});
  }

  Future<void> deleteAsset(String assetId) async {
    final vulnSnapshot = await FirebaseFirestore.instance
        .collection('vulnerabilities')
        .where('assetId', isEqualTo: assetId)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in vulnSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_assetsRef.doc(assetId));

    await batch.commit();

    await _eventService.logEvent('deleted an asset');
  }

  Stream<Asset> getAssetById(String assetId) {
    return _assetsRef.doc(assetId).snapshots().map((doc) {
      return Asset.fromFirestore(doc);
    });
  }
}
