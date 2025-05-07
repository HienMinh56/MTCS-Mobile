import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/incident_report_service.dart';
import '../../utils/dialog_helper.dart';
import 'package:image_picker/image_picker.dart';

class BillingImagesDialog extends StatefulWidget {
  final String reportId;
  final Function() onImagesUploaded;

  const BillingImagesDialog({
    Key? key,
    required this.reportId,
    required this.onImagesUploaded,
  }) : super(key: key);

  @override
  State<BillingImagesDialog> createState() => _BillingImagesDialogState();
}

class _BillingImagesDialogState extends State<BillingImagesDialog> {
  final IncidentReportService _incidentReportService = IncidentReportService();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;

  // Hằng số giới hạn số lượng ảnh
  static const int MAX_IMAGES_PER_UPLOAD = 5;

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      // For gallery, allow picking multiple images with smart limit handling
      final List<XFile> pickedImages = await _picker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedImages.isNotEmpty) {
        final List<File> images = pickedImages.map((image) => File(image.path)).toList();

        // Check if adding these images would exceed the limit
        if (_selectedImages.length + images.length > MAX_IMAGES_PER_UPLOAD) {
          setState(() {
            _errorMessage = 'Không được chọn quá $MAX_IMAGES_PER_UPLOAD ảnh';

            // Only add images up to the limit
            if (_selectedImages.length < MAX_IMAGES_PER_UPLOAD) {
              final int remainingSlots = MAX_IMAGES_PER_UPLOAD - _selectedImages.length;
              _selectedImages.addAll(images.take(remainingSlots));
              _errorMessage = 'Đã thêm $remainingSlots ảnh (tối đa $MAX_IMAGES_PER_UPLOAD ảnh)';
            }
          });
        } else {
          setState(() {
            _selectedImages.addAll(images);
            _errorMessage = null; // Clear error if any
          });
        }
      }
    } else {
      // For camera, keep single image capture
      if (_selectedImages.length >= MAX_IMAGES_PER_UPLOAD) {
        setState(() {
          _errorMessage = 'Đã đạt giới hạn tối đa $MAX_IMAGES_PER_UPLOAD ảnh';
        });
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _errorMessage = null;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      width: double.infinity,
      child: Column(
        children: [
          AppBar(
            title: const Text('Thêm ảnh hóa đơn'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: _selectedImages.isEmpty
                ? Center(
                    child: Text(
                      'Không có ảnh nào được chọn',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn từ thư viện'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Đã chọn ${_selectedImages.length}/$MAX_IMAGES_PER_UPLOAD ảnh',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _selectedImages.isEmpty
                        ? null
                        : () => _showConfirmDialog(),
                    child: const Text(
                      'Tải lên',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _uploadBillingImages() async {
    if (_selectedImages.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng chọn ít nhất một ảnh hóa đơn';
      });
      return;
    }

    if (_selectedImages.length > MAX_IMAGES_PER_UPLOAD) {
      setState(() {
        _errorMessage = 'Không được tải lên quá $MAX_IMAGES_PER_UPLOAD ảnh';
      });
      return;
    }

    try {
      DialogHelper.showLoadingDialog(context: context, message: 'Đang tải lên...');

      final result = await _incidentReportService.uploadBillingImages(
        reportId: widget.reportId,
        images: _selectedImages,
      );

      // Close the loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result['status'] == 1) {
        // Close the dialog
        Navigator.pop(context);

        // Show success message
        DialogHelper.showSnackBar(
          context: context,
          message: 'Tải lên ảnh hóa đơn thành công',
          isError: false,
        );

        // Call the callback to reload data
        widget.onImagesUploaded();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Không thể tải lên ảnh. Vui lòng thử lại sau.';
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

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận tải lên'),
          content: const Text(
              'Sau khi gửi, bạn sẽ không thể cập nhật hoặc thêm ảnh hóa đơn nữa. Bạn có chắc chắn muốn tải lên các ảnh này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadBillingImages();
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }
}

// Helper class to show the dialog
class BillingImagesDialogHelper {
  static void show({
    required BuildContext context,
    required String reportId,
    required Function() onImagesUploaded,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: BillingImagesDialog(
          reportId: reportId,
          onImagesUploaded: onImagesUploaded,
        ),
      ),
    );
  }
}