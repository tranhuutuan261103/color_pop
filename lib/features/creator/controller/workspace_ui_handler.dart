
import 'workspace_base_state.dart';

/// Mixin quản lý cập nhật giao diện (công cụ, màu sắc, thanh trượt, pan mode)
mixin WorkspaceUIHandler on WorkspaceBaseState {

  void selectTool(int index) {
    selectedToolIndex = index;
    if (isPanMode) isPanMode = false; 
    updatePaintEngineState();
    notifyListeners();
  }

  void selectColor(int index) {
    selectedColorIndex = index;
    updatePaintEngineState();
    notifyListeners();
  }

  void updateSliderValue(double value) {
    sliderValue = value;
    updatePaintEngineState();
    notifyListeners();
  }

  void togglePanMode() {
    isPanMode = !isPanMode;
    notifyListeners();
  }

  void toggleVectorOutline() {
    showVectorOutline = !showVectorOutline;
    notifyListeners();
  }

  void updateColor(int index) => selectColor(index);
  void updateTool(int index) => selectTool(index);
  void updateSlider(double value) => updateSliderValue(value);
}
