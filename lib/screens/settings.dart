// ignore_for_file: constant_identifier_names

import 'package:email_sender/manager.dart';
import 'package:flutter/foundation.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../widgets/page.dart';
import '/enums.dart';

const List<String> accentColorNames = [
  'Sistema',
  'Giallo',
  'Arancione',
  'Rosso',
  'Magenta',
  'Viola',
  'Blu',
  'Verde Acqua',
  'Verde',
];

bool get kIsWindowEffectsSupported {
  return !kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
}

const _LinuxWindowEffects = [
  WindowEffect.disabled,
  WindowEffect.transparent,
];

const _WindowsWindowEffects = [
  WindowEffect.disabled,
  WindowEffect.solid,
  WindowEffect.transparent,
  WindowEffect.aero,
  WindowEffect.acrylic,
  WindowEffect.mica,
  WindowEffect.tabbed,
];

const _MacosWindowEffects = [
  WindowEffect.disabled,
  WindowEffect.titlebar,
  WindowEffect.selection,
  WindowEffect.menu,
  WindowEffect.popover,
  WindowEffect.sidebar,
  WindowEffect.headerView,
  WindowEffect.sheet,
  WindowEffect.windowBackground,
  WindowEffect.hudWindow,
  WindowEffect.fullScreenUI,
  WindowEffect.toolTip,
  WindowEffect.contentBackground,
  WindowEffect.underWindowBackground,
  WindowEffect.underPageBackground,
];

List<WindowEffect> get currentWindowEffects {
  if (kIsWeb) return [];

  if (defaultTargetPlatform == TargetPlatform.windows) {
    return _WindowsWindowEffects;
  } else if (defaultTargetPlatform == TargetPlatform.linux) {
    return _LinuxWindowEffects;
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    return _MacosWindowEffects;
  }

  return [];
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with PageMixin {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final appTheme = context.watch<AppTheme>();
    const spacer = SizedBox(height: 10.0);
    const biggerSpacer = SizedBox(height: 40.0);

    return ScaffoldPage.scrollable(
      header: const PageHeader(title: Text('Impostazioni')),
      children: [
        Text('Tema', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        ...List.generate(ThemeMode.values.length, (index) {
          final mode = ThemeMode.values[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: RadioButton(
              checked: appTheme.mode == mode,
              onChanged: (value) {
                if (value) {
                  appTheme.mode = mode;

                  if (kIsWindowEffectsSupported) {
                    // some window effects require on [dark] to look good.
                    // appTheme.setEffect(WindowEffect.disabled, context);
                    appTheme.setEffect(appTheme.windowEffect, context);
                  }
                }
              },
              content: Text(mode.name),
            ),
          );
        }),
        biggerSpacer,
        Text('Color Accento', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        Wrap(children: [
          Tooltip(
            message: accentColorNames[0],
            child: _buildColorBlock(appTheme, systemAccentColor),
          ),
          ...List.generate(Colors.accentColors.length, (index) {
            final color = Colors.accentColors[index];
            return Tooltip(
              message: accentColorNames[index + 1],
              child: _buildColorBlock(appTheme, color),
            );
          }),
        ]),
        biggerSpacer,
        Text(
          'Modalità di Visualizzazione della Barra di Navigazione',
          style: FluentTheme.of(context).typography.subtitle,
        ),
        spacer,
        ...List.generate(PaneDisplayMode.values.length, (index) {
          final mode = PaneDisplayMode.values.reversed.toList()[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: RadioButton(
              checked: appTheme.displayMode == mode,
              onChanged: (value) {
                if (value) appTheme.displayMode = mode;
              },
              content: Text(mode.name),
            ),
          );
        }),
        /*Text('Indicatore di Navigazione', style: FluentTheme.of(context).typography.subtitle),
        spacer,
        ...List.generate(NavigationIndicators.values.length, (index) {
          final mode = NavigationIndicators.values[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8.0),
            child: RadioButton(
              checked: appTheme.indicator == mode,
              onChanged: (value) {
                if (value) appTheme.indicator = mode;
              },
              content: Text(
                mode.toString().replaceAll('NavigationIndicators.', ''),
              ),
            ),
          );
        }),
        biggerSpacer,*/
        if (kIsWindowEffectsSupported) ...[
          biggerSpacer,
          Text(
            'Trasparenza della Finestra',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          description(
            content: Text(
              'Impostazioni su ${defaultTargetPlatform.toString().replaceAll('TargetPlatform.', '')}',
            ),
          ),
          spacer,
          ...List.generate(currentWindowEffects.length, (index) {
            final mode = currentWindowEffects[index];
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 8.0),
              child: RadioButton(
                checked: appTheme.windowEffect == mode,
                onChanged: (value) {
                  if (value) {
                    appTheme.windowEffect = mode;
                    appTheme.setEffect(mode, context);
                    SettingsManager.saveSettings({'windowEffect': mode.name});
                  }
                },
                content: Text(mode.name),
              ),
            );
          }),
        ],
        /*biggerSpacer,
        Text('Locale', style: FluentTheme.of(context).typography.subtitle),
        description(
          content: const Text(
            'The locale used by the fluent_ui widgets, such as TimePicker and '
            'DatePicker. This does not reflect the language of this showcase app.',
          ),
        ),
        spacer,
        Wrap(
          spacing: 15.0,
          runSpacing: 10.0,
          children: List.generate(
            supportedLocales.length,
            (index) {
              final locale = supportedLocales[index];

              return Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8.0),
                child: RadioButton(
                  checked: currentLocale == locale,
                  onChanged: (value) {
                    if (value) {
                      appTheme.locale = locale;
                    }
                  },
                  content: Text('$locale'),
                ),
              );
            },
          ),
        ),*/
        biggerSpacer,
      ],
    );
  }

  Widget _buildColorBlock(AppTheme appTheme, AccentColor color) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Button(
        onPressed: () {
          appTheme.color = color;
        },
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.isPressed) {
              return color.light;
            } else if (states.isHovered) {
              return color.lighter;
            }
            return color;
          }),
        ),
        child: Container(
          height: 40,
          width: 40,
          alignment: AlignmentDirectional.center,
          child: appTheme.color == color
              ? Icon(
                  FluentIcons.check_mark,
                  color: color.basedOnLuminance(),
                  size: 22.0,
                )
              : null,
        ),
      ),
    );
  }
}
