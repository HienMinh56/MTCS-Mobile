import 'package:flutter/material.dart';
import 'package:driverapp/models/driver_profile.dart';
import 'package:driverapp/services/profile_service.dart';
import 'package:driverapp/utils/color_constants.dart';

class ProfileScreen extends StatefulWidget {
  final String driverId;

  const ProfileScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  DriverProfile? _driverProfile;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final profile = await _profileService.getDriverProfile(widget.driverId);
      setState(() {
        _driverProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
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
        _buildWorkingTimeSection(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: ColorConstants.backgroundLight,
            shape: BoxShape.circle,
            border: Border.all(width: 4, color: Theme.of(context).primaryColor.withOpacity(0.2)),
          ),
          child: const Center(
            child: Icon(
              Icons.person,
              size: 70,
              color: ColorConstants.profileColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _driverProfile!.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ID: ${_driverProfile!.driverId}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    
    switch (_driverProfile!.status) {
      case 1:
        badgeColor = Colors.green;
        statusText = 'Đang hoạt động';
        break;
      case 0:
        badgeColor = Colors.grey;
        statusText = 'Không hoạt động';
        break;
      default:
        badgeColor = Colors.orange;
        statusText = 'Không xác định';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
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
            const Text(
              'Thông Tin Liên Hệ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow(Icons.email, 'Email', _driverProfile!.email),
            _buildInfoRow(Icons.phone, 'Số Điện Thoại', _driverProfile!.phoneNumber),
            _buildInfoRow(
              Icons.calendar_today, 
              'Ngày Tham Gia', 
              _formatDate(_driverProfile!.createdDate)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingTimeSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thời Gian Làm Việc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildTimeRow(
              'Tổng Thời Gian Làm Việc',
              _profileService.formatWorkingTimeVietnamese(_driverProfile!.totalWorkingTime),
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildTimeRow(
              'Tuần Này',
              _profileService.formatWorkingTimeVietnamese(_driverProfile!.currentWeekWorkingTime),
              Colors.green,
            ),
          ],
        ),
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

  Widget _buildTimeRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Không có';
    }
  }
}
