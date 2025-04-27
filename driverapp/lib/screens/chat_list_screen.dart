import 'package:driverapp/models/chat_message.dart';
import 'package:driverapp/models/staff.dart';
import 'package:driverapp/screens/chat_screen.dart';
import 'package:driverapp/services/chat_service.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/services/staff_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ChatListScreen extends StatefulWidget {
  final String userId;

  const ChatListScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final ProfileService _profileService = ProfileService();
  
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;
  String _userName = ""; // Store the current user's name
  
  // Danh sách các stream subscription để hủy khi không cần thiết
  final List<StreamSubscription> _chatSubscriptions = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChatList();
  }

  @override
  void dispose() {
    // Hủy tất cả các subscription khi widget bị hủy
    for (var subscription in _chatSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getDriverProfile(widget.userId);
      setState(() {
        _userName = profile.fullName;
      });
    } catch (e) {
      // If we can't get the user's name, use the ID as a fallback
      setState(() {
        _userName = "Tài xế ${widget.userId}";
      });
    }
  }
  
  Future<void> _loadChatList() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatList = await _chatService.getChatList(widget.userId);
      
      setState(() {
        _chatList = chatList;
        _isLoading = false;
      });
      
      // Hủy các subscription cũ trước khi tạo mới
      for (var subscription in _chatSubscriptions) {
        subscription.cancel();
      }
      _chatSubscriptions.clear();
      
      // Đăng ký lắng nghe tin nhắn cho mỗi cuộc trò chuyện
      for (var chat in chatList) {
        final otherUserId = chat['otherUserId'];
        
        // Đăng ký stream lắng nghe tin nhắn mới
        final subscription = _chatService.getMessages(widget.userId, otherUserId)
            .listen((messages) {
          if (messages.isNotEmpty) {
            // Cập nhật danh sách chat khi có tin nhắn mới
            _updateChatListWithNewMessage(otherUserId, messages.first);
          }
        });
        
        _chatSubscriptions.add(subscription);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải danh sách chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Cập nhật danh sách chat khi có tin nhắn mới
  void _updateChatListWithNewMessage(String otherUserId, ChatMessage latestMessage) {
    // Tìm vị trí của cuộc hội thoại trong danh sách
    final chatIndex = _chatList.indexWhere((chat) => chat['otherUserId'] == otherUserId);
    
    if (chatIndex != -1) {
      setState(() {
        final currentChat = _chatList[chatIndex];
        final currentLastMessage = currentChat['lastMessage'] as ChatMessage;
        
        // Chỉ cập nhật nếu tin nhắn này mới hơn tin nhắn hiện tại
        if (latestMessage.timestamp.isAfter(currentLastMessage.timestamp)) {
          // Cập nhật tin nhắn mới nhất
          _chatList[chatIndex]['lastMessage'] = latestMessage;
          
          // Chỉ cập nhật số lượng tin nhắn chưa đọc nếu:
          // 1. Tin nhắn gửi đến người dùng hiện tại
          // 2. Tin nhắn chưa đọc
          // 3. Tin nhắn đến từ người dùng này (otherUserId), không phải cuộc hội thoại khác
          if (latestMessage.receiverId == widget.userId && 
              !latestMessage.read && 
              latestMessage.senderId == otherUserId) {
            _chatList[chatIndex]['unreadCount'] = (_chatList[chatIndex]['unreadCount'] ?? 0) + 1;
          }
          
          // Sắp xếp lại danh sách dựa trên tin nhắn mới nhất
          _chatList.sort((a, b) {
            final aTime = (a['lastMessage'] as ChatMessage).timestamp;
            final bTime = (b['lastMessage'] as ChatMessage).timestamp;
            return bTime.compareTo(aTime);
          });
        }
      });
    } else {
      // Nếu là cuộc hội thoại mới, tải lại toàn bộ danh sách
      _loadChatList();
    }
  }
  
  // Phương thức để tải danh sách nhân viên hỗ trợ
  Future<List<Staff>> _loadStaffList() async {
    try {
      final StaffService staffService = StaffService();
      return await staffService.getStaffList();
    } catch (e) {
      print('Lỗi khi tải danh sách nhân viên: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trò chuyện'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có cuộc trò chuyện nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChatList,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: _chatList.length,
                    itemBuilder: (context, index) {
                      final chat = _chatList[index];
                      final lastMessage = chat['lastMessage'] as ChatMessage;
                      final isUnread = lastMessage.receiverId == widget.userId && !lastMessage.read;
                      
                      // Tính thời gian hiển thị
                      String timeText = DateFormat('dd/MM/yyyy HH:mm').format(lastMessage.timestamp);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          elevation: 2,
                          shadowColor: Colors.blue.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isUnread 
                                ? BorderSide(color: Colors.blue.shade300, width: 1.5)
                                : BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.blue.withOpacity(0.1),
                            highlightColor: Colors.blue.withOpacity(0.05),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    userId: widget.userId,
                                    userName: _userName,
                                    otherUserId: chat['otherUserId'],
                                    otherUserName: chat['otherUserName'],
                                  ),
                                ),
                              ).then((_) {
                                // Reload chat list when returning from chat screen
                                _loadChatList();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade300,
                                          Colors.blue.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(27.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.support_agent,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Nội dung tin nhắn
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chat['otherUserName'],
                                                style: TextStyle(
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                  fontSize: 16,
                                                  color: isUnread ? Colors.black : Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isUnread 
                                                    ? Colors.blue.shade50
                                                    : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(10),
                                                border: isUnread
                                                    ? Border.all(color: Colors.blue.shade200)
                                                    : null,
                                              ),
                                              child: Text(
                                                timeText,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                                  color: isUnread ? Colors.blue.shade800 : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                lastMessage.text,
                                                style: TextStyle(
                                                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                                  color: isUnread ? Colors.black87 : Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (chat['unreadCount'] > 0)
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue.withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 24,
                                                  minHeight: 24,
                                                ),
                                                child: Text(
                                                  chat['unreadCount'].toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Hiển thị dialog để nhập ID người dùng muốn chat
          _showNewChatDialog();
        },
        child: const Icon(Icons.chat),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _showNewChatDialog() {
    TextEditingController searchController = TextEditingController();
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 500,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: Colors.blue,
                        width: double.infinity,
                        child: const Column(
                          children: [
                            Icon(
                              Icons.groups_outlined,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Chọn nhân viên để trò chuyện',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm nhân viên...',
                            prefixIcon: const Icon(Icons.search, color: Colors.blue),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<Staff>>(
                          future: _loadStaffList(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Đang tải danh sách nhân viên...'),
                                  ],
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Lỗi khi tải danh sách nhân viên:\n${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Không có nhân viên nào',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            // Lọc danh sách nhân viên theo từ khóa tìm kiếm
                            final filteredStaff = snapshot.data!.where((staff) {
                              return staff.fullName.toLowerCase().contains(searchQuery) ||
                                  staff.email.toLowerCase().contains(searchQuery);
                            }).toList();
                            
                            if (filteredStaff.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Không tìm thấy nhân viên phù hợp',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            // Hiển thị danh sách nhân viên
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  child: Card(
                                    elevation: 2,
                                    shadowColor: Colors.blue.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Colors.blue.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(15),
                                      splashColor: Colors.blue.withOpacity(0.1),
                                      highlightColor: Colors.blue.withOpacity(0.05),
                                      onTap: () {
                                        Navigator.pop(context);
                                        
                                        // Chuyển đến màn hình chat với nhân viên được chọn
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              userId: widget.userId,
                                              userName: _userName,
                                              otherUserId: staff.userId,
                                              otherUserName: staff.fullName,
                                            ),
                                          ),
                                        ).then((_) {
                                          _loadChatList();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 55,
                                              height: 55,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.blue.shade300,
                                                    Colors.blue.shade600,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(27.5),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.support_agent,
                                                  size: 28,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    staff.fullName,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.email_outlined,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          staff.email,
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 14,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.chat_outlined,
                                                size: 20,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: const Text(
                                'Hủy',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }
}