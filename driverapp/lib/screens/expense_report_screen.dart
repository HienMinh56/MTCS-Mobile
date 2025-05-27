import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:driverapp/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/validation_utils.dart';
import 'package:driverapp/services/expense_report_service.dart';
import 'package:driverapp/services/expense_type_manager.dart';
import 'package:driverapp/models/expense_report_type.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ExpenseReportScreen extends StatefulWidget {
  final String tripId;

  const ExpenseReportScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<ExpenseReportScreen> createState() => _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends State<ExpenseReportScreen> {
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoadingLocation = false;  // Report type options from API
  List<ExpenseReportType> _reportTypes = [];
  String? _selectedReportTypeId;
  bool _isLoadingReportTypes = false;

  // Add state variables for validation errors
  String? _costError;
  String? _locationError;
  String? _descriptionError;
  String? _imagesError;
  String? _reportTypeError;

  bool get _shouldShowDescription => _selectedReportTypeId == 'other';

  @override
  void initState() {
    super.initState();
    // Add listeners to validate on text changes
    _costController.addListener(_validateCost);
    _locationController.addListener(_validateLocation);
    _descriptionController.addListener(_validateDescription);
    
    // Load expense report types
    _initReportTypes();
  }
  Future<void> _initReportTypes() async {
    // Lấy dữ liệu từ ExpenseTypeManager đã được tải trước
    final expenseTypeManager = ExpenseTypeManager();
    final types = expenseTypeManager.getAllExpenseReportTypes();
    
    if (types.isNotEmpty) {
      setState(() {
        _reportTypes = types;
        
        // Set default report type if available (không phải other)
        if (_reportTypes.isNotEmpty) {
          // Tìm loại báo cáo không phải "other" để đặt làm mặc định
          final defaultType = _reportTypes.firstWhere(
            (type) => type.reportTypeId != 'other',
            orElse: () => _reportTypes.first,
          );
          _selectedReportTypeId = defaultType.reportTypeId;
        }
      });
    } else {
      // Nếu chưa có dữ liệu, tải từ API
      try {
        final freshTypes = await ExpenseReportService.getAllExpenseReportTypes();
        
        setState(() {
          _reportTypes = freshTypes;
          
          if (_reportTypes.isNotEmpty) {
            final defaultType = _reportTypes.firstWhere(
              (type) => type.reportTypeId != 'other',
              orElse: () => _reportTypes.first,
            );
            _selectedReportTypeId = defaultType.reportTypeId;
          }
        });
      } catch (e) {
        setState(() {
          _reportTypeError = 'Không thể tải loại báo cáo chi phí: $e';
        });
        
        DialogHelper.showSnackBar(
          context: context,
          message: 'Không thể tải loại báo cáo chi phí: $e',
          isError: true,
        );
      }
    }
  }
  
  // Validation methods
  void _validateCost() {
    setState(() {
      _costError = ValidationUtils.validateExpenseCost(_costController.text);
    });
  }

  void _validateLocation() {
    setState(() {
      _locationError = ValidationUtils.validateLocation(_locationController.text);
    });
  }

  void _validateDescription() {
    setState(() {
      _descriptionError = ValidationUtils.validateExpenseDescription(_descriptionController.text);
    });
  }

  void _validateImages() {
    setState(() {
      _imagesError = ValidationUtils.validateImages(_selectedImages);
    });
  }

  void _validateReportType() {
    setState(() {
      _reportTypeError = _selectedReportTypeId == null ? 'Vui lòng chọn loại chi phí' : null;
    });
  }

  // Validate all fields at once
  bool _validateAllFields() {
    _validateCost();
    _validateLocation();
    _validateImages();
    _validateReportType();
    
    // Chỉ validate mô tả khi loại chi phí là "khác"
    if (_shouldShowDescription) {
      _validateDescription();
      return _costError == null &&
          _locationError == null &&
          _descriptionError == null &&
          _imagesError == null &&
          _reportTypeError == null;
    } else {
      return _costError == null &&
          _locationError == null &&
          _imagesError == null &&
          _reportTypeError == null;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        DialogHelper.showSnackBar(
          context: context,
          message: 'Vui lòng bật dịch vụ định vị',
          isError: true,
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          DialogHelper.showSnackBar(
            context: context,
            message: 'Không có quyền truy cập vị trí',
            isError: true,
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        DialogHelper.showSnackBar(
          context: context,
          message: 'Vui lòng cấp quyền truy cập vị trí trong cài đặt',
          isError: true,
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address =
              '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
          address = address.replaceAll(RegExp(r', ,'), ',')
                           .replaceAll(RegExp(r',,'), ',')
                           .replaceAll(RegExp(r'^, '), '')
                           .replaceAll(RegExp(r', $'), '');

          setState(() {
            _locationController.text = address;
            _isLoadingLocation = false;
          });
          _validateLocation();
        }
      } catch (e) {
        setState(() {
          _locationController.text =
              '${position.latitude}, ${position.longitude}';
          _isLoadingLocation = false;
        });
        _validateLocation();
      }
    } catch (e) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Không thể lấy vị trí hiện tại: $e',
        isError: true,
      );
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<File> pickedFiles = await ImageUtils.pickMultipleImages();

      if (pickedFiles.isNotEmpty) {
        // Check if adding these images would exceed the limit
        if (_selectedImages.length + pickedFiles.length > 10) {
          setState(() {
            _imagesError = 'Không được chọn quá 10 ảnh';
            
            // Only add images up to the limit
            if (_selectedImages.length < 10) {
              final int remainingSlots = 10 - _selectedImages.length;
              _selectedImages.addAll(pickedFiles.take(remainingSlots));
              _imagesError = 'Đã thêm $remainingSlots ảnh (tối đa 10 ảnh)';
            }
          });
        } else {
          setState(() {
            _selectedImages.addAll(pickedFiles);
            _imagesError = null; // Clear error if any
          });
        }
        _validateImages();

        // Show confirmation
        DialogHelper.showSnackBar(
          context: context,
          message: 'Đã thêm ảnh thành công',
          isError: false,
        );
      }
    } catch (e) {
      // Show error message
      DialogHelper.showSnackBar(
        context: context,
        message: 'Lỗi khi chọn ảnh: $e',
        isError: true,
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final File? photo = await ImageUtils.takePhoto();

      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
        _validateImages();

        // Show confirmation
        DialogHelper.showSnackBar(
          context: context,
          message: 'Đã thêm ảnh từ camera',
          isError: false,
        );
      }
    } catch (e) {
      // Show error message
      DialogHelper.showSnackBar(
        context: context,
        message: 'Lỗi khi chụp ảnh: $e',
        isError: true,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _validateImages();
  }

  // Lấy tên loại báo cáo từ ID
  String _getReportTypeName(String? reportTypeId) {
    if (reportTypeId == null) return 'Không xác định';
    
    final type = _reportTypes.firstWhere(
      (type) => type.reportTypeId == reportTypeId,
      orElse: () => ExpenseReportType(
        reportTypeId: reportTypeId,
        reportType: 'Không xác định',
        isActive: 1,
      ),
    );
    
    return type.reportType;
  }

  Future<void> _submitReport() async {
    // Validate all fields before submitting
    if (!_validateAllFields()) {
      // Error messages are already shown in the form fields, no need for an additional SnackBar
      return;
    }

    // Kiểm tra nếu chưa có loại báo cáo chi phí
    if (_selectedReportTypeId == null) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Vui lòng chọn loại chi phí',
        isError: true,
      );
      return;
    }

    // Parse values (we know they're valid at this point)
    final double cost = double.parse(_costController.text);
    
    // Hiển thị dialog xác nhận trước khi gửi báo cáo
    bool? shouldProceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Xác nhận thông tin',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vui lòng kiểm tra lại thông tin trước khi gửi:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                _buildConfirmInfoRow(
                  Icons.category,
                  'Loại chi phí:',
                  _getReportTypeName(_selectedReportTypeId),
                  Colors.purple,
                ),
                _buildConfirmInfoRow(
                  Icons.monetization_on,
                  'Số tiền chi phí:',
                  '${cost.toStringAsFixed(0)} VND',
                  Colors.orange,
                ),
                _buildConfirmInfoRow(
                  Icons.location_on,
                  'Vị trí phát sinh:',
                  _locationController.text,
                  Colors.green,
                ),
                _buildConfirmInfoRow(
                  Icons.payment,
                  'Trạng thái thanh toán:',
                  'Chưa thanh toán',
                  Colors.red,
                ),
                if (_shouldShowDescription)
                  _buildConfirmInfoRow(
                    Icons.description,
                    'Mô tả:',
                    _descriptionController.text,
                    Colors.blue,
                  ),
                _buildConfirmInfoRow(
                  Icons.image,
                  'Số ảnh đính kèm:',
                  '${_selectedImages.length} ảnh',
                  Colors.teal,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Sửa lại',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
              ),
              child: Text('Xác nhận gửi', 
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
    
    // Nếu người dùng không xác nhận, dừng quá trình gửi báo cáo
    if (shouldProceed != true) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Submit the report using the service
    final result = await ExpenseReportService.submitExpenseReport(
      tripId: widget.tripId,
      reportTypeId: _selectedReportTypeId ?? 'other',
      cost: cost,
      location: _locationController.text,
      isPay: 0, // Luôn là chưa thanh toán (0)
      description: _descriptionController.text,
      images: _selectedImages,
    );

    // Close loading dialog
    Navigator.pop(context);

    // Handle the result
    if (result['success']) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Báo cáo chi phí đã được gửi thành công!',
        isError: false,
      );
      Navigator.pop(context);
    } else {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Lỗi khi gửi báo cáo: ${result['message']}',
        isError: true,
      );
    }
  }
  
  // Helper method để tạo các dòng thông tin trong dialog xác nhận
  Widget _buildConfirmInfoRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo chi phí'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              child: ListView(
                children: [                  const SizedBox(height: 16),
                  // Report Type Dropdown with improved styling
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Loại chi phí',
                          labelStyle: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.category, color: Colors.purple.shade400),
                          errorText: _reportTypeError,
                        ),
                        value: _selectedReportTypeId,
                        items: _reportTypes.isEmpty 
                          ? [const DropdownMenuItem<String>(
                              value: 'loading',
                              child: Text('Đang tải loại chi phí...'),
                            )]
                          : _reportTypes.map((type) => DropdownMenuItem<String>(
                              value: type.reportTypeId,
                              child: Text(type.reportType),
                            )).toList(),
                        onChanged: _reportTypes.isEmpty 
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedReportTypeId = value;
                                  _reportTypeError = null;
                                });
                              }
                            },
                        icon: _isLoadingReportTypes 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.blue.shade700,
                              ),
                            )
                          : Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
                        isExpanded: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cost Input Field with improved styling
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: _costController,
                        decoration: InputDecoration(
                          labelText: 'Số tiền chi phí (VND)',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          errorText: _costError,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.monetization_on, color: Colors.orange.shade400),
                          hintText: 'Nhập số tiền chi phí',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location Input Field with Get Current Location button
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Vị trí phát sinh chi phí',
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                          errorText: _locationError,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          prefixIcon: Icon(Icons.location_on, color: Colors.green.shade400),
                          suffixIcon: IconButton(
                            icon: _isLoadingLocation
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Colors.blue.shade700,
                                    ),
                                  )
                                : Icon(Icons.my_location, color: Colors.blue.shade700),
                            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                            tooltip: 'Lấy vị trí hiện tại',
                          ),
                          hintText: 'Nhập vị trí phát sinh chi phí',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description Input Field (chỉ hiển thị khi loại chi phí là "khác")
                  if (_shouldShowDescription)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Mô tả chi phí',
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            errorText: _descriptionError,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            prefixIcon: Icon(Icons.description, color: Colors.blue.shade400),
                            hintText: 'Nhập mô tả chi tiết về chi phí',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                          maxLines: 3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Image Upload Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ImageSection(
                        imageFiles: _selectedImages,
                        onPickImage: _pickImages,
                        onTakePhoto: _takePicture,
                        onRemoveImage: _removeImage,
                        errorText: _imagesError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _submitReport,
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi báo cáo chi phí'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _costController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}