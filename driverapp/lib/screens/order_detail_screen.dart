import 'package:flutter/material.dart';
import 'package:driverapp/services/order_service.dart';
import 'package:driverapp/utils/formatters.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/section_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              _getFileIcon(file['fileType']),
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['fileName'] ?? 'Tệp đính kèm',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (file['description'] != null && file['description'].toString().isNotEmpty)
                    Text(
                      file['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, size: 20),
                  tooltip: 'Tải về',
                  onPressed: () => _downloadFile(file['fileUrl'], file['fileName']),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_browser, size: 20),
                  tooltip: 'Mở trong trình duyệt',
                  onPressed: () => _openFileUrl(file['fileUrl']),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
  
  Future<void> _downloadFile(String? url, String? fileName) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải về tệp này')),
      );
      return;
    }

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần quyền lưu trữ để tải tệp')),
      );
      return;
    }

    bool downloading = true;
    double progress = 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Đang tải ${fileName ?? 'tệp'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 10),
                  Text('${(progress * 100).toInt()}%'),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    downloading = false;
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final Directory? appDocDir = await getExternalStorageDirectory();
      if (appDocDir == null) {
        throw 'Không thể truy cập thư mục lưu trữ';
      }
      
      String savePath = '${appDocDir.path}/${fileName ?? 'downloaded_file'}';
      
      if (!savePath.contains('.') && url.contains('.')) {
        final extension = url.split('.').last.split('?').first;
        savePath = '$savePath.$extension';
      }
      
      Dio dio = Dio();
      
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              progress = received / total;
            });
            
            if (downloading && mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Đang tải ${fileName ?? 'tệp'}'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 10),
                        Text('${(progress * 100).toInt()}%'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Hủy'),
                        onPressed: () {
                          downloading = false;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
        },
      );
      
      if (downloading && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fileName ?? 'Tệp'} đã tải thành công'),
            action: SnackBarAction(
              label: 'Mở',
              onPressed: () async {
                final file = File(savePath);
                if (file.existsSync()) {
                  final Uri uri = Uri.file(savePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (downloading && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải xuống: $e')),
        );
      }
    }
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
    
    final Uri uri = Uri.parse(url);
    
    if (preview) {
      _showPreviewDialog(url);
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở liên kết')),
        );
      }
    }
  }
  
  void _showPreviewDialog(String url) {
    final bool isImage = url.toLowerCase().endsWith('.jpg') || 
                          url.toLowerCase().endsWith('.jpeg') || 
                          url.toLowerCase().endsWith('.png') ||
                          url.toLowerCase().endsWith('.gif');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Xem trước tài liệu',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_browser),
                        tooltip: 'Mở trong trình duyệt',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openFileUrl(url);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: isImage
                      ? Image.network(
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
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.article_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text('Không thể xem trước định dạng này'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _openFileUrl(url);
                                },
                                child: const Text('Mở trong trình duyệt'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
