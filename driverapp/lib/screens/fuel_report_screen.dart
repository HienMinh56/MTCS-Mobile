import 'package:driverapp/components/delivery_report/image_section.dart';
import 'package:driverapp/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:driverapp/utils/image_utils.dart';
import 'package:driverapp/utils/validation_utils.dart';
import 'package:driverapp/services/fuel_report_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  bool _isLoadingLocation = false;

  // Add state variables for validation errors
  String? _fuelAmountError;
  String? _priceError;
  String? _locationError;
  String? _imagesError;

  @override
  void initState() {
    super.initState();
    // Add listeners to validate on text changes
    _fuelAmountController.addListener(_validateFuelAmount);
    _priceController.addListener(_validatePrice);
    _locationController.addListener(_validateLocation);
  }

  // Validation methods
  void _validateFuelAmount() {
    setState(() {
      _fuelAmountError =
          ValidationUtils.validateFuelAmount(_fuelAmountController.text);
    });
  }

  void _validatePrice() {
    setState(() {
      _priceError = ValidationUtils.validateFuelCost(_priceController.text);
    });
  }

  void _validateLocation() {
    setState(() {
      _locationError =
          ValidationUtils.validateLocation(_locationController.text);
    });
  }

  void _validateImages() {
    setState(() {
      _imagesError = ValidationUtils.validateImages(_selectedImages);
    });
  }

  // Validate all fields at once
  bool _validateAllFields() {
    _validateFuelAmount();
    _validatePrice();
    _validateLocation();
    _validateImages();

    return _fuelAmountError == null &&
        _priceError == null &&
        _locationError == null &&
        _imagesError == null;
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

  Future<void> _submitReport() async {
    // Validate all fields before submitting
    if (!_validateAllFields()) {
      // Error messages are already shown in the form fields, no need for an additional SnackBar
      return;
    }

    // Parse values (we know they're valid at this point)
    final double refuelAmount = double.parse(_fuelAmountController.text);
    final double fuelCost = double.parse(_priceController.text);
    
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
                  Icons.local_gas_station,
                  'Số lít nhiên liệu:',
                  '$refuelAmount lít',
                  Colors.blue,
                ),
                _buildConfirmInfoRow(
                  Icons.monetization_on,
                  'Giá nhiên liệu:',
                  '$fuelCost VND',
                  Colors.orange,
                ),
                _buildConfirmInfoRow(
                  Icons.location_on,
                  'Vị trí đổ nhiên liệu:',
                  _locationController.text,
                  Colors.green,
                ),
                _buildConfirmInfoRow(
                  Icons.image,
                  'Số ảnh đính kèm:',
                  '${_selectedImages.length} ảnh',
                  Colors.purple,
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
      DialogHelper.showSnackBar(
        context: context,
        message: 'Báo cáo đã được gửi thành công!',
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
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
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
          DialogHelper.showSnackBar(
            context: context,
            message: 'Quyền truy cập vị trí bị từ chối',
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
          message: 'Quyền truy cập vị trí bị từ chối vĩnh viễn',
          isError: true,
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Try to get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';

          // Build address string from available components
          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address += address.isNotEmpty
                ? ', ${place.subLocality}'
                : place.subLocality!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            address +=
                address.isNotEmpty ? ', ${place.locality}' : place.locality!;
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            address += address.isNotEmpty
                ? ', ${place.administrativeArea}'
                : place.administrativeArea!;
          }

          setState(() {
            _locationController.text = address;
          });
        } else {
          // If no address is found, use the coordinates
          setState(() {
            _locationController.text =
                '${position.latitude}, ${position.longitude}';
          });
        }
      } catch (e) {
        // If geocoding fails, fallback to coordinates
        setState(() {
          _locationController.text =
              '${position.latitude}, ${position.longitude}';
        });
      }

      DialogHelper.showSnackBar(
        context: context,
        message: 'Đã lấy vị trí hiện tại',
        isError: false,
      );
    } catch (e) {
      DialogHelper.showSnackBar(
        context: context,
        message: 'Lỗi khi lấy vị trí: $e',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _fuelAmountController.removeListener(_validateFuelAmount);
    _priceController.removeListener(_validatePrice);
    _locationController.removeListener(_validateLocation);
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
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
      ),
      body: Container(
        color: Colors.white, // Thay đổi từ gradient sang màu trắng đơn giản
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car,
                          color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        widget.tripId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Fuel input section
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin nhiên liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Fuel amount input with validation
                        TextField(
                          controller: _fuelAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Số lít nhiên liệu đổ *',
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.blue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _fuelAmountError != null
                                      ? Colors.red
                                      : Colors.blue.shade700,
                                  width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _fuelAmountError != null
                                      ? Colors.red
                                      : Colors.blue.shade200),
                            ),
                            prefixIcon: Icon(Icons.local_gas_station,
                                color: _fuelAmountError != null
                                    ? Colors.red
                                    : Colors.blue.shade700),
                            suffixText: 'lít',
                            fillColor: Colors.white,
                            filled: true,
                            errorText: _fuelAmountError,
                          ),
                          onChanged: (value) => _validateFuelAmount(),
                        ),
                        const SizedBox(height: 16),

                        // Price input with validation
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Giá nhiên liệu *',
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.blue.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _priceError != null
                                      ? Colors.red
                                      : Colors.blue.shade700,
                                  width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _priceError != null
                                      ? Colors.red
                                      : Colors.blue.shade200),
                            ),
                            prefixIcon: Icon(Icons.monetization_on,
                                color: _priceError != null
                                    ? Colors.red
                                    : Colors.blue.shade700),
                            suffixText: 'VND',
                            fillColor: Colors.white,
                            filled: true,
                            errorText: _priceError,
                          ),
                          onChanged: (value) => _validatePrice(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location section with validation
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vị trí đổ nhiên liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Location input with validation
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Vị trí đổ nhiên liệu *',
                            labelStyle: TextStyle(color: Colors.green.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: Colors.green.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _locationError != null
                                      ? Colors.red
                                      : Colors.green.shade700,
                                  width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _locationError != null
                                      ? Colors.red
                                      : Colors.green.shade200),
                            ),
                            prefixIcon: Icon(Icons.location_on,
                                color: _locationError != null
                                    ? Colors.red
                                    : Colors.green.shade700),
                            suffixIcon: _isLoadingLocation
                                ? Container(
                                    margin: const EdgeInsets.all(12),
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green.shade700),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.my_location,
                                        color: _locationError != null
                                            ? Colors.red
                                            : Colors.green.shade700),
                                    tooltip: 'Lấy vị trí hiện tại',
                                    onPressed: _getCurrentLocation,
                                  ),
                            fillColor: Colors.white,
                            filled: true,
                            errorText: _locationError,
                          ),
                          onChanged: (value) {
                            // Remove leading spaces immediately when typing
                            if (value.startsWith(' ')) {
                              _locationController.text = value.trimLeft();
                              _locationController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _locationController.text.length),
                              );
                            }
                            _validateLocation();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ImageSection(
                  title: 'Ảnh hoá đơn *',
                  imageFiles: _selectedImages,
                  onTakePhoto: () {
                    _takePicture().then((_) => _validateImages());
                  },
                  onPickImage: () {
                    _pickImages().then((_) => _validateImages());
                  },
                  onRemoveImage: (index) {
                    _removeImage(index);
                    _validateImages();
                  },
                  cameraButtonColor: Colors.blue.shade700,
                  galleryButtonColor: Colors.amber.shade700,
                  emptyMessage:
                      'Chưa có ảnh nào\nChọn "Chọn nhiều ảnh" để tải lên nhiều ảnh cùng lúc',
                  crossAxisCount: 2,
                  errorText: _imagesError,
                ),

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Gửi báo cáo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
