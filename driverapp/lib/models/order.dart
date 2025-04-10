import 'dart:ffi';

import 'package:flutter/material.dart';

class Order {
  final String orderId;
  final String customerName;
  final String creator;
  final String deliveryDate;
  final String deliveryLocation;
  final String status;
  final String? shippingCode;
  final String? containerType;
  final double? containerTemperature;
  final double? orderWeight;
  final String? pickupDate;
  final String? pickupLocation;
  final int? deliveryType; // 1: "nhập", 2: "xuất"
  final String? containerReturnLocation;
  final String? transportationType; // "nhập" or "xuất"
  final String? containerId;
  final String? partnerName;
  final TimeOfDay? completionTime;
  final Double? distance;
  final String? partnerPhone;
  final bool? isPaid;

  Order({
    required this.orderId,
    required this.customerName,
    required this.creator,
    required this.deliveryDate,
    required this.deliveryLocation,
    required this.status,
    this.shippingCode,
    this.containerType,
    this.containerTemperature,
    this.orderWeight,
    this.pickupDate,
    this.pickupLocation,
    this.deliveryType,
    this.containerReturnLocation,
    this.transportationType,
    this.containerId,
    this.partnerName,
    this.completionTime,
    this.distance,
    this.partnerPhone,
    this.isPaid,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['orderId'] ?? '',
      customerName: json['customerName'] ?? '',
      creator: json['creator'] ?? '',
      deliveryDate: json['deliveryDate'] ?? '',
      deliveryLocation: json['deliveryLocation'] ?? '',
      status: json['status'] ?? '',
      shippingCode: json['shippingCode'],
      containerType: json['containerType'],
      containerTemperature: json['containerTemperature']?.toDouble(),
      orderWeight: json['orderWeight']?.toDouble(),
      pickupDate: json['pickupDate'],
      pickupLocation: json['pickupLocation'],
      deliveryType: json['deliveryType'],
      containerReturnLocation: json['containerReturnLocation'],
      transportationType: json['transportationType'],
      containerId: json['containerId'],
      partnerName: json['partnerName'],
      completionTime: json['completionTime'],
      distance: json['distance'],
      partnerPhone: json['partnerPhone'],
      isPaid: json['isPaid'],
    );
  }
}
