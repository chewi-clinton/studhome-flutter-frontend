import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ModelViewerPage extends StatefulWidget {
  final String modelUrl;

  const ModelViewerPage({super.key, required this.modelUrl});

  @override
  State<ModelViewerPage> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewerPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // no background
        elevation: 0, // removes shadow for cleaner look
        title: Text(
          "3D Model View",
          style: textTheme.bodyLarge?.copyWith(
            color: textTheme.bodyLarge?.color, // adapts to light/dark
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: textTheme.bodyLarge?.color, // icons adapt too
        ),
      ),
      body: ModelViewer(
        src: widget.modelUrl,
        loading: Loading.auto,
        cameraControls: true,
        ar: false,
        autoRotate: true,
        backgroundColor: colorScheme.background, // adapts to light/dark
      ),
    );
  }
}
