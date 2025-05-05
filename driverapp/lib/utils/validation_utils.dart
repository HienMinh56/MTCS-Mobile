class ValidationUtils {
  /// Validates a fuel amount value
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateFuelAmount(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập số lít nhiên liệu';
    }

    // Check for leading zeros or invalid first characters
    if (value.startsWith('0')) {
      return 'Số lít nhiên liệu không được bắt đầu bằng số 0';
    }

    if (!RegExp(r'^[1-9][\d]*\.?[\d]*$').hasMatch(value)) {
      return 'Số lít nhiên liệu phải bắt đầu bằng số từ 1-9';
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

    // Check for leading zeros or invalid first characters
    if (value.startsWith('0')) {
      return 'Giá nhiên liệu không được bắt đầu bằng số 0';
    }

    if (!RegExp(r'^[1-9][\d]*\.?[\d]*$').hasMatch(value)) {
      return 'Giá nhiên liệu phải bắt đầu bằng số từ 1-9';
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
    
    // Added validation for maximum number of images
    if (images.length > 10) {
      return 'Số lượng ảnh không được vượt quá 10 ảnh';
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

  /// Validates a description for incident reports
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateIncidentDescription(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập mô tả sự cố';
    }
    
    // Check for leading spaces
    if (value.startsWith(' ')) {
      return 'Không được bắt đầu bằng khoảng trắng';
    }
    
    // Check for special characters at the beginning
    if (value.trim().isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(value.trim())) {
      return 'Không được bắt đầu bằng ký tự đặc biệt';
    }
    
    // Check minimum length after trimming
    if (value.trim().length < 10) {
      return 'Mô tả phải có ít nhất 10 ký tự';
    }
    
    // Check maximum length
    if (value.trim().length > 500) {
      return 'Mô tả không được quá 500 ký tự';
    }
    
    return null;
  }
  
  /// Validates a incident report location
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateIncidentLocation(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập địa điểm sự cố';
    }
    
    // Check for leading spaces
    if (value.startsWith(' ')) {
      return 'Không được bắt đầu bằng khoảng trắng';
    }
    
    // Check for special characters at the beginning
    if (value.trim().isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(value.trim())) {
      return 'Không được bắt đầu bằng ký tự đặc biệt';
    }
    
    // Check minimum length after trimming
    if (value.trim().length < 5) {
      return 'Địa điểm phải có ít nhất 5 ký tự';
    }
    
    // Check maximum length
    if (value.trim().length > 200) {
      return 'Địa điểm không được quá 200 ký tự';
    }
    
    return null;
  }

  /// Validates incident report images
  ///
  /// Returns null if valid, or an error message if invalid
  static String? validateIncidentImages(int existingCount, int toRemoveCount, int toAddCount) {
    final int finalImagesCount = existingCount - toRemoveCount + toAddCount;
    
    if (finalImagesCount <= 0) {
      return 'Cần ít nhất 1 hình ảnh';
    } 
    
    if (finalImagesCount > 10) {
      return 'Không được vượt quá 10 hình ảnh';
    }
    
    return null;
  }
  
  /// Validates incident type
  /// 
  /// Returns null if valid, or an error message if invalid
  static String? validateIncidentType(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty) {
      return 'Vui lòng nhập loại sự cố';
    }
    
    // Check for leading spaces
    if (value.startsWith(' ')) {
      return 'Không được bắt đầu bằng khoảng trắng';
    }
    
    // Check for special characters at the beginning
    if (value.trim().isNotEmpty && RegExp(r'^[^\w\sÀ-ỹ]').hasMatch(value.trim())) {
      return 'Không được bắt đầu bằng ký tự đặc biệt';
    }
    
    // Check minimum length after trimming
    if (value.trim().length < 3) {
      return 'Loại sự cố phải có ít nhất 3 ký tự';
    }
    
    // Check maximum length
    if (value.trim().length > 100) {
      return 'Loại sự cố không được quá 100 ký tự';
    }
    
    return null;
  }
}
