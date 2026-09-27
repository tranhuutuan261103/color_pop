// [FILE ĐỊNH DẠNG CẤU TRÚC]

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import '../models/color_pop_document.dart';
import '../topology/region.dart';
import '../topology/loop.dart';
import '../geometry/path_command.dart';
import '../geometry/point.dart';
import '../geometry/bounding_box.dart';

class ColorPopReader {
  static const int MAGIC_BYTES = 0x504F5043; // 'CPOP'

  static Future<ColorPopDocument?> readFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final bd = ByteData.view(bytes.buffer);
      int offset = 0;

      if (bd.getUint32(offset, Endian.little) != MAGIC_BYTES) {
        throw Exception("Invalid magic bytes. Not a ColorPop file.");
      }
      offset += 4;

      final version = bd.getUint32(offset, Endian.little);
      offset += 4;

      final width = bd.getFloat64(offset, Endian.little);
      offset += 8;
      final height = bd.getFloat64(offset, Endian.little);
      offset += 8;

      if (width.isNaN || width.isInfinite || width <= 0) throw Exception("Invalid width");
      if (height.isNaN || height.isInfinite || height <= 0) throw Exception("Invalid height");

      final regionCount = bd.getUint32(offset, Endian.little);
      offset += 4;

      final regions = <Region>[];

      for (int i = 0; i < regionCount; i++) {
        final id = bd.getUint32(offset, Endian.little);
        offset += 4;
        final colorValue = bd.getUint32(offset, Endian.little);
        offset += 4;
        final isStroke = bd.getUint8(offset) == 1;
        offset += 1;
        final confidence = bd.getFloat64(offset, Endian.little);
        offset += 8;

        Loop readLoop() {
          final pointCount = bd.getUint32(offset, Endian.little);
          offset += 4;
          final pts = <Point>[];
          for (int p = 0; p < pointCount; p++) {
            final x = bd.getFloat32(offset, Endian.little);
            offset += 4;
            final y = bd.getFloat32(offset, Endian.little);
            offset += 4;
            if (!x.isNaN && !y.isNaN && !x.isInfinite && !y.isInfinite) {
              pts.add(Point(x, y));
            }
          }
          final bounds = BoundingBox.fromPoints(pts).expand(2.0);
          return Loop(
            id: id, // Simplified loop ID
            path: GeometryPath.fromPoints(pts),
            bounds: bounds,
          );
        }

        final outerBoundary = readLoop();
        
        final holeCount = bd.getUint32(offset, Endian.little);
        offset += 4;
        final holes = <Loop>[];
        for (int h = 0; h < holeCount; h++) {
          holes.add(readLoop());
        }

        regions.add(Region(
          id: id,
          outerBoundary: outerBoundary,
          holes: holes,
          neighborIds: [], // Resolved later if needed
          color: Color(colorValue),
          bounds: outerBoundary.bounds,
          confidence: confidence,
          isStroke: isStroke,
        ));
      }

      return ColorPopDocument(
        version: version,
        width: width,
        height: height,
        regions: regions,
        metadata: Metadata(createdAt: DateTime.now().millisecondsSinceEpoch, sourceImageHash: "", globalConfidence: 1.0),
      );

    } catch (e) {
      print("Reader Error: \$e");
      return null;
    }
  }
}
