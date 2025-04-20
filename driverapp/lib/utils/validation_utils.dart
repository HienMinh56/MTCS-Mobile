class ValidationUtils {
  /// Validates a fuel amount value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateFuelAmount(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
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
    if (value == null || value.isEmpty || value.trim().isEmpty) {
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
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập vị trí đổ nhiên liệu';
    }
    
    // Check for leading spaces
    if (value.startsWith(' ')) {
      return 'Vị trí không được bắt đầu bằng dấu cách';
    }
    
    // Check minimum length after trimming
    if (value.trim().length < 5) {
      return 'Địa điểm phải có ít nhất 5 ký tự';
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
  
  /// Validates a name value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateName(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập họ tên';
    }
    
    if (value.trim().length < 3) {
      return 'Họ tên phải có ít nhất 3 ký tự';
    }
    
    return null;
  }
  
  /// Validates an email value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Vui lòng nhập email hợp lệ';
    }
    
    return null;
  }
  
  /// Validates a phone number value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value.trim())) {
      return 'Số điện thoại không hợp lệ';
    }
    
    return null;
  }
}
