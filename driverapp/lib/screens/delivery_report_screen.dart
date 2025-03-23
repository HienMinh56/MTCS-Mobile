import 'dart:io';
import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:driverapp/components/info_card.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/date_utils.dart';

class DeliveryReportScreen extends StatefulWidget {
  final String tripId;
  final String userId;

  const DeliveryReportScreen({
    Key? key,
    required this.tripId,
    required this.userId,
  }) : super(key: key);

  @override
  State<DeliveryReportScreen> createState() => _DeliveryReportScreenState();
}

class _DeliveryReportScreenState extends State<DeliveryReportScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _noteController = TextEditingController();
  final List<File> _imageFiles = [];
  String _driverName = 'Đang tải...';
  bool _isLoading = false;
  DateTime _reportTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDriverName();
  }

  Future<void> _loadDriverName() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _driverName = 'Chưa xác định';
      });
      return;
    }

    try {
      final profile = await _profileService.getDriverProfile(widget.userId);
      setState(() {
        _driverName = profile.fullName;
      });
    } catch (e) {
      setState(() {
        _driverName = 'Lỗi tải thông tin';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải thông tin tài xế: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    final File? image = await ImageUtils.takePhoto();
    if (image != null) {
      setState(() {
        _imageFiles.add(image);
      });
    }
  }

  Future<void> _pickImage() async {
    final List<File> images = await ImageUtils.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    if (_noteController.text.trim().isEmpty && _imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập ghi chú hoặc thêm ảnh trước khi gửi báo cáo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to submit the report
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo biên bản giao nhận đã được gửi thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi gửi báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biên bản giao nhận'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildNoteSection(),
            const SizedBox(height: 16),
            _buildImageSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: Colors.purple.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Gửi báo cáo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    String formattedDate = AppDateUtils.formatDateTime(_reportTime);
    
    return InfoCard(
      title: 'Thông tin báo cáo',
      children: [
        InfoRow(label: 'Mã chuyến đi', value: widget.tripId),
        InfoRow(label: 'Tên tài xế', value: _driverName),
        InfoRow(label: 'Thời gian báo cáo', value: formattedDate),
      ],
    );
  }

  Widget _buildNoteSection() {
    return InfoCard(
      title: 'Ghi chú',
      children: [
        TextFormField(
          controller: _noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú về việc giao nhận...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return ImageSection(
      title: 'Hình ảnh biên bản',
      imageFiles: _imageFiles,
      onTakePhoto: _takePhoto,
      onPickImage: _pickImage,
      onRemoveImage: _removeImage,
      cameraButtonColor: Colors.blue.shade700,
      galleryButtonColor: Colors.amber.shade700,
      emptyMessage: 'Chưa có ảnh nào\nChọn "Chọn nhiều ảnh" để tải lên nhiều ảnh cùng lúc',
    );
  }
}
