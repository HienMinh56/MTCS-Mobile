class ValidatorUtils {
  static String? validateRequired(String? value, String errorMessage) {
    if (value == null || value.trim().isEmpty) {
      return errorMessage;
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    
    final bool emailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim());
    if (!emailValid) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }
  
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    
    final bool phoneValid = RegExp(r'^[0-9]{10,11}$').hasMatch(value.trim());
    if (!phoneValid) {
      return 'Số điện thoại phải có 10-11 số';
    }
    
    return null;
  }
  
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    
    if (value.length < minLength) {
      return '$fieldName phải có ít nhất $minLength ký tự';
    }
    
    return null;
  }
  
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    
    if (double.tryParse(value.replaceAll(',', '.')) == null) {
      return '$fieldName phải là số hợp lệ';
    }
    
    return null;
  }
  
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) {
      return numberError;
    }
    
    final number = double.parse(value!.replaceAll(',', '.'));
    if (number <= 0) {
      return '$fieldName phải lớn hơn 0';
    }
    
    return null;
  }
}
