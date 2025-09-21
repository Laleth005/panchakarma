import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/conversation_model.dart';
import '../../models/practitioner_model.dart';
import 'conversation_screen.dart';

class PractitionerMessagesScreen extends StatefulWidget {
  final String? practitionerId;

  const PractitionerMessagesScreen({this.practitionerId, Key? key})
    : super(key: key);

  @override
  _PractitionerMessagesScreenState createState() =>
      _PractitionerMessagesScreenState();
}

class _PractitionerMessagesScreenState
    extends State<PractitionerMessagesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<ConversationModel> _conversations = [];
  String? _practitionerId;
  PractitionerModel? _practitionerData;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadConversations());
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // First, determine the practitioner ID
      _practitionerId = widget.practitionerId;

      if (_practitionerId == null) {
        // Try to get from Firebase Auth if not provided
        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          _practitionerId = currentUser.uid;
        }
      }

      if (_practitionerId == null) {
        throw Exception('Could not determine practitioner ID');
      }

      // Load practitioner data
      final DocumentSnapshot practitionerDoc = await _firestore
          .collection('practitioners')
          .doc(_practitionerId)
          .get();

      if (practitionerDoc.exists) {
        final data = practitionerDoc.data() as Map<String, dynamic>;
        data['uid'] = practitionerDoc.id;
        _practitionerData = PractitionerModel.fromJson(data);
      }

      // Load conversations where this practitioner is a participant
      final QuerySnapshot conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: _practitionerId)
          .orderBy('lastMessageTimestamp', descending: true)
          .get();

      _conversations = conversationsSnapshot.docs
          .map(
            (doc) => ConversationModel.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
        print('Error loading conversations: $e');
      });
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<ConversationModel> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }

    return _conversations.where((conversation) {
      // Search in participant names
      for (final name in conversation.participantNames.values) {
        if (name.toLowerCase().contains(_searchQuery)) {
          return true;
        }
      }

      // Search in last message
      if (conversation.lastMessageContent.toLowerCase().contains(
        _searchQuery,
      )) {
        return true;
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorView()
          : _buildConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to new message screen (to be implemented)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New message feature coming soon')),
          );
        },
        tooltip: 'New Message',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Error loading messages: $_errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadConversations,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_filteredConversations.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          const Expanded(
            child: Center(
              child: Text(
                'No conversations found',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredConversations.length,
            itemBuilder: (context, index) {
              final conversation = _filteredConversations[index];
              return _buildConversationTile(conversation);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
        onChanged: _handleSearch,
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    final otherParticipantName = conversation.getOtherParticipantName(
      _practitionerId ?? '',
    );
    final hasUnread = conversation.hasUnreadMessages(_practitionerId ?? '');
    final formattedTime = _formatTimestamp(conversation.lastMessageTimestamp);

    // Get initial letter for avatar
    final initial = otherParticipantName.isNotEmpty
        ? otherParticipantName[0].toUpperCase()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasUnread
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
      title: Text(
        otherParticipantName,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessageContent,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: hasUnread
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(top: 5),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversation.id,
              practitionerId: _practitionerId!,
              recipientName: otherParticipantName,
            ),
          ),
        ).then(
          (_) => _loadConversations(),
        ); // Refresh after returning from conversation
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (dateToCheck == today) {
      // Today, show time only
      return DateFormat.jm().format(timestamp); // e.g. 5:30 PM
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(dateToCheck).inDays < 7) {
      // Within the last week
      return DateFormat('EEEE').format(timestamp); // e.g. Monday
    } else {
      // Older than a week
      return DateFormat('MMM d').format(timestamp); // e.g. Jan 5
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
