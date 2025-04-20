import 'package:flutter/material.dart';
import 'package:driverapp/models/driver_profile.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/services/auth_service.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:intl/intl.dart';
import 'package:driverapp/services/working_time_service.dart'; // Add this import
import 'package:driverapp/utils/validation_utils.dart'; // Import validation utils

class ProfileScreen extends StatefulWidget {
  final String driverId;

  const ProfileScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final WorkingTimeService _workingTimeService = WorkingTimeService(); // Add this line
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isUpdating = false;
  DriverProfile? _driverProfile;
  String _errorMessage = '';
  String? _updateMessage;
  bool _updateSuccess = false;

  // Add these properties
  String _weeklyWorkingTime = '0 giờ 0 phút';
  String _dailyWorkingTime = '0 giờ 0 phút';
  bool _isLoadingWorkingTime = true;

  // Add these properties for date range working time
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();
  String _rangeWorkingTime = '';
  bool _isLoadingRangeTime = false;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
      _isLoadingWorkingTime = true;
      _errorMessage = '';
    });

    try {
      final profile = await _profileService.getDriverProfile(widget.driverId);
      setState(() {
        _driverProfile = profile;
        _isLoading = false;

        // Initialize form controllers
        _fullNameController.text = profile.fullName;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber;
        if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) {
          try {
            final date = DateTime.parse(profile.dateOfBirth!);
            _dobController.text = DateFormat('yyyy-MM-dd').format(date);
          } catch (e) {
            _dobController.text = '';
          }
        }
      });

      // Load the working time data
      _loadWorkingTimeData();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingWorkingTime = false;
      });
    }
  }

  // Add this method to load working time data
  Future<void> _loadWorkingTimeData() async {
    try {
      final weeklyTime = await _workingTimeService.getWeeklyWorkingTime(widget.driverId);
      final dailyTime = await _workingTimeService.getDailyWorkingTime(widget.driverId);

      setState(() {
        _weeklyWorkingTime = weeklyTime;
        _dailyWorkingTime = dailyTime;
        _isLoadingWorkingTime = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWorkingTime = false;
      });
    }
  }

  // Add this method to fetch working time for a specific range
  Future<void> _loadRangeWorkingTime() async {
    setState(() {
      _isLoadingRangeTime = true;
    });

    try {
      final rangeTime = await _workingTimeService.getWorkingTimeRange(
        widget.driverId,
        _fromDate,
        _toDate,
      );

      setState(() {
        _rangeWorkingTime = rangeTime;
        _isLoadingRangeTime = false;
      });
    } catch (e) {
      setState(() {
        _rangeWorkingTime = 'Lỗi: ${e.toString()}';
        _isLoadingRangeTime = false;
      });
    }
  }

  // Show date range picker dialog
  Future<void> _showDateRangeDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fromDate,
        end: _toDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadRangeWorkingTime();
    }
  }

  // Thêm phương thức xác nhận trước khi cập nhật
  Future<void> _showConfirmUpdateDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.help_outline, color: Colors.amber, size: 28),
              SizedBox(width: 8),
              Text('Xác nhận thay đổi', style: TextStyle(color: Colors.blue)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bạn có chắc chắn muốn cập nhật thông tin hồ sơ? Sau khi cập nhật, bạn sẽ cần đăng nhập lại để áp dụng thay đổi.'),
              const SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Xác nhận'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateProfile();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
      _updateMessage = null;
    });

    try {
      final updatedProfile = await _profileService.updateDriverProfile(
        widget.driverId,
        _fullNameController.text,
        _emailController.text,
        _phoneController.text,
        _dobController.text,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      setState(() {
        _driverProfile = updatedProfile;
        _isUpdating = false;
        _isEditing = false;
        _updateSuccess = true;
        _updateMessage = 'Cập nhật thông tin thành công';
        _passwordController.clear();
      });

      // Show success message based on _updateSuccess
      if (_updateSuccess) {
        // Show success message and logout confirmation
        _showUpdateSuccessAndLogoutDialog();
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _updateSuccess = false;
        _updateMessage = 'Lỗi: ${e.toString()}';
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_updateMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdateSuccessAndLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dialog dismissal with back button
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.blue, size: 28),
                SizedBox(width: 8),
                Text('Thành công', style: TextStyle(color: Colors.blue)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin hồ sơ của bạn đã được cập nhật thành công.'),
                const SizedBox(height: 12),
                Text(
                  'Bạn cần đăng nhập lại để áp dụng thay đổi.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () async {
                  await AuthService.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Tài Xế'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isLoading && _driverProfile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _isEditing
                    ? _buildEditProfileView()
                    : _buildProfileView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải hồ sơ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDriverProfile,
              child: const Text('Thử Lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    if (_driverProfile == null) {
      return const Center(child: Text('Không có thông tin hồ sơ'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 24),
        _buildInfoSection(),
        const SizedBox(height: 24),
        _buildWorkStatisticsSection(),
      ],
    );
  }

  Widget _buildEditProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Chỉnh Sửa Thông Tin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: 'Họ và Tên',
                        prefixIcon: Icon(Icons.person, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[700]),
                      ),
                      validator: ValidationUtils.validateName,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[700]),
                      ),
                      validator: ValidationUtils.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Số Điện Thoại',
                        prefixIcon: Icon(Icons.phone, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[700]),
                      ),
                      validator: ValidationUtils.validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth Field
                    TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Ngày Sinh (YYYY-MM-DD)',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: Icon(Icons.cake, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today, color: Colors.blue),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.blue,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          try {
                            DateTime.parse(value);
                          } catch (e) {
                            return 'Ngày không hợp lệ. Vui lòng sử dụng định dạng YYYY-MM-DD';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field (Optional)
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật Khẩu (Để trống nếu không thay đổi)',
                        prefixIcon: Icon(Icons.lock, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey[700]),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                            // Reset form data
                            _fullNameController.text = _driverProfile!.fullName;
                            _emailController.text = _driverProfile!.email;
                            _phoneController.text = _driverProfile!.phoneNumber;
                            if (_driverProfile!.dateOfBirth != null) {
                              try {
                                final date = DateTime.parse(_driverProfile!.dateOfBirth!);
                                _dobController.text = DateFormat('yyyy-MM-dd').format(date);
                              } catch (e) {
                                _dobController.text = '';
                              }
                            }
                            _passwordController.clear();
                          });
                        },
                  icon: const Icon(Icons.cancel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 2,
                  ),
                  label: const Text('Hủy'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _showConfirmUpdateDialog,
                  icon: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 3,
                  ),
                  label: const Text('Lưu Thay Đổi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ColorConstants.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(width: 4, color: Theme.of(context).primaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _driverProfile!.fullName.isNotEmpty ? _driverProfile!.fullName : 'Không có tên',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'ID: ${_driverProfile!.driverId}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (_driverProfile!.status) {
      case 2:
        badgeColor = Colors.blue;
        statusText = 'Đang giao hàng';
        statusIcon = Icons.local_shipping;
        break;
      case 1:
        badgeColor = Colors.green;
        statusText = 'Đang hoạt động';
        statusIcon = Icons.check_circle;
        break;
      case 0:
        badgeColor = Colors.grey;
        statusText = 'Không hoạt động';
        statusIcon = Icons.do_not_disturb_on;
        break;
      default:
        badgeColor = Colors.orange;
        statusText = 'Không xác định';
        statusIcon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.contact_mail, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Thông Tin Liên Hệ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.email, 'Email', _driverProfile!.email.isNotEmpty ? _driverProfile!.email : 'Không có'),
            _buildInfoRow(Icons.phone, 'Số Điện Thoại', _driverProfile!.phoneNumber.isNotEmpty ? _driverProfile!.phoneNumber : 'Không có'),
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày Tham Gia',
              _formatDate(_driverProfile!.createdDate),
            ),
            if (_driverProfile!.dateOfBirth != null && _driverProfile!.dateOfBirth!.isNotEmpty)
              _buildInfoRow(
                Icons.cake,
                'Ngày Sinh',
                _formatDate(_driverProfile!.dateOfBirth),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStatisticsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thống Kê Công Việc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showDateRangeDialog,
                  icon: const Icon(Icons.date_range, size: 18),
                  label: const Text('Ngày'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _isLoadingWorkingTime
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    children: [
                      _buildStatisticItem(
                        icon: Icons.date_range,
                        label: 'Thời Gian Làm Việc Tuần Này',
                        value: _weeklyWorkingTime,
                      ),
                      _buildStatisticItem(
                        icon: Icons.access_time,
                        label: 'Thời Gian Làm Việc Hôm Nay',
                        value: _dailyWorkingTime,
                      ),
                      if (_rangeWorkingTime.isNotEmpty)
                        _buildStatisticItem(
                          icon: Icons.date_range_outlined,
                          label: _isLoadingRangeTime 
                              ? 'Đang tải thời gian làm việc...' 
                              : 'Thời gian làm việc từ ${DateFormat('dd/MM/yyyy').format(_fromDate)} đến ${DateFormat('dd/MM/yyyy').format(_toDate)}',
                          value: _isLoadingRangeTime ? 'Đang tải...' : _rangeWorkingTime,
                        ),
                      _buildStatisticItem(
                        icon: Icons.local_shipping,
                        label: 'Tổng Số Đơn Hàng',
                        value: '${_driverProfile!.totalOrder}',
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Không có';
    }

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Không hợp lệ';
    }
  }
}
