import 'package:cloud_firestore/cloud_firestore.dart';

class KnowledgeItem {
  final String id;
  final String title;
  final String category;
  final String content;
  final List<String> tags;
  final DateTime? lastUpdated;
  final String? authorName;

  KnowledgeItem({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.tags,
    this.lastUpdated,
    this.authorName,
  });

  factory KnowledgeItem.fromJson(Map<String, dynamic> json) {
    return KnowledgeItem(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      content: json['content'],
      tags: List<String>.from(json['tags'] ?? []),
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
      authorName: json['authorName'],
    );
  }
}

class KnowledgeHubService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all knowledge categories
  Future<List<String>> getKnowledgeCategories() async {
    try {
      final snapshot = await _firestore
          .collection('knowledge_categories')
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
    } catch (e) {
      print('Error fetching knowledge categories: $e');
      return [
        'Panchakarma Basics',
        'Procedures',
        'Patient Care',
        'Best Practices',
      ];
    }
  }

  // Get knowledge items by category
  Future<List<KnowledgeItem>> getKnowledgeByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('knowledge_hub')
          .where('category', isEqualTo: category)
          .orderBy('title')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return KnowledgeItem.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching knowledge items: $e');
      return [];
    }
  }

  // Search knowledge hub
  Future<List<KnowledgeItem>> searchKnowledge(String query) async {
    try {
      final snapshot = await _firestore.collection('knowledge_hub').get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return KnowledgeItem.fromJson(data);
      }).toList();

      // Perform client-side filtering
      if (query.isEmpty) return items;

      final lowerQuery = query.toLowerCase();
      return items.where((item) {
        return item.title.toLowerCase().contains(lowerQuery) ||
            item.content.toLowerCase().contains(lowerQuery) ||
            item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    } catch (e) {
      print('Error searching knowledge hub: $e');
      return [];
    }
  }

  // Get procedural guidelines for a specific therapy
  Future<KnowledgeItem?> getTherapyGuidelines(String therapyType) async {
    try {
      final snapshot = await _firestore
          .collection('knowledge_hub')
          .where('category', isEqualTo: 'Procedures')
          .where('tags', arrayContains: therapyType)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      data['id'] = doc.id;
      return KnowledgeItem.fromJson(data);
    } catch (e) {
      print('Error fetching therapy guidelines: $e');
      return null;
    }
  }
}
