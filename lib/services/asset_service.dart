import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset.dart';
import 'event_service.dart';

class AssetService {
  final EventService _eventService = EventService();
  // this points at the "assets" collection in firestore
  final CollectionReference _assetsRef =
  FirebaseFirestore.instance.collection('assets');

  // gives us a live stream of all assets, shared across every logged in user -
  // ownerId is kept on each document just to record who originally created it,
  // but it no longer restricts who can see it
  Stream<List<Asset>> getAssets() {
    return _assetsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Asset.fromFirestore(doc)).toList();
    });
  }

  // adds a new asset to firestore
  Future<void> addAsset(String name, String type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    await _assetsRef.add({
      'name': name,
      'type': type,
      'ownerId': userId,
      'riskScore': 0.0, // starts at zero since it has no vulnerabilities yet
      'openIssueCount': 0,
      'createdAt': Timestamp.now(),
    });

    await _eventService.logEvent('added a new asset: "$name"');
  }

  // updates an existing asset's name and type
  Future<void> updateAsset(String assetId, String name, String type) async {
    await _assetsRef.doc(assetId).update({
      'name': name,
      'type': type,
    });
  }

// deletes an asset from firestore, along with all of its vulnerabilities
  // so we never leave orphaned data behind
  Future<void> deleteAsset(String assetId) async {
    // find every vulnerability that belongs to this asset
    final vulnSnapshot = await FirebaseFirestore.instance
        .collection('vulnerabilities')
        .where('assetId', isEqualTo: assetId)
        .get();

    // batch deletes everything together as one atomic operation -
    // either all of it succeeds, or none of it does, so we never end up
    // with the asset gone but some vulnerabilities left behind (or vice versa)
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in vulnSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_assetsRef.doc(assetId));

    await batch.commit();

    await _eventService.logEvent('deleted an asset');
  }

  // gives us a live stream of one specific asset, so the screen updates
  // automatically whenever the asset's data changes (like its risk score)
  Stream<Asset> getAssetById(String assetId) {
    return _assetsRef.doc(assetId).snapshots().map((doc) {
      return Asset.fromFirestore(doc);
    });
  }
}