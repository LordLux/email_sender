import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:email_sender/enums.dart';
import 'package:email_sender/screens/excel.dart';
import 'package:email_sender/theme.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../src/classes.dart';
import '../functions.dart';

class Manager {
  static String? excelPath;
  static String sourceMail = 'daniele.mason@maggioli.it';
  static String sourceName = 'Daniele Mason';
  static String? sourcePassword;
  
  static List<Ufficio> uffici = [];
  
  static bool multiSelection = false;
  static List<Ufficio> selectedGroups = [];
  static List<Map<String, String>> extraRecipients = [];
  
  static List<XFile> attachments = [];
  
  static TextEditingController emailController = TextEditingController();
  static TextEditingController oggettoController = TextEditingController();
  static TextEditingController extraRecNameController = TextEditingController();
  static TextEditingController extraRecEmailController = TextEditingController();


  static Future<String> get lastDirectory async => excelPath != null ? removeFileNameFromPath(excelPath!) : (await getApplicationSupportDirectory()).path;

  static void clearEmail(VoidCallback setState) {
    selectedGroups.clear();
    attachments.clear();
    emailController.clear();
    oggettoController.clear();
    extraRecipients.clear();
    multiSelection = false;
    setState();
  }

  static Future<void> loadExcel() async {
    uffici.clear(); // Clear the existing uffici list

    File file = File(Manager.excelPath!);
    final bytes = await file.readAsBytes();
    final Excel excel = Excel.decodeBytes(bytes);

    for (int i = 0; i < excel.sheets.keys.length; i++) {
      final Ufficio? ufficio = await loadExcelSheet(file, i);
      if (ufficio != null) {
        uffici.add(ufficio);
        print('Loaded ${ufficio.nome} with ${ufficio.entries.length} entries');
      }
    }
  }

  static Future<Ufficio?> loadExcelSheet(File file, int sheetIndex) async {
    try {
      final bytes = await file.readAsBytes();
      final Excel excel = Excel.decodeBytes(bytes);

      // Get the sheet by index
      final Sheet? sheet = excel.sheets[excel.sheets.keys.toList()[sheetIndex]];
      if (sheet == null) {
        if (kDebugMode) print('Sheet not found');
        return null;
      }

      // Read headers from the first row
      final List<String> headers = [];
      final int totalColumns = sheet.maxCols;
      for (int col = 0; col < totalColumns; col++) {
        final cellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value;
        if (cellValue == null || cellValue.toString().trim().isEmpty) break;
        headers.add(cellValue.toString().trim());
      }

      // Collect all rows data
      final List<List<String>> entries = [];
      final int totalRows = sheet.maxRows;
      for (int row = 1; row < totalRows; row++) {
        final List<String> rowData = [];
        for (int col = 0; col < headers.length; col++) {
          final cellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value;
          rowData.add(cellValue?.toString().trim() ?? '');
        }
        entries.add(rowData);
      }

      // Create the Ufficio object
      final ufficio = Ufficio(
        nome: excel.sheets.keys.toList()[sheetIndex].titleCase,
        headers: headers,
        entries: entries,
      );

      return ufficio;
    } catch (e) {
      if (kDebugMode) print('Error while loading Excel sheet: $e');
      return null;
    }
  }

  static Future<void> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      if (file.existsSync()) loadExcel();
    }
  }
}

class SettingsManager {
  static Map<String, dynamic> settings = {};
  // Load current settings as a map
  static Future<Map<String, String>> _loadCurrentSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> settingsList = prefs.getStringList('settings') ?? [];
    Map<String, String> settingsMap = {};

    for (String setting in settingsList) {
      final List<String> parts = setting.split(':');
      if (parts.length >= 2) {
        // Handle values with colons
        final String key = parts[0];
        final String value = parts.sublist(1).join(':');
        settingsMap[key] = value;
      }
    }

    return settingsMap;
  }

  static Future<void> resetSingleSetting(String setting) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, String> currentSettings = await _loadCurrentSettings();
    if (currentSettings.containsKey(setting))
      currentSettings.remove(setting);
    else
      return;

    final List<String> settingsList = currentSettings.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('settings', settingsList);
  }

  // Save one or more settings
  static Future<void> saveSettings(Map<String, dynamic> newSettings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Load current settings and merge with new ones
    final Map<String, String> currentSettings = await _loadCurrentSettings();
    newSettings.forEach((key, value) {
      currentSettings[key] = value.toString();
    });
    final List<String> settingsList = currentSettings.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList('settings', settingsList);
  }

  // Load settings
  static Future<Map<String, String>> loadSettings() async {
    return await _loadCurrentSettings();
  }

  static Future<void> assignSettings(BuildContext context) async {
    final AppTheme appTheme = Provider.of<AppTheme>(context, listen: false);
    if (_settingCheck(settings["excelPath"])) Manager.excelPath = settings["excelPath"];
    if (_settingCheck(settings["windowEffect"])) appTheme.windowEffect = windowEffectfromString(settings["windowEffect"]);
    if (_settingCheck(settings["password"])) Manager.sourcePassword = settings["password"];
    if (_settingCheck(settings["sourceMail"])) Manager.sourceMail = settings["sourceMail"];
    if (_settingCheck(settings["sourceName"])) Manager.sourceName = settings["sourceName"];
  }

  static void clearSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('settings', []);
    settings = {};

    Manager.excelPath = null;
  }

  static bool _settingCheck(String? setting) => setting != null && setting != "" && setting != "null";
}
