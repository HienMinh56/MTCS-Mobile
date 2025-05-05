import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/incident_report_service.dart';
import '../../utils/dialog_helper.dart';
import '../../utils/image_utils.dart';
import '../../utils/validation_utils.dart';

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

class _EditIncidentReportDialogState extends State<EditIncidentReportDialog> with SingleTickerProviderStateMixin {
  // Services
  final IncidentReportService _incidentReportService = IncidentReportService();

  // Animation controller for enhanced UI effects
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  late TextEditingController descriptionController;
  late TextEditingController locationController;
  late TextEditingController incidentTypeController;

  // Lists for tracking file changes
  List<String> fileIdsToRemove = [];
  List<File> addedFiles = [];

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
  
  // Colors for better UI
  final Color _primaryColor = Color(0xFF2D6ADF);
  final Color _accentColor = Color(0xFF65B8FF);
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = Color(0xFFF7FAFF);
  final Color _errorColor = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    
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

    // Add listeners for validation on change
    descriptionController.addListener(_validateDescription);
    locationController.addListener(_validateLocation);
    incidentTypeController.addListener(_validateIncidentType);
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
    
    // Dispose animation controller
    _animationController.dispose();
    
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
      final int existingImagesCount = ((widget.report['incidentReportsFiles'] as List?) ?? []).length;
      _imagesError = ValidationUtils.validateIncidentImages(
        existingImagesCount,
        fileIdsToRemove.length,
        addedFiles.length
      );
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

      // Call the API service to update the report
      final result = await _incidentReportService.updateIncidentReport(
        reportId: widget.report['reportId'],
        description: descriptionController.text,
        location: locationController.text,
        incidentType: incidentTypeController.text,
        vehicleType: vehicleType,
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primaryColor,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: errorText != null 
            ? [
                BoxShadow(
                  color: _errorColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          errorText: errorText,
          filled: true,
          fillColor: errorText != null ? _errorColor.withOpacity(0.05) : _cardColor,
          prefixIcon: prefixIcon != null 
              ? Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(prefixIcon, color: _primaryColor),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: _primaryColor.withOpacity(0.8),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: _errorColor.withOpacity(0.8),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: _errorColor,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: _errorColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  // Helper method to build radio button selections with modern UI
  Widget _buildRadioSelection({
    required List<Map<String, dynamic>> items,
    required int groupValue,
    required Function(int) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: _cardColor,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final int index = entry.key;
            final Map<String, dynamic> item = entry.value;
            final bool isSelected = groupValue == item['value'];
            
            return Column(
              children: [
                if (index > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                    indent: 15,
                    endIndent: 15,
                  ),
                InkWell(
                  onTap: () => onChanged(item['value']),
                  splashColor: _accentColor.withOpacity(0.1),
                  highlightColor: _accentColor.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, 
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? _primaryColor : Colors.white,
                            border: Border.all(
                              color: isSelected ? _primaryColor : Colors.grey.shade400,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.2),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        if (item['icon'] != null) ...[
                          Icon(
                            item['icon'],
                            color: isSelected ? _primaryColor : Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            item['label'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? _primaryColor : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Helper method to build the image section
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hình ảnh minh họa', Icons.photo_library_outlined),
        
        // Show existing images
        if (widget.report['incidentReportsFiles'] != null &&
            (widget.report['incidentReportsFiles'] as List).isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.image_outlined, color: _primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Hình ảnh hiện tại:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: (widget.report['incidentReportsFiles'] as List).map<Widget>((file) {
                    final String fileIdentifier = file['fileId']?.toString() ?? file['fileUrl'];
                    final bool isMarkedForRemoval = fileIdsToRemove.contains(fileIdentifier);
                    
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => widget.onShowFullScreenImage(file['fileUrl']),
                          child: Hero(
                            tag: 'image_${file['fileUrl']}',
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMarkedForRemoval ? _errorColor.withOpacity(0.5) : Colors.transparent,
                                  width: isMarkedForRemoval ? 2 : 0,
                                ),
                                boxShadow: isMarkedForRemoval 
                                    ? [] 
                                    : [BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      file['fileUrl'],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: _primaryColor,
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.broken_image_outlined),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isMarkedForRemoval)
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
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
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isMarkedForRemoval ? _primaryColor : _errorColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isMarkedForRemoval ? _primaryColor : _errorColor).withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isMarkedForRemoval ? Icons.restore_outlined : Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
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

        // Show newly added images
        if (addedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Hình ảnh mới thêm:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: addedFiles.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final File file = entry.value;
                    
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  addedFiles.removeAt(index);
                                  _validateImages();
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _errorColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _errorColor.withOpacity(0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
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

        // Add image buttons
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildActionButton(
                onPressed: () async {
                  final image = await ImageUtils.takePhoto();
                  if (image != null) {
                    setState(() {
                      addedFiles.add(image);
                      _validateImages();
                    });
                  }
                },
                icon: Icons.camera_alt_outlined,
                label: 'Chụp ảnh',
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                onPressed: () async {
                  final images = await ImageUtils.pickMultipleImages();
                  if (images.isNotEmpty) {
                    setState(() {
                      addedFiles.addAll(images);
                      _validateImages();
                    });
                  }
                },
                icon: Icons.photo_library_outlined,
                label: 'Thêm ảnh',
                color: _accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Helper method to build action buttons
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          backgroundColor: color.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 5,
              offset: const Offset(0, -4),
            ),
          ],
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
                  width: 65,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chỉnh sửa báo cáo sự cố',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 5),
              
              // Thin gradient divider
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor.withOpacity(0.1), _primaryColor, _accentColor, _accentColor.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              
              // Make the content scrollable
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Incident Type
                          _buildSectionTitle('Loại sự cố', Icons.report_problem_outlined),
                          _buildTextField(
                            controller: incidentTypeController,
                            hintText: 'Nhập loại sự cố',
                            prefixIcon: Icons.category_outlined,
                            errorText: _incidentTypeError,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Incident Resolution Type
                          
                          
                          
                          const SizedBox(height: 24),
                          
                          // Vehicle Type
                          _buildSectionTitle('Loại xe', Icons.local_shipping_outlined),
                          _buildRadioSelection(
                            items: const [
                              {'label': 'Xe đầu kéo', 'value': 1, 'icon': Icons.fire_truck_outlined},
                              {'label': 'Xe rơ mooc', 'value': 2, 'icon': Icons.rv_hookup_outlined},
                            ],
                            groupValue: vehicleType,
                            onChanged: (value) {
                              setState(() {
                                vehicleType = value;
                              });
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Location
                          _buildSectionTitle('Địa điểm xảy ra sự cố', Icons.place_outlined),
                          _buildTextField(
                            controller: locationController,
                            hintText: 'Nhập địa điểm xảy ra sự cố',
                            prefixIcon: Icons.location_on_outlined,
                            errorText: _locationError,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Description
                          _buildSectionTitle('Mô tả chi tiết', Icons.description_outlined),
                          _buildTextField(
                            controller: descriptionController,
                            hintText: 'Nhập chi tiết về sự cố...',
                            maxLines: 5,
                            errorText: _descriptionError,
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Images section
                          _buildImageSection(),
                          
                          // Show image validation error
                          if (_imagesError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: _errorColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _imagesError!,
                                    style: TextStyle(
                                      color: _errorColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _updateIncidentReport,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _primaryColor,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _accentColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined, size: 22),
                          const SizedBox(width: 12),
                          const Text(
                            'LƯU THAY ĐỔI',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    DialogHelper.showCustomDialog(
      context: context,
      child: EditIncidentReportDialog(
        report: report,
        onReportUpdated: onReportUpdated,
        onShowFullScreenImage: onShowFullScreenImage,
      ),
    );
  }
}