import 'package:flutter/material.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class IncidentConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function(String, List<File>, List<File>) onConfirm;

  const IncidentConfirmationDialog({
    Key? key,
    required this.report,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<IncidentConfirmationDialog> createState() => _IncidentConfirmationDialogState();
}

class _IncidentConfirmationDialogState extends State<IncidentConfirmationDialog> {
  final TextEditingController resolutionController = TextEditingController();
  final List<File> resolutionImages = []; // Type 2 (resolution proof)
  final List<File> receiptImages = [];    // Type 3 (receipts)

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Title
              const Text(
                'Xác nhận giải quyết sự cố',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Make content scrollable to prevent overflow
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resolution details input
                      TextField(
                        controller: resolutionController,
                        decoration: const InputDecoration(
                          labelText: 'Chi tiết giải quyết',
                          hintText: 'Mô tả cách giải quyết sự cố',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Existing images section
                      const Text(
                        'Hình ảnh hiện tại:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildExistingImages(),
                      const SizedBox(height: 16),
                      
                      // Resolution images (Type 2)
                      const Text(
                        'Hình ảnh kết quả giải quyết:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildImageUploadSection(
                        resolutionImages, 
                        ColorConstants.primaryColor,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Receipt images (Type 3)
                      const Text(
                        'Hình ảnh hóa đơn (nếu có):',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      _buildImageUploadSection(
                        receiptImages,
                        Colors.amber,
                        iconData: Icons.receipt_long,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Dialog buttons
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onConfirm(
                        resolutionController.text,
                        resolutionImages,
                        receiptImages,
                      );
                    },
                    child: const Text('Xác nhận'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingImages() {
    if (widget.report['incidentReportsFiles'] != null && 
        (widget.report['incidentReportsFiles'] as List).isNotEmpty) {
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: (widget.report['incidentReportsFiles'] as List).length,
          itemBuilder: (context, index) {
            final file = widget.report['incidentReportsFiles'][index];
            return Container(
              margin: const EdgeInsets.only(right: 8),
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  file['fileUrl'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.error)),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return const Text('Không có hình ảnh');
    }
  }

  Widget _buildImageUploadSection(List<File> images, Color borderColor, {IconData iconData = Icons.add_a_photo}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...images.map((file) => buildImagePreview(
          file,
          borderColor,
          () {
            setState(() {
              images.remove(file);
            });
          },
        )).toList(),
        
        // Add image button
        GestureDetector(
          onTap: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              setState(() {
                images.add(File(image.path));
              });
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, size: 30),
          ),
        ),
      ],
    );
  }

  // Helper method to build image preview
  Widget buildImagePreview(File file, Color borderColor, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
