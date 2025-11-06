import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import 'dart:ui' as ui;

/// Share card service for creating and sharing score cards
class ShareCardService {
  final _logger = Logger();

  /// Create and share score card
  Future<bool> shareScoreCard({
    required int score,
    required int streak,
    required GlobalKey cardKey,
  }) async {
    try {
      // Capture widget as image
      final imageBytes = await _captureWidget(cardKey);
      if (imageBytes == null) return false;

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/iam_score_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // Share
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Can you beat my score of $score on I AM? 🔥',
      );

      _logger.i('Score card shared');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to share score card', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Capture widget as PNG
  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      _logger.e('Failed to capture widget', error: e, stackTrace: stack);
      return null;
    }
  }
}
