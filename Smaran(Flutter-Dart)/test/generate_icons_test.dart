import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('Generate Android launcher icons from logo.png', () async {
    final sourcePath = 'assets/images/logo.png';
    final sourceFile = File(sourcePath);
    expect(await sourceFile.exists(), true);

    final bytes = await sourceFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    expect(originalImage, isNotNull);

    final targets = {
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };

    for (var entry in targets.entries) {
      final folder = entry.key;
      final size = entry.value;
      final resized = img.copyResize(
        originalImage!,
        width: size,
        height: size,
      );

      final outPath = 'android/app/src/main/res/$folder/ic_launcher.png';
      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(img.encodePng(resized));
    }
  });
}
