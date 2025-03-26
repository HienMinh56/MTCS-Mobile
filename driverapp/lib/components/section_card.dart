import 'package:flutter/material.dart';
import 'package:driverapp/utils/color_constants.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    Key? key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
