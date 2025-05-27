import 'package:driverapp/models/expense_report_type.dart';
import 'package:driverapp/services/expense_report_service.dart';

class ExpenseTypeManager {
  // Single instance to manage all expense report types
  static final ExpenseTypeManager _instance = ExpenseTypeManager._internal();
  factory ExpenseTypeManager() => _instance;
  ExpenseTypeManager._internal();

  // Cache expense report types
  List<ExpenseReportType>? _cachedReportTypes;

  // Flag to track initialization status
  bool _isInitialized = false;

  /// Initialize and load expense report types
  static Future<void> initialize() async {
    await _instance._loadExpenseReportTypes();
  }

  /// Get all expense report types
  List<ExpenseReportType> getAllExpenseReportTypes() {
    return _cachedReportTypes ?? [];
  }

  /// Check if manager is initialized
  bool get isInitialized => _isInitialized;

  /// Internal method to load expense report types
  Future<void> _loadExpenseReportTypes() async {
    try {
      _cachedReportTypes = await ExpenseReportService.getAllExpenseReportTypes();
      _isInitialized = true;
    } catch (e) {
      print('Không thể tải loại báo cáo chi phí: $e');
      _isInitialized = false;
    }
  }

  /// Refresh expense report types data
  Future<void> refresh() async {
    await _loadExpenseReportTypes();
  }
}
