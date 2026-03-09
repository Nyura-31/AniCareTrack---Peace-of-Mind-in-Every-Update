import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A90E2),
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('conversations')
            .where('participants', arrayContains: currentUserId)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv =
                  conversations[index].data() as Map<String, dynamic>;
              final conversationId = conversations[index].id;

              // Get the other user ID
              final otherUserId = (conv['participants'] as List)
                  .firstWhere((id) => id != currentUserId);

              return _buildConversationTile(
                context,
                conv,
                conversationId,
                otherUserId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Map<String, dynamic> conversation,
    String conversationId,
    String otherUserId,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox();
        }

        final otherUser = userSnapshot.data!.data() as Map<String, dynamic>;
        final unreadCount = (conversation['unreadCount'] ?? 0) as int;
        final lastMessage = conversation['lastMessage'] ?? 'No messages yet';
        final lastTimestamp = conversation['lastTimestamp'] as Timestamp?;

        String formatTime(Timestamp? timestamp) {
          if (timestamp == null) return '';
          final dateTime = timestamp.toDate();
          final now = DateTime.now();
          final difference = now.difference(dateTime);

          if (difference.inDays == 0) {
            return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          } else if (difference.inDays == 1) {
            return 'Yesterday';
          } else if (difference.inDays < 7) {
            return '${difference.inDays}d ago';
          } else {
            return '${dateTime.day}/${dateTime.month}';
          }
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  conversationId: conversationId,
                  otherUserId: otherUserId,
                  otherUserName: otherUser['displayName'] ?? 'Unknown',
                  otherUserAvatar:
                      otherUser['profileImageUrl'] ?? '',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF4A90E2),
                      backgroundImage: (otherUser['profileImageUrl'] ?? '')
                              .isNotEmpty
                          ? NetworkImage(otherUser['profileImageUrl'])
                          : null,
                      child: (otherUser['profileImageUrl'] ?? '').isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7A7A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Message Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            otherUser['displayName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: unreadCount > 0
                                  ? const Color(0xFF333333)
                                  : const Color(0xFF7A7A7A),
                            ),
                          ),
                          Text(
                            formatTime(lastTimestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: unreadCount > 0
                                  ? const Color(0xFF4A90E2)
                                  : const Color(0xFF7A7A7A),
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: unreadCount > 0
                              ? const Color(0xFF333333)
                              : const Color(0xFF7A7A7A),
                          fontWeight: unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Message a walker to get started',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}