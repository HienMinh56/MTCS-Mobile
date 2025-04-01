class DeliveryStatus {
  final String statusId;
  final String statusName;
  final int statusIndex;
  final int isActive;

  DeliveryStatus({
    required this.statusId,
    required this.statusName,
    required this.statusIndex,
    required this.isActive,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      statusId: json['statusId'] ?? '',
      statusName: json['statusName'] ?? '',
      statusIndex: json['statusIndex'] ?? 0,
      isActive: json['isActive'] ?? 1,
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
