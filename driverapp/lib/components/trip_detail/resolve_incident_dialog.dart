import 'package:flutter/material.dart';
import '../../services/incident_report_service.dart';
import '../../utils/dialog_helper.dart';

class ResolveIncidentDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function() onReportResolved;

  const ResolveIncidentDialog({
    Key? key,
    required this.report,
    required this.onReportResolved,
  }) : super(key: key);

  @override
  State<ResolveIncidentDialog> createState() => _ResolveIncidentDialogState();
}

class _ResolveIncidentDialogState extends State<ResolveIncidentDialog> {
  final IncidentReportService _incidentReportService = IncidentReportService();
  final TextEditingController _resolutionController = TextEditingController();
  String? _errorMessage;
  String? _resolutionError;

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  void _validateResolution() {
    setState(() {
      final String value = _resolutionController.text;
      
      if (value.isEmpty) {
        _resolutionError = 'Vui lòng nhập chi tiết giải pháp';
        return;
      }
      
      // Trim value to remove leading/trailing whitespace
      final String trimmedValue = value.trim();
      
      // Check if original value starts with whitespace
      if (value.startsWith(' ')) {
        _resolutionError = 'Không được bắt đầu bằng khoảng trắng';
        return;
      }
      
      // Check if first character is a special character
      if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
        _resolutionError = 'Không được bắt đầu bằng ký tự đặc biệt';
        return;
      }
      
      // Check length after trimming
      if (trimmedValue.length < 5) {
        _resolutionError = 'Chi tiết giải pháp quá ngắn (tối thiểu 5 ký tự)';
        return;
      }
      
      // Check maximum length
      if (trimmedValue.length > 500) {
        _resolutionError = 'Chi tiết giải pháp quá dài (tối đa 500 ký tự)';
        return;
      }
      
      _resolutionError = null;
    });
  }

  bool _validateAllFields() {
    _validateResolution();
    return _resolutionError == null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giải quyết sự cố',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Mã báo cáo: #${widget.report['reportId']}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          
          // Incident type and description section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Incident type
                Text(
                  'Loại sự cố:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.report['incidentType'] ?? 'Không xác định',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                // Incident description
                Text(
                  'Nội dung sự cố:',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.report['description'] ?? 'Không có mô tả',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Resolution details field
          TextField(
            controller: _resolutionController,
            maxLines: 4,
            onChanged: (_) => _validateResolution(),
            decoration: InputDecoration(
              labelText: 'Chi tiết giải pháp',
              hintText: 'Nhập cách bạn đã giải quyết sự cố này',
              border: const OutlineInputBorder(),
              errorText: _resolutionError,
            ),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 20),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _resolveIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Xác nhận giải quyết'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolveIncident() async {
    if (!_validateAllFields()) {
      return;
    }

    // Hiển thị dialog xác nhận trước khi giải quyết
    final bool confirmResult = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xác nhận',
      content: 'Sau khi xác nhận giải quyết, báo cáo sẽ được đánh dấu là đã hoàn thành và không thể chỉnh sửa.',
      confirmText: 'Xác nhận giải quyết',
      cancelText: 'Hủy',
    );

    if (!confirmResult) {
      return;
    }

    try {
      DialogHelper.showLoadingDialog(context: context, message: 'Đang xử lý...');

      final result = await _incidentReportService.resolveIncidentReport(
        reportId: widget.report['reportId'],
        resolutionDetails: _resolutionController.text,
        resolutionImages: null,
      );

      // Close the loading dialog
      Navigator.pop(context);

      if (result['status'] == 200 || result['status'] == 1) {
        // Close the dialog
        Navigator.pop(context);

        // Show success message
        DialogHelper.showSnackBar(
          context: context,
          message: 'Sự cố đã được giải quyết thành công',
          isError: false,
        );

        // Call the callback to reload data
        widget.onReportResolved();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Không thể giải quyết sự cố. Vui lòng thử lại sau.';
        });
      }
    } catch (e) {
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    }
  }
}

// Helper class to show the dialog
class ResolveIncidentDialogHelper {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> report,
    required Function() onReportResolved,
  }) {
    DialogHelper.showCustomDialog(
      context: context,
      child: ResolveIncidentDialog(
        report: report,
        onReportResolved: onReportResolved,
      ),
    );
  }
}