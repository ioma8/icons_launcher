import 'dart:io';
import 'package:icons_launcher/utils/svg_utils.dart';
import 'package:test/test.dart';

void main() {
  group('SvgUtils', () {
    test('isSvgFile returns true for .svg files', () {
      expect(SvgUtils.isSvgFile('icon.svg'), isTrue);
      expect(SvgUtils.isSvgFile('path/to/icon.svg'), isTrue);
      expect(SvgUtils.isSvgFile('ICON.SVG'), isTrue);
      expect(SvgUtils.isSvgFile('icon.Svg'), isTrue);
    });

    test('isSvgFile returns false for non-SVG files', () {
      expect(SvgUtils.isSvgFile('icon.png'), isFalse);
      expect(SvgUtils.isSvgFile('icon.jpg'), isFalse);
      expect(SvgUtils.isSvgFile('icon.jpeg'), isFalse);
      expect(SvgUtils.isSvgFile('svg.png'), isFalse);
      expect(SvgUtils.isSvgFile('icon'), isFalse);
    });

    test('svgStringToPngBytes converts SVG to PNG', () async {
      const svgContent = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#FF0000" />
</svg>
''';
      
      final pngBytes = await SvgUtils.svgStringToPngBytes(svgContent);
      expect(pngBytes, isNotNull);
      expect(pngBytes!.length, greaterThan(0));
      
      // Verify PNG signature
      expect(pngBytes[0], 0x89);
      expect(pngBytes[1], 0x50); // 'P'
      expect(pngBytes[2], 0x4E); // 'N'
      expect(pngBytes[3], 0x47); // 'G'
    });

    test('svgStringToPngBytes respects size parameter', () async {
      const svgContent = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#00FF00" />
</svg>
''';
      
      final pngBytes256 = await SvgUtils.svgStringToPngBytes(svgContent, size: 256);
      final pngBytes512 = await SvgUtils.svgStringToPngBytes(svgContent, size: 512);
      
      expect(pngBytes256, isNotNull);
      expect(pngBytes512, isNotNull);
      
      // Larger images should generally have more bytes (though not always proportional)
      expect(pngBytes512!.length, greaterThan(pngBytes256!.length));
    });

    test('cache stores and retrieves converted bytes', () async {
      const svgContent = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50">
  <circle cx="25" cy="25" r="20" fill="#0000FF" />
</svg>
''';
      
      // Clear cache first
      SvgUtils.clearCache();
      
      // Initially not cached
      expect(SvgUtils.getCachedPngBytes('test_path.svg'), isNull);
      
      // Convert and cache
      final pngBytes = await SvgUtils.svgStringToPngBytes(svgContent);
      expect(pngBytes, isNotNull);
      
      SvgUtils.cachePngBytes('test_path.svg', pngBytes!);
      
      // Now cached
      final cachedBytes = SvgUtils.getCachedPngBytes('test_path.svg');
      expect(cachedBytes, isNotNull);
      expect(cachedBytes, equals(pngBytes));
      
      // Clear cache
      SvgUtils.clearCache();
      expect(SvgUtils.getCachedPngBytes('test_path.svg'), isNull);
    });

    test('preConvertSvgFile returns true for non-SVG files', () async {
      final result = await SvgUtils.preConvertSvgFile('icon.png');
      expect(result, isTrue);
    });

    test('svgToPngBytes with file', () async {
      // Create a temporary SVG file
      final tempDir = Directory.systemTemp.createTempSync('svg_test_');
      final svgFile = File('${tempDir.path}/test_icon.svg');
      
      const svgContent = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#FFFF00" />
</svg>
''';
      
      await svgFile.writeAsString(svgContent);
      
      try {
        // Clear cache
        SvgUtils.clearCache();
        
        // Convert file
        final pngBytes = await SvgUtils.svgToPngBytes(svgFile.path);
        expect(pngBytes, isNotNull);
        expect(pngBytes!.length, greaterThan(0));
        
        // Should be cached now
        final cachedBytes = SvgUtils.getCachedPngBytes(svgFile.path);
        expect(cachedBytes, isNotNull);
        expect(cachedBytes, equals(pngBytes));
      } finally {
        // Cleanup
        await tempDir.delete(recursive: true);
        SvgUtils.clearCache();
      }
    });
  });
}
