// File server_edge_detection_service.dart
//
// Service gọi API server để tách viền bằng AI.
// Server chạy PyTorch gốc (FP32) — chất lượng cao nhất, giống web app.
//
// So sánh với EdgeDetectionService (on-device TFLite):
// - Server: chất lượng cao nhất, cần mạng, phụ thuộc server
// - On-device: chạy offline, nhanh, nhưng chất lượng thấp hơn do quantize
//
// Cùng interface để dễ dàng swap/compare giữa 2 phương pháp.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'edge_detection_settings.dart';

class ServerEdgeDetectionService {
  /// URL gốc của server.
  /// VD: http://192.168.1.100:5000
  String _serverUrl;

  /// Timeout cho mỗi request (giây).
  final int timeoutSeconds;

  /// Số lần retry khi gặp lỗi mạng.
  final int maxRetries;

  ServerEdgeDetectionService({
    required String serverUrl,
    this.timeoutSeconds = 30,
    this.maxRetries = 2,
  }) : _serverUrl = serverUrl.endsWith('/')
           ? serverUrl.substring(0, serverUrl.length - 1)
           : serverUrl;

  /// Cập nhật URL server (VD: khi user đổi IP).
  void updateServerUrl(String newUrl) {
    _serverUrl = newUrl.endsWith('/')
        ? newUrl.substring(0, newUrl.length - 1)
        : newUrl;
  }

  /// Kiểm tra server có hoạt động không.
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/health'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('Server health check: OK');
        return true;
      }
      debugPrint('Server health check failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Server health check error: $e');
      return false;
    }
  }

  /// Lấy thông tin model trên server.
  Future<Map<String, dynamic>?> getModelInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/model-info'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Parse JSON manually since we might not want to add a json dependency
        // In practice, you'd use dart:convert
        return {'raw': response.body};
      }
      return null;
    } catch (e) {
      debugPrint('Get model info error: $e');
      return null;
    }
  }

  /// Gửi ảnh lên server để tách viền.
  /// Trả về byte ảnh PNG kết quả, hoặc null nếu thất bại.
  ///
  /// [imageBytes] - Byte ảnh đầu vào (JPEG, PNG, etc.)
  /// [settings] - Cấu hình post-processing (giống EdgeDetectionSettings)
  /// [filename] - Tên file (để server biết format, mặc định 'image.png')
  Future<Uint8List?> detectEdges(
    Uint8List imageBytes, {
    EdgeDetectionSettings settings = const EdgeDetectionSettings(),
    String filename = 'image.png',
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint('Retry attempt $attempt/$maxRetries...');
          // Exponential backoff
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

        final result = await _sendDetectRequest(imageBytes, settings, filename);
        return result;
      } on SocketException catch (e) {
        debugPrint('Network error (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) return null;
      } on http.ClientException catch (e) {
        debugPrint('HTTP error (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) return null;
      } catch (e) {
        debugPrint('Unexpected error (attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) return null;
      }
    }
    return null;
  }

  /// Gửi request multipart POST đến server.
  Future<Uint8List?> _sendDetectRequest(
    Uint8List imageBytes,
    EdgeDetectionSettings settings,
    String filename,
  ) async {
    final uri = Uri.parse('$_serverUrl/detect-edges');

    final request = http.MultipartRequest('POST', uri);

    // Thêm file ảnh
    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
    );

    // Thêm các tham số post-processing
    request.fields['threshold'] = settings.threshold.toString();
    request.fields['invert_colors'] = settings.invertColors.toString();
    request.fields['use_soft_edges'] = settings.useSoftEdges.toString();
    request.fields['soft_edge_clarity'] = settings.softEdgeClarity.toString();
    request.fields['gaussian_blur_size'] = settings.gaussianBlurSize.toString();
    request.fields['morphology_size'] = settings.morphologySize.toString();
    request.fields['anti_alias_sigma'] = settings.antiAliasSigma.toString();

    debugPrint(
      'Sending image to server: $_serverUrl/detect-edges '
      '(${imageBytes.length} bytes, soft_edges=${settings.useSoftEdges})',
    );

    final streamedResponse = await request.send().timeout(
      Duration(seconds: timeoutSeconds),
    );

    if (streamedResponse.statusCode == 200) {
      final responseBytes = await streamedResponse.stream.toBytes();
      final decoded = img.decodeImage(responseBytes);
      final contentType = streamedResponse.headers['content-type'] ?? '';
      if (decoded == null || !contentType.toLowerCase().contains('image/')) {
        debugPrint(
          'Invalid server image response: content-type=$contentType, '
          'bytes=${responseBytes.length}',
        );
        return null;
      }

      // HED trả về nền đen, viền trắng. Đảo màu theo lựa chọn của người dùng
      // để hai chế độ local và server cho cùng một quy ước màu.
      if (settings.invertColors) {
        img.invert(decoded);
      }

      final finalBytes = Uint8List.fromList(img.encodePng(decoded));

      debugPrint(
        'Server response: ${finalBytes.length} bytes '
        '(${decoded.width}x${decoded.height})',
      );
      return finalBytes;
    } else {
      final body = await streamedResponse.stream.bytesToString();
      debugPrint('Server error ${streamedResponse.statusCode}: $body');
      return null;
    }
  }

  /// [Convenience] Chạy inference và trả về raw result (giống interface EdgeDetectionService).
  /// Server đã bao gồm post-processing, nên method này trả thẳng ảnh PNG.
  Future<Uint8List?> detectEdgesWithSettings(
    Uint8List imageBytes,
    EdgeDetectionSettings settings,
  ) async {
    return detectEdges(imageBytes, settings: settings);
  }
}
