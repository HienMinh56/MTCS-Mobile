import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

class IncidentReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool isTripEnded;
  final Function(String) onShowFullImage;
  final Function(Map<String, dynamic>)? onEditReport;
  final Function(Map<String, dynamic>)? onResolveReport;
  final Function(Map<String, dynamic>)? onAddBillingImages;
  final Function(Map<String, dynamic>)? onAddExchangeImages;

  const IncidentReportCard({
    Key? key,
    required this.report,
    required this.isTripEnded,
    required this.onShowFullImage,
    this.onEditReport,
    this.onResolveReport,
    this.onAddBillingImages,
    this.onAddExchangeImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert incident type to int for badge coloring
    final int incidentTypeValue = int.tryParse(report['type']?.toString() ?? '1') ?? 1;
    final String incidentTypeName = _getIncidentTypeName(incidentTypeValue);
    
    // Check if vehicle type is available
    final bool hasVehicleType = report['vehicleType'] != null;
    
    // Get vehicle type info if available
    final int vehicleTypeValue = hasVehicleType ? 
        (int.tryParse(report['vehicleType'].toString()) ?? 1) : 1;
    final String vehicleTypeName = vehicleTypeValue == 1 ? 'Xe kéo' : 'Rơ moóc';
    
    // Choose badge color based on type
    final Color typeBadgeColor = incidentTypeValue == 2 ? Colors.orange : Colors.blue;
    final Color vehicleTypeBadgeColor = vehicleTypeValue == 1 ? Colors.green : Colors.purple;
    
    // Check if billing or exchange images already exist
    final bool hasBillingImages = _checkImageTypeExists(report['incidentReportsFiles'], 2);
    final bool hasExchangeImages = _checkImageTypeExists(report['incidentReportsFiles'], 3);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with colored strip or badge showing status and type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: report['status'] == 'Resolved' ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${report['reportId']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: report['status'] == 'Resolved' ? Colors.green.shade800 : Colors.orange.shade800,
                        fontSize: 16,
                      ),
                    ),
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: report['status'] == 'Resolved' 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12), 
                        border: Border.all(
                          color: report['status'] == 'Resolved' ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        report['status'] == 'Resolved' ? 'Đã giải quyết' : 'Chưa giải quyết',
                        style: TextStyle(
                          color: report['status'] == 'Resolved' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Type badges row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Vehicle type badge - only show if vehicle type is available
                    if (hasVehicleType)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: vehicleTypeBadgeColor.withOpacity(0.1),
                          border: Border.all(color: vehicleTypeBadgeColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              vehicleTypeValue == 1 ? Icons.local_shipping : Icons.add_box,
                              size: 12,
                              color: vehicleTypeBadgeColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              vehicleTypeName,
                              style: TextStyle(
                                fontSize: 11,
                                color: vehicleTypeBadgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Incident type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeBadgeColor.withOpacity(0.1),
                        border: Border.all(color: typeBadgeColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            incidentTypeValue == 2 ? Icons.build : Icons.warning,
                            size: 12,
                            color: typeBadgeColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            incidentTypeName,
                            style: TextStyle(
                              fontSize: 11,
                              color: typeBadgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Loại sự cố:', report['incidentType'] ?? 'N/A'),
                _buildInfoRow('Mô tả:', report['description'] ?? 'N/A'),
                _buildInfoRow(
                  'Thời gian xảy ra:',
                  DateFormatter.formatDateTimeFromString(report['incidentTime']),
                ),
                _buildInfoRow('Địa điểm:', report['location'] ?? 'N/A'),
                
                // Status with colored indicator
                Row(
                  children: [
                    Text(
                      'Trạng thái:', 
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report['status'] == 'Resolved' 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12), 
                      ),
                      child: Text(
                        report['status'] == 'Resolved' ? 'Đã giải quyết' : 'Chưa giải quyết',
                        style: TextStyle(
                          color: report['status'] == 'Resolved' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                if (report['resolutionDetails'] != null &&
                    report['resolutionDetails'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  _buildInfoRow(
                    'Giải pháp:',
                    report['resolutionDetails'],
                  ),
                ],

                if (report['handledBy'] != null &&
                    report['handledBy'].toString().isNotEmpty)
                  _buildInfoRow('Người xử lý:', report['handledBy']),

                if (report['handledTime'] != null)
                  _buildInfoRow(
                    'Thời gian xử lý:',
                    DateFormatter.formatDateTimeFromString(
                        report['handledTime']),
                  ),

                if (report['incidentReportsFiles'] != null) ...[
                  const SizedBox(height: 12),
                  
                  // Group images by type
                  ..._buildImageSections(report['incidentReportsFiles']),
                ],
              ],
            ),
          ),
                
          // Buttons section - only if not resolved and callbacks are provided
          if (report['status'] != 'Resolved')
            Column(
              children: [
                const Divider(height: 24, thickness: 1),
                // First row of buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Edit button
                    if (onEditReport != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ElevatedButton.icon(
                            onPressed: () => onEditReport!(report),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                    
                    // Add Billing Images button - only show if no billing images exist
                    if (onAddBillingImages != null && !hasBillingImages)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ElevatedButton.icon(
                            onPressed: () => onAddBillingImages!(report),
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('Thêm hóa đơn', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                    
                    // Placeholder empty container when billing images already exist
                    if (onAddBillingImages != null && hasBillingImages)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: ElevatedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Đã thêm hóa đơn', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              disabledBackgroundColor: Colors.grey.shade200,
                              disabledForegroundColor: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Second row with Exchange Images button - only show if no exchange images exist
                if (onAddExchangeImages != null && !hasExchangeImages)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10.0, left: 6.0, right: 6.0),
                    child: ElevatedButton.icon(
                      onPressed: () => onAddExchangeImages!(report),
                      icon: const Icon(Icons.sync_alt, size: 18),
                      label: const Text(
                        'Thêm ảnh trao đổi',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                
                // Placeholder button when exchange images already exist
                if (onAddExchangeImages != null && hasExchangeImages)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10.0, left: 6.0, right: 6.0),
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text(
                        'Đã thêm ảnh trao đổi',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade700,
                      ),
                    ),
                  ),
                
                // Third row with Resolve button
                if (onResolveReport != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10.0, left: 6.0, right: 6.0, bottom: 10.0),
                    child: ElevatedButton.icon(
                      onPressed: () => onResolveReport!(report),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Giải quyết',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Check if images of a specific type already exist
  bool _checkImageTypeExists(List? files, int typeToCheck) {
    if (files == null || files.isEmpty) return false;
    
    return files.any((file) {
      int type = int.tryParse(file['type']?.toString() ?? '0') ?? 0;
      return type == typeToCheck;
    });
  }

  // Helper method to build image sections grouped by type
  List<Widget> _buildImageSections(List incidentReportsFiles) {
    // Group files by type
    Map<int, List> filesByType = {};
    
    for (var file in incidentReportsFiles) {
      int type = int.tryParse(file['type']?.toString() ?? '1') ?? 1;
      if (!filesByType.containsKey(type)) {
        filesByType[type] = [];
      }
      filesByType[type]!.add(file);
    }
    
    List<Widget> sections = [];
    
    // Incident images (type 1)
    if (filesByType.containsKey(1) && filesByType[1]!.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSectionHeader(
              title: 'Ảnh sự cố',
              icon: Icons.camera_alt,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildImageList(filesByType[1]!),
            const SizedBox(height: 16),
          ],
        )
      );
    }
    
    // Billing images (type 2)
    if (filesByType.containsKey(2) && filesByType[2]!.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSectionHeader(
              title: 'Ảnh hóa đơn',
              icon: Icons.receipt,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 8),
            _buildImageList(filesByType[2]!),
            const SizedBox(height: 16),
          ],
        )
      );
    }
    
    // Exchange images (type 3)
    if (filesByType.containsKey(3) && filesByType[3]!.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSectionHeader(
              title: 'Ảnh trao đổi',
              icon: Icons.sync_alt,
              color: Colors.indigo,
            ),
            const SizedBox(height: 8),
            _buildImageList(filesByType[3]!),
            const SizedBox(height: 16),
          ],
        )
      );
    }
    
    // If no images with recognized types
    if (sections.isEmpty && incidentReportsFiles.isNotEmpty) {
      sections.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSectionHeader(
              title: 'Hình ảnh',
              icon: Icons.image, 
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildImageList(incidentReportsFiles),
          ],
        )
      );
    } else if (incidentReportsFiles.isEmpty) {
      sections.add(
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Không có hình ảnh', style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        )
      );
    }
    
    return sections;
  }
  
  // Helper method to build image section header
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
  
  // Helper method to build image list
  Widget _buildImageList(List files) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return GestureDetector(
            onTap: () => onShowFullImage(file['fileUrl']),
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
                      file['fileUrl'],
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
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
                          const Center(
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to convert incident type to readable text
  String _getIncidentTypeName(int incidentType) {
    switch (incidentType) {
      case 1:
        return 'Có thể sửa';
      case 2:
        return 'Cần hỗ trợ loại 1';
      case 3:
        return 'Cần hỗ trợ loại 2';
      default:
        return 'Khác';
    }
  }
}