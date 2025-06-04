import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _errorMessage;
  String? _resolutionError;
  String? _priceError;
  List<File> _billingImages = [];
  
  static const int MAX_IMAGES = 5;

  @override
  void dispose() {
    _resolutionController.dispose();
    _priceController.dispose();
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

  void _validatePrice() {
    setState(() {
      final String value = _priceController.text;
      
      // If there are billing images, price is required
      if (_billingImages.isNotEmpty && value.isEmpty) {
        _priceError = 'Vui lòng nhập giá khi có hóa đơn';
        return;
      }
      
      // If price is provided, validate it
      if (value.isNotEmpty) {
        final double? price = double.tryParse(value.replaceAll(',', ''));
        if (price == null) {
          _priceError = 'Giá không hợp lệ';
          return;
        }
        
        if (price <= 1000) {
          _priceError = 'Giá phải lớn hơn 0';
          return;
        }
        
        if (price > 999999999) {
          _priceError = 'Giá quá lớn';
          return;
        }
      }
      
      _priceError = null;
    });
  }

  bool _validateAllFields() {
    _validateResolution();
    _validatePrice();
    return _resolutionError == null && _priceError == null;
  }  Future<void> _pickImages() async {
    if (_billingImages.length >= MAX_IMAGES) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Chỉ được chọn tối đa $MAX_IMAGES ảnh',
        isError: true,
      );
      return;
    }

    try {
      final int remainingSlots = MAX_IMAGES - _billingImages.length;
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty) {
        final int imagesToAdd = images.length > remainingSlots ? remainingSlots : images.length;
        
        setState(() {
          // Only add images up to the remaining slots
          for (int i = 0; i < imagesToAdd; i++) {
            _billingImages.add(File(images[i].path));
          }
        });
        
        // Show warning if user selected more images than available slots
        if (images.length > remainingSlots) {
          DialogHelper.showSnackBar(
            context: context,
            message: 'Chỉ có thể thêm $remainingSlots ảnh nữa. $imagesToAdd ảnh đã được thêm.',
            isError: false,
          );
        }
        
        // Validate price after adding images
        _validatePrice();
      }
    } catch (e) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Lỗi khi chọn ảnh: $e',
        isError: true,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _billingImages.removeAt(index);
    });
    // Validate price after removing images
    _validatePrice();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
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

          // Billing images section
          _buildBillingImagesSection(),
          const SizedBox(height: 16),

          // Price field (shows only when there are billing images)
          if (_billingImages.isNotEmpty) ...[
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  final int? value = int.tryParse(newValue.text);
                  if (value == null) return oldValue;
                  return TextEditingValue(
                    text: value.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    ),
                    selection: TextSelection.collapsed(
                      offset: value.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},',
                      ).length,
                    ),
                  );
                }),
              ],
              onChanged: (_) => _validatePrice(),
              decoration: InputDecoration(
                labelText: 'Giá (VND) *',
                hintText: 'Nhập giá hóa đơn',
                border: const OutlineInputBorder(),
                errorText: _priceError,
                suffixText: 'VND',
              ),
            ),
            const SizedBox(height: 16),
          ],

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
            ),          const SizedBox(height: 16),
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
                child: const Text(
                  'Xác nhận giải quyết', 
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),],
        ),
      ),
    );
  }
  Widget _buildBillingImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [        Row(
          children: [
            Expanded(
              child: Text(
                'Ảnh hóa đơn (tùy chọn) - Tối đa ${MAX_IMAGES} ảnh',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _billingImages.length >= MAX_IMAGES ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate, size: 20),
              label: Text(
                _billingImages.length >= MAX_IMAGES ? 'Đã đầy' : 'Thêm',
                style: const TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),const SizedBox(height: 8),
        if (_billingImages.isNotEmpty) ...[
          Container(
            height: 100,
            width: double.infinity,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _billingImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _billingImages[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Chưa có ảnh hóa đơn nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ],
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

      // Parse price if provided
      double? price;
      if (_priceController.text.isNotEmpty) {
        price = double.tryParse(_priceController.text.replaceAll(',', ''));
      }

      final result = await _incidentReportService.resolveIncidentReport(
        reportId: widget.report['reportId'],
        resolutionDetails: _resolutionController.text,
        billingImages: _billingImages.isNotEmpty ? _billingImages : null,
        price: price,
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