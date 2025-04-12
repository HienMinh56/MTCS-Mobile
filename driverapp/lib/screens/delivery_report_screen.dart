import 'dart:io';
import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:driverapp/components/info_card.dart';
import 'package:driverapp/components/info_row.dart';
import 'package:flutter/material.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/services/delivery_report_service.dart';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/date_utils.dart';

class DeliveryReportScreen extends StatefulWidget {
  final String tripId;
  final String userId;
  final Function(bool success)? onReportSubmitted;

  const DeliveryReportScreen({
    Key? key,
    required this.tripId,
    required this.userId,
    this.onReportSubmitted,
  }) : super(key: key);

  @override
  State<DeliveryReportScreen> createState() => _DeliveryReportScreenState();
}

class _DeliveryReportScreenState extends State<DeliveryReportScreen> {
  final ProfileService _profileService = ProfileService();
  final DeliveryReportService _reportService = DeliveryReportService();
  final TextEditingController _noteController = TextEditingController();
  final List<File> _imageFiles = [];
  String _driverName = 'Đang tải...';
  bool _isLoading = false;
  DateTime _reportTime = DateTime.now();

  // Validation constants
  static const int _maxNoteLength = 500;
  static const int _minNoteLength = 10;
  static const int _maxImageCount = 10;

  // Validation state variables
  String? _noteError;
  String? _imageError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadDriverName();
    _noteController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _noteController.removeListener(_validateForm);
    _noteController.dispose();
    super.dispose();
  }

  void _validateForm() {
    _validateNote();
    _validateImages();

    setState(() {
      _isFormValid = (_noteError == null && _imageError == null) &&
          (_noteController.text.trim().isNotEmpty || _imageFiles.isNotEmpty);
    });
  }

  void _validateNote() {
    final note = _noteController.text.trim();

    setState(() {
      if (note.isEmpty) {
        _noteError = null;
      } else if (note.length < _minNoteLength) {
        _noteError = 'Ghi chú quá ngắn (tối thiểu $_minNoteLength ký tự)';
      } else if (note.length > _maxNoteLength) {
        _noteError = 'Ghi chú quá dài (tối đa $_maxNoteLength ký tự)';
      } else {
        _noteError = null;
      }
    });
  }

  void _validateImages() {
    setState(() {
      if (_imageFiles.isEmpty) {
        _imageError = null;
      } else if (_imageFiles.length > _maxImageCount) {
        _imageError = 'Số lượng ảnh tối đa là $_maxImageCount';
      } else {
        _imageError = null;
      }
    });
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
      _validateForm();
    }
  }

  Future<void> _pickImage() async {
    final List<File> images = await ImageUtils.pickMultipleImages();
    if (images.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(images);
      });
      _validateForm();
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
    _validateForm();
  }

  Future<void> _submitReport() async {
    _validateForm();

    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin trước khi gửi báo cáo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool confirmed = await _showConfirmationDialog();
    if (!confirmed) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _reportService.submitDeliveryReport(
        tripId: widget.tripId,
        notes: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        imageFiles: _imageFiles.isNotEmpty ? _imageFiles : null,
      );

      if (result['success']) {
        if (mounted) {
          _onReportSuccess();
        }
      } else {
        throw Exception(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        _onReportFailure(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onReportSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Báo cáo đã được gửi thành công'),
        backgroundColor: Colors.green,
      ),
    );

    if (widget.onReportSubmitted != null) {
      widget.onReportSubmitted!(true);
    } else {
      Navigator.pop(context);
    }
  }

  void _onReportFailure(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lỗi gửi báo cáo: $message'),
        backgroundColor: Colors.red,
      ),
    );

    if (widget.onReportSubmitted != null) {
      widget.onReportSubmitted!(false);
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận gửi báo cáo'),
          content: const Text(
            'Sau khi gửi, báo cáo không thể chỉnh sửa. Vui lòng kiểm tra kỹ nội dung trước khi xác nhận gửi.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
              ),
              child: const Text('Xác nhận gửi', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ) ?? false;
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorText: _noteError,
            helperText: 'Tối thiểu $_minNoteLength ký tự, tối đa $_maxNoteLength ký tự',
            counterText: '${_noteController.text.length}/$_maxNoteLength',
          ),
          onChanged: (_) => _validateForm(),
        ),
        if (_noteController.text.isEmpty && _imageFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Vui lòng nhập ghi chú hoặc thêm ảnh',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImageSection(
          title: 'Hình ảnh biên bản',
          imageFiles: _imageFiles,
          onTakePhoto: _takePhoto,
          onPickImage: _pickImage,
          onRemoveImage: _removeImage,
          cameraButtonColor: Colors.blue.shade700,
          galleryButtonColor: Colors.amber.shade700,
          emptyMessage: 'Chưa có ảnh nào\nChọn "Chọn nhiều ảnh" để tải lên nhiều ảnh cùng lúc',
        ),
        if (_imageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              _imageError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
          child: Text(
            'Tối đa $_maxImageCount ảnh',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
