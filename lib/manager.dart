import 'dart:io';

import 'package:email_sender/enums.dart';
import 'package:email_sender/theme.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Manager {
  static String? excelPath;
  static int lastExcelSheetIndex = 0;

  static Future<List<Map<String, String>>> loadExcelData(File file) async {
    final List<Map<String, String>> extractedData = [];
    int page = lastExcelSheetIndex;

    // Open the Excel file as a stream
    final bytes = await file.readAsBytes();
    final Excel excel = Excel.decodeBytes(bytes);
    final Sheet? sheet = excel.sheets[excel.sheets.keys.toList()[page]];

    if (sheet == null) {
      print('Sheet not found');
      return extractedData;
    }

    // Get the used range (rows and columns with data)
    final int totalRows = sheet.maxRows;
    final int totalColumns = sheet.maxCols;

    // Identify the columns for Name, Mail, and Extra (assuming they are in the first row)
    int nameCol = -1;
    int mailCol = -1;
    int extraCol = -1;

    for (int col = 1; col <= totalColumns; col++) {
      final cellValue = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col - 1, rowIndex: 0)).value.toString().trim().toLowerCase();
      if (cellValue == 'name') nameCol = col;
      if (cellValue == 'mail') mailCol = col;
      if (cellValue == 'extra') extraCol = col;
    }

    if (nameCol == -1 || mailCol == -1 || extraCol == -1) {
      print('Required columns not found');
      return extractedData;
    }

    // Extract data from rows
    for (int row = 2; row <= totalRows; row++) {
      final String name = sheet.cell(CellIndex.indexByColumnRow(columnIndex: nameCol - 1, rowIndex: row - 1)).value.toString();
      final String mail = sheet.cell(CellIndex.indexByColumnRow(columnIndex: mailCol - 1, rowIndex: row - 1)).value.toString();
      final String extra = sheet.cell(CellIndex.indexByColumnRow(columnIndex: extraCol - 1, rowIndex: row - 1)).value.toString();

      extractedData.add({
        'Name': name,
        'Mail': mail,
        'Extra': extra,
      });
    }

    return extractedData;
  }

  static Future<void> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final file = File(result.files.single.path!);
      if (file.existsSync()) loadExcelData(file);
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
    if (settings["excelPath"] != null && settings["excelPath"] != "") Manager.excelPath = settings["excelPath"];
    if (settings["windowEffect"] != null && settings["windowEffect"] != "") appTheme.windowEffect = windowEffectfromString(settings["windowEffect"]);
  }

  static void clearSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('settings', []);
    settings = {};
    
    Manager.excelPath = null;
  }
}
