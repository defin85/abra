import 'package:flutter/material.dart';

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

enum ScreenSize {
  small,    // < 600px
  medium,   // 600px - 1024px  
  large,    // > 1024px
}

class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  
  // Panel widths for different screen sizes
  static const double mobilePanelWidth = 280;
  static const double tabletPanelWidth = 300;
  static const double desktopPanelWidth = 320;
  
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return ScreenSize.small;
    } else if (width < tabletBreakpoint) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }
  
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }
  
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return getDeviceType(context) == DeviceType.desktop;
  }
  
  static double getPanelWidth(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobilePanelWidth;
      case DeviceType.tablet:
        return tabletPanelWidth;
      case DeviceType.desktop:
        return desktopPanelWidth;
    }
  }
  
  static bool shouldShowPanelsAsDrawers(BuildContext context) {
    return isMobile(context);
  }
  
  static bool shouldShowBothPanels(BuildContext context) {
    return isDesktop(context);
  }
  
  static bool shouldUseTabs(BuildContext context) {
    return isMobile(context);
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(8.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(12.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) {
      return baseFontSize * 0.9;
    } else if (isTablet(context)) {
      return baseFontSize * 0.95;
    } else {
      return baseFontSize;
    }
  }
}

// Extension for easier usage
extension ResponsiveContext on BuildContext {
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  double get panelWidth => ResponsiveUtils.getPanelWidth(this);
  bool get shouldShowPanelsAsDrawers => ResponsiveUtils.shouldShowPanelsAsDrawers(this);
  bool get shouldShowBothPanels => ResponsiveUtils.shouldShowBothPanels(this);
  bool get shouldUseTabs => ResponsiveUtils.shouldUseTabs(this);
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
}