// File edge_detection_settings.dart

/// Data Model: Cấu hình các thông số hậu xử lý (post-processing) cho pipeline tách viền AI.
/// Các biến này là Immutable (Bất biến). Khi cần thay đổi, sử dụng hàm [copyWith].
class EdgeDetectionSettings {
  // ==========================================
  // NHÓM CẤU HÌNH CƠ BẢN
  // ==========================================

  /// Ngưỡng lọc viền (0.1 - 0.95). Giá trị thấp: lấy nhiều chi tiết. Cao: chỉ lấy nét chính.
  final double threshold;

  /// Đảo màu ảnh. True = Nền đen, viền trắng (Phòng trường hợp tách viền bị sai).
  final bool invertColors;

  /// Số lần/mức độ làm mảnh viền (Line Thinning).
  /// 0 = Tắt. 1-3 = Làm mảnh; mức 3 là mức mạnh nhất ổn định.
  final int lineThinning;

  /// Kích thước tối đa của ảnh làm việc khi chạy patch inference offline.
  final int patchMaxDim;

  // ==========================================
  // NHÓM ALGORITHM: SOFT EDGES (Viền mềm)
  // ==========================================

  /// Công tắc chuyển đổi thuật toán.
  /// Bật (True): Dùng đường cong Sigmoid cho viền mượt/sắc tự nhiên. (Bỏ qua cấu hình nhóm Hard Edge bên dưới).
  /// Tắt (False): Dùng thuật toán Hard Threshold truyền thống.
  final bool useSoftEdges;

  /// Độ dốc (steepness) của thuật toán Soft Edges.
  /// 1-4: Viền mờ/mềm | 6-10: Cân bằng | 12-25: Viền cực sắc nét.
  final double softEdgeClarity;

  // ==========================================
  // NHÓM ALGORITHM: HARD EDGE (Chỉ hoạt động khi useSoftEdges = false)
  // ==========================================

  /// Độ mờ Gaussian Blur (làm nhòe trước khi lọc viền).
  /// 0 = Tắt. Số càng to ảnh càng mượt nhưng mất đi chi tiết nhỏ.
  final int gaussianBlurSize;

  /// Kích thước thuật toán Morphology (Lấp vết nứt trên viền & xóa nhiễu rác li ti).
  /// 0 = Tắt. 2-3 = Tác động nhẹ. 4-5 = Tác động mạnh.
  final int morphologySize;

  /// Độ khử răng cưa (Anti-Alias) ở bước cuối.
  /// 0 = Tắt. 0.5-1.0 = Khử nhẹ. 1.5-3.0 = Khử mạnh.
  final double antiAliasSigma;

  /// Constructor khởi tạo với các giá trị mặc định tối ưu sẵn.
  const EdgeDetectionSettings({
    this.threshold = 0.65,
    this.invertColors = false,
    this.lineThinning = 3,
    this.patchMaxDim = 512,
    this.useSoftEdges = false,
    this.softEdgeClarity = 8.0,
    this.gaussianBlurSize = 3,
    this.morphologySize = 0,
    this.antiAliasSigma = 0.0,
  });

  /// Pattern CopyWith (Bắt buộc dùng trong State Management như BLoC).
  /// Giúp tạo ra một bản sao mới của [EdgeDetectionSettings] với các tham số được truyền vào,
  /// các tham số không được truyền sẽ giữ nguyên giá trị cũ.
  EdgeDetectionSettings copyWith({
    double? threshold,
    bool? invertColors,
    int? lineThinning,
    int? patchMaxDim,
    bool? useSoftEdges,
    double? softEdgeClarity,
    int? gaussianBlurSize,
    int? morphologySize,
    double? antiAliasSigma,
  }) {
    return EdgeDetectionSettings(
      // Toán tử ?? nghĩa là: Nếu tham số truyền vào là null (không thay đổi), thì lấy giá trị cũ (this...)
      threshold: threshold ?? this.threshold,
      invertColors: invertColors ?? this.invertColors,
      lineThinning: lineThinning ?? this.lineThinning,
      patchMaxDim: patchMaxDim ?? this.patchMaxDim,
      useSoftEdges: useSoftEdges ?? this.useSoftEdges,
      softEdgeClarity: softEdgeClarity ?? this.softEdgeClarity,
      gaussianBlurSize: gaussianBlurSize ?? this.gaussianBlurSize,
      morphologySize: morphologySize ?? this.morphologySize,
      antiAliasSigma: antiAliasSigma ?? this.antiAliasSigma,
    );
  }
}
