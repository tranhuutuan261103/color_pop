import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/view/home_page.dart';
import '../../library/view/library_screen.dart';
import '../../profile/view/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),        // Index 0: HomeTab
    const LibraryScreen(),   // Index 1: LibraryTab
    const SizedBox.shrink(), // Index 2: Create (Action, not a screen)
    const Center(child: Text('Khám phá')), // Index 3: Discover (Placeholder)
    const ProfileScreen(),   // Index 4: ProfileTab
  ];

  Future<void> _pickImageAndNavigate() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    // Kiểm tra 'mounted' để tránh crash nếu widget đã bị hủy
    if (image != null && mounted) {
      await Navigator.pushNamed(
        context, 
        '/workspace', 
        arguments: image.path,
      );
      if (mounted) {
        context.read<HomeCubit>().loadHomeData();
      }
    }
  }

  // Xử lý logic khi bấm vào thanh điều hướng
  void _onBottomNavTapped(int index) {
    if (index == 2) {
      // Create tab triggers image picker directly
      _pickImageAndNavigate();
      return;
    }
    
    if (index == 0) {
      // Refresh home data when switching to home tab
      context.read<HomeCubit>().loadHomeData();
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
