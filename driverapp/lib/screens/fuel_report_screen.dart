import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/validation_utils.dart';
import 'package:driverapp/services/fuel_report_service.dart';

class FuelReportScreen extends StatefulWidget {
  final String tripId;

  const FuelReportScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  State<FuelReportScreen> createState() => _FuelReportScreenState();
}

class _FuelReportScreenState extends State<FuelReportScreen> {
  final TextEditingController _fuelAmountController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final List<File> _selectedImages = [];

  Future<void> _pickImages() async {
    try {
      final List<File> pickedFiles = await ImageUtils.pickMultipleImages();
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm ${pickedFiles.length} ảnh'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
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
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm ảnh từ camera'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReport() async {
    // Validate inputs using ValidationUtils
    String? fuelAmountError = ValidationUtils.validateFuelAmount(_fuelAmountController.text);
    if (fuelAmountError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fuelAmountError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    String? fuelCostError = ValidationUtils.validateFuelCost(_priceController.text);
    if (fuelCostError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fuelCostError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    String? locationError = ValidationUtils.validateLocation(_locationController.text);
    if (locationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    String? imagesError = ValidationUtils.validateImages(_selectedImages);
    if (imagesError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(imagesError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Parse values (we know they're valid at this point)
    final double refuelAmount = double.parse(_fuelAmountController.text);
    final double fuelCost = double.parse(_priceController.text);
    
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
    final result = await FuelReportService.submitFuelReport(
      tripId: widget.tripId,
      refuelAmount: refuelAmount,
      fuelCost: fuelCost,
      location: _locationController.text,
      images: _selectedImages,
    );
    
    // Close loading dialog
    Navigator.pop(context);
    
    // Handle the result
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fuelAmountController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Đổ Nhiên Liệu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chuyến đi #${widget.tripId}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              // Fuel amount input
              TextField(
                controller: _fuelAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số lít nhiên liệu đổ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_gas_station),
                  suffixText: 'lít',
                ),
              ),
              const SizedBox(height: 16),
              
              // Price input
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá nhiên liệu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: 'VND',
                ),
              ),
              const SizedBox(height: 16),
              
              // Location input
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Vị trí đổ nhiên liệu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 24),
              
              // Replace the image upload section with the new component
              ImageSection(
                title: 'Ảnh hoá đơn',
                imageFiles: _selectedImages,
                onTakePhoto: _takePicture,
                onPickImage: _pickImages,
                onRemoveImage: _removeImage,
                cameraButtonColor: Colors.blue.shade700,
                galleryButtonColor: Colors.amber.shade700,
                emptyMessage: 'Chưa có ảnh nào\nChọn "Chọn nhiều ảnh" để tải lên nhiều ảnh cùng lúc',
                crossAxisCount: 2,
              ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text(
                    'Gửi báo cáo',
                    style: TextStyle(fontSize: 16),
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