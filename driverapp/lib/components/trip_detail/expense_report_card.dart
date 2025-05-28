import 'package:flutter/material.dart';
import '../../utils/color_constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/number_formatter.dart';
import '../../services/expense_type_manager.dart';
import '../../models/expense_report_type.dart';

class ExpenseReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final bool isTripEnded;
  final Function(String) onShowFullImage;
  final Function(Map<String, dynamic>)? onEditReport;

  const ExpenseReportCard({
    Key? key,
    required this.report,
    required this.isTripEnded,
    required this.onShowFullImage,
    this.onEditReport,
  }) : super(key: key);  String getReportTypeName(String reportTypeId) {
    // Sử dụng ExpenseTypeManager để lấy thông tin loại báo cáo chi phí từ API
    final expenseTypeManager = ExpenseTypeManager();
    final reportTypes = expenseTypeManager.getAllExpenseReportTypes();
    
    // Nếu chưa có dữ liệu từ ExpenseTypeManager, trả về giá trị mặc định
    if (reportTypes.isEmpty) {
      return 'Chi phí khác';
    }
    
    // Tìm loại báo cáo chi phí phù hợp từ danh sách
    final reportType = reportTypes.firstWhere(
      (type) => type.reportTypeId == reportTypeId,
      orElse: () => ExpenseReportType(
        reportTypeId: reportTypeId,
        reportType: 'Chi phí khác', // Giá trị mặc định nếu không tìm thấy
        isActive: 1
      )
    );
    
    // Trả về tên loại báo cáo chi phí
    return reportType.reportType;
  }

  @override
  Widget build(BuildContext context) {
    final String reportTypeName = getReportTypeName(report['reportTypeId'] ?? 'other');
    final bool isPaymentDone = report['isPay'] == 1;

    // Lấy danh sách file ảnh từ đúng key
    final List files = report['expenseReportFiles'] ?? report['expenseReportFile'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with colored accent
          Container(
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt,
                  color: ColorConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportTypeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormatter.formatDateTimeFromString(report['reportTime']),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ColorConstants.primaryColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${NumberFormatter.formatCurrency(report['cost'])} đ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,              children: [
                // Trạng thái thanh toán
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Trạng thái',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPaymentDone ? Icons.check_circle : Icons.pending,
                            color: isPaymentDone ? Colors.green : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isPaymentDone ? 'Đã thanh toán' : 'Chưa thanh toán',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isPaymentDone ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Địa điểm
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.lightBlue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Địa điểm',
                          style: TextStyle(
                            color: Colors.lightBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report['location'] ?? 'N/A',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Description if available
                if (report['description'] != null && report['description'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    report['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Images section
                if (files.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.photo_library, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Hình ảnh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: files.length,
                      itemBuilder: (context, index) {
                        final file = files[index];
                        return GestureDetector(
                          onTap: () {
                            if (file is Map<String, dynamic> && file.containsKey('fileUrl')) {
                              onShowFullImage(file['fileUrl']);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                file['fileUrl'] ?? '',
                                fit: BoxFit.cover,
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
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        children: [
                          Icon(Icons.no_photography, color: Colors.grey, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Không có hình ảnh',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Edit button - only if trip not ended and onEditReport is provided
                if (!isTripEnded && onEditReport != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () => onEditReport!(report),
                        icon: const Icon(Icons.edit),
                        label: const Text('Chỉnh sửa báo cáo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}