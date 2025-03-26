import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double padding;
  final bool showLabel;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.padding = 4.0,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel && label.isNotEmpty)
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
