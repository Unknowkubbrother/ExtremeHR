import 'package:client/src/components/HomePage/home_job_page.dart';
import 'package:client/src/components/ProfilePage/profile_page.dart';
import 'package:client/src/components/ResumePage/resume_page.dart';
import 'package:client/src/components/InterviewPage/interview_page.dart';
import 'package:client/src/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:client/src/constants/app_font_sizes.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeJobPage(),
    ResumePage(),
    InterviewPage(),
    ProfilePage(),
  ];

  static const List<Widget> _widgetTitle = <Widget>[
    Text(
      'Dream Job awaits!',
      style: TextStyle(
        color: AppColors.textPrimaryTo,
        fontSize: AppFontSizes.subtitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      'Resume Extraction',
      style: TextStyle(
        color: AppColors.textPrimaryTo,
        fontSize: AppFontSizes.subtitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      'My Interview',
      style: TextStyle(
        color: AppColors.textPrimaryTo,
        fontSize: AppFontSizes.subtitle,
        fontWeight: FontWeight.bold,
      ),
    ),
    Text(
      'Profile',
      style: TextStyle(
        color: AppColors.textPrimaryTo,
        fontSize: AppFontSizes.subtitle,
        fontWeight: FontWeight.bold,
      ),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _widgetTitle.elementAt(_selectedIndex)),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: "Home",
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.edit_document,
                activeIcon: Icons.edit_document,
                label: "Resume",
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.video_camera_front_outlined,
                activeIcon: Icons.video_camera_front,
                label: "Interview",
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: "Profile",
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(icon),
      ),
      activeIcon: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(activeIcon, color: AppColors.primary),
      ),
      label: label,
    );
  }
}
