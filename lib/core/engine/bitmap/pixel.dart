class Pixel {
  final int x;
  final int y;
  final int argb;

  const Pixel({
    required this.x,
    required this.y,
    required this.argb,
  });

  Pixel copyWith({
    int? x,
    int? y,
    int? argb,
  }) {
    return Pixel(
      x: x ?? this.x,
      y: y ?? this.y,
      argb: argb ?? this.argb,
    );
  }

  bool get isTransparent => (argb >> 24) == 0;
  int get alpha => (argb >> 24) & 0xff;
  int get red => (argb >> 16) & 0xff;
  int get green => (argb >> 8) & 0xff;
  int get blue => argb & 0xff;
}