// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:pdfx/pdfx.dart'; // 📄 for viewing PDFs

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Road Distress Detection',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.deepOrange),
//       home: const HomePage(),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});                   

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   List<String> savedVideos = [];
//   Map<String, String> reports = {}; // videoPath -> reportPath
//   Map<String, String> thumbnails = {}; // videoPath -> thumbnail image path

//   Future<void> _generateReport(String videoPath) async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (context) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text("Road Distress Report",
//                 style: pw.TextStyle(
//                     fontSize: 24, fontWeight: pw.FontWeight.bold)),
//             pw.SizedBox(height: 20),
//             pw.Text("Date: ${DateTime.now()}"),
//             pw.Text("Video: $videoPath"),
//             pw.Text("Detections: (Insert ML model results here)"),
//           ],
//         ),
//       ),
//     );

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//         "${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
//     await file.writeAsBytes(await pdf.save());

//     setState(() {
//       reports[videoPath] = file.path;
//     });
//   }

//   Future<void> _pickVideo({bool fromCamera = false}) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickVideo(
//       source: fromCamera ? ImageSource.camera : ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       final videoPath = pickedFile.path;

//       // generate thumbnail
//       final thumbPath = await VideoThumbnail.thumbnailFile(
//         video: videoPath,
//         imageFormat: ImageFormat.PNG,
//         maxWidth: 128,
//         quality: 75,
//       );

//       setState(() {
//         savedVideos.add(videoPath);
//         if (thumbPath != null) {
//           thumbnails[videoPath] = thumbPath;
//         }
//       });

//       _generateReport(videoPath);
//     }
//   }

//   void _openVideoPlayer(String videoPath) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => VideoPlayerScreen(videoPath: videoPath),
//       ),
//     );
//   }

//   void _handleReportTap(String reportPath) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Report Options"),
//         content: const Text("Do you want to view or share this report?"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => PdfViewerPage(reportPath: reportPath),
//                 ),
//               );
//             },
//             child: const Text("View"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               Share.shareXFiles([XFile(reportPath)],
//                   text: "Road Distress Report");
//             },
//             child: const Text("Share"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // 🔶 Top Bar
//           Container(
//             height: 60,
//             width: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.orange, Colors.deepOrange],
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//               ),
//             ),
//             child: const Center(
//               child: Text(
//                 "ROAD DISTRESS",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                 ),
//               ),
//             ),
//           ),

//           // 📋 Header row for Saved Videos / Reports
//           Container(
//             color: Colors.black12,
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: const Row(
//               children: [
//                 Expanded(
//                   child: Center(
//                     child: Text(
//                       "Saved Videos",
//                       style:
//                           TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: Center(
//                     child: Text(
//                       "Saved Reports",
//                       style:
//                           TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // 📋 Middle section: Each row has video + report
//           Expanded(
//             child: ListView.builder(
//               itemCount: savedVideos.length,
//               itemBuilder: (ctx, i) {
//                 final video = savedVideos[i];
//                 final reportPath = reports[video];

//                 return Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 16.0, horizontal: 8),
//                       child: Row(
//                         children: [
//                           // 🎥 Video Thumbnail (left)
//                           Expanded(
//                             child: Center(
//                               child: GestureDetector(
//                                 onTap: () => _openVideoPlayer(video),
//                                 child: thumbnails[video] != null
//                                     ? Image.file(File(thumbnails[video]!),
//                                         height: 100, fit: BoxFit.cover)
//                                     : const Icon(Icons.videocam, size: 64),
//                               ),
//                             ),
//                           ),

//                           // 📄 Report (right)
//                           Expanded(
//                             child: Center(
//                               child: reportPath != null
//                                   ? ListTile(
//                                       leading: const Icon(Icons.picture_as_pdf,
//                                           color: Colors.red),
//                                       title: Text(reportPath.split("/").last,
//                                           textAlign: TextAlign.center),
//                                       onTap: () => _handleReportTap(reportPath),
//                                     )
//                                   : const Text("No Report",
//                                       style: TextStyle(
//                                           fontSize: 14,
//                                           fontStyle: FontStyle.italic)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Divider(thickness: 1),
//                   ],
//                 );
//               },
//             ),
//           ),

//           // 🔶 Bottom Bar: Live Capture | Upload (with icons)
//           Container(
//             height: 60,
//             width: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.orange, Colors.deepOrange],
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.videocam, color: Colors.black),
//                   iconSize: 32,
//                   onPressed: () => _pickVideo(fromCamera: true),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.upload_file, color: Colors.black),
//                   iconSize: 32,
//                   onPressed: () => _pickVideo(fromCamera: false),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoPath;
//   const VideoPlayerScreen({super.key, required this.videoPath});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(File(widget.videoPath))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.videoPath.split("/").last)),
//       body: Center(
//         child: _controller.value.isInitialized
//             ? AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             : const CircularProgressIndicator(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _controller.value.isPlaying
//                 ? _controller.pause()
//                 : _controller.play();
//           });
//         },
//         child: Icon(
//           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }
// }

// class PdfViewerPage extends StatelessWidget {
//   final String reportPath;
//   const PdfViewerPage({super.key, required this.reportPath});

//   @override
//   Widget build(BuildContext context) {
//     final pdfController = PdfController(
//       document: PdfDocument.openFile(reportPath),
//     );

//     return Scaffold(
//       appBar: AppBar(title: Text(reportPath.split("/").last)),
//       body: PdfView(
//         controller: pdfController,
//       ),
//     );
//   }
// }
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:open_filex/open_filex.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Road Distress Detection',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.deepOrange),
//       home: const HomePage(),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   List<String> savedVideos = [];
//   Map<String, String> reports = {};
//   Map<String, String> thumbnails = {};

//   Future<void> _generateReport(String videoPath) async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (context) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text("Road Distress Report",
//                 style: pw.TextStyle(
//                     fontSize: 24, fontWeight: pw.FontWeight.bold)),
//             pw.SizedBox(height: 20),
//             pw.Text("Date: ${DateTime.now()}"),
//             pw.Text("Video: $videoPath"),
//             pw.SizedBox(height: 20),
//             pw.Text("Detections: (Insert ML model results here)"),
//           ],
//         ),
//       ),
//     );

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//         "${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
//     await file.writeAsBytes(await pdf.save());

//     setState(() {
//       reports[videoPath] = file.path;
//     });
//   }

//   Future<void> _pickVideo({bool fromCamera = false}) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickVideo(
//       source: fromCamera ? ImageSource.camera : ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       final videoPath = pickedFile.path;

//       final thumbPath = await VideoThumbnail.thumbnailFile(
//         video: videoPath,
//         imageFormat: ImageFormat.PNG,
//         maxWidth: 128,
//         quality: 75,
//       );

//       setState(() {
//         savedVideos.add(videoPath);
//         if (thumbPath != null) thumbnails[videoPath] = thumbPath;
//       });

//       _generateReport(videoPath);
//     }
//   }

//   void _openVideoPlayer(String videoPath) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => VideoPlayerScreen(videoPath: videoPath),
//       ),
//     );
//   }

//   void _handleReportTap(String reportPath) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Report Options"),
//         content: const Text("Do you want to view or share this report?"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               OpenFilex.open(reportPath); // external PDF viewer
//             },
//             child: const Text("View"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               Share.shareXFiles([XFile(reportPath)],
//                   text: "Road Distress Report");
//             },
//             child: const Text("Share"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openAssetFile(String assetPath, String filename) async {
//     final bytes = await rootBundle.load(assetPath);
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File("${dir.path}/$filename");
//     await file.writeAsBytes(bytes.buffer.asUint8List());
//     await OpenFilex.open(file.path);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "ROAD DISTRESS",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.deepOrange,
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.menu_book, color: Colors.black),
//             onSelected: (value) {
//               if (value == "guide") {
//                 _openAssetFile("assets/presentation.pdf", "presentationSSS.pdf");
//               } else if (value == "docs") {
//                 _openAssetFile("assets/documentation.pdf", "documentation.pdf");
//               }
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(value: "guide", child: Text("Presentation")),
//               const PopupMenuItem(
//                   value: "docs", child: Text("Documentation")),
//             ],
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 📋 Header row
//           Container(
//             color: Colors.black12,
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: const Row(
//               children: const [
//                 Expanded(
//                   child: Center(
//                     child: Text("Saved Videos",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16)),
//                   ),
//                 ),
//                 Expanded(
//                   child: Center(
//                     child: Text("Saved Reports",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16)),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // 📋 Video + Report rows
//           Expanded(
//             child: ListView.builder(
//               itemCount: savedVideos.length,
//               itemBuilder: (ctx, i) {
//                 final video = savedVideos[i];
//                 final reportPath = reports[video];

//                 return Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 16.0, horizontal: 8),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Center(
//                               child: GestureDetector(
//                                 onTap: () => _openVideoPlayer(video),
//                                 child: thumbnails[video] != null
//                                     ? Image.file(File(thumbnails[video]!),
//                                         height: 100, fit: BoxFit.cover)
//                                     : const Icon(Icons.videocam, size: 64),
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Center(
//                               child: reportPath != null
//                                   ? ListTile(
//                                       leading: const Icon(Icons.picture_as_pdf,
//                                           color: Colors.red),
//                                       title: Text(reportPath.split("/").last,
//                                           textAlign: TextAlign.center),
//                                       onTap: () => _handleReportTap(reportPath),
//                                     )
//                                   : const Text("No Report",
//                                       style: TextStyle(
//                                           fontSize: 14,
//                                           fontStyle: FontStyle.italic)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Divider(thickness: 1),
//                   ],
//                 );
//               },
//             ),
//           ),

//           // 🔶 Bottom bar with icons
//           Container(
//             height: 60,
//             width: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.orange, Colors.deepOrange],
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.videocam, color: Colors.black),
//                   iconSize: 32,
//                   onPressed: () => _pickVideo(fromCamera: true),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.upload_file, color: Colors.black),
//                   iconSize: 32,
//                   onPressed: () => _pickVideo(fromCamera: false),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoPath;
//   const VideoPlayerScreen({super.key, required this.videoPath});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(File(widget.videoPath))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.videoPath.split("/").last)),
//       body: Center(
//         child: _controller.value.isInitialized
//             ? AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             : const CircularProgressIndicator(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _controller.value.isPlaying
//                 ? _controller.pause()
//                 : _controller.play();
//           });
//         },
//         child: Icon(
//           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';

import 'ml_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Distress Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> savedVideos = [];
  Map<String, String> reports = {};
  Map<String, String> thumbnails = {};

  final mlService = MLService();
  String latestDetection = "Not analyzed yet";

  @override
  void initState() {
    super.initState();
    mlService.loadModel(); // load ML model + labels
  }

  Future<void> _generateReport(String videoPath) async {
    // Dummy input to model (replace with extracted frame data later)
    List<double> dummyInput = List.filled(224 * 224 * 3, 0.0); 
    String detectedClass = mlService.runModel(dummyInput);

    latestDetection = detectedClass;

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Road Distress Report",
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text("Date: ${DateTime.now()}"),
            pw.Text("Video: $videoPath"),
            pw.SizedBox(height: 20),
            pw.Text("Detection Result: $detectedClass"),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        "${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
    await file.writeAsBytes(await pdf.save());

    setState(() {
      reports[videoPath] = file.path;
    });
  }

  Future<void> _pickVideo({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile != null) {
      final videoPath = pickedFile.path;

      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxWidth: 128,
        quality: 75,
      );

      setState(() {
        savedVideos.add(videoPath);
        if (thumbPath != null) thumbnails[videoPath] = thumbPath;
      });

      _generateReport(videoPath);
    }
  }

  void _openVideoPlayer(String videoPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoPath: videoPath),
      ),
    );
  }

  void _handleReportTap(String reportPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report Options"),
        content: const Text("Do you want to view or share this report?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              OpenFilex.open(reportPath);
            },
            child: const Text("View"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(reportPath)],
                  text: "Road Distress Report");
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }

  Future<void> _openAssetFile(String assetPath, String filename) async {
    final bytes = await rootBundle.load(assetPath);
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$filename");
    await file.writeAsBytes(bytes.buffer.asUint8List());
    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ROAD DISTRESS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_book, color: Colors.black),
            onSelected: (value) {
              if (value == "guide") {
                _openAssetFile("assets/guide.pdf", "guide.pdf");
              } else if (value == "docs") {
                _openAssetFile("assets/documentation.pdf", "documentation.pdf");
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "guide", child: Text("Open Guide PDF")),
              const PopupMenuItem(
                  value: "docs", child: Text("Open Documentation PDF")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black12,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: const [
                Expanded(
                  child: Center(
                    child: Text("Saved Videos",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text("Saved Reports",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: savedVideos.length,
              itemBuilder: (ctx, i) {
                final video = savedVideos[i];
                final reportPath = reports[video];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _openVideoPlayer(video),
                                child: thumbnails[video] != null
                                    ? Image.file(File(thumbnails[video]!),
                                        height: 100, fit: BoxFit.cover)
                                    : const Icon(Icons.videocam, size: 64),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: reportPath != null
                                  ? ListTile(
                                      leading: const Icon(Icons.picture_as_pdf,
                                          color: Colors.red),
                                      title: Text(reportPath.split("/").last,
                                          textAlign: TextAlign.center),
                                      onTap: () => _handleReportTap(reportPath),
                                    )
                                  : const Text("No Report",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 1),
                  ],
                );
              },
            ),
          ),

          Container(
            height: 60,
            width: double.infinity,
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
                  onPressed: () => _pickVideo(fromCamera: true),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file, color: Colors.black),
                  iconSize: 32,
                  onPressed: () => _pickVideo(fromCamera: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.videoPath.split("/").last)),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:open_filex/open_filex.dart';
// import 'package:geolocator/geolocator.dart';

// import 'ml_service.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Road Distress Detection',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.deepOrange),
//       home: const HomePage(),
//     );
//   }
// }

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   List<String> savedVideos = [];
//   Map<String, String> reports = {};
//   Map<String, String> thumbnails = {};
//   Map<String, Position?> gpsData = {};

//   final mlService = MLService();
//   String latestDetection = "Not analyzed yet";

//   @override
//   void initState() {
//     super.initState();
//     mlService.loadModel();
//   }

//   Future<Position?> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return null;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     if (permission == LocationPermission.deniedForever) return null;

//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.best,
//     );
//   }

//   Future<void> _generateReport(String videoPath) async {
//     // Dummy input → replace with real frame preprocessing
//     List<double> dummyInput = List.filled(224 * 224 * 3, 0.0);
//     String detectedClass = mlService.runModel(dummyInput);

//     latestDetection = detectedClass;

//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.Page(
//         build: (context) => pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text("Road Distress Report",
//                 style: pw.TextStyle(
//                     fontSize: 24, fontWeight: pw.FontWeight.bold)),
//             pw.SizedBox(height: 20),
//             pw.Text("Date: ${DateTime.now()}"),
//             pw.Text("Video: ${videoPath.split('/').last}"),
//             pw.SizedBox(height: 20),
//             if (gpsData[videoPath] != null) ...[
//               pw.Text("Latitude: ${gpsData[videoPath]!.latitude}"),
//               pw.Text("Longitude: ${gpsData[videoPath]!.longitude}"),
//             ] else
//               pw.Text("GPS: Not Available"),
//             pw.SizedBox(height: 20),
//             pw.Text("Detection Result: $detectedClass"),
//           ],
//         ),
//       ),
//     );

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File(
//         "${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.pdf");
//     await file.writeAsBytes(await pdf.save());

//     setState(() {
//       reports[videoPath] = file.path;
//     });
//   }

//   Future<void> _pickVideo({bool fromCamera = false}) async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickVideo(
//       source: fromCamera ? ImageSource.camera : ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       final videoPath = pickedFile.path;

//       final thumbPath = await VideoThumbnail.thumbnailFile(
//         video: videoPath,
//         imageFormat: ImageFormat.PNG,
//         maxWidth: 128,
//         quality: 75,
//       );

//       Position? pos = await _getCurrentLocation();

//       setState(() {
//         savedVideos.add(videoPath);
//         if (thumbPath != null) thumbnails[videoPath] = thumbPath;
//         gpsData[videoPath] = pos;
//       });

//       _generateReport(videoPath);
//     }
//   }

//   void _openVideoPlayer(String videoPath) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => VideoPlayerScreen(videoPath: videoPath),
//       ),
//     );
//   }

//   void _handleReportTap(String reportPath) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Report Options"),
//         content: const Text("Do you want to view or share this report?"),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               OpenFilex.open(reportPath);
//             },
//             child: const Text("View"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               Share.shareXFiles([XFile(reportPath)],
//                   text: "Road Distress Report");
//             },
//             child: const Text("Share"),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _openAssetFile(String assetPath, String filename) async {
//     final bytes = await rootBundle.load(assetPath);
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File("${dir.path}/$filename");
//     await file.writeAsBytes(bytes.buffer.asUint8List());
//     await OpenFilex.open(file.path);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "ROAD DISTRESS",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.deepOrange,
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.menu_book, color: Colors.black),
//             onSelected: (value) {
//               if (value == "guide") {
//                 _openAssetFile("assets/guide.pdf", "guide.pdf");
//               } else if (value == "docs") {
//                 _openAssetFile("assets/documentation.pdf", "documentation.pdf");
//               }
//             },
//             itemBuilder: (context) => const [
//               PopupMenuItem(value: "guide", child: Text("Open Guide PDF")),
//               PopupMenuItem(
//                   value: "docs", child: Text("Open Documentation PDF")),
//             ],
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: Colors.black12,
//             padding: const EdgeInsets.symmetric(vertical: 8.0),
//             child: const Row(
//               children: [
//                 Expanded(
//                   child: Center(
//                     child: Text("Saved Videos",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16)),
//                   ),
//                 ),
//                 Expanded(
//                   child: Center(
//                     child: Text("Saved Reports",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: savedVideos.length,
//               itemBuilder: (ctx, i) {
//                 final video = savedVideos[i];
//                 final reportPath = reports[video];

//                 return Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 16.0, horizontal: 8),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: Column(
//                               children: [
//                                 GestureDetector(
//                                   onTap: () => _openVideoPlayer(video),
//                                   child: thumbnails[video] != null
//                                       ? Image.file(File(thumbnails[video]!),
//                                           height: 100, fit: BoxFit.cover)
//                                       : const Icon(Icons.videocam, size: 64),
//                                 ),
//                                 if (gpsData[video] != null)
//                                   Text(
//                                     "GPS: ${gpsData[video]!.latitude.toStringAsFixed(4)}, ${gpsData[video]!.longitude.toStringAsFixed(4)}",
//                                     style: const TextStyle(fontSize: 12),
//                                   ),
//                               ],
//                             ),
//                           ),
//                           Expanded(
//                             child: Center(
//                               child: reportPath != null
//                                   ? ListTile(
//                                       leading: const Icon(Icons.picture_as_pdf,
//                                           color: Colors.red),
//                                       title: Text(reportPath.split("/").last,
//                                           textAlign: TextAlign.center),
//                                       onTap: () => _handleReportTap(reportPath),
//                                     )
//                                   : const Text("No Report",
//                                       style: TextStyle(
//                                           fontSize: 14,
//                                           fontStyle: FontStyle.italic)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Divider(thickness: 1),
//                   ],
//                 );
//               },
//             ),
//           ),
//           Container(
//             height: 60,
//             width: double.infinity,
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.orange, Colors.deepOrange],
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//               ),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.videocam, color: Colors.black),
//                   iconSize: 32,
//                   onPressed: () => _pickVideo(fromCamera: true),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.upload_file, color: Colors.black),
//                   iconSize: 32,
//                   onPressed: () => _pickVideo(fromCamera: false),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class VideoPlayerScreen extends StatefulWidget {
//   final String videoPath;
//   const VideoPlayerScreen({super.key, required this.videoPath});

//   @override
//   State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
// }

// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.file(File(widget.videoPath))
//       ..initialize().then((_) {
//         setState(() {});
//         _controller.play();
//       });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.videoPath.split("/").last)),
//       body: Center(
//         child: _controller.value.isInitialized
//             ? AspectRatio(
//                 aspectRatio: _controller.value.aspectRatio,
//                 child: VideoPlayer(_controller),
//               )
//             : const CircularProgressIndicator(),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             _controller.value.isPlaying
//                 ? _controller.pause()
//                 : _controller.play();
//           });
//         },
//         child: Icon(
//           _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//         ),
//       ),
//     );
//   }
// }
