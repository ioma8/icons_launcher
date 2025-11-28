import 'package:pure_svg/src/loaders.dart';
import 'package:pure_svg/src/vector_graphics/vector_graphics/vector_graphics.dart';
import 'package:pure_ui/pure_ui.dart' as ui;
import 'package:test/test.dart';

const String testSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#FF0000" />
  <circle cx="50" cy="50" r="30" fill="#00FF00" />
</svg>
''';

void main() {
  test('SVG to PNG conversion works', () async {
    // Load SVG using pure_svg
    const loader = SvgStringLoader(testSvg);
    final pictureInfo = await vg.loadPicture(loader);
    
    expect(pictureInfo.size.width, greaterThan(0));
    expect(pictureInfo.size.height, greaterThan(0));
    
    // Render to image
    const targetSize = 1024;
    final image = await pictureInfo.picture.toImage(targetSize, targetSize);
    
    expect(image.width, targetSize);
    expect(image.height, targetSize);
    
    // Convert to PNG
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(byteData, isNotNull);
    
    final pngBytes = byteData!.buffer.asUint8List();
    expect(pngBytes.length, greaterThan(0));
    
    // Verify PNG signature
    // PNG files start with: 0x89 0x50 0x4E 0x47 0x0D 0x0A 0x1A 0x0A
    expect(pngBytes[0], 0x89);
    expect(pngBytes[1], 0x50); // 'P'
    expect(pngBytes[2], 0x4E); // 'N'
    expect(pngBytes[3], 0x47); // 'G'
  });
}
