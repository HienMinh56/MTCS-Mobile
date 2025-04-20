import 'package:flutter/material.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/formatters.dart';

class TripFilterPanel extends StatefulWidget {
  final String? statusFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final String? trackingCodeFilter;
  final Function(String? status, DateTime? startDate, DateTime? endDate, String? trackingCode) onApplyFilter;
  final VoidCallback onResetFilter;
  final bool showStatusFilter; // Thêm tham số mới để điều khiển hiển thị bộ lọc trạng thái

  const TripFilterPanel({
    Key? key,
    this.statusFilter,
    this.startDateFilter,
    this.endDateFilter,
    this.trackingCodeFilter,
    required this.onApplyFilter,
    required this.onResetFilter,
    this.showStatusFilter = true, // Mặc định là hiển thị
  }) : super(key: key);

  @override
  State<TripFilterPanel> createState() => _TripFilterPanelState();
}

class _TripFilterPanelState extends State<TripFilterPanel> {
  String? _statusFilter;
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  String? _trackingCodeFilter;
  final TextEditingController _trackingCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.statusFilter;
    _startDateFilter = widget.startDateFilter;
    _endDateFilter = widget.endDateFilter;
    _trackingCodeFilter = widget.trackingCodeFilter;
    if (_trackingCodeFilter != null) {
      _trackingCodeController.text = _trackingCodeFilter!;
    }
  }

  @override
  void dispose() {
    _trackingCodeController.dispose();
    super.dispose();
  }

  // Select date range helper method
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDateFilter ?? DateTime.now()) 
          : (_endDateFilter ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: ColorConstants.primaryColor,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDateFilter = picked;
        } else {
          _endDateFilter = picked;
        }
      });
    }
  }

  // Reset all filters
  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _startDateFilter = null;
      _endDateFilter = null;
      _trackingCodeFilter = null;
      _trackingCodeController.clear();
    });
    widget.onResetFilter();
  }

  // Apply filters
  void _applyFilters() {
    setState(() {
      _trackingCodeFilter = _trackingCodeController.text.isNotEmpty ? _trackingCodeController.text.trim() : null;
    });
    widget.onApplyFilter(_statusFilter, _startDateFilter, _endDateFilter, _trackingCodeFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with reset option
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Lọc Danh Sách",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: ColorConstants.accentColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Đặt lại"),
              ),
            ],
          ),
          
          const Divider(),
          
          // Tracking code filter
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Mã vận đơn",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _trackingCodeController,
              decoration: InputDecoration(
                hintText: 'Nhập mã vận đơn...',
                border: InputBorder.none,
                suffixIcon: _trackingCodeController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _trackingCodeController.clear();
                          });
                        },
                        child: Icon(Icons.clear, size: 18, color: Colors.grey.shade600),
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status filter dropdown
          if (widget.showStatusFilter) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Trạng thái",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _statusFilter,
                  hint: const Text('Tất cả'),
                  icon: const Icon(Icons.arrow_drop_down, color: ColorConstants.primaryColor),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'completed',
                      child: Text('Hoàn thành'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'canceled',
                      child: Text('Đã hủy'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Date filter section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Thời gian bắt đầu",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          
          // Date selection inputs with better styling
          Row(
            children: [
              // Start date
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today, 
                          size: 16, 
                          color: ColorConstants.primaryColor
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDateFilter != null
                                ? DateFormatter.formatDate(_startDateFilter!)
                                : 'Từ ngày',
                            style: TextStyle(
                              color: _startDateFilter != null ? Colors.black : Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_startDateFilter != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _startDateFilter = null;
                              });
                            },
                            child: Icon(Icons.clear, size: 16, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Arrow between dates
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward, 
                  size: 16, 
                  color: Colors.grey.shade600
                ),
              ),
              
              // End date
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today, 
                          size: 16, 
                          color: ColorConstants.primaryColor
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDateFilter != null
                                ? DateFormatter.formatDate(_endDateFilter!)
                                : 'Đến ngày',
                            style: TextStyle(
                              color: _endDateFilter != null ? Colors.black : Colors.grey,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_endDateFilter != null)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _endDateFilter = null;
                              });
                            },
                            child: Icon(Icons.clear, size: 16, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
