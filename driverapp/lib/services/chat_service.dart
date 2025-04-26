import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'https://mtcs-server.azurewebsites.net//api/Chat'; // Thay đổi URL theo API của bạn

  // Lấy chat ID dựa trên 2 userId
  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_${userId2}'
        : '${userId2}_${userId1}';
  }

  // Lấy danh sách tin nhắn của một cuộc trò chuyện
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    final chatId = _getChatId(userId1, userId2);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Gửi tin nhắn thông qua API
  Future<bool> sendMessage(String senderId, String senderName, String receiverId, String receiverName, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessageAsRead(String userId1, String userId2, String messageId) async {
    final chatId = _getChatId(userId1, userId2);
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'read': true});
  }

  // Đếm số tin nhắn chưa đọc
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: {'id': userId})
          .get();

      int count = 0;

      for (final chatDoc in querySnapshot.docs) {
        final messagesQuery = await chatDoc.reference
            .collection('messages')
            .where('receiverId', isEqualTo: userId)
            .where('read', isEqualTo: false)
            .get();

        count += messagesQuery.docs.length;
      }

      return count;
    } catch (e) {
      print('Error getting unread message count: $e');
      return 0;
    }
  }

  // Lấy danh sách các cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getChatList(String userId) async {
    try {
      print('Getting chat list for user: $userId');
      // Truy vấn tất cả các cuộc trò chuyện có chứa userId
      final querySnapshot = await _firestore
          .collection('chats')
          .get();
      
      print('Found ${querySnapshot.docs.length} potential chats');
      
      List<Map<String, dynamic>> chatList = [];

      for (final chatDoc in querySnapshot.docs) {
        try {
          print('Processing chat: ${chatDoc.id}');
          // Kiểm tra xem tài liệu chat có trường participants không
          if (!chatDoc.exists || !chatDoc.data().containsKey('participants')) {
            print('Chat ${chatDoc.id} does not have participants field');
            continue;
          }
          
          // Lấy thông tin participants
          final participantsData = chatDoc.get('participants');
          if (participantsData == null) {
            print('Participants is null for chat: ${chatDoc.id}');
            continue;
          }
          
          print('Raw participants data: $participantsData');
          
          // Chuyển đổi dữ liệu participants sang danh sách
          List<Map<String, dynamic>> participants = [];
          if (participantsData is List) {
            // Nếu participants là một danh sách, chuyển đổi mỗi phần tử sang Map
            participants = List<Map<String, dynamic>>.from(
              participantsData.map((item) => item is Map ? Map<String, dynamic>.from(item) : {'id': '', 'name': ''})
            );
          } else {
            print('Participants is not a list for chat: ${chatDoc.id}');
            continue;
          }
          
          print('Processed participants: $participants');
          
          // Kiểm tra xem người dùng hiện tại có trong danh sách participants không
          final isUserInChat = participants.any((participant) => 
            participant['id'] == userId);
          
          if (!isUserInChat) {
            print('User $userId not in chat ${chatDoc.id}');
            continue;
          }
          
          // Lấy thông tin của người tham gia còn lại
          final otherUser = participants.firstWhere(
            (participant) => participant['id'] != userId,
            orElse: () => {'id': '', 'name': ''}
          );

          if (otherUser['id'].isEmpty) {
            print('No other user found for chat: ${chatDoc.id}');
            continue;
          }
          
          print('Found other user: ${otherUser['id']} - ${otherUser['name']}');

          // Lấy tin nhắn gần nhất
          final lastMessageQuery = await chatDoc.reference
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (lastMessageQuery.docs.isEmpty) {
            print('No messages for chat: ${chatDoc.id}');
            continue;
          }

          final lastMessage = ChatMessage.fromFirestore(lastMessageQuery.docs.first);
          print('Last message: ${lastMessage.text}');

          // Đếm tin nhắn chưa đọc
          final unreadQuery = await chatDoc.reference
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('read', isEqualTo: false)
              .get();

          chatList.add({
            'chatId': chatDoc.id,
            'otherUserId': otherUser['id'],
            'otherUserName': otherUser['name'],
            'lastMessage': lastMessage,
            'unreadCount': unreadQuery.docs.length,
          });
          
          print('Added chat to list: ${chatDoc.id}');
        } catch (e) {
          print('Error processing chat document ${chatDoc.id}: $e');
          // Tiếp tục xử lý các cuộc trò chuyện khác
          continue;
        }
      }

      // Sắp xếp theo thời gian tin nhắn gần nhất
      if (chatList.isNotEmpty) {
        chatList.sort((a, b) {
          final aTime = (a['lastMessage'] as ChatMessage).timestamp;
          final bTime = (b['lastMessage'] as ChatMessage).timestamp;
          return bTime.compareTo(aTime);
        });
      }
      
      print('Returning ${chatList.length} chats');
      return chatList;
    } catch (e) {
      print('Error getting chat list: $e');
      return [];
    }
  }

  // Lấy thông tin participants từ một cuộc trò chuyện
  Future<Map<String, String>> getChatParticipants(String userId1, String userId2) async {
    try {
      final chatId = _getChatId(userId1, userId2);
      
      final chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();
      
      if (!chatDoc.exists || !chatDoc.data()!.containsKey('participants')) {
        throw Exception('Chat does not exist or does not have participants field');
      }
      
      final participantsData = chatDoc.get('participants');
      Map<String, String> result = {};
      
      if (participantsData is List) {
        for (var participant in participantsData) {
          if (participant is Map && participant.containsKey('id') && participant.containsKey('name')) {
            result[participant['id']] = participant['name'];
          }
        }
      }
      
      return result;
    } catch (e) {
      print('Error getting chat participants: $e');
      return {};
    }
  }
}