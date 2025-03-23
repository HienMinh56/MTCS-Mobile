import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:driverapp/models/delivery_report.dart';
import 'package:driverapp/services/image_service.dart';

class ReportImageCard extends StatelessWidget {
  final DeliveryReportFile file;
  final ImageService imageService;

  ReportImageCard({
    super.key, 
    required this.file,
    ImageService? imageService,
  }) : imageService = imageService ?? ImageService();

  @override
  Widget build(BuildContext context) {
    bool isImage = file.fileType.toLowerCase() == 'image';
    String formattedDate = DateFormat('dd/MM/yyyy').format(file.uploadDate);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage) ...[
            InkWell(
              onTap: () => imageService.showFullScreenImage(context, file.fileUrl),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: file.fileUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [          
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isImage ? Icons.image : Icons.insert_drive_file,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      file.fileType,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),           
              ],
            ),
          ),
        ],
      ),
    );
  }
}
