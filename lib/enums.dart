import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

extension PaneDisplayModeX on PaneDisplayMode {
  String get name {
    switch (this) {
      case PaneDisplayMode.auto:
        return 'Automatico';
      case PaneDisplayMode.compact:
        return 'Compatto';
      case PaneDisplayMode.minimal:
        return 'Minimal';
      case PaneDisplayMode.open:
        return 'Aperto';
      case PaneDisplayMode.top:
        return 'In alto';
    }
  }
}

extension ThemeX on ThemeMode {
  String get name {
    switch (this) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Chiaro';
      case ThemeMode.dark:
        return 'Scuro';
    }
  }
}

extension WindowEffectX on WindowEffect {
  String get name {
    switch (this) {
      case WindowEffect.disabled:
        return 'Disabilitato';
      case WindowEffect.transparent:
        return 'Trasparente';
      case WindowEffect.solid:
        return 'Solido';
      case WindowEffect.aero:
        return 'Aero';
      case WindowEffect.acrylic:
        return 'Acrylic';
      case WindowEffect.mica:
        return 'Mica';
      case WindowEffect.tabbed:
        return 'Tabbato';
      case WindowEffect.titlebar:
        return 'Barra del titolo';
      case WindowEffect.selection:
        return 'Selezione';
      case WindowEffect.menu:
        return 'Menu';
      case WindowEffect.popover:
        return 'Popover';
      case WindowEffect.sidebar:
        return 'Barra laterale';
      case WindowEffect.headerView:
        return 'HeaderView';
      case WindowEffect.sheet:
        return 'Sheet';
      case WindowEffect.windowBackground:
        return 'WindowBackground';
      case WindowEffect.hudWindow:
        return 'HudWindow';
      case WindowEffect.fullScreenUI:
        return 'FullScreenUI';
      case WindowEffect.toolTip:
        return 'ToolTip';
      case WindowEffect.contentBackground:
        return 'ContentBackground';
      case WindowEffect.underWindowBackground:
        return 'UnderWindowBackground';
      case WindowEffect.underPageBackground:
        return 'UnderPageBackground';
    }
  }
}

WindowEffect windowEffectfromString(String value) {
  switch (value) {
    case 'Disabilitato':
      return WindowEffect.disabled;
    case 'Trasparente':
      return WindowEffect.transparent;
    case 'Solido':
      return WindowEffect.solid;
    case 'Aero':
      return WindowEffect.aero;
    case 'Acrylic':
      return WindowEffect.acrylic;
    case 'Mica':
      return WindowEffect.mica;
    case 'Tabbato':
      return WindowEffect.tabbed;
    case 'Barra del titolo':
      return WindowEffect.titlebar;
    case 'Selezione':
      return WindowEffect.selection;
    case 'Menu':
      return WindowEffect.menu;
    case 'Popover':
      return WindowEffect.popover;
    case 'Barra laterale':
      return WindowEffect.sidebar;
    case 'HeaderView':
      return WindowEffect.headerView;
    case 'Sheet':
      return WindowEffect.sheet;
    case 'WindowBackground':
      return WindowEffect.windowBackground;
    case 'HudWindow':
      return WindowEffect.hudWindow;
    case 'FullScreenUI':
      return WindowEffect.fullScreenUI;
    case 'ToolTip':
      return WindowEffect.toolTip;
    case 'ContentBackground':
      return WindowEffect.contentBackground;
    case 'UnderWindowBackground':
      return WindowEffect.underWindowBackground;
    case 'UnderPageBackground':
      return WindowEffect.underPageBackground;
    default:
      return WindowEffect.disabled;
  }
}
