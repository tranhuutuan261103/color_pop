import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:gal/gal.dart';
import '../../../core/models/color_project.dart';
import '../../../core/services/database_helper.dart';

class WorkspaceScreen extends StatefulWidget {
  final String imagePath;
  
  const WorkspaceScreen({super.key, required this.imagePath});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  bool _isLoading = true;
  ColorProject? _project;
  late String _currentImagePath;

  // New UI states
  int _selectedToolIndex = 2; // Default to 'Cọ lớn' (index 2)
  double _sliderValue = 0.5;
  int _selectedColorIndex = 3; // Default to the light blue in row 1

  final List<Color> _colors = [
    // Row 1
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF03A9F4), // Light Blue
    const Color(0xFF4CAF50), // Green
    Colors.white,
    Colors.black,
    Colors.grey,
    // Row 2
    const Color(0xFFF48FB1), // Pink light
    const Color(0xFFE91E63), // Pink
    const Color(0xFFF44336), // Red
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFFFFEB3B), // Yellow
    const Color(0xFFFFF59D), // Light Yellow
    const Color(0xFFCE93D8), // Purple light
    const Color(0xFFE1BEE7), // Purple very light
  ];

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
    _initProject();
  }

  Future<void> _initProject() async {
    final appDir = await getApplicationDocumentsDirectory();
    
    if (!_currentImagePath.contains(appDir.path)) {
      final fileName = 'bw_${DateTime.now().millisecondsSinceEpoch}_${p.basename(_currentImagePath)}';
      final savedImagePath = p.join(appDir.path, fileName);
      
      final imageBytes = await File(_currentImagePath).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        final grayscaleImage = img.grayscale(decodedImage);
        final encodedImage = img.encodeJpg(grayscaleImage);
        await File(savedImagePath).writeAsBytes(encodedImage);
      } else {
        await File(_currentImagePath).copy(savedImagePath);
      }
      
      _currentImagePath = savedImagePath;

      final project = ColorProject(
        imagePath: savedImagePath,
        status: 'in_progress',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      final id = await DatabaseHelper.instance.insertProject(project);
      _project = project.copyWith(id: id);
    } else {
      final allProjects = await DatabaseHelper.instance.getAllProjects();
      try {
        _project = allProjects.firstWhere((proj) => proj.imagePath == _currentImagePath);
      } catch (e) {
        _project = ColorProject(
          imagePath: _currentImagePath,
          status: 'in_progress',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _markAsCompleted() async {
    if (_project != null) {
      final updatedProject = _project!.copyWith(status: 'completed');
      await DatabaseHelper.instance.updateProject(updatedProject);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dự án đã được lưu vào Hoàn thành!')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(_currentImagePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu ảnh vào Thư viện máy!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(
                        File(_currentImagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildToolsPalette(),
            _buildSlider(),
            _buildColorSwatches(),
            const SizedBox(height: 16),
            _buildBottomToolbar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildAppBarButton(
            icon: Icons.reply,
            color: Colors.red[300]!,
            onTap: () => Navigator.pop(context),
          ),
          const Row(
            children: [
              Text(
                'Sáng tạo: Kỳ lân ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text('🎨', style: TextStyle(fontSize: 18)),
            ],
          ),
          Row(
            children: [
              _buildAppBarButton(
                icon: Icons.check,
                color: Colors.white,
                backgroundColor: Colors.green[400]!,
                onTap: _markAsCompleted,
              ),
              const SizedBox(width: 8),
              _buildAppBarButton(
                icon: Icons.block,
                color: Colors.red[400]!,
                text: 'ADS',
                onTap: () {},
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    String? text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(text != null ? 4.0 : 8.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: text != null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                  Icon(icon, size: 24, color: color.withOpacity(0.5)),
                ],
              )
            : Icon(icon, size: 24, color: color),
      ),
    );
  }

  Widget _buildToolsPalette() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildToolItem(0, 'Tô màu', Icons.format_color_fill, const Color(0xFF90CAF9)),
          _buildToolItem(1, 'Tẩy', Icons.cleaning_services, const Color(0xFFF48FB1)),
          _buildToolItem(2, 'Cọ lớn', Icons.brush, const Color(0xFFA5D6A7)),
          _buildToolItem(3, 'Bút chì', Icons.edit, const Color(0xFFFFF59D)),
          _buildToolItem(4, 'Bình xịt', Icons.blur_on, const Color(0xFFCE93D8)),
        ],
      ),
    );
  }

  Widget _buildToolItem(int index, String label, IconData icon, Color color) {
    bool isSelected = _selectedToolIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedToolIndex = index;
        });
      },
      child: Container(
        width: 64,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
          border: isSelected ? Border.all(color: Theme.of(context).primaryColorDark, width: 3) : null,
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.black54),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        height: 24,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: 12,
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.1),
            thumbColor: Theme.of(context).primaryColorDark,
            overlayColor: Theme.of(context).primaryColorDark.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: _sliderValue,
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildColorSwatches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (index) => _buildColorSwatch(index)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (index) => _buildColorSwatch(index + 8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatch(int index) {
    bool isSelected = _selectedColorIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColorIndex = index;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _colors[index],
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : (index == 5 ? Border.all(color: Colors.grey[300]!, width: 1) : null),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.blue.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 4,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(Icons.access_time, iconColor: Colors.black87, backgroundColor: const Color(0xFFB3E5FC)),
          _buildToolbarButton(Icons.colorize, iconColor: Colors.black87),
          const Icon(Icons.chevron_left, color: Colors.grey, size: 30),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                )
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSmallDot(const Color(0xFF673AB7)),
                            const SizedBox(width: 2),
                            _buildSmallDot(const Color(0xFF03A9F4)),
                            const SizedBox(width: 2),
                            _buildSmallDot(const Color(0xFF2196F3)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSmallDot(const Color(0xFF4CAF50)),
                            const SizedBox(width: 2),
                            _buildSmallDot(Colors.black),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Text('Basic', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Icon(Icons.chevron_right, color: Colors.grey, size: 30),
          
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF03A9F4),
                ),
              ),
            ),
          ),
          
          _buildToolbarButton(Icons.open_in_full, iconColor: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, {Color iconColor = Colors.black54, Color? backgroundColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  Widget _buildSmallDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}