class ValidationUtils {
  /// Validates a fuel amount value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateFuelAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số lít nhiên liệu';
    }

    final double? amount = double.tryParse(value);
    if (amount == null) {
      return 'Vui lòng nhập số hợp lệ';
    }

    if (amount <= 0) {
      return 'Số lít nhiên liệu phải lớn hơn 0';
    }

    return null;
  }

  /// Validates a fuel cost value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateFuelCost(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập giá nhiên liệu';
    }

    final double? cost = double.tryParse(value);
    if (cost == null) {
      return 'Vui lòng nhập số hợp lệ';
    }

    if (cost <= 0) {
      return 'Giá nhiên liệu phải lớn hơn 0';
    }

    return null;
  }

  /// Validates a location value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateLocation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập vị trí đổ nhiên liệu';
    }
    return null;
  }

  /// Validates if images are selected
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateImages(List<dynamic>? images) {
    if (images == null || images.isEmpty) {
      return 'Vui lòng tải lên ít nhất một ảnh';
    }
    return null;
  }
}
