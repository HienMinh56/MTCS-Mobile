import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/fuel_report_service.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/image_utils.dart';
import '../../utils/validation_utils.dart';

class EditFuelReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function() onReportUpdated;
  final Function(String) onShowFullScreenImage;

  const EditFuelReportDialog({
    Key? key,
    required this.report,
    required this.onReportUpdated,
    required this.onShowFullScreenImage,
  }) : super(key: key);

  @override
  State<EditFuelReportDialog> createState() => _EditFuelReportDialogState();
}

class _EditFuelReportDialogState extends State<EditFuelReportDialog> {
  // Services
  final FuelReportService _fuelReportService = FuelReportService();

  // Form controllers
  late TextEditingController amountController;
  late TextEditingController costController;
  late TextEditingController locationController;

  // Lists for tracking file changes
  List<String> fileIdsToRemove = [];
  List<File> addedFiles = [];

  // Validation error states
  String? _amountError;
  String? _costError;
  String? _locationError;
  String? _imagesError;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    final refuelAmount = widget.report['refuelAmount'];
    final fuelCost = widget.report['fuelCost'];
    
    // Định dạng số để loại bỏ .0 nếu là số nguyên
    String formatNumber(dynamic value) {
      if (value == null) return '';
      if (value is int) return value.toString();
      if (value is double) {
        // Loại bỏ phần thập phân .0 nếu là số nguyên
        return value % 1 == 0 ? value.toInt().toString() : value.toString();
      }
      return value.toString();
    }
    
    amountController = TextEditingController(
      text: formatNumber(refuelAmount),
    );
    costController = TextEditingController(
      text: formatNumber(fuelCost),
    );
    locationController = TextEditingController(
      text: widget.report['location'] ?? '',
    );

    // Add listeners for validation on change
    amountController.addListener(_validateAmount);
    costController.addListener(_validateCost);
    locationController.addListener(_validateLocation);
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    amountController.removeListener(_validateAmount);
    costController.removeListener(_validateCost);
    locationController.removeListener(_validateLocation);

    // Dispose controllers to prevent memory leaks
    amountController.dispose();
    costController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateAmount() {
    setState(() {
      _amountError = ValidationUtils.validateFuelAmount(amountController.text);
    });
  }

  void _validateCost() {
    setState(() {
      _costError = ValidationUtils.validateFuelCost(costController.text);
    });
  }

  void _validateLocation() {
    setState(() {
      _locationError = ValidationUtils.validateLocation(locationController.text);
    });
  }

  void _validateImages() {
    final List<dynamic> allImages = [];

    // Count existing images that are not marked for deletion
    final existingFiles = widget.report['fuelReportFiles'] as List? ?? [];
    for (final file in existingFiles) {
      if (!fileIdsToRemove.contains(file['fileId'].toString())) {
        allImages.add(file);
      }
    }

    // Add all newly added images
    allImages.addAll(addedFiles);

    setState(() {
      _imagesError = ValidationUtils.validateImages(allImages);
    });
  }

  // Validate all fields at once and return whether all are valid
  bool _validateAllFields() {
    _validateAmount();
    _validateCost();
    _validateLocation();
    _validateImages();

    return _amountError == null &&
        _costError == null &&
        _locationError == null &&
        _imagesError == null;
  }

  // Method to update the fuel report
  Future<void> _updateFuelReport() async {
    // Validate all fields before proceeding
    if (!_validateAllFields()) {
      // // Show a message about validation errors
      // DialogHelper.showSnackBar(
      //   context: context,
      //   message: 'Vui lòng kiểm tra lại thông tin nhập vào',
      //   isError: true,
      // );
      return;
    }

    // Hiển thị dialog xác nhận trước khi lưu
    final bool confirmResult = await DialogHelper.showConfirmDialog(
      context: context,
      title: 'Xác nhận',
      content: 'Bạn có chắc chắn muốn lưu những thay đổi này?',
      confirmText: 'Lưu thay đổi',
      cancelText: 'Hủy',
    );

    // Nếu người dùng không xác nhận, không thực hiện cập nhật
    if (!confirmResult) {
      return;
    }

    try {
      DialogHelper.showLoadingDialog(context: context, message: 'Đang cập nhật...');

      // Parse the input values
      final double amountValue = double.tryParse(amountController.text) ?? 0.0;
      final double costValue = double.tryParse(costController.text) ?? 0.0;

      // Call the API service to update the report
      final result = await _fuelReportService.updateFuelReport(
        reportId: widget.report['reportId'],
        refuelAmount: amountValue,
        fuelCost: costValue,
        location: locationController.text,
        fileIdsToRemove: fileIdsToRemove,
        addedFiles: addedFiles,
      );

      // Close the loading dialog
      Navigator.pop(context);

      // Check if the update was successful
      if (result['status'] == 200) {
        // Close the edit dialog
        Navigator.pop(context);

        // Show success message
        DialogHelper.showSnackBar(
          context: context,
          message: 'Cập nhật báo cáo thành công',
          isError: false
        );

        // Call the callback to reload data
        widget.onReportUpdated();
      } else {
        // Show error message
        DialogHelper.showInformationDialog(
          context: context,
          title: 'Lỗi',
          content: result['message'] ?? 'Không thể cập nhật báo cáo. Vui lòng thử lại sau.',
        );
      }
    } catch (e) {
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      DialogHelper.showInformationDialog(
        context: context,
        title: 'Lỗi',
        content: 'Đã xảy ra lỗi: $e',
      );
    }
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
            'Chỉnh sửa báo cáo đổ xăng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Số lượng (lít)',
              border: const OutlineInputBorder(),
              errorText: _amountError,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: costController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Chi phí (đồng)',
              border: const OutlineInputBorder(),
              errorText: _costError,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: locationController,
            decoration: InputDecoration(
              labelText: 'Địa điểm',
              border: const OutlineInputBorder(),
              errorText: _locationError,
            ),
          ),

          // Display existing images with delete option
          if (widget.report['fuelReportFiles'] != null &&
              (widget.report['fuelReportFiles'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hình ảnh hiện có',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fileIdsToRemove.isNotEmpty)
                  Text(
                    'Đã chọn ${fileIdsToRemove.length} hình để xóa',
                    style: const TextStyle(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (widget.report['fuelReportFiles'] as List).length,
                itemBuilder: (context, index) {
                  final file = widget.report['fuelReportFiles'][index];
                  final String fileId = file['fileId'].toString();
                  final bool isSelected = fileIdsToRemove.contains(fileId);

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => widget.onShowFullScreenImage(file['fileUrl']),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? Colors.red : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(
                              file['fileUrl'],
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
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                fileIdsToRemove.remove(fileId);
                              } else {
                                fileIdsToRemove.add(fileId);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.red : Colors.grey,
                              ),
                            ),
                            child: Icon(
                              isSelected ? Icons.close : Icons.delete_outline,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          // Display newly added images section
          if (addedFiles.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hình ảnh mới thêm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${addedFiles.length} ảnh',
                  style: const TextStyle(
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: addedFiles.length,
                itemBuilder: (context, index) {
                  final File file = addedFiles[index];

                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.shade300,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 10,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              addedFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (_imagesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _imagesError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),

          // Add image buttons
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final image = await ImageUtils.takePhoto();
                  if (image != null) {
                    setState(() {
                      addedFiles.add(image);
                      _validateImages();
                    });
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp ảnh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final images = await ImageUtils.pickMultipleImages();
                  if (images.isNotEmpty) {
                    setState(() {
                      addedFiles.addAll(images);
                      _validateImages();
                    });
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn từ thư viện'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  foregroundColor: Colors.amber.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Hủy'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _updateFuelReport,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Phương thức tiện ích để hiển thị dialog
class EditFuelReportDialogHelper {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> report,
    required Function() onReportUpdated,
    required Function(String) onShowFullScreenImage,
  }) {
    DialogHelper.showCustomDialog(
      context: context,
      child: EditFuelReportDialog(
        report: report,
        onReportUpdated: onReportUpdated,
        onShowFullScreenImage: onShowFullScreenImage,
      ),
    );
  }
}