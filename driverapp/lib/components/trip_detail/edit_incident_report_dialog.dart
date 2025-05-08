import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/incident_report_service.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/image_utils.dart';

class EditIncidentReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function() onReportUpdated;
  final Function(String) onShowFullScreenImage;

  const EditIncidentReportDialog({
    Key? key,
    required this.report,
    required this.onReportUpdated,
    required this.onShowFullScreenImage,
  }) : super(key: key);

  @override
  State<EditIncidentReportDialog> createState() => _EditIncidentReportDialogState();
}

class _EditIncidentReportDialogState extends State<EditIncidentReportDialog> {
  // Hằng số giới hạn số lượng ảnh
  static const int MAX_IMAGES_PER_UPLOAD = 5; // Số ảnh tối đa mỗi lần tải lên
  static const int MAX_TOTAL_IMAGES = 10; // Tổng số ảnh tối đa

  // Services
  final IncidentReportService _incidentReportService = IncidentReportService();

  // Form controllers
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController incidentTypeController;

  // Lists for tracking file changes
  List<String> fileIdsToRemove = [];
  List<File> addedFiles = [];
  
  // Keep track of incident images (type = 1)
  List<Map<String, dynamic>> incidentImages = [];
  List<Map<String, dynamic>> billingImages = []; // type = 2, just for display
  List<Map<String, dynamic>> exchangeImages = []; // type = 3, just for display

  // Incident type and vehicle type
  late int incidentType;
  late int vehicleType;

  // Validation error states
  String? _descriptionError;
  String? _locationError;
  String? _imagesError;
  String? _incidentTypeError;

  // Form key
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    descriptionController = TextEditingController(
      text: widget.report['description'] ?? '',
    );
    locationController = TextEditingController(
      text: widget.report['location'] ?? '',
    );
    incidentTypeController = TextEditingController(
      text: widget.report['incidentType'] ?? '',
    );

    // Initialize dropdown values
    vehicleType = int.tryParse(widget.report['vehicleType']?.toString() ?? '1') ?? 1;

    // Filter and categorize incident report files by type
    _categorizeImages();

    // Add listeners for validation on change
    descriptionController.addListener(_validateDescription);
    locationController.addListener(_validateLocation);
    incidentTypeController.addListener(_validateIncidentType);
  }
  
  // Categorize images by type (1 = incident, 2 = billing, 3 = exchange)
  void _categorizeImages() {
    if (widget.report['incidentReportsFiles'] != null && 
        (widget.report['incidentReportsFiles'] as List).isNotEmpty) {
      
      for (var file in widget.report['incidentReportsFiles']) {
        int fileType = int.tryParse(file['type']?.toString() ?? '1') ?? 1;
        
        if (fileType == 1) {
          incidentImages.add(file);
        } else if (fileType == 2) {
          billingImages.add(file);
        } else if (fileType == 3) {
          exchangeImages.add(file);
        } else {
          // Default to incident images if type is unknown
          incidentImages.add(file);
        }
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    descriptionController.removeListener(_validateDescription);
    locationController.removeListener(_validateLocation);
    incidentTypeController.removeListener(_validateIncidentType);

    // Dispose controllers to prevent memory leaks
    descriptionController.dispose();
    locationController.dispose();
    incidentTypeController.dispose();
    
    super.dispose();
  }

  // Validation methods using ValidationUtils
  void _validateDescription() {
    setState(() {
      final String value = descriptionController.text;
      
      if (value.isEmpty) {
        _descriptionError = 'Vui lòng nhập mô tả sự cố';
        return;
      }
      
      // Trim value to remove leading/trailing whitespace
      final String trimmedValue = value.trim();
      
      // Check if original value starts with whitespace
      if (value.startsWith(' ')) {
        _descriptionError = 'Không được bắt đầu bằng khoảng trắng';
        return;
      }
      
      // Check if first character is a special character
      if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
        _descriptionError = 'Không được bắt đầu bằng ký tự đặc biệt';
        return;
      }
      
      // Check length after trimming
      if (trimmedValue.length < 10) {
        _descriptionError = 'Mô tả phải có ít nhất 10 ký tự (không tính khoảng trắng đầu/cuối)';
        return;
      }
      
      if (trimmedValue.length > 500) {
        _descriptionError = 'Mô tả không được quá 500 ký tự';
        return;
      }
      
      _descriptionError = null;
    });
  }

  void _validateLocation() {
    setState(() {
      final String value = locationController.text;
      
      if (value.isEmpty) {
        _locationError = 'Vui lòng nhập địa điểm xảy ra sự cố';
        return;
      }
      
      // Trim value to remove leading/trailing whitespace
      final String trimmedValue = value.trim();
      
      // Check if original value starts with whitespace
      if (value.startsWith(' ')) {
        _locationError = 'Không được bắt đầu bằng khoảng trắng';
        return;
      }
      
      // Check if first character is a special character
      if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
        _locationError = 'Không được bắt đầu bằng ký tự đặc biệt';
        return;
      }
      
      // Check length after trimming
      if (trimmedValue.length < 5) {
        _locationError = 'Địa điểm phải có ít nhất 5 ký tự (không tính khoảng trắng đầu/cuối)';
        return;
      }
      
      if (trimmedValue.length > 200) {
        _locationError = 'Địa điểm không được quá 200 ký tự';
        return;
      }
      
      _locationError = null;
    });
  }

  void _validateIncidentType() {
    setState(() {
      final String value = incidentTypeController.text;
      
      if (value.isEmpty) {
        _incidentTypeError = 'Vui lòng nhập loại sự cố';
        return;
      }
      
      // Trim value to remove leading/trailing whitespace
      final String trimmedValue = value.trim();
      
      // Check if original value starts with whitespace
      if (value.startsWith(' ')) {
        _incidentTypeError = 'Không được bắt đầu bằng khoảng trắng';
        return;
      }
      
      // Check if first character is a special character
      if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
        _incidentTypeError = 'Không được bắt đầu bằng ký tự đặc biệt';
        return;
      }
      
      // Check length after trimming
      if (trimmedValue.length < 3) {
        _incidentTypeError = 'Loại sự cố phải có ít nhất 3 ký tự (không tính khoảng trắng đầu/cuối)';
        return;
      }
      
      if (trimmedValue.length > 100) {
        _incidentTypeError = 'Loại sự cố không được quá 100 ký tự';
        return;
      }
      
      _incidentTypeError = null;
    });
  }

  void _validateImages() {
    setState(() {
      final int existingImagesCount = incidentImages.length;
      final int finalImagesCount = existingImagesCount - fileIdsToRemove.length + addedFiles.length;
      
      if (finalImagesCount <= 0) {
        _imagesError = 'Cần ít nhất 1 hình ảnh sự cố';
      } else if (finalImagesCount > MAX_TOTAL_IMAGES) {
        _imagesError = 'Không được vượt quá $MAX_TOTAL_IMAGES hình ảnh sự cố';
      } else if (addedFiles.length > MAX_IMAGES_PER_UPLOAD) {
        _imagesError = 'Không được tải lên quá $MAX_IMAGES_PER_UPLOAD ảnh mỗi lần';
      } else {
        _imagesError = null;
      }
    });
  }

  // Validate all fields at once
  bool _validateAllFields() {
    _validateDescription();
    _validateLocation();
    _validateImages();
    _validateIncidentType();

    return _descriptionError == null &&
        _locationError == null &&
        _imagesError == null &&
        _incidentTypeError == null;
  }

  // Method to update the incident report
  Future<void> _updateIncidentReport() async {
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

      // Check if vehicle type exists in the original report
      final bool hasVehicleType = widget.report['vehicleType'] != null;

      // Call the API service to update the report
      final result = await _incidentReportService.updateIncidentReport(
        reportId: widget.report['reportId'],
        description: descriptionController.text,
        location: locationController.text,
        incidentType: incidentTypeController.text,
        vehicleType: hasVehicleType ? vehicleType : null, // Only send vehicle type if it existed originally
        fileIdsToRemove: fileIdsToRemove,
        addedFiles: addedFiles,
      );

      // Close the loading dialog
      Navigator.pop(context);

      // Check if the update was successful
      if (result['status'] == 1) {
        // Close the edit dialog
        Navigator.pop(context);

        // Show success message
        DialogHelper.showSnackBar(
          context: context,
          message: 'Cập nhật báo cáo sự cố thành công',
          isError: false,
        );

        // Call the callback to reload data
        widget.onReportUpdated();
      } else {
        // Show error message
        DialogHelper.showInformationDialog(
          context: context,
          title: 'Lỗi',
          content: result['message'] ?? 'Không thể cập nhật báo cáo sự cố. Vui lòng thử lại sau.',
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

  // Helper method to build section titles with icons
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    int maxLines = 1,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: prefixIcon != null 
            ? Icon(prefixIcon, color: Colors.blue)
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
  
  // Helper method to build radio button selections
  Widget _buildRadioSelection({
    required List<Map<String, dynamic>> items,
    required int groupValue,
    required Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> item = entry.value;
          final bool isSelected = groupValue == item['value'];
          
          return Column(
            children: [
              if (index > 0)
                const Divider(height: 1, thickness: 1),
              ListTile(
                onTap: () => onChanged(item['value']),
                leading: Radio<int>(
                  value: item['value'],
                  groupValue: groupValue,
                  onChanged: (value) => onChanged(value!),
                  activeColor: Colors.blue,
                ),
                title: Row(
                  children: [
                    if (item['icon'] != null) ...[
                      Icon(item['icon'], color: Colors.grey[700], size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      item['label'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Helper method to build the image section
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hình ảnh minh họa', Icons.camera_alt),
        
        // Show existing incident images (type = 1) - editable
        if (incidentImages.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    const Text(
                      'Ảnh sự cố (có thể chỉnh sửa):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: incidentImages.map<Widget>((file) {
                    final String fileIdentifier = file['fileId']?.toString() ?? file['fileUrl'];
                    final bool isMarkedForRemoval = fileIdsToRemove.contains(fileIdentifier);
                    
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => widget.onShowFullScreenImage(file['fileUrl']),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isMarkedForRemoval ? Colors.red : Colors.blue.shade300,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    file['fileUrl'],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image),
                                        ),
                                      );
                                    },
                                  ),
                                  if (isMarkedForRemoval)
                                    Container(
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Center(
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isMarkedForRemoval) {
                                  fileIdsToRemove.remove(fileIdentifier);
                                } else {
                                  fileIdsToRemove.add(fileIdentifier);
                                }
                                _validateImages();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isMarkedForRemoval ? Colors.blue : Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isMarkedForRemoval ? Icons.restore : Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        
        // Show billing images (type = 2) - readonly
        if (billingImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Ảnh hóa đơn (chỉ xem):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: billingImages.map<Widget>((file) {
                    return GestureDetector(
                      onTap: () => widget.onShowFullScreenImage(file['fileUrl']),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            file['fileUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        // Show exchange images (type = 3) - readonly
        if (exchangeImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigo.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_alt, size: 16, color: Colors.indigo),
                    const SizedBox(width: 6),
                    const Text(
                      'Ảnh trao đổi (chỉ xem):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: exchangeImages.map<Widget>((file) {
                    return GestureDetector(
                      onTap: () => widget.onShowFullScreenImage(file['fileUrl']),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.indigo.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            file['fileUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        // Show newly added incident images
        if (addedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_photo_alternate, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    const Text(
                      'Ảnh sự cố mới thêm:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: addedFiles.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final File file = entry.value;
                    
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                addedFiles.removeAt(index);
                                _validateImages();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        // Note about image types
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Lưu ý: Chỉ có thể chỉnh sửa ảnh sự cố.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),

        // Add image buttons (only for incident images)
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ElevatedButton.icon(
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
                label: const Text('Chụp ảnh sự cố'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final images = await ImageUtils.pickMultipleImages();
                  if (images.isNotEmpty) {
                    // Calculate current total images (existing + added - removed)
                    final int existingCount = incidentImages.length - fileIdsToRemove.length;
                    final int currentTotal = existingCount + addedFiles.length;
                    
                    // Check if adding these images would exceed the limit
                    if (currentTotal + images.length > MAX_TOTAL_IMAGES) {
                      setState(() {
                        // Only add images up to the limit
                        if (currentTotal < MAX_TOTAL_IMAGES) {
                          final int remainingSlots = MAX_TOTAL_IMAGES - currentTotal;
                          addedFiles.addAll(images.take(remainingSlots));
                          _imagesError = 'Đã thêm $remainingSlots ảnh (tổng số không vượt quá $MAX_TOTAL_IMAGES ảnh)';
                        } else {
                          _imagesError = 'Không thể thêm ảnh, đã đạt giới hạn $MAX_TOTAL_IMAGES ảnh';
                        }
                      });
                    } else if (images.length > MAX_IMAGES_PER_UPLOAD) {
                      setState(() {
                        addedFiles.addAll(images.take(MAX_IMAGES_PER_UPLOAD));
                        _imagesError = 'Đã thêm $MAX_IMAGES_PER_UPLOAD ảnh (mỗi lần chỉ được chọn $MAX_IMAGES_PER_UPLOAD ảnh)';
                      });
                    } else {
                      setState(() {
                        addedFiles.addAll(images);
                        _imagesError = null; // Clear error if any
                      });
                    }
                    _validateImages();
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Thêm ảnh sự cố'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[300],
                ),
              ),
            ),
          ],
        ),
        
        if (_imagesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _imagesError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem report ban đầu có vehicle type không
    final bool hasVehicleType = widget.report['vehicleType'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator at top of dialog
            Center(
              child: Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chỉnh sửa báo cáo sự cố',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),
            
            const Divider(),
            
            // Make the content scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Incident Type
                    _buildSectionTitle('Loại sự cố', Icons.report_problem_outlined),
                    _buildTextField(
                      controller: incidentTypeController,
                      hintText: 'Nhập loại sự cố',
                      prefixIcon: Icons.category,
                      errorText: _incidentTypeError,
                    ),
                    
                    // Vehicle Type - chỉ hiển thị khi báo cáo ban đầu có vehicle type
                    if (hasVehicleType) ...[
                      const SizedBox(height: 16),
                      _buildSectionTitle('Loại xe', Icons.local_shipping),
                      _buildRadioSelection(
                        items: const [
                          {'label': 'Xe đầu kéo', 'value': 1, 'icon': Icons.fire_truck},
                          {'label': 'Xe rơ mooc', 'value': 2, 'icon': Icons.rv_hookup},
                        ],
                        groupValue: vehicleType,
                        onChanged: (value) {
                          setState(() {
                            vehicleType = value;
                          });
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Location
                    _buildSectionTitle('Địa điểm xảy ra sự cố', Icons.place),
                    _buildTextField(
                      controller: locationController,
                      hintText: 'Nhập địa điểm xảy ra sự cố',
                      prefixIcon: Icons.location_on,
                      errorText: _locationError,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    _buildSectionTitle('Mô tả chi tiết', Icons.description),
                    _buildTextField(
                      controller: descriptionController,
                      hintText: 'Nhập chi tiết về sự cố...',
                      maxLines: 4,
                      errorText: _descriptionError,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Images section
                    _buildImageSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateIncidentReport,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('LƯU THAY ĐỔI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Phương thức tiện ích để hiển thị dialog
class EditIncidentReportDialogHelper {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> report,
    required Function() onReportUpdated,
    required Function(String) onShowFullScreenImage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return GestureDetector(
          onVerticalDragEnd: (details) {
            // Nếu kéo xuống đủ nhanh, đóng dialog
            if (details.primaryVelocity! > 300) {
              Navigator.of(context).pop();
            }
          },
          child: EditIncidentReportDialog(
            report: report,
            onReportUpdated: onReportUpdated,
            onShowFullScreenImage: onShowFullScreenImage,
          ),
        );
      },
    );
  }
}