import 'package:flutter/material.dart';

class StatusCounter extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const StatusCounter({
    super.key, 
    required this.label, 
    required this.count, 
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
