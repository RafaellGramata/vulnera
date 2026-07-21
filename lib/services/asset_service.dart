import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/asset.dart';

class AssetService {
  // this points at the "assets" collection in firestore
  final CollectionReference _assetsRef =
  FirebaseFirestore.instance.collection('assets');

  // gives us a live stream of assets belonging to the current logged in user
  // a stream means the list updates automatically whenever the data changes
  Stream<List<Asset>> getAssets() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return _assetsRef
        .where('ownerId', isEqualTo: userId)
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
  }

  // updates an existing asset's name and type
  Future<void> updateAsset(String assetId, String name, String type) async {
    await _assetsRef.doc(assetId).update({
      'name': name,
      'type': type,
    });
  }

  // deletes an asset from firestore
  Future<void> deleteAsset(String assetId) async {
    await _assetsRef.doc(assetId).delete();
  }

  // gives us a live stream of one specific asset, so the screen updates
  // automatically whenever the asset's data changes (like its risk score)
  Stream<Asset> getAssetById(String assetId) {
    return _assetsRef.doc(assetId).snapshots().map((doc) {
      return Asset.fromFirestore(doc);
    });
  }
}