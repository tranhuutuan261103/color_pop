import 'package:opencv_dart/opencv_dart.dart' as cv;

void main() {
  try {
    print("Testing opencv skeleton...");
    var mat = cv.Mat.zeros(100, 100, cv.MatType.CV_8UC1);
    // Draw a thick line
    final element = cv.getStructuringElement(cv.MORPH_CROSS, (3, 3));
    var eroded = cv.erode(mat, element);
    var dilated = cv.dilate(eroded, element);
    var sub = cv.subtract(mat, dilated);
    var skel = cv.bitwiseOR(mat, sub);
    int nonZero = cv.countNonZero(mat);
    print("OpenCV Skeleton functions working! nonZero: $nonZero");
  } catch (e) {
    print("Error: $e");
  }
}
