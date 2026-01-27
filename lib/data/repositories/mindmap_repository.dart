import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mindmap_model.dart';

class MindmapRepository {
  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('mindmaps');

  // Get all mindmaps for a user
  Future<List<MindmapModel>> getMindmaps(String userId) async {
    try {
      final snapshot = await _collection
          .where('ownerId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MindmapModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load mindmaps: $e');
    }
  }

  // Get single mindmap
  Future<MindmapModel?> getMindmap(String mindmapId) async {
    try {
      final doc = await _collection.doc(mindmapId).get();
      if (!doc.exists) return null;
      return MindmapModel.fromJson({...doc.data()!, 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to load mindmap: $e');
    }
  }

  // Save mindmap (create or update)
  Future<void> saveMindmap(MindmapModel mindmap) async {
    try {
      final data = mindmap.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _collection.doc(mindmap.id).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save mindmap: $e');
    }
  }

  // Create new mindmap
  Future<MindmapModel> createMindmap(MindmapModel mindmap) async {
    try {
      final data = mindmap.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _collection.doc(mindmap.id).set(data);
      return mindmap;
    } catch (e) {
      throw Exception('Failed to create mindmap: $e');
    }
  }

  // Delete mindmap
  Future<void> deleteMindmap(String mindmapId) async {
    try {
      await _collection.doc(mindmapId).delete();
    } catch (e) {
      throw Exception('Failed to delete mindmap: $e');
    }
  }

  // Update mindmap title
  Future<void> updateTitle(String mindmapId, String title) async {
    try {
      await _collection.doc(mindmapId).update({
        'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update title: $e');
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String mindmapId, bool isFavorite) async {
    try {
      await _collection.doc(mindmapId).update({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Get shared mindmaps
  Future<List<MindmapModel>> getSharedMindmaps(String userId) async {
    try {
      final snapshot = await _collection
          .where('collaboratorIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MindmapModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      throw Exception('Failed to load shared mindmaps: $e');
    }
  }

  // Real-time updates stream
  Stream<MindmapModel?> mindmapStream(String mindmapId) {
    return _collection.doc(mindmapId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MindmapModel.fromJson({...doc.data()!, 'id': doc.id});
    });
  }

  // Search mindmaps
  Future<List<MindmapModel>> searchMindmaps(String userId, String query) async {
    try {
      final snapshot =
          await _collection.where('ownerId', isEqualTo: userId).get();

      final results = snapshot.docs
          .map((doc) => MindmapModel.fromJson({...doc.data(), 'id': doc.id}))
          .where((m) => m.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return results;
    } catch (e) {
      throw Exception('Failed to search mindmaps: $e');
    }
  }
}
