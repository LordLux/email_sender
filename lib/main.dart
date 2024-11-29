import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart' as mat;

import '../screens/gruppi.dart';
import '../src/database.dart' as db;
import 'functions.dart';
import 'src/manager.dart';
import 'screens/credentials.dart';
import 'screens/email.dart';
import 'screens/excel.dart';
import 'screens/home.dart';
import 'screens/settings.dart';
import 'theme.dart';

final _appTheme = AppTheme();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await flutter_acrylic.Window.hideWindowControls();
    }
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setMinimumSize(const Size(850, 400));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }
  //
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  //db.EmailDatabase().cleanDatabase();

  SettingsManager.settings = await SettingsManager.loadSettings();

  if (Manager.excelPath != null) loadDefaultExcelFile();

  runApp(const MyApp());
}

Future<void> loadDefaultExcelFile() async {
  final file = File(Manager.excelPath!);
  if (file.existsSync()) Manager.loadExcel();
}

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

const String appTitle = "Email Sender";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, child) {
        final appTheme = context.watch<AppTheme>();
        return mat.ScaffoldMessenger(
          child: FluentApp.router(
            title: appTitle,
            themeMode: appTheme.mode,
            debugShowCheckedModeBanner: false,
            color: appTheme.color,
            darkTheme: FluentThemeData(
              brightness: Brightness.dark,
              accentColor: appTheme.color,
              visualDensity: VisualDensity.standard,
              focusTheme: FocusThemeData(
                glowFactor: is10footScreen(context) ? 2.0 : 0.0,
              ),
            ),
            theme: FluentThemeData(
              accentColor: appTheme.color,
              visualDensity: VisualDensity.standard,
              focusTheme: FocusThemeData(
                glowFactor: is10footScreen(context) ? 2.0 : 0.0,
              ),
            ),
            locale: const Locale('it'),
            builder: (context, child) {
              return Navigator(
                onGenerateRoute: (_) => mat.MaterialPageRoute(
                  builder: (context) => Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder: (context) => mat.ValueListenableBuilder(
                            valueListenable: overlayEntry,
                            builder: (context, overlay, _) {
                              return Container(
                                color: Colors.black.withOpacity(.5),
                                child: GestureDetector(
                                  behavior: overlay != null ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                                  onTap: () {
                                    removeOverlay();
                                  },
                                  child: Directionality(
                                    textDirection: appTheme.textDirection,
                                    child: NavigationPaneTheme(
                                      data: NavigationPaneThemeData(
                                        backgroundColor: appTheme.windowEffect != flutter_acrylic.WindowEffect.disabled ? Colors.transparent : null,
                                      ),
                                      child: child ?? const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              );
            },
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
            routeInformationProvider: router.routeInformationProvider,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.child,
    required this.shellContext,
  });

  final Widget child;
  final BuildContext? shellContext;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  bool value = false;

  // int index = 0;

  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();

  late final List<NavigationPaneItem> originalItems = [
    PaneItem(
      key: const ValueKey('/'),
      icon: const Icon(FluentIcons.home),
      title: const Text('Home'),
      body: const SizedBox.shrink(),
      //infoBadge: const InfoBadge(source: Icon(mat.Icons.check, size: 12.0)),
    ),
    PaneItemSeparator(),
    //PaneItemHeader(header: const Text('Excel')),
    PaneItem(
      key: const ValueKey('/excel'),
      icon: const Icon(FluentIcons.excel_document),
      title: const Text('Excel'),
      body: const SizedBox.shrink(),
    ),
    PaneItem(
      key: const ValueKey('/gruppi'),
      icon: const Icon(FluentIcons.people),
      title: const Text('Destinatari'),
      body: const SizedBox.shrink(),
    ),
    PaneItem(
      key: const ValueKey('/email'),
      icon: const Icon(FluentIcons.mail),
      title: const Text('Email'),
      body: const SizedBox.shrink(),
    ),
  ].map<NavigationPaneItem>((e) {
    PaneItem buildPaneItem(PaneItem item) {
      return PaneItem(
        key: item.key,
        icon: item.icon,
        title: item.title,
        body: item.body,
        infoBadge: item.infoBadge,
        onTap: () {
          final path = (item.key as ValueKey).value;
          if (GoRouterState.of(context).uri.toString() != path) {
            context.go(path);
          }
          item.onTap?.call();
        },
      );
    }

    if (e is PaneItemExpander) {
      return PaneItemExpander(
        key: e.key,
        icon: e.icon,
        title: e.title,
        body: e.body,
        infoBadge: e.infoBadge,
        items: e.items.map((item) {
          if (item is PaneItem) return buildPaneItem(item);
          return item;
        }).toList(),
      );
    }
    if (e is PaneItem) return buildPaneItem(e);
    return e;
  }).toList();
  late final List<NavigationPaneItem> footerItems = [
    PaneItemSeparator(),
    PaneItem(
      key: const ValueKey('/credentials'),
      icon: const Icon(FluentIcons.lock),
      title: const Text('Credenziali'),
      body: const SizedBox.shrink(),
      onTap: () {
        if (GoRouterState.of(context).uri.toString() != '/credentials') {
          context.go('/credentials');
        }
      },
    ),
    PaneItem(
      key: const ValueKey('/settings'),
      icon: const Icon(FluentIcons.settings),
      title: const Text('Impostazioni'),
      body: const SizedBox.shrink(),
      onTap: () {
        if (GoRouterState.of(context).uri.toString() != '/settings') {
          context.go('/settings');
        }
      },
    ),
  ];

  void _loadSettings() async => await SettingsManager.assignSettings(context);

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadSettings();
      if (Manager.excelPath != null) {
        File file = File(Manager.excelPath!);
        if (file.existsSync()) await Manager.loadExcel();
        checkEmails(Manager.uffici, context, () => setState(() {}));
      }
      await Future.delayed(const Duration(milliseconds: 100));
      if (Manager.sourceMail.isEmpty || Manager.sourcePassword == null || Manager.sourcePassword!.isEmpty) {
        infoBadge('/credentials', false);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int indexOriginal = originalItems.where((item) => item.key != null).toList().indexWhere((item) => item.key == Key(location));

    if (indexOriginal == -1) {
      int indexFooter = footerItems.where((element) => element.key != null).toList().indexWhere((element) => element.key == Key(location));
      if (indexFooter == -1) {
        return 0;
      }
      return originalItems.where((element) => element.key != null).toList().length + indexFooter;
    } else {
      return indexOriginal;
    }
  }

  /// Build
  @override
  Widget build(BuildContext context) {
    final localizations = FluentLocalizations.of(context);

    final appTheme = context.watch<AppTheme>();
    if (widget.shellContext != null) {
      if (router.canPop() == false) {
        setState(() {});
      }
    }
    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: () {
          if (kIsWeb) {
            return const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            );
          }
          return const DragToMoveArea(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            ),
          );
        }(),
        actions: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if (!kIsWeb) WindowButtons(),
        ]),
      ),
      paneBodyBuilder: (item, child) {
        final name = item?.key is ValueKey ? (item!.key as ValueKey).value : null;
        return FocusTraversalGroup(
          key: ValueKey('body$name'),
          child: widget.child,
        );
      },
      pane: NavigationPane(
        selected: _calculateSelectedIndex(context),
        displayMode: appTheme.displayMode,
        indicator: () {
          switch (appTheme.indicator) {
            case NavigationIndicators.end:
              return const EndNavigationIndicator();
            case NavigationIndicators.sticky:
            default:
              return const StickyNavigationIndicator();
          }
        }(),
        items: originalItems,
        footerItems: footerItems,
      ),
      onOpenSearch: searchFocusNode.requestFocus,
      transitionBuilder: (child, animation) {
        return DrillInPageTransition(
          animation: animation,
          child: child,
        );
      },
    );
  }

  @override
  void onWindowClose() async {
    if (context.mounted) Navigator.of(context).pop();
    db.EmailDatabase().close();
    await windowManager.destroy();
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<_MyHomePageState> myHomePageKey = GlobalKey<_MyHomePageState>();
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MyHomePage(
          key: myHomePageKey,
          shellContext: _shellNavigatorKey.currentContext,
          child: child,
        );
      },
      routes: <GoRoute>[
        /// Home
        GoRoute(path: '/', builder: (context, state) => HomePage(key: homePageKey)),

        /// Excel
        GoRoute(
            path: '/excel',
            builder: (context, state) {
              removeOverlay();
              return ExcelScreen(key: excelKey);
            }),

        // Gruppi
        GoRoute(
            path: '/gruppi',
            builder: (context, state) {
              removeOverlay();
              return MailingLists(key: gruppiKey);
            }),

        //Email
        GoRoute(
            path: '/email',
            builder: (context, state) {
              removeOverlay();
              return const Email();
            }),

        /////////////////////

        /// Credentials
        GoRoute(
            path: '/credentials',
            builder: (context, state) {
              removeOverlay();
              return const Credentials();
            }),

        /// Settings
        GoRoute(
            path: '/settings',
            builder: (context, state) {
              removeOverlay();
              return const Settings();
            }),
      ],
    ),
  ],
);
//mocv zuqy cfvy emck
//TODO add 'closing' screen when closing the app
//TODO add  tooltip warning for empty uffici
//TODO intercept 'Invalid Message' error when sending email with no recipients
//TODO show 'annulla' and 'aggiungi' only when nome/email controllers not empty
//TODO change Visual Name of the app

//TODO check fix for acrylic not starting correctly sometimes