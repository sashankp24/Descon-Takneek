// lib/widgets/action_buttons.dart
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPickFromCamera;
  final VoidCallback onPickFromGallery;

  const ActionButtons({
    super.key,
    required this.isEnabled,
    required this.onPickFromCamera,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.black),
            iconSize: 32,
            onPressed: isEnabled ? onPickFromCamera : null,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.black),
            iconSize: 32,
            onPressed: isEnabled ? onPickFromGallery : null,
          ),
        ],
      ),
    );
  }
}
