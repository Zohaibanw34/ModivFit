import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

import 'package:fitness_app/core/utils/app_responsive.dart';
import 'package:fitness_app/features/home/controllers/home_profile_controller.dart';
import 'package:fitness_app/routes/app_routes.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? headerContent;
  final bool isHome;
  final bool showAppBar;
  final bool showBottomNav;
  final bool showBackButton;
  final bool showAvatar;
  final int currentIndex;
  final bool constrainBody;
  final double? contentMaxWidth;
  final bool useScreenPadding;
  final bool highlightCenterAdd;

  const MainLayout({
    super.key,
    required this.title,
    required this.body,
    this.headerContent,
    this.isHome = false,
    this.showAppBar = false,
    this.showBottomNav = true,
    this.showBackButton = false,
    this.showAvatar = false,
    this.currentIndex = 0,
    this.constrainBody = true,
    this.contentMaxWidth,
    this.useScreenPadding = true,
    this.highlightCenterAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final bottomBarColor =
        isDark ? const Color(0xFF020617) : Colors.white.withOpacity(0.94);
    final bottomActiveColor =
        isDark ? theme.colorScheme.primary : theme.colorScheme.primary;
    final bottomInactiveColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFFB0B0C0);

    final maxContentWidth =
        contentMaxWidth ?? AppResponsive.contentMaxWidth(context);
    final horizontalPadding = AppResponsive.screenPadding(context).left;

    final bodyContent = constrainBody
        ? LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final width = maxWidth < maxContentWidth
                  ? maxWidth
                  : maxContentWidth;
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: width, child: body),
              );
            },
          )
        : body;

    final paddedBody = useScreenPadding
        ? Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: bodyContent,
          )
        : bodyContent;

    if (!showAppBar || isHome) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(top: false, bottom: false, child: paddedBody),
        bottomNavigationBar: showBottomNav
            ? _BottomNavBar(
                currentIndex: currentIndex,
                highlightCenterAdd: highlightCenterAdd,
                backgroundColor: bottomBarColor,
                activeColor: bottomActiveColor,
                inactiveColor: bottomInactiveColor,
              )
            : null,
      );
    }

    final screenSize = MediaQuery.of(context).size;
    const headerHeight = 220.0;
    final bodyTop = screenSize.height < 700 ? 120.0 : 127.0;
    // Manually building header to allow avatar and back button in the same space without affecting title position
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // Gradient hero header
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0B1120),
                          const Color(0xFF1E293B),
                          theme.colorScheme.primary.withOpacity(0.85),
                        ]
                      : [
                          const Color(0xFFEEF2FF),
                          const Color(0xFFE0EAFF),
                          theme.colorScheme.primary.withOpacity(0.85),
                        ],
                ),
              ),
            ),
            _ManualHeader(
              title: title,
              headerContent: headerContent,
              showBackButton: showBackButton,
              showAvatar: _shouldShowAvatar(),
              onBackTap: _handleBackTap,
            ),
            Positioned.fill(
              top: bodyTop,
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.7)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: paddedBody,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? _BottomNavBar(
              currentIndex: currentIndex,
              highlightCenterAdd: highlightCenterAdd,
              backgroundColor: bottomBarColor,
              activeColor: bottomActiveColor,
              inactiveColor: bottomInactiveColor,
            )
          : null,
    );
  }

  bool _shouldShowAvatar() {
    if (showBackButton) return false;
    if (showAvatar) return true;
    if (currentIndex == 3 || currentIndex == 4) return true;

    final lowerTitle = title.toLowerCase();
    return lowerTitle == 'foryou' ||
        lowerTitle == 'for you' ||
        lowerTitle == 'explore' ||
        lowerTitle == 'chat';
  }

  void _handleBackTap() {
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
      return;
    }
    Get.offNamed(AppRoutes.home);
  }
}

class _ManualHeader extends StatelessWidget {
  final String title;
  final Widget? headerContent;
  final bool showBackButton;
  final bool showAvatar;
  final VoidCallback onBackTap;

  const _ManualHeader({
    required this.title,
    required this.headerContent,
    required this.showBackButton,
    required this.showAvatar,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBack = showBackButton;
    final hasAvatar = !hasBack && showAvatar;
    final left = hasBack ? 22.0 : 26.0;
    final top = hasBack ? 60.0 : 62.0;
    final size = hasBack ? 32.0 : 28.0;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth < 360 ? 22.0 : 24.0;

    return Stack(
      children: [
        if (hasBack)
          Positioned(
            top: top,
            left: left,
            width: size,
            height: size,
            child: _HeaderBackButton(onTap: onBackTap),
          ),
        if (hasAvatar)
          Positioned(
            top: top,
            left: left,
            width: size,
            height: size,
            child: _HeaderAvatar(size: size),
          ),
        if (headerContent != null)
          Positioned(
            top: 52,
            left: showBackButton ? 72 : 26,
            right: 22,
            child: headerContent!,
          )
        else
          Positioned(
            top: 60,
            left: 72,
            right: 72,
            height: 32,
            child: Center(
              child: Text(
                title.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeaderBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      elevation: 4,
      color: isDark ? const Color(0xFF020617) : Colors.white,
      shadowColor:
          isDark ? Colors.black.withOpacity(0.9) : Colors.black.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: isDark
                ? const Color(0xFFE2E8F0)
                : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  final double size;

  const _HeaderAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    if (Get.isRegistered<HomeProfileController>()) {
      final profileController = Get.find<HomeProfileController>();
      return Obx(
        () => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
          ),
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.profile),
            borderRadius: BorderRadius.circular(size / 2),
            child: CircleAvatar(
              radius: size / 2,
              backgroundImage: profileController.avatarProvider,
              backgroundColor: const Color(0xFFEAEAEA),
              child: profileController.avatarProvider == null
                  ? const Icon(Icons.person, size: 14, color: Colors.black54)
                  : null,
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.profile),
        borderRadius: BorderRadius.circular(size / 2),
        child: const CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFFEAEAEA),
          child: Icon(Icons.person, size: 14, color: Colors.black54),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool highlightCenterAdd;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const _BottomNavBar({
    required this.currentIndex,
    required this.highlightCenterAdd,
    required this.backgroundColor,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final mediaPadding = MediaQuery.of(context).padding;
    final bottomInset = mediaPadding.bottom;
    final horizontalInset = mediaPadding.left + mediaPadding.right;
    const barHeight = 70.0;
    const barTopPadding = 8.0;
    const centerButtonWidth = 58.5;
    const centerButtonHeight = 60.0;
    const centerButtonBorder = 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = (constraints.maxWidth - horizontalInset).clamp(
          0.0,
          double.infinity,
        );
        final available = totalWidth - centerButtonWidth;
        final itemWidth = math.max(48.0, available / 6);
        final iconSize = itemWidth >= 72 ? 26.0 : 24.0;
        final labelFontSize = itemWidth >= 72 ? 12.0 : 10.0;

        return Padding(
          padding: EdgeInsets.only(
            left: mediaPadding.left,
            right: mediaPadding.right,
          ),
          child: SizedBox(
            height: barHeight + bottomInset,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: barHeight + bottomInset,
                  padding: EdgeInsets.only(
                    bottom: bottomInset,
                    top: barTopPadding,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 12,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        width: itemWidth,
                        label: 'Home'.tr,
                        icon: Icons.home,
                        isActive: currentIndex == 0,
                        onTap: () => _goTo(AppRoutes.home, 0),
                        iconSize: iconSize,
                        fontSize: labelFontSize,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      _NavItem(
                        width: itemWidth,
                        label: 'Food Log'.tr,
                        icon: Icons.restaurant_menu,
                        isActive: currentIndex == 1,
                        onTap: () => _goTo(AppRoutes.foodLog, 1),
                        iconSize: iconSize,
                        fontSize: labelFontSize,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      _NavItem(
                        width: itemWidth,
                        label: 'Challenges'.tr,
                        icon: Icons.fitness_center,
                        isActive: currentIndex == 2,
                        onTap: () => _goTo(AppRoutes.challenges, 2),
                        iconSize: iconSize,
                        fontSize: labelFontSize,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      SizedBox(width: centerButtonWidth),
                      _NavItem(
                        width: itemWidth,
                        label: 'Leaderboard'.tr,
                        icon: Icons.bar_chart,
                        isActive: currentIndex == 3,
                        onTap: () => _goTo(AppRoutes.leaderboard, 3),
                        iconSize: iconSize,
                        fontSize: labelFontSize,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      _NavItem(
                        width: itemWidth,
                        label: 'Guides'.tr,
                        icon: Icons.menu_book,
                        isActive: currentIndex == 4,
                        onTap: () => _goTo(AppRoutes.guides, 4),
                        iconSize: iconSize,
                        fontSize: labelFontSize,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                      _NavItem(
                        width: itemWidth,
                        label: 'Settings'.tr,
                        icon: Icons.settings,
                        isActive: currentIndex == 5,
                        onTap: () => _goTo(AppRoutes.settings, 5),
                        iconSize: iconSize,
                        fontSize: labelFontSize,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  child: InkWell(
                    onTap: _onCenterAddTap,
                    borderRadius: BorderRadius.circular(centerButtonHeight / 2),
                    child: Container(
                      width: centerButtonWidth,
                      height: centerButtonHeight,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: highlightCenterAdd
                              ? const Color(0xFFE84C64)
                              : const Color(0xFFE6E6E6),
                          width: centerButtonBorder,
                        ),
                      ),
                      child: const Icon(Icons.add, size: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goTo(String route, int index) {
    if (currentIndex == index) return;
    Get.offNamed(route);
  }

  void _onCenterAddTap() {
    final route = Get.currentRoute;
    if (route == AppRoutes.profile) {
      Get.toNamed(AppRoutes.addAction);
      return;
    }

    if (route == AppRoutes.reelsHome) return;
    Get.toNamed(AppRoutes.reelsHome, arguments: {'openWatchView': true});
  }
}

class _NavItem extends StatelessWidget {
  final double width;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final double iconSize;
  final double fontSize;
  final Color activeColor;
  final Color inactiveColor;

  const _NavItem({
    required this.width,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.iconSize,
    required this.fontSize,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
