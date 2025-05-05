import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/models/chat_message.dart';
import 'package:driverapp/utils/api_utils.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _chatEndpoint = '/api/Chat';

  // Lấy chat ID dựa trên 2 userId
  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_${userId2}'
        : '${userId2}_${userId1}';
  }
  
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

  // Gửi tin nhắn mới sử dụng API
  Future<bool> sendMessage(String senderId, String senderName, String receiverId, String receiverName, String message) async {
    try {
      // Gửi tin nhắn qua API
      final response = await ApiUtils.post(
        '$_chatEndpoint/send',
        {
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message
        },
      );
      
      
      // Kiểm tra response
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
        .update({
          'read': true,
          'readAt': FieldValue.serverTimestamp(), // Thêm timestamp khi đọc để hiển thị thời gian đã xem
        });
  }

  // Đếm số tin nhắn chưa đọc
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      // Lấy tất cả các chat documents
      final querySnapshot = await _firestore
          .collection('chats')
          .get();

      int count = 0;

      for (final chatDoc in querySnapshot.docs) {
        try {
          // Kiểm tra xem tài liệu chat có trường participants không
          if (!chatDoc.exists || !chatDoc.data().containsKey('participants')) {
            continue;
          }
          
          // Lấy thông tin participants
          final participantsData = chatDoc.get('participants');
          if (participantsData == null) {
            continue;
          }
          
          // Chuyển đổi dữ liệu participants sang danh sách
          List<Map<String, dynamic>> participants = [];
          if (participantsData is List) {
            participants = List<Map<String, dynamic>>.from(
              participantsData.map((item) => item is Map ? Map<String, dynamic>.from(item) : {'id': '', 'name': ''})
            );
          } else {
            continue;
          }
          
          // Kiểm tra xem người dùng hiện tại có trong danh sách participants không
          final isUserInChat = participants.any((participant) => 
            participant['id'] == userId);
          
          if (!isUserInChat) {
            continue;
          }

          // Đếm tin nhắn chưa đọc - chỉ đếm chính xác những tin nhắn gửi đến userId và chưa đọc
          final messagesQuery = await chatDoc.reference
              .collection('messages')
              .where('receiverId', isEqualTo: userId)
              .where('read', isEqualTo: false)
              .get();

          count += messagesQuery.docs.length;
        } catch (e) {
          continue;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  // Lấy danh sách các cuộc trò chuyện
  Future<List<Map<String, dynamic>>> getChatList(String userId) async {
    try {
      // Truy vấn tất cả các cuộc trò chuyện có thể chứa userId
      final querySnapshot = await _firestore
          .collection('chats')
          .get();
      
      
      List<Map<String, dynamic>> chatList = [];

      for (final chatDoc in querySnapshot.docs) {
        try {
          print('Processing chat: ${chatDoc.id}');
          // Kiểm tra xem tài liệu chat có trường participants không
          if (!chatDoc.exists || !chatDoc.data().containsKey('participants')) {
            continue;
          }
          
          // Lấy thông tin participants
          final participantsData = chatDoc.get('participants');
          if (participantsData == null) {
            continue;
          }
          
          // Chuyển đổi dữ liệu participants sang danh sách
          List<Map<String, dynamic>> participants = [];
          if (participantsData is List) {
            participants = List<Map<String, dynamic>>.from(
              participantsData.map((item) => item is Map ? Map<String, dynamic>.from(item) : {'id': '', 'name': ''})
            );
          } else {
            continue;
          }
          
          // Kiểm tra xem người dùng hiện tại có trong danh sách participants không
          final isUserInChat = participants.any((participant) => 
            participant['id'] == userId);
          
          if (!isUserInChat) {
            continue;
          }
          
          // Lấy thông tin của người tham gia còn lại
          final otherUser = participants.firstWhere(
            (participant) => participant['id'] != userId,
            orElse: () => {'id': '', 'name': ''}
          );

          if (otherUser['id'].isEmpty) {
            continue;
          }
          
          // Lấy tin nhắn gần nhất
          final lastMessageQuery = await chatDoc.reference
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (lastMessageQuery.docs.isEmpty) {
            continue;
          }

          final lastMessage = ChatMessage.fromFirestore(lastMessageQuery.docs.first);
          
          // Đếm tin nhắn chưa đọc - chỉ đếm chính xác những tin nhắn gửi đến userId và chưa đọc
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
        } catch (e) {
          continue;
        }
      }

      // Sắp xếp theo thời gian tin nhắn gần nhất
      chatList.sort((a, b) {
        final aTime = (a['lastMessage'] as ChatMessage).timestamp;
        final bTime = (b['lastMessage'] as ChatMessage).timestamp;
        return bTime.compareTo(aTime);
      });
      
      return chatList;
    } catch (e) {
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
      
      
      // Nếu chat document không tồn tại hoặc không có trường participants, 
      // trả về map rỗng thay vì ném ra exception
      if (!chatDoc.exists || !chatDoc.data()!.containsKey('participants')) {
        // Thử tìm kiếm chat với ID khác
        final allChats = await _firestore.collection('chats').get();
        for (var doc in allChats.docs) {
          if (doc.data().containsKey('participants')) {
            final parts = doc.get('participants');
            if (parts is List) {
              bool hasUser1 = false;
              bool hasUser2 = false;
              for (var part in parts) {
                if (part is Map && part.containsKey('id')) {
                  if (part['id'] == userId1) hasUser1 = true;
                  if (part['id'] == userId2) hasUser2 = true;
                }
              }
              if (hasUser1 && hasUser2) {
                // Nếu tìm thấy, trả về thông tin participants
                Map<String, String> result = {};
                for (var participant in parts) {
                  if (participant is Map) {
                    final id = participant['id'] ?? participant['userId'] ?? '';
                    final name = participant['name'] ?? participant['fullName'] ?? '';
                    if (id.isNotEmpty) {
                      result[id] = name;
                    }
                  }
                }
                return result;
              }
            }
          }
        }
        return {}; // Trả về map rỗng nếu vẫn không tìm thấy
      }
      
      final participantsData = chatDoc.get('participants');
      Map<String, String> result = {};
      
      if (participantsData is List) {
        for (var participant in participantsData) {
          if (participant is Map) {
            // Hỗ trợ các định dạng khác nhau của dữ liệu participants
            final id = participant['id'] ?? participant['userId'] ?? '';
            final name = participant['name'] ?? participant['fullName'] ?? '';
            
            if (id.isNotEmpty) {
              result[id] = name;
            }
          }
        }
      } else {
        return {};
      }
      
      return result;
    } catch (e) {
      return {}; 
    }
  }
}