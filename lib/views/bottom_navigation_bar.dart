import 'package:flutter/material.dart';
import 'package:mindlink_app/views/screens/image_screen.dart';
import 'package:mindlink_app/views/screens/text_screen.dart';
import 'package:mindlink_app/views/screens/video_screen.dart';

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    TextPostScreen(),
     VideoPostScreen(),
     const ImagePostScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
          onTap: (screenIndex) {
            setState(() {
              _currentIndex = screenIndex;
            });
          },
          items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.format_color_text_rounded),
        label: "Text"
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: "Video"
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: "Image"
        )
      ]),
    );
  }
}
