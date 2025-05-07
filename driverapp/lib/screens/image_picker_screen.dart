import 'dart:io';
import 'package:flutter/material.dart';
import '../components/image_picker/image_picker_component.dart';

class ImagePickerScreen extends StatelessWidget {
  final String title;
  final int maxImages;
  final String buttonText;
  final List<File>? initialImages;

  const ImagePickerScreen({
    Key? key,
    required this.title,
    this.maxImages = 10,
    required this.buttonText,
    this.initialImages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ImagePickerComponent(
        title: title,
        maxImages: maxImages,
        buttonText: buttonText,
        initialImages: initialImages,
      ),
    );
  }
}