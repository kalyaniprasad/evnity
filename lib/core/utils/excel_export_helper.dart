import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelExportHelper {
  /// Converts a list of registration maps into an Excel file and shares it.
  static Future<void> exportAndShare({
    required String eventTitle,
    required List<Map<String, dynamic>> registrations,
  }) async {
    if (registrations.isEmpty) return;

    final excel = Excel.createExcel();
    final sheet = excel['Attendees'];

    // 1. Determine all unique headers
    final Set<String> headers = {'Name', 'Email', 'Phone', 'Branch', 'Year', 'Registered At'};
    
    // Add custom response fields to headers
    for (final reg in registrations) {
      final responses = reg['responses'] as Map<String, dynamic>?;
      if (responses != null) {
        headers.addAll(responses.keys);
      }
    }

    final headerList = headers.toList();

    // 2. Add header row styling
    for (var i = 0; i < headerList.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headerList[i]);
    }

    // 3. Populate rows
    for (var r = 0; r < registrations.length; r++) {
      final reg = registrations[r];
      final responses = reg['responses'] as Map<String, dynamic>? ?? {};
      
      for (var c = 0; c < headerList.length; c++) {
        final header = headerList[c];
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        
        dynamic value;
        switch (header) {
          case 'Name': value = reg['aliasName'] ?? reg['name']; break;
          case 'Email': value = reg['email']; break;
          case 'Phone': value = reg['phone']; break;
          case 'Branch': value = reg['branch']; break;
          case 'Year': value = reg['year']; break;
          case 'Registered At': value = reg['registeredAt']?.toString(); break;
          default: value = _formatValue(responses[header]);
        }
        
        cell.value = TextCellValue(value?.toString() ?? '-');
      }
    }

    // 4. Save and store
    final fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final fileName = '${eventTitle.replaceAll(' ', '_')}_Attendees.xlsx';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(fileBytes!);

    // 5. Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Attendee List for $eventTitle',
    );
  }

  static dynamic _formatValue(dynamic val) {
    if (val == null) return '-';
    if (val is List) {
       return val.join(', ');
    }
    if (val is Map) {
       // For repeating blocks, format as a string summary
       return val.values.join(' | ');
    }
    return val;
  }
}
