import 'dart:typed_data';

import 'package:pure_svg/src/loaders.dart';
import 'package:pure_svg/src/vector_graphics/vector_graphics/vector_graphics.dart';
import 'package:pure_ui/pure_ui.dart' as ui;
import 'package:universal_io/io.dart';

/// Cache for storing pre-converted SVG to PNG bytes
/// Key: file path, Value: PNG bytes
final Map<String, Uint8List> _svgConversionCache = {};

/// Utility class for handling SVG files
class SvgUtils {
  SvgUtils._();

  /// Default render size for SVG to PNG conversion (1024x1024 is suitable for all icon sizes)
  static const int defaultRenderSize = 1024;

  /// Checks if a file path is an SVG file
  static bool isSvgFile(String filePath) {
    return filePath.toLowerCase().endsWith('.svg');
  }

  /// Gets cached PNG bytes for an SVG file
  /// Returns null if not cached
  static Uint8List? getCachedPngBytes(String filePath) {
    return _svgConversionCache[filePath];
  }

  /// Caches PNG bytes for an SVG file
  static void cachePngBytes(String filePath, Uint8List bytes) {
    _svgConversionCache[filePath] = bytes;
  }

  /// Clears the SVG conversion cache
  static void clearCache() {
    _svgConversionCache.clear();
  }

  /// Converts an SVG file to PNG bytes
  ///
  /// [filePath] - Path to the SVG file
  /// [size] - Target size for the PNG output (default is 1024x1024)
  ///
  /// Returns PNG bytes as Uint8List, or null if conversion fails
  static Future<Uint8List?> svgToPngBytes(
    String filePath, {
    int size = defaultRenderSize,
  }) async {
    // Check cache first
    final cached = getCachedPngBytes(filePath);
    if (cached != null) {
      return cached;
    }

    try {
      final svgContent = File(filePath).readAsStringSync();
      final bytes = await svgStringToPngBytes(svgContent, size: size);
      if (bytes != null) {
        // Cache the result
        cachePngBytes(filePath, bytes);
      }
      return bytes;
    } catch (e) {
      return null;
    }
  }

  /// Converts an SVG string to PNG bytes
  ///
  /// [svgContent] - SVG content as string
  /// [size] - Target size for the PNG output (default is 1024x1024)
  ///
  /// Returns PNG bytes as Uint8List, or null if conversion fails
  static Future<Uint8List?> svgStringToPngBytes(
    String svgContent, {
    int size = defaultRenderSize,
  }) async {
    try {
      // Load and parse SVG
      final loader = SvgStringLoader(svgContent);
      final pictureInfo = await vg.loadPicture(loader);

      // Render to image at the specified size
      final image = await pictureInfo.picture.toImage(size, size);

      // Convert to PNG
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Pre-converts an SVG file and caches the result
  /// Returns true if successful, false otherwise
  static Future<bool> preConvertSvgFile(String filePath) async {
    if (!isSvgFile(filePath)) {
      return true; // Not an SVG, nothing to convert
    }

    final bytes = await svgToPngBytes(filePath);
    return bytes != null;
  }
}

