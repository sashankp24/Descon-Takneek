// lib/services/video_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickVideo(ImageSource source) async {
    final pickedFile = await _picker.pickVideo(source: source);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<String?> generateThumbnail(String videoPath) async {
    return await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.PNG,
      maxWidth: 128,
      quality: 75,
    );
  }
}