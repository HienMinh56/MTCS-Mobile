class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    return null;
  }

  /// Validate text không được bắt đầu bằng khoảng trắng và đảm bảo độ dài hợp lệ sau khi trim
  /// - [value]: giá trị text cần validate
  /// - [minLength]: độ dài tối thiểu (mặc định là 1)
  /// - [maxLength]: độ dài tối đa (mặc định là null - không giới hạn)
  /// - [fieldName]: tên trường để hiển thị trong thông báo lỗi (mặc định là "Nội dung")
  /// - [requiredMessage]: thông báo khi trường bắt buộc (mặc định là "Vui lòng nhập {fieldName}")
  static String? validateText(
    String? value, {
    int minLength = 1,
    int? maxLength,
    String fieldName = "Nội dung",
    String? requiredMessage,
  }) {
    // Kiểm tra null hoặc rỗng
    if (value == null || value.isEmpty) {
      return requiredMessage ?? 'Vui lòng nhập $fieldName';
    }
    
    // Kiểm tra bắt đầu bằng khoảng trắng
    if (value.startsWith(' ')) {
      return '$fieldName không được bắt đầu bằng khoảng trắng';
    }
    
    // Kiểm tra độ dài sau khi trim
    String trimmed = value.trim();
    
    if (trimmed.length < minLength) {
      return '$fieldName phải có ít nhất $minLength ký tự (không tính khoảng trắng đầu/cuối)';
    }
    
    if (maxLength != null && trimmed.length > maxLength) {
      return '$fieldName không được quá $maxLength ký tự';
    }
    
    return null;
  }
  
  /// Validate mô tả với các điều kiện thông dụng: không bắt đầu bằng khoảng trắng, có độ dài tối thiểu và tối đa sau khi trim
  static String? validateDescription(
    String? value, {
    int minLength = 10,
    int maxLength = 500,
    String fieldName = "Mô tả",
  }) {
    return validateText(
      value, 
      minLength: minLength, 
      maxLength: maxLength, 
      fieldName: fieldName,
    );
  }
  
  /// Validate tiêu đề với các điều kiện thông dụng: không bắt đầu bằng khoảng trắng, có độ dài tối thiểu và tối đa sau khi trim
  static String? validateTitle(
    String? value, {
    int minLength = 3,
    int maxLength = 100,
    String fieldName = "Tiêu đề",
  }) {
    return validateText(
      value, 
      minLength: minLength, 
      maxLength: maxLength, 
      fieldName: fieldName,
    );
  }
  
  /// Validate location với các điều kiện thông dụng: không bắt đầu bằng khoảng trắng, có độ dài tối thiểu và tối đa sau khi trim
  static String? validateLocation(
    String? value, {
    int minLength = 5,
    int maxLength = 200,
    String fieldName = "Địa điểm",
  }) {
    return validateText(
      value, 
      minLength: minLength, 
      maxLength: maxLength, 
      fieldName: fieldName,
    );
  }
}
