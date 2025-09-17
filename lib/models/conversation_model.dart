import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final String lastMessageContent;
  final DateTime lastMessageTimestamp;
  final String lastMessageSenderId;
  final Map<String, bool> unreadStatus; // Map of userId to whether they have unread messages
  
  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantRoles,
    required this.lastMessageContent,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    required this.unreadStatus,
  });
  
  factory ConversationModel.fromJson(Map<String, dynamic> json, String docId) {
    // Convert the dynamic Maps from Firestore to the required types
    Map<String, String> names = {};
    if (json['participantNames'] != null) {
      final Map<String, dynamic> rawNames = Map<String, dynamic>.from(json['participantNames']);
      rawNames.forEach((key, value) {
        names[key] = value.toString();
      });
    }
    
    Map<String, String> roles = {};
    if (json['participantRoles'] != null) {
      final Map<String, dynamic> rawRoles = Map<String, dynamic>.from(json['participantRoles']);
      rawRoles.forEach((key, value) {
        roles[key] = value.toString();
      });
    }
    
    Map<String, bool> unread = {};
    if (json['unreadStatus'] != null) {
      final Map<String, dynamic> rawUnread = Map<String, dynamic>.from(json['unreadStatus']);
      rawUnread.forEach((key, value) {
        unread[key] = value as bool;
      });
    }
    
    return ConversationModel(
      id: docId,
      participantIds: List<String>.from(json['participantIds']),
      participantNames: names,
      participantRoles: roles,
      lastMessageContent: json['lastMessageContent'] as String? ?? '',
      lastMessageTimestamp: (json['lastMessageTimestamp'] is Timestamp)
          ? (json['lastMessageTimestamp'] as Timestamp).toDate()
          : (json['lastMessageTimestamp'] != null)
              ? DateTime.parse(json['lastMessageTimestamp'].toString())
              : DateTime.now(),
      lastMessageSenderId: json['lastMessageSenderId'] as String? ?? '',
      unreadStatus: unread,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'lastMessageContent': lastMessageContent,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadStatus': unreadStatus,
    };
  }
  
  // Helper method to get participant name that is not the current user
  String getOtherParticipantName(String currentUserId) {
    if (participantIds.length <= 1) {
      return 'Unknown';
    }
    
    for (final id in participantIds) {
      if (id != currentUserId) {
        return participantNames[id] ?? 'Unknown User';
      }
    }
    
    return 'Unknown User';
  }
  
  // Helper method to check if the conversation has unread messages for a user
  bool hasUnreadMessages(String userId) {
    return unreadStatus[userId] ?? false;
  }
  
  // Create a copy with updated fields
  ConversationModel copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String>? participantRoles,
    String? lastMessageContent,
    DateTime? lastMessageTimestamp,
    String? lastMessageSenderId,
    Map<String, bool>? unreadStatus,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantRoles: participantRoles ?? this.participantRoles,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadStatus: unreadStatus ?? this.unreadStatus,
    );
  }
}