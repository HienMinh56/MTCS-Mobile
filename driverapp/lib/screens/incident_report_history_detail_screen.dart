import 'package:flutter/material.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:driverapp/components/status_header.dart';
import 'package:driverapp/components/info_card.dart';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/status_utils.dart';
import 'package:driverapp/utils/date_formatter.dart';

class IncidentReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> report;

  const IncidentReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi Tiết Báo Cáo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildDescriptionCard(),
            if (report['incidentReportsFiles'] != null && 
                (report['incidentReportsFiles'] as List).isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildImagesCard(context),
            ],
            if (report['handledBy'] != null) ...[
              const SizedBox(height: 16),
              _buildResolutionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor = StatusUtils.getStatusColor(report['status']);
    IconData statusIcon = StatusUtils.getStatusIcon(report['status']);

    return StatusHeader(
      title: 'Trạng thái: ${report['status'] == 'Resolved' ? 'Đã xử lý' : 'Đang xử lý'}',
      subtitle: 'Cập nhật: ${DateFormatter.formatDateTimeFromString(report['createdDate'])}',
      icon: statusIcon,
      color: statusColor,
    );
  }
  Widget _buildInfoCard(BuildContext context) {
    final int type = int.tryParse(report['type']?.toString() ?? '1') ?? 1;
    final int? vehicleType = report['vehicleType'] != null
        ? int.tryParse(report['vehicleType'].toString())
        : null;
    final double price = double.tryParse(report['price']?.toString() ?? '0') ?? 0;
    final int isPay = int.tryParse(report['isPay']?.toString() ?? '0') ?? 0;

    return InfoCard(
      title: 'Thông tin sự cố',
      children: [
        InfoRow(label: 'Mã báo cáo:', value: report['reportId'] ?? ''),
        InfoRow(label: 'Mã chuyến đi:', value: report['tripId'] ?? ''),
        InfoRow(label: 'Loại sự cố:', value: report['incidentType'] ?? ''),
        InfoRow(label: 'Type:', value: _getTypeText(type)),
        InfoRow(label: 'Loại phương tiện:', value: _getVehicleTypeText(vehicleType)),
        InfoRow(label: 'Vị trí:', value: report['location'] ?? ''),
        InfoRow(
          label: 'Thời gian xảy ra:',
          value: DateFormatter.formatDateTimeFromString(report['incidentTime']),
        ),
        InfoRow(label: 'Người báo cáo:', value: report['reportedBy'] ?? ''),
        // Chỉ hiển thị giá tiền khi price > 0
        if (price > 0) ...[
          InfoRow(
            label: 'Giá:', 
            value: '${price.toStringAsFixed(0)} VND'
          ),
          InfoRow(
            label: 'Trạng thái thanh toán:', 
            value: _getPaymentStatusText(isPay)
          ),
        ],
      ],
    );
  }

  String _getTypeText(int type) {
    switch (type) {
      case 1: return 'Có thể sửa';
      case 2: return 'Cần hỗ trợ loại 1';
      case 3: return 'Cần hỗ trợ loại 2';
      default: return 'Không xác định';
    }
  }
  String _getVehicleTypeText(int? vehicleType) {
    if (vehicleType == null) return 'Không có';
    switch (vehicleType) {
      case 1: return 'Đầu kéo';
      case 2: return 'Rơ móc';
      default: return 'Không xác định';
    }
  }

  String _getPaymentStatusText(int isPay) {
    switch (isPay) {
      case 0: return 'Chưa thanh toán';
      case 1: return 'Đã thanh toán';
      default: return 'Không xác định';
    }
  }

  Widget _buildDescriptionCard() {
    return InfoCard(
      title: 'Mô tả sự cố',
      children: [
        Text(
          report['description'] ?? '',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildImagesCard(BuildContext context) {
    final List incidentReportsFiles = report['incidentReportsFiles'] ?? [];
    
    // Nhóm hình ảnh theo loại
    Map<int, List> filesByType = {};
    
    for (var file in incidentReportsFiles) {
      int type = int.tryParse(file['type']?.toString() ?? '1') ?? 1;
      if (!filesByType.containsKey(type)) {
        filesByType[type] = [];
      }
      filesByType[type]!.add(file);
    }
    
    return InfoCard(
      title: 'Hình ảnh',
      children: [
        if (incidentReportsFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: Text('Không có hình ảnh')),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiển thị ảnh sự cố (type 1)
              if (filesByType.containsKey(1) && filesByType[1]!.isNotEmpty) ...[
                _buildImageSectionHeader(
                  title: 'Ảnh sự cố',
                  icon: Icons.camera_alt,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildImageList(filesByType[1]!, context),
                const SizedBox(height: 16),
              ],
              
              // Hiển thị ảnh hóa đơn (type 2)
              if (filesByType.containsKey(2) && filesByType[2]!.isNotEmpty) ...[
                _buildImageSectionHeader(
                  title: 'Ảnh hóa đơn',
                  icon: Icons.receipt,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(height: 8),
                _buildImageList(filesByType[2]!, context),
                const SizedBox(height: 16),
              ],
              
              // Hiển thị ảnh trao đổi (type 3)
              if (filesByType.containsKey(3) && filesByType[3]!.isNotEmpty) ...[
                _buildImageSectionHeader(
                  title: 'Ảnh trao đổi',
                  icon: Icons.sync_alt,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 8),
                _buildImageList(filesByType[3]!, context),
                const SizedBox(height: 16),
              ],
              
              // Hiển thị các ảnh khác nếu có
              if (incidentReportsFiles.any((file) {
                int type = int.tryParse(file['type']?.toString() ?? '1') ?? 1;
                return type > 3 || type < 1;
              })) ...[
                _buildImageSectionHeader(
                  title: 'Hình ảnh khác',
                  icon: Icons.image,
                  color: Colors.grey,
                ),
                const SizedBox(height: 8),
                _buildImageList(
                  incidentReportsFiles.where((file) {
                    int type = int.tryParse(file['type']?.toString() ?? '1') ?? 1;
                    return type > 3 || type < 1;
                  }).toList(),
                  context
                ),
              ],
            ],
          ),
      ],
    );
  }
  
  // Helper method để xây dựng danh sách hình ảnh
  Widget _buildImageList(List files, BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return GestureDetector(
            onTap: () => _showFullImage(context, file),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      file['fileUrl'] ?? '',
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Helper method để hiển thị ảnh đầy đủ
  void _showFullImage(BuildContext context, Map<String, dynamic> file) {
    ImageUtils.showFullImageDialog(
      context, 
      file['fileUrl'] ?? '',
      title: file['fileName'] ?? '',
      description: file['description'] ?? 'Không có mô tả',
    );
  }
  
  Widget _buildImageSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionCard() {
    return InfoCard(
      title: 'Thông tin xử lý',
      children: [
        InfoRow(
          label: 'Người xử lý:',
          value: report['handledBy'] ?? 'Chưa có',
        ),
        InfoRow(
          label: 'Thời gian xử lý:',
          value: report['handledTime'] != null
              ? DateFormatter.formatDateTimeFromString(report['handledTime'])
              : 'Chưa có',
        ),
        if (report['resolutionDetails'] != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Chi tiết xử lý:',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            report['resolutionDetails'] ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ],
    );
  }
}
