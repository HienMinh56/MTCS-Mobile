import 'dart:async';
import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/services/incident_report_service.dart';

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
  int _incidentType = 1; // 1 = On Site, 2 = Change Vehicle
  final List<File> _images = [];
  bool _isSubmitting = false;
  
  // Incident report service
  final _incidentReportService = IncidentReportService();
  
  // Incident types for auto-complete
  final List<String> _incidentTypes = [
    'Xe hỏng động cơ',
    'Xe bị nổ lốp',
    'Tai nạn giao thông',
    'Hàng hóa hư hỏng',
    'Giao hàng muộn',
    'Vấn đề giấy tờ',
    'Khác'
  ];

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
        status: 'Resolved', // Defaulting to Resolved as per API example
        images: _images,
      );
      
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
                          'Chuyến đi #${widget.tripId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Incident Type
                _buildSectionTitle('Loại sự cố'),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _incidentTypes.where((option) {
                      return option.toLowerCase().contains(
                            textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _selectedIncidentType = selection;
                    });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Chọn hoặc nhập loại sự cố',
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
                          return 'Vui lòng chọn loại sự cố';
                        }
                        return null;
                      },
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Incident Resolution Type (On Site vs Change Vehicle)
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
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa điểm xảy ra sự cố';
                    }
                    return null;
                  },
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
                    return null;
                  },
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