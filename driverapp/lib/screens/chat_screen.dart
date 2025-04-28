import 'package:driverapp/models/chat_message.dart';
import 'package:driverapp/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.otherUserId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  
  // Thêm biến để lưu thông tin participants
  Map<String, String> _participants = {};
  
  // Thêm biến để theo dõi tin nhắn nào đang được chạm vào để hiển thị thời gian đã xem
  String? _selectedMessageId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadParticipantsInfo();
  }
  
  // Hàm mới để lấy thông tin participants từ collection chats
  Future<void> _loadParticipantsInfo() async {
    try {
      // Thiết lập giá trị mặc định trước (sử dụng giá trị từ widget)
      setState(() {
        _participants = {
          widget.userId: widget.userName,
          widget.otherUserId: widget.otherUserName,
        };
      });
      
      // Sau đó thử lấy thông tin participants từ Firestore (nếu có)
      final participants = await _chatService.getChatParticipants(widget.userId, widget.otherUserId);
      
      // Chỉ cập nhật state nếu kết quả không rỗng
      if (participants.isNotEmpty) {
        setState(() {
          _participants = participants;
        });
      } else {
        print('Using default participant info - chat may be new');
      }
    } catch (e) {
      print('Error loading participants info: $e, using default values');
      // Đã thiết lập giá trị mặc định ở trên, không cần làm gì thêm
    }
  }
  
  void _loadMessages() {
    _chatService.getMessages(widget.userId, widget.otherUserId).listen((messages) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      // Đánh dấu các tin nhắn chưa đọc là đã đọc
      _markMessagesAsRead();
    });
  }
  
  // Đánh dấu tất cả tin nhắn chưa đọc là đã đọc
  Future<void> _markMessagesAsRead() async {
    List<String> markedMessageIds = [];
    List<ChatMessage> updatedMessages = List.from(_messages);
    
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.receiverId == widget.userId && !message.read) {
        // Mark message as read in Firestore
        await _chatService.markMessageAsRead(
          widget.userId,
          widget.otherUserId,
          message.id,
        );
        markedMessageIds.add(message.id);
        
        // Update local message copy with read=true and current readAt time
        updatedMessages[i] = message.copyWith(
          read: true,
          readAt: DateTime.now(), // Set the current time as readAt
        );
      }
    }
    
    // Update the UI immediately after marking messages as read
    if (markedMessageIds.isNotEmpty) {
      setState(() {
        _messages = updatedMessages;
      });
    }
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // Sử dụng tên từ participants hoặc mặc định từ widget
      final senderName = _participants[widget.userId] ?? widget.userName;
      final receiverName = _participants[widget.otherUserId] ?? widget.otherUserName;
      
      // Thêm một biến để theo dõi xem đây là gửi tin nhắn đầu tiên hay không
      final isFirstMessage = _messages.isEmpty;
      
      final success = await _chatService.sendMessage(
        widget.userId,
        senderName,
        widget.otherUserId,
        receiverName,
        message,
      );
      
      if (success) {
        _messageController.clear();
        
        // Nếu đây là tin nhắn đầu tiên (không có tin nhắn trước đó), 
        // đợi thêm thời gian để Firestore cập nhật và tránh gửi tin nhắn trùng
        if (isFirstMessage) {
          // Tăng khoảng thời gian chờ để đảm bảo Firestore đã xử lý xong tin nhắn đầu tiên
          await Future.delayed(const Duration(milliseconds: 1000));
          _loadParticipantsInfo();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi tin nhắn'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        backgroundColor: Colors.blue[700],
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.support_agent,
                size: 20,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Nhân viên",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100]!.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(
                                    Icons.support_agent,
                                    size: 40,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Điều phối viên",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                 widget.otherUserName,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Hãy bắt đầu cuộc trò chuyện',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isSentByMe = message.senderId == widget.userId;
                            
                            // Kiểm tra xem có nên hiển thị timestamp không
                            bool showTimestamp = true;
                            if (index < _messages.length - 1) {
                              final prevMessage = _messages[index + 1];
                              // Nếu tin nhắn cách nhau ít hơn 5 phút và cùng người gửi, không hiển thị
                              if (message.timestamp.difference(prevMessage.timestamp).inMinutes < 5) {
                                showTimestamp = false;
                              }
                            } 
                            return Column(
                              crossAxisAlignment: isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (showTimestamp)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              blurRadius: 2,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _formatTimestamp(message.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[800],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: isSentByMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (!isSentByMe)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Colors.blue[100],
                                            child: Icon(
                                              Icons.support_agent,
                                              size: 16,
                                              color: Colors.blue[700],
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: () {
                                            // Khi chạm vào tin nhắn, cập nhật _selectedMessageId
                                            setState(() {
                                              // Nếu tin nhắn đã được chọn, bỏ chọn nó
                                              if (_selectedMessageId == message.id) {
                                                _selectedMessageId = null;
                                              } else {
                                                // Nếu chưa được chọn, đặt nó làm tin nhắn được chọn
                                                _selectedMessageId = message.id;
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSentByMe 
                                                  ? Colors.blue[700] 
                                                  : Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(18),
                                                topRight: const Radius.circular(18),
                                                bottomLeft: Radius.circular(
                                                    isSentByMe ? 18 : 4),
                                                bottomRight: Radius.circular(
                                                    isSentByMe ? 4 : 18),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              message.text,
                                              style: TextStyle(
                                                color: isSentByMe ? Colors.white : Colors.black87,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isSentByMe)
                                        Icon(
                                          message.read 
                                              ? Icons.done_all 
                                              : Icons.done,
                                          size: 16,
                                          color: message.read ? Colors.blue : Colors.grey,
                                        ),
                                    ],
                                  ),
                                ),
                                // Chỉ hiển thị thời gian đã xem khi:
                                // 1. Tin nhắn do người dùng hiện tại gửi
                                // 2. Tin nhắn đã được đọc và có thời gian đọc
                                // 3. Tin nhắn được chọn (người dùng đã chạm vào)
                                if (isSentByMe && message.read && message.readAt != null && _selectedMessageId == message.id)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0, bottom: 8.0, right: 8.0),
                                    child: Text(
                                      "Đã xem lúc ${DateFormat('HH:mm').format(message.readAt!)}",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[800]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: _isSending ? null : _sendMessage,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      mini: true,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}