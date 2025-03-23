import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driverapp/components/full_screen_image_viewer.dart';

class ImageUtils {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<File?> takePhoto({int imageQuality = 80}) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  static Future<List<File>> pickMultipleImages({int imageQuality = 80}) async {
    final List<XFile>? images = await _imagePicker.pickMultiImage(
      imageQuality: imageQuality
    );
    if (images != null && images.isNotEmpty) {
      return images.map((image) => File(image.path)).toList();
    }
    return [];
  }

  static void showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  static void showFullImageDialog(BuildContext context, String imageUrl, {String? title, String? description}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: title != null ? Text(title, style: const TextStyle(color: Colors.black87)) : null,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              ),
              if (description != null && description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> openFileUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  static String formatUploadDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
