class DeliveryStatus {
  final String statusId;
  final String statusName;
  final int statusIndex;
  final bool isActive;

  DeliveryStatus({
    required this.statusId,
    required this.statusName,
    required this.statusIndex,
    required this.isActive,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      statusId: json['statusId'] as String,
      statusName: json['statusName'] as String,
      statusIndex: json['statusIndex'] as int,
      isActive: json['isActive'] == 1,
    );
  }

  @override
  String toString() => statusName;
}
