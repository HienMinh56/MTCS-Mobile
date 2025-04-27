import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driverapp/models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseUrl = 'https://mtcs-server.azurewebsites.net//api/Chat'; // Thay đổi URL theo API của bạn

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

  // Gửi tin nhắn mới và đảm bảo cuộc trò chuyện được khởi tạo đúng
  Future<bool> sendMessage(String senderId, String senderName, String receiverId, String receiverName, String message) async {
    try {
      final chatId = _getChatId(senderId, receiverId);
      
      // Kiểm tra xem chat document đã tồn tại chưa
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      // Nếu chưa tồn tại, tạo chat document với thông tin participants
      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'createdAt': FieldValue.serverTimestamp(),
          'participants': [
            {'id': senderId, 'name': senderName},
            {'id': receiverId, 'name': receiverName}
          ],
          'lastActivity': FieldValue.serverTimestamp(),
        });
      }
      
      // Tạo tin nhắn mới
      final newMessage = {
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'text': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };
      
      // Lưu tin nhắn vào Firestore
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(newMessage);
      
      // Cập nhật lastActivity cho chat document
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({'lastActivity': FieldValue.serverTimestamp()});
      
      // Gửi thông báo qua API (nếu cần) - Ghi chú giúp gỡ lỗi
      // Tránh việc gửi ở đây vì có thể dẫn đến tin nhắn trùng lặp
      // Backend đã xử lý Firestore trigger để gửi thông báo
      try {
        // Đoạn mã này chỉ ghi log cho mục đích debug, không thực sự gửi API request
        print('API notification would be sent to: $receiverId (skipped to avoid duplication)');
        
        // Chỉ gửi request nếu cần thiết (đặt code back nếu muốn gửi lại)
        /*
        await http.post(
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
        */
      } catch (apiError) {
        // Ghi log lỗi API nhưng không ảnh hưởng đến việc gửi tin nhắn
        print('API notification error: $apiError');
      }

      return true;
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
          print('Error processing chat document for unread count: $e');
          continue;
        }
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
      // Truy vấn tất cả các cuộc trò chuyện có thể chứa userId
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
          
          // Chuyển đổi dữ liệu participants sang danh sách
          List<Map<String, dynamic>> participants = [];
          if (participantsData is List) {
            participants = List<Map<String, dynamic>>.from(
              participantsData.map((item) => item is Map ? Map<String, dynamic>.from(item) : {'id': '', 'name': ''})
            );
          } else {
            print('Participants is not a list for chat: ${chatDoc.id}');
            continue;
          }
          
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
          print('Error processing chat document ${chatDoc.id}: $e');
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
      print('Error getting chat list: $e');
      return [];
    }
  }

  // Lấy thông tin participants từ một cuộc trò chuyện
  Future<Map<String, String>> getChatParticipants(String userId1, String userId2) async {
    try {
      final chatId = _getChatId(userId1, userId2);
      print('Attempting to get participants for chat ID: $chatId');
      print('UserID1: $userId1, UserID2: $userId2');
      print('Participants data: $chatId');
      
      final chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();
      
      print('Chat document exists: ${chatDoc.exists}');
      if (chatDoc.exists) {
        print('Chat data: ${chatDoc.data()}');
      }
      
      // Nếu chat document không tồn tại hoặc không có trường participants, 
      // trả về map rỗng thay vì ném ra exception
      if (!chatDoc.exists || !chatDoc.data()!.containsKey('participants')) {
        print('Chat does not exist or does not have participants field, returning empty map');
        // Thử tìm kiếm chat với ID khác
        print('Trying to find chat manually by querying all chats...');
        final allChats = await _firestore.collection('chats').get();
        for (var doc in allChats.docs) {
          print('Checking chat: ${doc.id}');
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
                print('Found matching chat with different ID: ${doc.id}');
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
        print('Participants is a list with ${participantsData.length} items');
        for (var participant in participantsData) {
          if (participant is Map) {
            // Hỗ trợ các định dạng khác nhau của dữ liệu participants
            final id = participant['id'] ?? participant['userId'] ?? '';
            final name = participant['name'] ?? participant['fullName'] ?? '';
            
            print('Extracted participant: id=$id, name=$name');
            if (id.isNotEmpty) {
              result[id] = name;
            }
          }
        }
      } else {
        print('Participants is not a list: ${participantsData.runtimeType}');
      }
      
      print('Returning participant map: $result');
      return result;
    } catch (e) {
      print('Error getting chat participants: $e');
      return {}; // Trả về map rỗng trong trường hợp có lỗi
    }
  }
}