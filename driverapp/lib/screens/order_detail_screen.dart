import 'package:flutter/material.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/section_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart'; // Add this import for Dio
import 'dart:io';

class OrderDetailScreen extends StatefulWidget {
  final String tripId;

  const OrderDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _orderDetails;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load order details
      final orderDetails = await _orderService.getOrderByTripId(widget.tripId);

      if (mounted) {
        setState(() {
          _orderDetails = orderDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khi tải dữ liệu: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết Order: ${_orderDetails?['orderId'] ?? ''}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrderDetails,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _buildOrderContent(),
      ),
    );
  }

  Widget _buildOrderContent() {
    if (_orderDetails == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Thông tin Cơ bản',
            children: [
              InfoRow(label: 'Order ID:', value: _orderDetails!['orderId'] ?? 'N/A'),
              InfoRow(label: 'Tracking Code:', value: _orderDetails!['trackingCode'] ?? 'N/A'),
              InfoRow(label: 'Số Container:', value: _orderDetails!['containerNumber'] ?? 'N/A'),
              InfoRow(label: 'Giá:', value: CurrencyFormatter.formatVND(_orderDetails!['price'])),
              InfoRow(label: 'Loại:', value: _orderDetails!['deliveryType'] == 1 ? "Nhập" : "Xuất"),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Điểm Giao Nhận',
            children: [
              InfoRow(label: 'Điểm lấy hàng:', value: _orderDetails!['pickUpLocation'] ?? 'N/A'),
              InfoRow(label: 'Điểm giao hàng:', value: _orderDetails!['deliveryLocation'] ?? 'N/A'),
              InfoRow(label: 'Điểm trả rỗng:', value: _orderDetails!['conReturnLocation'] ?? 'N/A'),
              InfoRow(label: 'Khoảng cách:', value: '${_orderDetails!['distance']} km'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Thông tin Hàng Hóa',
            children: [
              InfoRow(label: 'Loại Container:', value: _getContainerType(_orderDetails!['containerType'])),
              InfoRow(label: 'Loại Giao Hàng:', value: _getDeliveryType(_orderDetails!['deliveryType'])),
              InfoRow(label: 'Nhiệt độ:', value: '${_orderDetails!['temperature']} °C'),
              InfoRow(label: 'Khối lượng:', value: '${_orderDetails!['weight']} tấn'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Thời Gian',
            children: [
              InfoRow(label: 'Ngày lấy hàng:', value: _formatDate(_orderDetails!['pickUpDate'])),
              InfoRow(label: 'Ngày giao hàng:', value: _formatDate(_orderDetails!['deliveryDate'])),
              InfoRow(label: 'Hoàn thành cần:', value: _orderDetails!['completionTime']),
            ],
          ),
          
          const SizedBox(height: 16),
          
          SectionCard(
            title: 'Thông tin Liên Hệ',
            children: [
              InfoRow(label: 'Người liên hệ:', value: _orderDetails!['contactPerson'] ?? 'N/A'),
              InfoRow(label: 'SĐT liên hệ:', value: _orderDetails!['contactPhone'] ?? 'N/A'),
              InfoRow(label: 'Người đặt hàng:', value: _orderDetails!['orderPlacer'] ?? 'N/A'),
            ],
          ),
          
          if (_orderDetails!['note'] != null && _orderDetails!['note'].toString().isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Ghi Chú',
                  children: [
                    InfoRow(label: '', value: _orderDetails!['note'] ?? 'Không có ghi chú'),
                  ],
                ),
              ],
            ),
            
          if (_orderDetails!['orderFiles'] != null && (_orderDetails!['orderFiles'] as List).isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Tài liệu đính kèm',
                  children: _buildFilesList(_orderDetails!['orderFiles']),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildFilesList(List<dynamic> files) {
    return files.map<Widget>((file) {
      // Extract file details
      final String fileName = file['fileName'] ?? 'Tệp đính kèm';
      final String? description = file['description'];
      final bool hasDescription = description != null && description.toString().isNotEmpty;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File header with icon and name
              Row(
                children: [
                  Icon(
                    _getFileIcon(file['fileType']),
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Description section if available
              if (hasDescription)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Preview button if file is an image
                    if (_isImageFile(file['fileUrl']))
                      TextButton.icon(
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Xem trước'),
                        onPressed: () => _openFileUrl(file['fileUrl'], preview: true),
                      ),
                    const SizedBox(width: 8),
                    // Open file button
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('Mở tệp'),
                      onPressed: () => _openFileUrl(file['fileUrl']),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
  
  // Helper method to check if a file is an image based on URL extension
  bool _isImageFile(String? url) {
    if (url == null || url.isEmpty) return false;
    
    final extension = url.split('.').last.split('?').first.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    
    final lowerType = fileType.toLowerCase();
    if (lowerType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerType.contains('image') || 
               lowerType.contains('jpg') || 
               lowerType.contains('jpeg') || 
               lowerType.contains('png')) {
      return Icons.image;
    } else if (lowerType.contains('doc') || lowerType.contains('document')) {
      return Icons.description;
    } else if (lowerType.contains('sheet') || lowerType.contains('excel')) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }
  
  Future<void> _openFileUrl(String? url, {bool preview = false}) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở tệp này')),
      );
      return;
    }
    
    try {
      // Hiển thị dialog đang tải
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang chuẩn bị liên kết...'),
              ],
            ),
          );
        },
      );
      
      // Xử lý URL Firebase
      String formattedUrl = url;
      
      // Kiểm tra xem URL có phải là URL Firebase Storage không
      bool isFirebaseStorage = formattedUrl.contains('firebasestorage.googleapis.com') || 
                              formattedUrl.contains('storage.googleapis.com');
      
      // Đảm bảo URL có giao thức
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      
      // Xử lý trường hợp đặc biệt cho URL Firebase Storage
      if (isFirebaseStorage) {
        // Đóng dialog
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Đối với Firebase Storage, chuyển hướng qua trình duyệt web
        final bool result = await _downloadAndOpen(formattedUrl);
        if (!result) {
          // Nếu không thể tải và mở, thử mở trực tiếp
          _openInExternalBrowser(formattedUrl);
        }
        return;
      }
      
      // Parse URL cho các URL không phải Firebase Storage
      final Uri uri = Uri.parse(formattedUrl);
      
      if (preview) {
        // Đóng dialog
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showPreviewDialog(url);
        return;
      }
      
      // Kiểm tra xem có thể mở URL không
      bool canLaunch = await canLaunchUrl(uri);
      
      // Đóng dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (canLaunch) {
        // Thử các phương pháp khác nhau để mở URL
        await _tryLaunchUrlWithMultipleMethods(uri);
      } else {
        // Hiển thị thông báo lỗi và cung cấp tùy chọn để mở trong trình duyệt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể mở liên kết trực tiếp'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Mở trong trình duyệt',
              onPressed: () => _openInExternalBrowser(formattedUrl),
            ),
          ),
        );
      }
    } catch (e) {
      // Đóng dialog nếu còn mở
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: () => _openFileUrl(url, preview: preview),
            ),
          ),
        );
      }
    }
  }
  
  // Hàm mới: Mở URL trong trình duyệt bên ngoài
  void _openInExternalBrowser(String url) async {
    if (url.isEmpty) return;

    try {
      // Sử dụng Intent để mở trình duyệt bên ngoài
      final Uri uri = Uri.parse(url);
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      
      if (!opened) {
        // Nếu không thể mở bằng ứng dụng không phải trình duyệt, thử với trình duyệt
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Hiển thị thông báo lỗi nếu không thể mở URL
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở trình duyệt: $e'),
          ),
        );
      }
    }
  }
  
  // Hàm mới: Thử nhiều cách khác nhau để mở URL
  Future<void> _tryLaunchUrlWithMultipleMethods(Uri uri) async {
    try {
      // Phương pháp 1: LaunchMode.platformDefault
      bool launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      
      if (!launched) {
        // Phương pháp 2: LaunchMode.externalApplication
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (!launched) {
          // Phương pháp 3: LaunchMode.externalNonBrowserApplication
          launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
          
          if (!launched) {
            // Phương pháp cuối cùng: LaunchMode.inAppWebView
            launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
            
            if (!launched) {
              throw Exception('Không thể mở URL sau khi thử tất cả các phương pháp');
            }
          }
        }
      }
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở URL: $e'),
            action: SnackBarAction(
              label: 'Mở trong trình duyệt',
              onPressed: () => _openInExternalBrowser(uri.toString()),
            ),
          ),
        );
      }
    }
  }
  
  // Hàm mới: Tải và mở tệp từ Firebase Storage
  Future<bool> _downloadAndOpen(String url) async {
    if (url.isEmpty) return false;
    
    try {
      // Hiển thị dialog đang tải
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tạo liên kết tạm thời...'),
            ],
          ),
        ),
      );
      
      // Tên tệp tạm thời
      final fileName = url.split('/').last.split('?').first;
      
      // Lấy thư mục tạm
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileName';
      
      // Tải tệp
      final Dio dio = Dio();
      await dio.download(url, tempPath);
      
      // Đóng dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Mở tệp đã tải
      final File file = File(tempPath);
      if (await file.exists()) {
        final Uri fileUri = Uri.file(tempPath);
        if (await canLaunchUrl(fileUri)) {
          return await launchUrl(fileUri);
        }
      }
      
      return false;
    } catch (e) {
      // Đóng dialog nếu còn mở
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải tệp: $e')),
        );
      }
      return false;
    }
  }
  
  void _showPreviewDialog(String? url) {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xem trước tệp này')),
      );
      return;
    }

    final extension = url.split('.').last.split('?').first.toLowerCase();
    final bool isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Xem trước tài liệu', style: TextStyle(fontSize: 16)),
                centerTitle: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: isImage
                    ? InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.error, color: Colors.red, size: 50)),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getFileIconByExtension(extension),
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('Không thể xem trước định dạng này'),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getFileIconByExtension(String? extension) {
    if (extension == null) return Icons.insert_drive_file;
    
    final ext = extension.toLowerCase();
    
    // Tài liệu văn bản
    if (ext == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx', 'odt', 'rtf'].contains(ext)) {
      return Icons.description;
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return Icons.table_chart;
    } else if (['ppt', 'pptx'].contains(ext)) {
      return Icons.slideshow;
    } else if (['txt', 'md'].contains(ext)) {
      return Icons.text_snippet;
    }
    
    // Hình ảnh
    else if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff'].contains(ext)) {
      return Icons.image;
    }
    
    // Audio/Video
    else if (['mp3', 'wav', 'ogg', 'flac'].contains(ext)) {
      return Icons.audio_file;
    } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv'].contains(ext)) {
      return Icons.video_file;
    }
    
    // Nén
    else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return Icons.folder_zip;
    }
    
    // Mặc định
    else {
      return Icons.insert_drive_file;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }
  
  String _getContainerType(int? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 1:
        return 'Container Thường';
      case 2:
        return 'Container Lạnh';
      default:
        return 'Loại $type';
    }
  }
  
  String _getDeliveryType(int? type) {
    if (type == null) return 'N/A';
    switch (type) {
      case 1:
        return 'Giao thẳng';
      case 2:
        return 'Giao kho';
      default:
        return 'Loại $type';
    }
  }
}
