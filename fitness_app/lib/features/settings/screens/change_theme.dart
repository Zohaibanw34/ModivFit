import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:fitness_app/layout/main_layout.dart';

class ChangeThemeScreen extends StatefulWidget {
  const ChangeThemeScreen({super.key});

  @override
  State<ChangeThemeScreen> createState() => _ChangeThemeScreenState();
}

class _ChangeThemeScreenState extends State<ChangeThemeScreen> {
  String selectedTheme = 'Light';

  @override
  void initState() {
    super.initState();
    // Sync initial selection with current theme mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mode = AdaptiveTheme.of(context).mode;
      setState(() {
        selectedTheme = mode.isDark ? 'Dark' : 'Light';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Theme',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 5,
      body: Center(
        child: Container(
          width: 389,
          height: 790,
          margin: const EdgeInsets.only(top: 33),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1F1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            child: Column(
              children: [
                _themeTile('Dark'),
                const SizedBox(height: 10),
                _themeTile('Light'),
                const SizedBox(height: 30),
                SizedBox(
                  width: 187,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _saveTheme(context),
                    child: Text(
                      'Save'.tr,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeTile(String themeName) {
    final isSelected = themeName == selectedTheme;

    return InkWell(
      onTap: () {
        setState(() => selectedTheme = themeName);
        // Apply theme immediately when user taps the option
        if (themeName == 'Dark') {
          AdaptiveTheme.of(context).setDark();
        } else {
          AdaptiveTheme.of(context).setLight();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 345,
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFD6E8D8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF4E97FF) : Colors.transparent,
            width: isSelected ? 1.3 : 1,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          themeName.tr,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _saveTheme(BuildContext context) {
    if (selectedTheme == 'Dark') {
      AdaptiveTheme.of(context).setDark();
    } else {
      AdaptiveTheme.of(context).setLight();
    }
  }
}
