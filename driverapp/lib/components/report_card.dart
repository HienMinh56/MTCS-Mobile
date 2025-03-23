import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double elevation;
  final double margin;

  const ReportCard({
    Key? key,
    required this.child,
    required this.onTap,
    this.elevation = 4,
    this.margin = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: margin),
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
