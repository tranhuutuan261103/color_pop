import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/repository/asset_library_datasource.dart';
import '../../../core/engine/logic/workspace_logic.dart';
import '../../../core/processingAI/native_edge_detection.dart';
import '../../../core/models/artwork_model.dart';

class CpopGeneratorScreen extends StatefulWidget {
  const CpopGeneratorScreen({super.key});

  @override
  State<CpopGeneratorScreen> createState() => _CpopGeneratorScreenState();
}

class _CpopGeneratorScreenState extends State<CpopGeneratorScreen> {
  bool _isRunning = false;
  String _statusText = "Sẵn sàng";
  double _progress = 0;
  List<String> _logs = [];

  void _addLog(String msg) {
    debugPrint(msg);
    setState(() {
      _logs.insert(0, msg);
    });
  }

  Future<void> _startBatchConvert() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _progress = 0;
      _logs.clear();
      _statusText = "Đang lấy danh sách Artwork...";
    });

    try {
      final artworks = await AssetLibraryDataSource.loadArtworks();
      if (artworks.isEmpty) {
        _addLog("Không tìm thấy artwork nào trong library.json!");
        setState(() => _isRunning = false);
        return;
      }

      _addLog("Tìm thấy ${artworks.length} ảnh. Bắt đầu xử lý...");

      final extDir = await getExternalStorageDirectory(); // Android: /storage/emulated/0/Android/data/.../files
      final outDir = Directory(p.join(extDir?.path ?? '', 'GeneratedCpops'));
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }
      _addLog("Thư mục lưu trữ: ${outDir.path}");

      for (int i = 0; i < artworks.length; i++) {
        final ArtworkModel artwork = artworks[i];
        _addLog("[${i + 1}/${artworks.length}] Đang xử lý: ${artwork.title}");

        try {
          // 1. Lấy byte ảnh gốc
          final imageBytes = await WorkspaceLogic.getBytes(artwork.imagePath);

          // 2. Chạy CANNY thay vì AI để lấy viền
          _addLog("  -> Dùng Canny tách viền...");
          final edgeBytes = await NativeEdgeDetection.applyCanny(imageBytes);
          
          if (edgeBytes == null) {
            _addLog("  -> ❌ Lỗi tách viền Canny");
            continue;
          }

          // 3. Lưu file viền tạm thời
          final tempDir = await getTemporaryDirectory();
          final tempEdgePath = p.join(tempDir.path, 'temp_canny_${DateTime.now().millisecondsSinceEpoch}.png');
          await File(tempEdgePath).writeAsBytes(edgeBytes);

          // 4. Đưa xuống Native C++ để sinh file .cpop
          _addLog("  -> Gọi C++ Engine xuất .cpop...");
          final cpopPath = await WorkspaceLogic.createColorPopDocument(tempEdgePath);

          if (cpopPath != null) {
            // 5. Copy file cpop thành phẩm ra thư mục ngoài để copy vào máy tính
            // File đích sẽ giữ nguyên tên file gốc. VD: cat.png -> cat.cpop
            String fileName = artwork.imagePath.split('/').last;
            int lastDot = fileName.lastIndexOf('.');
            if (lastDot != -1) {
              fileName = '${fileName.substring(0, lastDot)}.cpop';
            } else {
              fileName = '$fileName.cpop';
            }

            final finalDestPath = p.join(outDir.path, fileName);
            await File(cpopPath).copy(finalDestPath);
            _addLog("  -> ✅ Thành công: $fileName");
          } else {
            _addLog("  -> ❌ Lỗi C++ Engine");
          }
        } catch (e) {
          _addLog("  -> ❌ Lỗi exception: $e");
        }

        setState(() {
          _progress = (i + 1) / artworks.length;
        });
      }

      _statusText = "Đã hoàn thành!";
      _addLog("========== HOÀN TẤT ==========");
      _addLog("Vui lòng mở thư mục: ${outDir.path} qua cáp USB và copy tất cả file .cpop vào thư mục 'assets/cpop' trong source code!");

    } catch (e) {
      _statusText = "Lỗi tổng thể!";
      _addLog("ERROR: $e");
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev Tool: Sinh .cpop Hàng Loạt'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Text(
                'CẢNH BÁO: Màn hình này chỉ dành cho Lập trình viên.\n'
                'Chức năng này sẽ quét qua toàn bộ thư viện ảnh, sử dụng thuật toán Canny để tách viền và gọi Native Engine chuyển thành định dạng .cpop.\n'
                'Có thể mất nhiều thời gian nếu thư viện lớn.',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isRunning 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.rocket_launch, color: Colors.white),
              label: Text(_isRunning ? 'Đang xử lý...' : 'BẮT ĐẦU CHUYỂN ĐỔI (CANNY)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isRunning ? null : _startBatchConvert,
            ),
            const SizedBox(height: 16),
            Text(
              _statusText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _progress, minHeight: 10),
            const SizedBox(height: 16),
            const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
