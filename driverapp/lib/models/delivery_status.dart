class DeliveryStatus {
  final String statusId;
  final String statusName;
  final int isActive;
  final int statusIndex;

  DeliveryStatus({
    required this.statusId,
    required this.statusName,
    required this.isActive,
    required this.statusIndex,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      statusId: json['statusId'] ?? '',
      statusName: json['statusName'] ?? '',
      isActive: json['isActive'] ?? 0,
      statusIndex: json['statusIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusId': statusId,
      'statusName': statusName,
      'statusIndex': statusIndex,
      'isActive': isActive,
    };
  }

  @override
  String toString() => statusName;
}
