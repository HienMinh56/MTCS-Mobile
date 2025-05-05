import 'package:flutter/material.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/section_card.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: Text('Chi tiết đơn hàng: ${_orderDetails?['orderId'] ?? ''}'),
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
              InfoRow(label: 'Mã đơn:', value: _orderDetails!['orderId'] ?? 'N/A'),
              InfoRow(label: 'Mã vận chuyển:', value: _orderDetails!['trackingCode'] ?? 'N/A'),
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
              InfoRow(label: 'Ước lượng thời gian hoàn thành:', value: _orderDetails!['completionTime']),
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
  
  Future<void> _openFileUrl(String? url) async {
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
      
      // Xử lý URL
      String formattedUrl = url;
      
      // Đảm bảo URL có giao thức
      if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
        formattedUrl = 'https://$formattedUrl';
      }
      
      // Đóng dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Luôn mở trong trình duyệt bên ngoài
      final Uri uri = Uri.parse(formattedUrl);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết. Vui lòng thử lại sau.')),
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
              onPressed: () => _openFileUrl(url),
            ),
          ),
        );
      }
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
}
