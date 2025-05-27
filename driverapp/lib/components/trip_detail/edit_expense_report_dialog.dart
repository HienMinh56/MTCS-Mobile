import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/expense_report_service.dart';
import '../../services/expense_type_manager.dart';
import '../../models/expense_report_type.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/image_utils.dart';
import '../../utils/validation_utils.dart';

class EditExpenseReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function() onReportUpdated;
  final Function(String) onShowFullScreenImage;

  const EditExpenseReportDialog({
    Key? key,
    required this.report,
    required this.onReportUpdated,
    required this.onShowFullScreenImage,
  }) : super(key: key);

  @override
  State<EditExpenseReportDialog> createState() => _EditExpenseReportDialogState();
}

class _EditExpenseReportDialogState extends State<EditExpenseReportDialog> {
  // Services
  final ExpenseReportService _expenseReportService = ExpenseReportService();
    // Hằng số giới hạn số lượng ảnh
  static const int MAX_TOTAL_IMAGES = 10; // Tổng số ảnh tối đa

  // Form controllers
  late TextEditingController costController;
  late TextEditingController locationController;
  late TextEditingController descriptionController;
  
  // Expense Report Types
  List<ExpenseReportType> _reportTypes = [];
  late String _selectedReportTypeId;
  bool _isLoadingReportTypes = false;

  // Lists for tracking file changes
  List<String> fileIdsToRemove = [];
  List<File> addedFiles = [];
  
  // Store existing images
  List<Map<String, dynamic>> existingImages = [];

  // Validation error states
  String? _costError;
  String? _locationError;
  String? _descriptionError;
  String? _reportTypeError;
  String? _imagesError;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    final cost = widget.report['cost'];
    
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
    
    costController = TextEditingController(
      text: formatNumber(cost),
    );
    locationController = TextEditingController(
      text: widget.report['location'] ?? '',
    );
    descriptionController = TextEditingController(
      text: widget.report['description'] ?? '',
    );    // Initialize selected report type ID - không cho phép thay đổi loại chi phí
    _selectedReportTypeId = widget.report['reportTypeId'] ?? 'other';
    
    // Load expense report types (only for display purposes)
    _initReportTypes();
    
    // Process existing images
    _loadExistingImages();
  }

  @override
  void dispose() {
    costController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Load expense report types from manager or API
  Future<void> _initReportTypes() async {
    setState(() {
      _isLoadingReportTypes = true;
    });

    try {
      // Lấy dữ liệu từ ExpenseTypeManager đã được tải trước
      final expenseTypeManager = ExpenseTypeManager();
      final types = expenseTypeManager.getAllExpenseReportTypes();

      if (types.isNotEmpty) {
        setState(() {
          _reportTypes = types;
          _isLoadingReportTypes = false;
        });
      } else {
        // Nếu chưa có dữ liệu, tải từ API
        try {
          final freshTypes = await ExpenseReportService.getAllExpenseReportTypes();
          setState(() {
            _reportTypes = freshTypes;
            _isLoadingReportTypes = false;
          });
        } catch (e) {
          setState(() {
            _reportTypeError = 'Không thể tải loại báo cáo chi phí: $e';
            _isLoadingReportTypes = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _reportTypeError = 'Không thể tải loại báo cáo chi phí: $e';
        _isLoadingReportTypes = false;
      });
    }
  }

  // Load existing images from the report
  void _loadExistingImages() {
    // Lấy danh sách file ảnh từ đúng key
    final List files = widget.report['expenseReportFiles'] ?? widget.report['expenseReportFile'] ?? [];
    
    if (files.isNotEmpty) {
      for (var file in files) {
        if (file is Map<String, dynamic> && file.containsKey('fileUrl')) {
          existingImages.add(file);
        }
      }
    }
  }
  
  // Validation methods
  void _validateCost() {
    setState(() {
      _costError = ValidationUtils.validateExpenseCost(costController.text);
    });
  }

  void _validateLocation() {
    setState(() {
      _locationError = ValidationUtils.validateLocation(locationController.text);
    });
  }
  void _validateDescription() {
    setState(() {
      final String value = descriptionController.text;
      
      // Chỉ bắt buộc nhập mô tả khi chi phí là "other"
      if (_selectedReportTypeId == 'other' && value.isEmpty) {
        _descriptionError = 'Vui lòng nhập mô tả cho chi phí khác';
        return;
      }
      
      if (value.length > 500) {
        _descriptionError = 'Mô tả không được vượt quá 500 ký tự';
        return;
      }
      
      _descriptionError = null;
    });
  }
    void _validateReportType() {
    setState(() {
      // Vì loại chi phí không thể thay đổi và giá trị đã được thiết lập từ report gốc,
      // nên không cần kiểm tra lỗi
      _reportTypeError = null;
    });
  }
  
  void _validateImages() {
    setState(() {
      // Calculate total number of images (existing + new)
      final int totalImagesCount = existingImages.length - fileIdsToRemove.length + addedFiles.length;
      
      if (totalImagesCount > MAX_TOTAL_IMAGES) {
        _imagesError = 'Không được vượt quá $MAX_TOTAL_IMAGES ảnh';
        return;
      }
      
      _imagesError = null;
    });
  }
  
  bool _validateAllFields() {
    _validateCost();
    _validateLocation();
    _validateDescription();
    _validateReportType();
    _validateImages();
    
    return _costError == null &&
        _locationError == null &&
        _descriptionError == null &&
        _reportTypeError == null &&
        _imagesError == null;
  }

  // Method to add image from gallery or camera
  Future<void> _addImage(ImageSource source) async {
    try {
      List<File> newImages = [];
      
      if (source == ImageSource.gallery) {
        // Pick multiple images from gallery
        newImages = await ImageUtils.pickMultipleImages();
      } else {
        // Take a photo
        final File? newImage = await ImageUtils.takePhoto();
        if (newImage != null) {
          newImages = [newImage];
        }
      }
      
      // Calculate total images after adding new ones
      final int potentialTotalImages = existingImages.length - fileIdsToRemove.length + addedFiles.length + newImages.length;
      
      if (potentialTotalImages > MAX_TOTAL_IMAGES) {
        // Show error - too many images
        DialogHelper.showSnackBar(
          context: context,
          message: 'Không thể thêm ảnh. Tối đa $MAX_TOTAL_IMAGES ảnh.',
          isError: true,
        );
        return;
      }
      
      if (newImages.isNotEmpty) {
        setState(() {
          addedFiles.addAll(newImages);
        });
        _validateImages();
        
        // Show confirmation
        DialogHelper.showSnackBar(
          context: context,
          message: 'Đã thêm ${newImages.length} ảnh',
          isError: false,
        );
      }
    } catch (e) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Lỗi khi chọn ảnh: $e',
        isError: true,
      );
    }
  }
  
  // Method to remove an existing image
  void _removeExistingImage(int index) {
    final image = existingImages[index];
    final fileId = image['fileId'];
    
    setState(() {
      fileIdsToRemove.add(fileId);
    });
    
    _validateImages();
  }
  
  // Method to remove a newly added image
  void _removeNewImage(int index) {
    setState(() {
      addedFiles.removeAt(index);
    });
    
    _validateImages();
  }
  
  // Method to update the expense report
  Future<void> _updateExpenseReport() async {
    // Validate all fields before proceeding
    if (!_validateAllFields()) {
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

      // Parse the cost value
      final double costValue = double.tryParse(costController.text.replaceAll(',', '')) ?? 0.0;      // Call the API service to update the report
      // Sử dụng lại reportTypeId ban đầu từ widget.report để đảm bảo không thay đổi loại chi phí
      final result = await _expenseReportService.updateExpenseReport(
        reportId: widget.report['reportId'],
        reportTypeId: widget.report['reportTypeId'] ?? _selectedReportTypeId,
        cost: costValue,
        location: locationController.text,
        isPay: widget.report['isPay'] ?? 0,
        description: descriptionController.text,
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
      } else {        // Show error message
        DialogHelper.showInformationDialog(
          context: context,
          title: 'Lỗi',
          content: result['message'] ?? 'Không thể cập nhật báo cáo. Vui lòng thử lại sau.',
          confirmText: 'Đồng ý',
        );
      }
    } catch (e) {
      // Close the loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }      // Show error message
      DialogHelper.showInformationDialog(
        context: context,
        title: 'Lỗi',
        content: 'Đã xảy ra lỗi: $e',
        confirmText: 'Đồng ý',
      );
    }
  }
  
  // UI Helper Methods
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: Colors.blue[800]),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.blue) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      ),
    );
  }  Widget _buildReportTypeDropdown() {
    // Find the report type name for the selected ID
    String getReportTypeName() {
      if (_reportTypes.isEmpty) return 'Đang tải...';
      
      // Find the report type with matching ID
      for (var type in _reportTypes) {
        if (type.reportTypeId == _selectedReportTypeId) {
          return type.reportType;
        }
      }
      
      // If not found, return the ID itself
      return _selectedReportTypeId;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display non-editable expense type field
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Loại chi phí',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            helperText: 'Không thể thay đổi loại chi phí',
          ),
          child: Text(
            getReportTypeName(),
            style: TextStyle(color: Colors.blue[800], fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hình ảnh chứng từ', Icons.photo_library),
        
        // Error message if any
        if (_imagesError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              _imagesError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        
        // Add image buttons with improved styling
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn từ thư viện'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _addImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Chụp ảnh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Display existing images with improved styling
        if (existingImages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ảnh hiện tại:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: existingImages.length,
                  itemBuilder: (context, index) {
                    final image = existingImages[index];
                    final bool isMarkedForRemoval = fileIdsToRemove.contains(image['fileId']);
                    
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isMarkedForRemoval ? Colors.red : Colors.grey.shade300,
                              width: 1.5,
                            ),
                            boxShadow: isMarkedForRemoval ? null : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GestureDetector(
                              onTap: () {
                                if (!isMarkedForRemoval) {
                                  widget.onShowFullScreenImage(image['fileUrl']);
                                }
                              },
                              child: Opacity(
                                opacity: isMarkedForRemoval ? 0.5 : 1.0,
                                child: Image.network(
                                  image['fileUrl'],
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
                                        child: Icon(Icons.error, color: Colors.red, size: 32),
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Toggle remove button with improved styling
                        Positioned(
                          top: 5,
                          right: 17,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isMarkedForRemoval) {
                                  fileIdsToRemove.remove(image['fileId']);
                                } else {
                                  _removeExistingImage(index);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isMarkedForRemoval ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                isMarkedForRemoval ? Icons.add : Icons.close,
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
            ],
          ),
          
        // Display newly added images with improved styling
        if (addedFiles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ảnh mới thêm:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: addedFiles.length,
                  itemBuilder: (context, index) {
                    final file = addedFiles[index];
                    
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        
                        // Remove button with improved styling
                        Positioned(
                          top: 5,
                          right: 17,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(5),
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
            ],
          ),

        // Display image count
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Số lượng ảnh: ${existingImages.length - fileIdsToRemove.length + addedFiles.length}/$MAX_TOTAL_IMAGES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: (existingImages.length - fileIdsToRemove.length + addedFiles.length) >= MAX_TOTAL_IMAGES
                  ? Colors.red
                  : Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }  @override
  Widget build(BuildContext context) {
    final bool isOtherExpense = _selectedReportTypeId == 'other';
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 600, // Maximum width for better display on larger devices
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog title with improved styling
              const Center(
                child: Text(
                  'Chỉnh sửa báo cáo chi phí',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const Divider(thickness: 1.5, height: 36),
                // Report Type Display (Read-only)
              _buildSectionTitle('Loại chi phí (Chỉ xem)', Icons.category),
              _isLoadingReportTypes
                  ? const Center(child: CircularProgressIndicator())
                  : _buildReportTypeDropdown(),
              const SizedBox(height: 24),
              
              // Cost field
              _buildSectionTitle('Chi phí (VND)', Icons.monetization_on),
              _buildTextField(
                controller: costController,
                hintText: 'Nhập số tiền chi phí',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                errorText: _costError,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 24),
              
              // Location field
              _buildSectionTitle('Địa điểm', Icons.location_on),
              _buildTextField(
                controller: locationController,
                hintText: 'Nhập địa điểm phát sinh chi phí',
                prefixIcon: Icons.location_on,
                errorText: _locationError,
              ),
              const SizedBox(height: 24),
              
              // Description field - show required indicator only for 'other' type
              _buildSectionTitle(
                isOtherExpense ? 'Mô tả (bắt buộc)' : 'Mô tả',
                Icons.description
              ),
              _buildTextField(
                controller: descriptionController,
                hintText: isOtherExpense 
                    ? 'Vui lòng mô tả chi tiết về chi phí này...'
                    : 'Nhập chi tiết về chi phí (tùy chọn)...',
                maxLines: 3,
                errorText: _descriptionError,
              ),
              const SizedBox(height: 24),
              
              // Images section
              _buildImageSection(),
              const SizedBox(height: 28),
              
              // Action buttons with improved styling
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateExpenseReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text('Lưu thay đổi', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class to show the dialog
class EditExpenseReportDialogHelper {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> report,
    required Function() onReportUpdated,
    required Function(String) onShowFullScreenImage,
  }) {
    DialogHelper.showCustomDialog(
      context: context,
      child: EditExpenseReportDialog(
        report: report,
        onReportUpdated: onReportUpdated,
        onShowFullScreenImage: onShowFullScreenImage,
      ),
    );
  }
}