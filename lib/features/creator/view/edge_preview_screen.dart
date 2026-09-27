// File: edge_preview_screen.dart
// Chức năng: Màn hình hiển thị bản xem trước kết quả tách viền AI dựa trên các thông số đã cài đặt, hỗ trợ xử lý qua Server hoặc Local TFLite.

import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/processingAI/edge_detection_settings.dart';
import '../../../core/processingAI/edge_detection_service.dart';


class EdgePreviewScreen extends StatefulWidget {
  final Uint8List imageBytes; // Dữ liệu bytes của ảnh gốc
  final String imagePath; // Đường dẫn lưu trữ ảnh gốc
  final EdgeDetectionSettings
  initialSettings; // Cấu hình thông số nhận từ màn hình trước

  const EdgePreviewScreen({
    super.key,
    required this.imageBytes,
    required this.imagePath,
    this.initialSettings = const EdgeDetectionSettings(),
  });

  @override
  State<EdgePreviewScreen> createState() => _EdgePreviewScreenState();
}

class _EdgePreviewScreenState extends State<EdgePreviewScreen> {
  // Dịch vụ xử lý AI chạy ngầm trên thiết bị (Local TFLite)
  final EdgeDetectionService _aiService = EdgeDetectionService();

  // Kết quả suy luận (Inference result) từ mô hình, được lưu giữ để tái sử dụng cho các lần chỉnh sửa post-process nhanh
  Map<String, dynamic>? _inferenceResult;

  // Dữ liệu ảnh xem trước đã qua xử lý
  Uint8List? _previewBytes;

  // Các cờ quản lý trạng thái tải (loading)
  bool _isRunningInference = true;
  bool _isProcessing = false;

  // Đối tượng lưu trữ các thông số cài đặt hiện tại
  late EdgeDetectionSettings _settings;

  int _processingGeneration =
      0; // Biến kiểm soát thứ tự xử lý để tránh xung đột dữ liệu cũ/mới

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
    _runInference(); // Bắt đầu chạy AI ngay khi mở màn hình
  }

  @override
  void dispose() {
    _aiService.close(); // Giải phóng tài nguyên mô hình AI khi thoát màn hình
    super.dispose();
  }

  /// Bước 1: Chạy suy luận AI (chỉ thực hiện 1 lần khởi tạo đầu tiên)
  Future<void> _runInference() async {
    setState(() => _isRunningInference = true);

    await _aiService.loadModel();
    _inferenceResult = await _aiService.runInference(widget.imageBytes);

    setState(() => _isRunningInference = false);

    if (_inferenceResult != null) {
      _applyPostProcessing();
    }
  }

  /// Bước 2: Áp dụng các hiệu ứng hậu kỳ (post-processing) dựa trên thông số cài đặt
  Future<void> _applyPostProcessing() async {
    final int generation = ++_processingGeneration;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    Uint8List? result;

    if (_inferenceResult == null) {
      setState(() => _isProcessing = false);
      return;
    }
    result = await EdgeDetectionService.applyPostProcessing(
      _inferenceResult!,
      _settings,
    );

    // Cập nhật lại UI nếu đây là tiến trình mới nhất được yêu cầu
    if (mounted && generation == _processingGeneration) {
      setState(() {
        _previewBytes = result;
        _isProcessing = false;
        _isRunningInference = false;
      });
    } else if (mounted) {
      setState(() {
        _isProcessing = false;
        _isRunningInference = false;
      });
      _applyPostProcessing();
    }
  }

  /// Khi người dùng nhấn nút 'Apply': Chạy xử lý hậu kỳ ở độ phân giải gốc rồi chuyển tiếp sang Workspace
  Future<void> _onApply() async {
    // Hiển thị hộp thoại chờ (loading dialog)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Uint8List? fullResResult;
    final highQualityInference = await _aiService.runHighQualityInference(
      widget.imageBytes,
      maxDim: _settings.patchMaxDim,
    );
    if (highQualityInference != null) {
      final processedBytes = await EdgeDetectionService.applyPostProcessing(
        highQualityInference,
        _settings,
      );
      fullResResult = processedBytes;
    }

    if (mounted) {
      Navigator.pop(context); // Đóng hộp thoại loading

      if (fullResResult != null) {
        // Trả kết quả bytes đường viền và đường dẫn ảnh về màn hình trước đó để điều hướng tới /workspace
        Navigator.pop(context, {
          'edgeBytes': fullResResult,
          'imagePath': widget.imagePath,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi xử lý ảnh. Vui lòng thử lại.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        // Nút quay lại màn hình thông số
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edge Preview',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.titleLarge?.color ?? Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          // Nút 'Apply' ở góc phải trên để xác nhận hoàn tất preview
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _previewBytes != null
                  ? _onApply
                  : null, // Chỉ cho phép bấm khi đã có ảnh preview
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isRunningInference
          // Hiển thị trạng thái đang phân tích AI lần đầu
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang phân tích ảnh bằng AI...',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            )
          : _inferenceResult == null && _previewBytes == null
          // Thông báo lỗi nếu không thể xử lý ảnh
          ? const Center(
              child: Text(
                'Không thể xử lý ảnh này',
                style: TextStyle(fontSize: 16),
              ),
            )
          // Khung hiển thị ảnh kết quả preview
          : Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hiển thị ảnh bytes kết quả nếu có
                    if (_previewBytes != null)
                      Image.memory(
                        _previewBytes!,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    // Hiển thị vòng xoay loading nhỏ đè lên trên nếu đang cập nhật post-processing
                    if (_isProcessing)
                      Container(
                        color: Colors.white.withValues(alpha: 0.6),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
