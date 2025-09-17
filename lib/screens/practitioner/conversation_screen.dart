import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String practitionerId;
  final String recipientName;
  
  const ConversationScreen({
    required this.conversationId,
    required this.practitionerId,
    required this.recipientName,
    Key? key,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isInitialLoad = true;
  bool _isSending = false;
  String? _errorMessage;
  List<MessageModel> _messages = [];
  
  Stream<QuerySnapshot>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _setupMessagesStream();
    // Mark all messages as read when this screen opens
    _markConversationAsRead();
  }

  void _setupMessagesStream() {
    _messagesStream = _firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> _markConversationAsRead() async {
    try {
      // Get the conversation document
      DocumentReference conversationRef = _firestore
          .collection('conversations')
          .doc(widget.conversationId);
      
      // Update the unread status for this practitioner
      await conversationRef.update({
        'unreadStatus.${widget.practitionerId}': false
      });
      
      // Mark all messages from other participants as read
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: widget.practitionerId)
          .where('isRead', isEqualTo: false)
          .get();
      
      WriteBatch batch = _firestore.batch();
      
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking conversation as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    
    if (messageText.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // Get user details for the sender info
      final User? currentUser = _auth.currentUser;
      String senderName = 'Unknown Practitioner';
      
      // Get practitioner's name from Firestore
      DocumentSnapshot practitionerDoc = await _firestore
          .collection('practitioners')
          .doc(widget.practitionerId)
          .get();
          
      if (practitionerDoc.exists) {
        Map<String, dynamic> data = practitionerDoc.data() as Map<String, dynamic>;
        senderName = data['fullName'] as String? ?? 'Unknown Practitioner';
      }
      
      // Create a new message document
      DocumentReference messageRef = _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc();
          
      MessageModel newMessage = MessageModel(
        id: messageRef.id,
        senderId: widget.practitionerId,
        senderName: senderName,
        senderRole: 'practitioner',
        content: messageText,
        timestamp: DateTime.now(),
        isRead: false,
      );
      
      // Add the new message to Firestore
      await messageRef.set(newMessage.toJson());
      
      // Update the conversation with the latest message
      await _firestore.collection('conversations').doc(widget.conversationId).update({
        'lastMessageContent': messageText,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': widget.practitionerId,
      });
      
      // Update unread status for all participants except the sender
      DocumentSnapshot conversationDoc = await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .get();
          
      if (conversationDoc.exists) {
        Map<String, dynamic> data = conversationDoc.data() as Map<String, dynamic>;
        List<String> participantIds = List<String>.from(data['participantIds'] ?? []);
        
        Map<String, bool> unreadStatus = {};
        for (String id in participantIds) {
          // Set unread true for everyone except the sender
          unreadStatus[id] = id != widget.practitionerId;
        }
        
        await _firestore.collection('conversations').doc(widget.conversationId).update({
          'unreadStatus': unreadStatus,
        });
      }
      
      // Clear the text field
      _messageController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send message: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'Failed to send message')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show patient info dialog
              _showPatientInfoDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start a conversation!'),
                  );
                }

                if (_isInitialLoad) {
                  setState(() {
                    _isInitialLoad = false;
                  });
                }

                final messages = snapshot.data!.docs.map((doc) => 
                  MessageModel.fromJson(doc.data() as Map<String, dynamic>, doc.id)
                ).toList();
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          
          // Error message if any
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          // Message input field
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final bool isMe = message.senderId == widget.practitionerId;
    final time = DateFormat.jm().format(message.timestamp);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0] : '?',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMe 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24), // Space for avatar alignment
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            spreadRadius: 1.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Implement attachment functionality (future enhancement)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attachments coming soon')),
                );
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
            ),
            _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }

  void _showPatientInfoDialog() {
    // Get patient info from conversation and display in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${widget.recipientName} Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Patient information will be shown here in a future update.'),
            SizedBox(height: 16),
            Text('This will include:'),
            SizedBox(height: 8),
            Text('• Patient contact details'),
            Text('• Current treatment plan'),
            Text('• Recent therapy sessions'),
            Text('• Notes and medical history'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Placeholder for navigating to patient details
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('View full profile feature coming soon')),
              );
            },
            child: const Text('View Full Profile'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}