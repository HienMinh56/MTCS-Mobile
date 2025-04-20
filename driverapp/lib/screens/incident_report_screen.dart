import 'dart:async';
import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/services/incident_report_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Tạo class TextInputFormatter để ngăn chặn khoảng trắng đầu dòng và ký tự đặc biệt
class NoLeadingSpaceOrSpecialCharFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Nếu chuỗi rỗng, cho phép nhập bình thường
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Nếu ký tự đầu tiên là khoảng trắng, giữ nguyên giá trị cũ
    if (newValue.text.startsWith(' ')) {
      return oldValue;
    }
    
    // Nếu ký tự đầu tiên là ký tự đặc biệt (không phải chữ cái, số, khoảng trắng hoặc chữ Việt có dấu)
    if (RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(newValue.text)) {
      return oldValue;
    }
    
    return newValue;
  }
}

class IncidentReportScreen extends StatefulWidget {
  final String tripId;
  
  const IncidentReportScreen({
    Key? key, 
    required this.tripId,
  }) : super(key: key);

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedIncidentType;
  int _incidentType = 1; // 1 = On Site, 2 = Change Vehicle, 3 = Hủy chuyến trong ngày
  int _vehicleType = 1; // 1 = Tractor, 2 = Trailer
  final List<File> _images = [];
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  
  // Incident report service
  final _incidentReportService = IncidentReportService();
  
  // Update image picking to support multiple images
  Future<void> _pickImages() async {
    final List<File> images = await ImageUtils.pickMultipleImages();
    
    if (images.isNotEmpty) {
      setState(() {
        _images.addAll(images);
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${images.length} ảnh'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Add camera capture function
  Future<void> _takePicture() async {
    final File? photo = await ImageUtils.takePhoto();
    
    if (photo != null) {
      setState(() {
        _images.add(photo);
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm ảnh từ camera'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      // Form validation errors are already shown in the input fields
      return;
    }
    
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất một hình ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_images.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng hình ảnh không được vượt quá 10 ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Hiển thị dialog xác nhận trước khi gửi báo cáo
    bool confirmSubmit = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận gửi báo cáo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bạn có chắc chắn muốn gửi báo cáo sự cố này?'),
              const SizedBox(height: 16),
              Text('Loại sự cố: ${_selectedIncidentType ?? ""}'),
              const SizedBox(height: 8),
              Text('Xử lý: ${_incidentType == 1 ? "Xử lý tại chỗ" : _incidentType == 2 ? "Thay xe" : "Hủy chuyến trong ngày"}'),
              const SizedBox(height: 8),
              Text('Loại xe: ${_vehicleType == 1 ? "Xe đầu kéo" : "Rơ mooc"}'),
              const SizedBox(height: 8),
              Text('Địa điểm: ${_locationController.text}'),
              const SizedBox(height: 8),
              Text('Số ảnh đính kèm: ${_images.length}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Không xác nhận
              },
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Xác nhận gửi
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('XÁC NHẬN'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
    
    // Nếu người dùng không xác nhận, dừng quá trình gửi
    if (confirmSubmit != true) {
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
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
    
    try {
      final response = await _incidentReportService.submitIncidentReport(
        tripId: widget.tripId,
        incidentType: _selectedIncidentType ?? '',
        description: _descriptionController.text,
        location: _locationController.text,
        type: _incidentType,
        vehicleType: _vehicleType, // Added vehicle type parameter
        status: 'Handling', // Defaulting to Resolved as per API example
        images: _images,
      );
      print('Response: $response');
      // Close loading indicator
      Navigator.pop(context);
      
      if (response.success) {
        // Show success message with report ID if available
        final reportId = response.data?['reportId'] ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reportId.isNotEmpty 
                  ? 'Báo cáo sự cố đã được gửi thành công. Mã báo cáo: $reportId'
                  : 'Báo cáo sự cố đã được gửi thành công'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context); // Return to previous screen
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi không xác định: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quyền truy cập vị trí bị từ chối'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn, vui lòng cấp quyền trong cài đặt'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Try to get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';
          
          // Build address string from available components
          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address += address.isNotEmpty ? ', ${place.subLocality}' : place.subLocality!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            address += address.isNotEmpty ? ', ${place.locality}' : place.locality!;
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            address += address.isNotEmpty ? ', ${place.administrativeArea}' : place.administrativeArea!;
          }
          
          setState(() {
            _locationController.text = address;
          });
        } else {
          // If no address is found, use the coordinates
          setState(() {
            _locationController.text = '${position.latitude}, ${position.longitude}';
          });
        }
      } catch (e) {
        // If geocoding fails, fallback to coordinates
        setState(() {
          _locationController.text = '${position.latitude}, ${position.longitude}';
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật vị trí hiện tại'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy vị trí: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo sự cố'),
        backgroundColor: Colors.blue.shade700,
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip ID display
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.directions_car, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.tripId,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Incident Type
                _buildSectionTitle('Loại sự cố'),
                TextFormField(
                  initialValue: _selectedIncidentType,
                  onChanged: (value) {
                    setState(() {
                      _selectedIncidentType = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Nhập loại sự cố',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.category, color: Colors.blue.shade700),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập loại sự cố';
                    }
                    
                    // Trim value to remove leading/trailing whitespace
                    final trimmedValue = value.trim();
                    
                    // Check if original value starts with whitespace
                    if (value.startsWith(' ')) {
                      return 'Không được bắt đầu bằng khoảng trắng';
                    }
                    
                    // Check if first character is a special character
                    if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
                      return 'Không được bắt đầu bằng ký tự đặc biệt';
                    }
                    
                    // Check length after trimming
                    if (trimmedValue.length < 3) {
                      return 'Loại sự cố phải có ít nhất 3 ký tự (không tính khoảng trắng đầu/cuối)';
                    }
                    
                    if (trimmedValue.length > 100) {
                      return 'Loại sự cố không được quá 100 ký tự';
                    }
                    
                    return null;
                  },
                  inputFormatters: [NoLeadingSpaceOrSpecialCharFormatter()],
                ),
                
                const SizedBox(height: 20),
                
                // Incident Resolution Type (On Site vs Change Vehicle vs Cancel Trip)
                _buildSectionTitle('Loại xử lý sự cố'),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        title: const Text('Xử lý tại chỗ (On Site)'),
                        value: 1,
                        groupValue: _incidentType,
                        activeColor: Colors.blue.shade700,
                        onChanged: (value) {
                          setState(() {
                            _incidentType = value!;
                          });
                        },
                      ),
                      Divider(height: 1, color: Colors.blue.shade100),
                      RadioListTile<int>(
                        title: const Text('Thay xe (Change Vehicle)'),
                        value: 2,
                        groupValue: _incidentType,
                        activeColor: Colors.blue.shade700,
                        onChanged: (value) {
                          setState(() {
                            _incidentType = value!;
                          });
                        },
                      ),
                      Divider(height: 1, color: Colors.blue.shade100),
                      RadioListTile<int>(
                        title: const Text('Hủy chuyến trong ngày (Cancel Trip)'),
                        value: 3,
                        groupValue: _incidentType,
                        activeColor: Colors.blue.shade700,
                        onChanged: (value) {
                          setState(() {
                            _incidentType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Vehicle Type
                _buildSectionTitle('Loại xe'),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        title: const Text('Xe đầu kéo (Tractor)'),
                        value: 1,
                        groupValue: _vehicleType,
                        activeColor: Colors.blue.shade700,
                        onChanged: (value) {
                          setState(() {
                            _vehicleType = value!;
                          });
                        },
                      ),
                      Divider(height: 1, color: Colors.blue.shade100),
                      RadioListTile<int>(
                        title: const Text('Xe rơ mooc (Trailer)'),
                        value: 2,
                        groupValue: _vehicleType,
                        activeColor: Colors.blue.shade700,
                        onChanged: (value) {
                          setState(() {
                            _vehicleType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Location
                _buildSectionTitle('Địa điểm xảy ra sự cố'),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Nhập địa điểm xảy ra sự cố',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.location_on, color: Colors.blue.shade700),
                    suffixIcon: _isLoadingLocation
                      ? Container(
                          margin: const EdgeInsets.all(12),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade700,
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.my_location, color: Colors.blue.shade700),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Lấy vị trí hiện tại',
                        ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa điểm xảy ra sự cố';
                    }
                    
                    // Trim value to remove leading/trailing whitespace
                    final trimmedValue = value.trim();
                    
                    // Check if original value starts with whitespace
                    if (value.startsWith(' ')) {
                      return 'Không được bắt đầu bằng khoảng trắng';
                    }
                    
                    // Check if first character is a special character
                    if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
                      return 'Không được bắt đầu bằng ký tự đặc biệt';
                    }
                    
                    // Check length after trimming
                    if (trimmedValue.length < 5) {
                      return 'Địa điểm phải có ít nhất 5 ký tự (không tính khoảng trắng đầu/cuối)';
                    }
                    
                    if (trimmedValue.length > 200) {
                      return 'Địa điểm không được quá 200 ký tự';
                    }
                    
                    return null;
                  },
                  inputFormatters: [NoLeadingSpaceOrSpecialCharFormatter()],
                ),
                
                const SizedBox(height: 20),
                
                // Description
                _buildSectionTitle('Mô tả chi tiết'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Nhập chi tiết về sự cố...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mô tả sự cố';
                    }
                    
                    // Trim value to remove leading/trailing whitespace
                    final trimmedValue = value.trim();
                    
                    // Check if original value starts with whitespace
                    if (value.startsWith(' ')) {
                      return 'Không được bắt đầu bằng khoảng trắng';
                    }
                    
                    // Check if first character is a special character
                    if (trimmedValue.isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(trimmedValue)) {
                      return 'Không được bắt đầu bằng ký tự đặc biệt';
                    }
                    
                    // Check length after trimming
                    if (trimmedValue.length < 10) {
                      return 'Mô tả phải có ít nhất 10 ký tự (không tính khoảng trắng đầu/cuối)';
                    }
                    
                    if (trimmedValue.length > 500) {
                      return 'Mô tả không được quá 500 ký tự';
                    }
                    
                    return null;
                  },
                  inputFormatters: [NoLeadingSpaceOrSpecialCharFormatter()],
                ),
                
                const SizedBox(height: 24),
                
                // Images - use the new implementation
                _buildImageSection(),
                
                const SizedBox(height: 30),
                
                // Submit Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: const Icon(Icons.send, size: 22),
                    label: const Text(
                      'GỬI BÁO CÁO',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ImageSection(
      title: 'Hình ảnh minh họa',
      imageFiles: _images,
      onTakePhoto: _takePicture,
      onPickImage: _pickImages,
      onRemoveImage: _removeImage,
      cameraButtonColor: Colors.blue.shade600,
      galleryButtonColor: Colors.blue.shade600,
      emptyMessage: 'Chưa có ảnh nào\nChọn "Chọn nhiều ảnh" để tải lên nhiều ảnh cùng lúc',
      crossAxisCount: 2,
    );
  }
}