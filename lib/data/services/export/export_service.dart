import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/account.dart';
import '../../models/financial_report.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_entry_line.dart';
import '../../models/print_config.dart';
import '../database/database_service_interface.dart';

enum CsvImportType { accounts, journalEntries, unknown }

class CsvImportResult {
  final CsvImportType type;
  final int importedAccountsCount;
  final int importedTransactionsCount;
  final List<String> warnings;
  final String summary;

  const CsvImportResult({
    required this.type,
    this.importedAccountsCount = 0,
    this.importedTransactionsCount = 0,
    this.warnings = const [],
    required this.summary,
  });
}

class ExportResult {
  final String filePath;
  final String csvContent;
  final String fileName;

  const ExportResult({
    required this.filePath,
    required this.csvContent,
    required this.fileName,
  });

  Uint8List get bytesWithBom =>
      Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)]);
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  String _convertToCsv(List<List<dynamic>> rows) {
    return rows
        .map((row) {
          return row
              .map((cell) {
                final str = cell?.toString() ?? '';
                if (str.contains(',') ||
                    str.contains('"') ||
                    str.contains('\n') ||
                    str.contains('\r')) {
                  return '"${str.replaceAll('"', '""')}"';
                }
                return str;
              })
              .join(',');
        })
        .join('\r\n');
  }

  Future<ExportResult> exportGeneralLedgerToCsv({
    required Account account,
    required List<LedgerEntry> entries,
    required PrintConfig printConfig,
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];

    // Report Header
    rows.add([printConfig.companyName]);
    rows.add([printConfig.slogan]);
    rows.add(['General Ledger: ${account.code} - ${account.name}']);
    rows.add(['Account Type: ${account.type}']);
    rows.add(['Date Generated: ${_dateFormat.format(now)}']);
    rows.add([]); // empty separator line

    // Table Column Headers
    rows.add([
      'Date',
      'Description',
      'Transaction ID',
      'Debit (MMK)',
      'Credit (MMK)',
      'Balance (MMK)',
    ]);

    // Data rows
    double totalDebit = 0;
    double totalCredit = 0;
    for (final e in entries) {
      totalDebit += e.debit;
      totalCredit += e.credit;
      rows.add([
        e.date,
        e.description,
        e.txId,
        e.debit > 0 ? e.debit.toStringAsFixed(2) : '0.00',
        e.credit > 0 ? e.credit.toStringAsFixed(2) : '0.00',
        e.balance.toStringAsFixed(2),
      ]);
    }

    // Totals row
    rows.add([]);
    rows.add([
      'TOTALS',
      '',
      '',
      totalDebit.toStringAsFixed(2),
      totalCredit.toStringAsFixed(2),
      entries.isNotEmpty ? entries.last.balance.toStringAsFixed(2) : '0.00',
    ]);
    rows.add([
      '',
      '',
      '',
      '',
      'ENDING BALANCE',
      entries.isNotEmpty ? entries.last.balance.toStringAsFixed(2) : '0.00',
    ]);
    rows.add([]);
    rows.add([printConfig.footerNote]);

    final csvString = _convertToCsv(rows);
    final fileName =
        'general_ledger_${account.code}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
    final file = await _saveFile(fileName, csvString);

    return ExportResult(
      filePath: file.path,
      csvContent: csvString,
      fileName: fileName,
    );
  }

  Future<ExportResult> exportIncomeStatementToCsv({
    required IncomeStatementReport report,
    required PrintConfig printConfig,
    String? periodLabel,
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];

    // Header
    rows.add([printConfig.companyName]);
    rows.add(['INCOME STATEMENT (PROFIT & LOSS)']);
    if (periodLabel != null && periodLabel.isNotEmpty) {
      rows.add(['Period: $periodLabel']);
    }
    rows.add(['Date Generated: ${_dateFormat.format(now)}']);
    rows.add(['Currency: ${printConfig.currencySymbol}']);
    rows.add([]);

    // Revenue Section
    rows.add(['1. REVENUE', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final r in report.revenues) {
      rows.add([r.account.name, r.account.code, r.amount.toStringAsFixed(2)]);
    }
    rows.add(['Total Net Revenue', '', report.totalRevenue.toStringAsFixed(2)]);
    rows.add([]);

    // COGS Section
    rows.add([
      '2. COST OF GOODS SOLD (COGS)',
      'Code',
      'Amount (${printConfig.currencySymbol})',
    ]);
    for (final c in report.costOfGoodsSold) {
      rows.add([c.account.name, c.account.code, c.amount.toStringAsFixed(2)]);
    }
    rows.add(['Total COGS', '', report.totalCogs.toStringAsFixed(2)]);
    rows.add(['GROSS PROFIT', '', report.grossProfit.toStringAsFixed(2)]);
    rows.add([]);

    // Operating Expenses Section
    rows.add([
      '3. OPERATING EXPENSES',
      'Code',
      'Amount (${printConfig.currencySymbol})',
    ]);
    for (final o in report.operatingExpenses) {
      rows.add([o.account.name, o.account.code, o.amount.toStringAsFixed(2)]);
    }
    rows.add([
      'Total Operating Expenses',
      '',
      report.totalOperatingExpenses.toStringAsFixed(2),
    ]);
    rows.add([]);

    // Net Profit / Loss
    rows.add(['NET PROFIT / LOSS', '', report.netProfit.toStringAsFixed(2)]);
    rows.add([]);
    rows.add([printConfig.footerNote]);

    final csvString = _convertToCsv(rows);
    final fileName =
        'income_statement_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
    final file = await _saveFile(fileName, csvString);

    return ExportResult(
      filePath: file.path,
      csvContent: csvString,
      fileName: fileName,
    );
  }

  Future<ExportResult> exportBalanceSheetToCsv({
    required BalanceSheetReport report,
    required PrintConfig printConfig,
    String? asOfLabel,
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];

    // Header
    rows.add([printConfig.companyName]);
    rows.add(['BALANCE SHEET STATEMENT']);
    if (asOfLabel != null && asOfLabel.isNotEmpty) {
      rows.add(['As of Date: $asOfLabel']);
    }
    rows.add(['Date Generated: ${_dateFormat.format(now)}']);
    rows.add([
      'Balanced Check: ${report.isBalanced ? "BALANCED" : "OUT OF BALANCE"}',
    ]);
    rows.add(['Currency: ${printConfig.currencySymbol}']);
    rows.add([]);

    // Assets
    rows.add(['ASSETS', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final a in report.assets) {
      rows.add([a.account.name, a.account.code, a.amount.toStringAsFixed(2)]);
    }
    rows.add(['TOTAL ASSETS', '', report.totalAssets.toStringAsFixed(2)]);
    rows.add([]);

    // Liabilities
    rows.add(['LIABILITIES', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final l in report.liabilities) {
      rows.add([l.account.name, l.account.code, l.amount.toStringAsFixed(2)]);
    }
    rows.add([
      'TOTAL LIABILITIES',
      '',
      report.totalLiabilities.toStringAsFixed(2),
    ]);
    rows.add([]);

    // Equities
    rows.add(['EQUITY', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final eq in report.equities) {
      rows.add([
        eq.account.name,
        eq.account.code,
        eq.amount.toStringAsFixed(2),
      ]);
    }
    rows.add([
      'Current Period Net Income',
      '',
      report.currentPeriodNetIncome.toStringAsFixed(2),
    ]);
    rows.add([
      'TOTAL LIABILITIES & EQUITY',
      '',
      report.totalLiabilitiesAndEquity.toStringAsFixed(2),
    ]);
    rows.add([]);
    rows.add(['IS BALANCED', '', report.isBalanced ? 'YES' : 'NO']);
    rows.add([]);
    rows.add([printConfig.footerNote]);

    final csvString = _convertToCsv(rows);
    final fileName =
        'balance_sheet_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
    final file = await _saveFile(fileName, csvString);

    return ExportResult(
      filePath: file.path,
      csvContent: csvString,
      fileName: fileName,
    );
  }

  Future<File> _saveFile(String fileName, String content) async {
    Directory dir;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docDir.path, 'AccountingMyanmarExports'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (_) {
      dir = Directory.current;
    }

    final filePath = p.join(dir.path, fileName);
    final file = File(filePath);
    await file.writeAsString(content);
    return file;
  }

  /// Exports chart of accounts to CSV format.
  Future<ExportResult> exportAccountsToCsv({
    required List<Account> accounts,
    PrintConfig? printConfig,
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];

    if (printConfig != null) {
      rows.add([printConfig.companyName]);
      rows.add(['Chart of Accounts (စာရင်းဇယား)']);
      rows.add(['Date Generated: ${_dateFormat.format(now)}']);
      rows.add([]);
    }

    rows.add(['Code', 'Name', 'Type']);
    for (final acc in accounts) {
      rows.add([acc.code, acc.name, acc.type]);
    }

    final csvString = _convertToCsv(rows);
    final fileName =
        'chart_of_accounts_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
    final file = await _saveFile(fileName, csvString);

    return ExportResult(
      filePath: file.path,
      csvContent: csvString,
      fileName: fileName,
    );
  }

  /// Exports journal entries to CSV format.
  Future<ExportResult> exportJournalEntriesToCsv({
    required List<JournalEntry> entries,
    required List<Account> accounts,
    PrintConfig? printConfig,
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];
    final accMap = {for (final a in accounts) a.id: a};

    if (printConfig != null) {
      rows.add([printConfig.companyName]);
      rows.add(['Journal Entries (နေ့စဉ်စာရင်းသွင်းမှုများ)']);
      rows.add(['Date Generated: ${_dateFormat.format(now)}']);
      rows.add([]);
    }

    rows.add([
      'Date',
      'Transaction ID',
      'Description',
      'Account Code',
      'Account Name',
      'Debit',
      'Credit',
      'Status',
      'Remark',
    ]);

    for (final entry in entries) {
      for (final line in entry.lines) {
        final acc = accMap[line.accountId];
        rows.add([
          entry.date,
          entry.id,
          entry.description,
          acc?.code ?? '',
          acc?.name ?? '',
          line.debit > 0 ? line.debit.toStringAsFixed(2) : '0.00',
          line.credit > 0 ? line.credit.toStringAsFixed(2) : '0.00',
          entry.status,
          entry.remark ?? '',
        ]);
      }
    }

    final csvString = _convertToCsv(rows);
    final fileName =
        'journal_entries_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
    final file = await _saveFile(fileName, csvString);

    return ExportResult(
      filePath: file.path,
      csvContent: csvString,
      fileName: fileName,
    );
  }

  /// Saves CSV content using system FilePicker dialog with UTF-8 BOM encoding.
  Future<Uri?> saveCsvWithPicker({
    required String fileName,
    required String csvContent,
    String? dialogTitle,
  }) async {
    final bytes = Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(csvContent),
    ]);

    final savedUri = await FilePicker.saveFile(
      dialogTitle: dialogTitle ?? 'Save CSV File (CSV ဖိုင်သိမ်းဆည်းပါ)',
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (savedUri != null && savedUri.scheme == 'file') {
      try {
        final file = File(savedUri.toFilePath());
        if (!await file.exists() || await file.length() == 0) {
          await file.writeAsBytes(bytes);
        }
      } catch (e) {
        debugPrint('[ExportService] Error verifying saved file: $e');
      }
    }

    return savedUri;
  }

  /// Parses CSV text adhering to RFC 4180 (handling quotes, commas, escapes, and CRLF).
  List<List<String>> parseCsv(String input) {
    var text = input;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }
    final rows = <List<String>>[];
    final currentField = StringBuffer();
    final currentRow = <String>[];
    bool inQuotes = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            currentField.write('"');
            i++; // skip next quote
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString().trim());
          currentField.clear();
        } else if (char == '\n' || char == '\r') {
          if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
            i++; // skip \n
          }
          currentRow.add(currentField.toString().trim());
          currentField.clear();
          if (currentRow.any((c) => c.isNotEmpty)) {
            rows.add(List.from(currentRow));
          }
          currentRow.clear();
        } else {
          currentField.write(char);
        }
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.any((c) => c.isNotEmpty)) {
        rows.add(List.from(currentRow));
      }
    }

    return rows;
  }

  /// Detects whether rows represent Chart of Accounts or Journal Entries.
  CsvImportType detectCsvType(List<List<String>> rows) {
    for (final r in rows.take(10)) {
      final lower = r.map((c) => c.toLowerCase()).toList();
      final hasCode = lower.any((c) => c.contains('code'));
      final hasName = lower.any((c) => c.contains('name'));
      final hasType = lower.any((c) => c.contains('type'));
      final hasDebit = lower.any((c) => c.contains('debit'));
      final hasCredit = lower.any((c) => c.contains('credit'));
      final hasDesc = lower.any((c) => c.contains('desc'));

      if (hasDebit || hasCredit || hasDesc) {
        return CsvImportType.journalEntries;
      }
      if (hasCode && (hasName || hasType)) {
        return CsvImportType.accounts;
      }
    }
    return CsvImportType.unknown;
  }

  /// Imports CSV text into the database after detecting type and parsing.
  Future<CsvImportResult> importCsvContent(
    String csvContent, {
    required DatabaseServiceInterface dbService,
  }) async {
    final rows = parseCsv(csvContent);
    if (rows.isEmpty) {
      throw const FormatException(
        'CSV ဖိုင်ထဲတွင် ဒေတာ အချက်အလက်များ မရှိပါ (CSV file is empty)',
      );
    }

    final type = detectCsvType(rows);
    switch (type) {
      case CsvImportType.accounts:
        return await _importAccountsCsv(rows, dbService);
      case CsvImportType.journalEntries:
        return await _importJournalEntriesCsv(rows, dbService);
      case CsvImportType.unknown:
        throw const FormatException(
          'မသိရှိနိုင်သော CSV ပုံစံ ဖြစ်နေပါသည်။ (Unrecognized CSV structure. Expecting Chart of Accounts or Journal Entries format.)',
        );
    }
  }

  Future<CsvImportResult> _importAccountsCsv(
    List<List<String>> rows,
    DatabaseServiceInterface dbService,
  ) async {
    int headerIdx = -1;
    int codeIdx = -1;
    int nameIdx = -1;
    int typeIdx = -1;

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r].map((e) => e.toLowerCase()).toList();
      final cIdx = row.indexWhere((col) => col.contains('code'));
      final nIdx = row.indexWhere((col) => col.contains('name'));
      final tIdx = row.indexWhere((col) => col.contains('type'));
      if (cIdx != -1 && nIdx != -1) {
        headerIdx = r;
        codeIdx = cIdx;
        nameIdx = nIdx;
        typeIdx = tIdx;
        break;
      }
    }

    if (headerIdx == -1) {
      throw const FormatException(
        'Account Code နှင့် Account Name ကော်လံများ မတွေ့ရှိပါ',
      );
    }

    int count = 0;
    final existingAccounts = await dbService.getAllAccounts();
    final existingMap = {for (final a in existingAccounts) a.code: a};

    for (int r = headerIdx + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.length <= codeIdx || row.length <= nameIdx) continue;
      final code = row[codeIdx].trim();
      final name = row[nameIdx].trim();
      if (code.isEmpty || name.isEmpty) continue;

      String type = 'Asset';
      if (typeIdx != -1 &&
          row.length > typeIdx &&
          row[typeIdx].trim().isNotEmpty) {
        final rawType = row[typeIdx].trim().toLowerCase();
        if (rawType.contains('liab')) {
          type = 'Liability';
        } else if (rawType.contains('eq')) {
          type = 'Equity';
        } else if (rawType.contains('rev') || rawType.contains('income')) {
          type = 'Revenue';
        } else if (rawType.contains('exp')) {
          type = 'Expense';
        } else {
          type = 'Asset';
        }
      }

      final existing = existingMap[code];
      final account = Account(
        id:
            existing?.id ??
            'acc_${DateTime.now().microsecondsSinceEpoch}_$count',
        code: code,
        name: name,
        type: type,
      );

      if (existing != null) {
        await dbService.updateAccount(account);
      } else {
        await dbService.insertAccount(account);
      }
      count++;
    }

    return CsvImportResult(
      type: CsvImportType.accounts,
      importedAccountsCount: count,
      summary:
          'အကောင့် $count ခု အောင်မြင်စွာ ထည့်သွင်း/ပြင်ဆင်ပြီးပါပြီ။ ($count accounts imported/updated)',
    );
  }

  Future<CsvImportResult> _importJournalEntriesCsv(
    List<List<String>> rows,
    DatabaseServiceInterface dbService,
  ) async {
    int headerIdx = -1;
    int dateIdx = -1;
    int descIdx = -1;
    int codeIdx = -1;
    int debitIdx = -1;
    int creditIdx = -1;
    int remarkIdx = -1;

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r].map((e) => e.toLowerCase()).toList();
      final dtIdx = row.indexWhere((col) => col.contains('date'));
      final dsIdx = row.indexWhere((col) => col.contains('desc'));
      final dbIdx = row.indexWhere((col) => col.contains('debit'));
      final crIdx = row.indexWhere((col) => col.contains('credit'));
      final cdIdx = row.indexWhere(
        (col) => col.contains('code') || col.contains('account'),
      );
      final rmIdx = row.indexWhere(
        (col) => col.contains('remark') || col.contains('note'),
      );

      if ((dtIdx != -1 || dsIdx != -1) && (dbIdx != -1 || crIdx != -1)) {
        headerIdx = r;
        dateIdx = dtIdx;
        descIdx = dsIdx;
        codeIdx = cdIdx;
        debitIdx = dbIdx;
        creditIdx = crIdx;
        remarkIdx = rmIdx;
        break;
      }
    }

    if (headerIdx == -1) {
      throw const FormatException('Journal Entries ကော်လံများ မတွေ့ရှိပါ');
    }

    final existingAccounts = await dbService.getAllAccounts();
    final accByCode = {for (final a in existingAccounts) a.code: a};

    // Group rows by Date + Description (or single transaction)
    int entryCounter = 0;
    final Map<String, List<List<String>>> groupedRows = {};

    for (int r = headerIdx + 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty) continue;
      final date = (dateIdx != -1 && row.length > dateIdx)
          ? row[dateIdx].trim()
          : '';
      final desc = (descIdx != -1 && row.length > descIdx)
          ? row[descIdx].trim()
          : '';
      if (date.isEmpty && desc.isEmpty) continue;

      final key = '${date}_$desc';
      groupedRows.putIfAbsent(key, () => []).add(row);
    }

    for (final entryGroup in groupedRows.values) {
      final firstRow = entryGroup.first;
      final date =
          (dateIdx != -1 &&
              firstRow.length > dateIdx &&
              firstRow[dateIdx].isNotEmpty)
          ? firstRow[dateIdx].trim()
          : DateFormat('yyyy-MM-dd').format(DateTime.now());
      final desc =
          (descIdx != -1 &&
              firstRow.length > descIdx &&
              firstRow[descIdx].isNotEmpty)
          ? firstRow[descIdx].trim()
          : 'Imported Journal Entry';
      final remark = (remarkIdx != -1 && firstRow.length > remarkIdx)
          ? firstRow[remarkIdx].trim()
          : null;

      final entryId =
          'tx_${DateTime.now().microsecondsSinceEpoch}_$entryCounter';
      final lines = <JournalEntryLine>[];
      int lineCounter = 0;

      for (final r in entryGroup) {
        final code = (codeIdx != -1 && r.length > codeIdx)
            ? r[codeIdx].trim()
            : '';
        final debitStr = (debitIdx != -1 && r.length > debitIdx)
            ? r[debitIdx].trim()
            : '0';
        final creditStr = (creditIdx != -1 && r.length > creditIdx)
            ? r[creditIdx].trim()
            : '0';

        final debit = double.tryParse(debitStr.replaceAll(',', '')) ?? 0.0;
        final credit = double.tryParse(creditStr.replaceAll(',', '')) ?? 0.0;
        if (debit == 0.0 && credit == 0.0) continue;

        // Resolve account or create placeholder account if not exists
        var account = accByCode[code];
        if (account == null) {
          final newAccId =
              'acc_${DateTime.now().microsecondsSinceEpoch}_${entryCounter}_$lineCounter';
          final newAccCode = code.isNotEmpty
              ? code
              : 'ACC-${1000 + accByCode.length}';
          account = Account(
            id: newAccId,
            code: newAccCode,
            name: code.isNotEmpty ? 'Account $code' : 'General Account',
            type: 'Asset',
          );
          await dbService.insertAccount(account);
          accByCode[account.code] = account;
        }

        lines.add(
          JournalEntryLine(
            id: 'line_${DateTime.now().microsecondsSinceEpoch}_$lineCounter',
            journalEntryId: entryId,
            accountId: account.id,
            debit: debit,
            credit: credit,
          ),
        );
        lineCounter++;
      }

      if (lines.isNotEmpty) {
        final entry = JournalEntry(
          id: entryId,
          date: date,
          description: desc,
          remark: remark,
          status: 'active',
          lines: lines,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await dbService.insertJournalEntry(entry);
        entryCounter++;
      }
    }

    return CsvImportResult(
      type: CsvImportType.journalEntries,
      importedTransactionsCount: entryCounter,
      summary:
          'ဂျာနယ်စာရင်း $entryCounter စောင် အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ။ ($entryCounter journal entries imported)',
    );
  }
}
