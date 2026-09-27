// [FILE ĐỊNH DẠNG CẤU TRÚC]

import 'dart:io';
import 'dart:typed_data';
import '../models/color_pop_document.dart';
import '../topology/loop.dart';
import '../geometry/path_command.dart';
import '../geometry/point.dart';

class ColorPopWriter {
  static const int MAGIC_BYTES = 0x504F5043; // 'CPOP' in little endian

  static Future<bool> writeToFile(ColorPopDocument doc, String filePath) async {
    try {
      final file = File(filePath);
      
      // Calculate buffer size
      int bufferSize = 4 + 4 + 8 + 8 + 4; // Magic, Version, Width, Height, RegionCount
      
      for (final region in doc.regions) {
        bufferSize += 4 + 4; // ID, Color
        bufferSize += 1; // isStroke
        bufferSize += 8; // Confidence
        
        // Outer boundary
        bufferSize += 4 + (region.outerBoundary.path.commands.length * 8); // CommandCount + Points
        
        // Holes
        bufferSize += 4; // Hole count
        for (final hole in region.holes) {
          bufferSize += 4 + (hole.path.commands.length * 8);
        }
      }
      
      // To simplify, we'll use a BytesBuilder
      final builder = BytesBuilder();
      final bd = ByteData(8);
      
      // Magic
      bd.setUint32(0, MAGIC_BYTES, Endian.little);
      builder.add(bd.buffer.asUint8List(0, 4));
      
      // Version
      bd.setUint32(0, doc.version, Endian.little);
      builder.add(bd.buffer.asUint8List(0, 4));
      
      // Width & Height
      bd.setFloat64(0, doc.width, Endian.little);
      builder.add(bd.buffer.asUint8List(0, 8));
      bd.setFloat64(0, doc.height, Endian.little);
      builder.add(bd.buffer.asUint8List(0, 8));
      
      // Region Count
      bd.setUint32(0, doc.regions.length, Endian.little);
      builder.add(bd.buffer.asUint8List(0, 4));
      
      for (final region in doc.regions) {
        // ID & Color
        bd.setUint32(0, region.id, Endian.little);
        builder.add(bd.buffer.asUint8List(0, 4));
        bd.setUint32(0, region.color.value, Endian.little);
        builder.add(bd.buffer.asUint8List(0, 4));
        
        // isStroke
        builder.addByte(region.isStroke ? 1 : 0);
        
        // Confidence
        bd.setFloat64(0, region.confidence, Endian.little);
        builder.add(bd.buffer.asUint8List(0, 8));
        
        // Helper to write loop
        void writeLoop(Loop loop) {
          final pts = <Point>[];
          for (final cmd in loop.path.commands) {
            if (cmd is MoveToCommand) {
              pts.add(cmd.target);
            } else if (cmd is LineToCommand) {
              pts.add(cmd.target);
            } else if (cmd is CubicToCommand) {
              pts.add(cmd.target);
            }
          }
          bd.setUint32(0, pts.length, Endian.little);
          builder.add(bd.buffer.asUint8List(0, 4));
          for (final pt in pts) {
            bd.setFloat32(0, pt.x, Endian.little);
            builder.add(bd.buffer.asUint8List(0, 4));
            bd.setFloat32(0, pt.y, Endian.little);
            builder.add(bd.buffer.asUint8List(0, 4));
          }
        }
        
        writeLoop(region.outerBoundary);
        
        bd.setUint32(0, region.holes.length, Endian.little);
        builder.add(bd.buffer.asUint8List(0, 4));
        
        for (final hole in region.holes) {
          writeLoop(hole);
        }
      }
      
      await file.writeAsBytes(builder.toBytes(), flush: true);
      return true;
    } catch (e) {
      print("Writer Error: \$e");
      return false;
    }
  }
}
