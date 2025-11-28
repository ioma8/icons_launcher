import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:universal_io/io.dart';

import 'svg_utils.dart';

/// Icon template
class IconTemplate {
  /// Constructor
  const IconTemplate({required this.size});

  /// Size
  final int size;
}

/// Icon
class Icon {
  Icon._(this.image);

  /// Image
  Image image;

  /// Load an image from bytes
  static Icon? _loadBytes(Uint8List bytes) {
    final image = decodeImage(bytes);
    if (image == null) {
      return null;
    }

    return Icon._(image);
  }

  /// Load an image from file (supports PNG, JPG, JPEG, and SVG formats)
  ///
  /// For SVG files, the file must be pre-converted using [SvgUtils.preConvertSvgFile]
  /// before calling this method. The converted PNG bytes will be retrieved from cache.
  static Icon? loadFile(String filePath) {
    // Check if it's an SVG file
    if (SvgUtils.isSvgFile(filePath)) {
      // Get pre-converted PNG bytes from cache
      final pngBytes = SvgUtils.getCachedPngBytes(filePath);
      if (pngBytes == null) {
        throw StateError(
          'SVG file "$filePath" must be pre-converted before loading. '
          'Use SvgUtils.preConvertSvgFile() first.',
        );
      }
      return Icon._loadBytes(pngBytes);
    }
    return Icon._loadBytes(File(filePath).readAsBytesSync());
  }

  /// Load an image from file asynchronously (supports PNG, JPG, JPEG, and SVG formats)
  static Future<Icon?> loadFileAsync(String filePath) async {
    if (SvgUtils.isSvgFile(filePath)) {
      final pngBytes = await SvgUtils.svgToPngBytes(filePath);
      if (pngBytes == null) {
        return null;
      }
      return Icon._loadBytes(pngBytes);
    }
    return Icon._loadBytes(await File(filePath).readAsBytes());
  }

  /// Check image has an alpha channel
  bool get hasAlpha => image.hasAlpha;

  /// Remove alpha channel from the image
  void removeAlpha() {
    if (!hasAlpha) {
      return;
    }

    image.backgroundColor = ColorUint8.rgb(255, 255, 255);
    image = image.convert(
      numChannels: 3,
    );
  }

  /// Create a resized copy of this Icon
  Icon copyResized(int iconSize) {
    if (image.width >= iconSize) {
      return Icon._(copyResize(
        image,
        width: iconSize,
        height: iconSize,
        interpolation: Interpolation.average,
      ));
    } else {
      return Icon._(copyResize(
        image,
        width: iconSize,
        height: iconSize,
        interpolation: Interpolation.linear,
      ));
    }
  }

  /// Save the resized image to a file
  void saveResizedPng(int iconSize, String filePath) {
    final data = encodePng(copyResized(iconSize).image);
    final file = File(filePath);
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
  }

  /// Save the resized image to a Windows ico file
  static void saveIco(List<Icon> icons, String filePath) {
    final image = Image(width: 256, height: 256);
    image.frames = icons.map((icon) => icon.image).toList();
    image.frameType = FrameType.sequence;

    final data = encodeIco(image);
    final file = File(filePath);
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
  }

  void convertToGrayscale() => image = grayscale(image);

  void convertToWhite() {
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        if (pixel.a > 0) {
          image.setPixel(x, y, image.getColor(255, 255, 255, pixel.a));
        }
      }
    }
  }
}
