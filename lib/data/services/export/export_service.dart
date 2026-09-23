import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/account.dart';
import '../../models/financial_report.dart';
import '../../models/print_config.dart';

class ExportResult {
  final String filePath;
  final String csvContent;
  final String fileName;

  const ExportResult({
    required this.filePath,
    required this.csvContent,
    required this.fileName,
  });
}

class ExportService {
  static final ExportService instance = ExportService._();
  ExportService._();

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  String _convertToCsv(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        final str = cell?.toString() ?? '';
        if (str.contains(',') || str.contains('"') || str.contains('\n') || str.contains('\r')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\r\n');
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
    rows.add(['Date', 'Description', 'Transaction ID', 'Debit (MMK)', 'Credit (MMK)', 'Balance (MMK)']);

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
    rows.add(['', '', '', '', 'ENDING BALANCE', entries.isNotEmpty ? entries.last.balance.toStringAsFixed(2) : '0.00']);
    rows.add([]);
    rows.add([printConfig.footerNote]);

    final csvString = _convertToCsv(rows);
    final fileName = 'general_ledger_${account.code}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
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
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];

    // Header
    rows.add([printConfig.companyName]);
    rows.add(['INCOME STATEMENT (PROFIT & LOSS)']);
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
    rows.add(['2. COST OF GOODS SOLD (COGS)', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final c in report.costOfGoodsSold) {
      rows.add([c.account.name, c.account.code, c.amount.toStringAsFixed(2)]);
    }
    rows.add(['Total COGS', '', report.totalCogs.toStringAsFixed(2)]);
    rows.add(['GROSS PROFIT', '', report.grossProfit.toStringAsFixed(2)]);
    rows.add([]);

    // Operating Expenses Section
    rows.add(['3. OPERATING EXPENSES', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final o in report.operatingExpenses) {
      rows.add([o.account.name, o.account.code, o.amount.toStringAsFixed(2)]);
    }
    rows.add(['Total Operating Expenses', '', report.totalOperatingExpenses.toStringAsFixed(2)]);
    rows.add([]);

    // Net Profit / Loss
    rows.add(['NET PROFIT / LOSS', '', report.netProfit.toStringAsFixed(2)]);
    rows.add([]);
    rows.add([printConfig.footerNote]);

    final csvString = _convertToCsv(rows);
    final fileName = 'income_statement_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
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
  }) async {
    final now = DateTime.now();
    final rows = <List<dynamic>>[];

    // Header
    rows.add([printConfig.companyName]);
    rows.add(['BALANCE SHEET STATEMENT']);
    rows.add(['Date Generated: ${_dateFormat.format(now)}']);
    rows.add(['Balanced Check: ${report.isBalanced ? "BALANCED" : "OUT OF BALANCE"}']);
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
    rows.add(['TOTAL LIABILITIES', '', report.totalLiabilities.toStringAsFixed(2)]);
    rows.add([]);

    // Equities
    rows.add(['EQUITY', 'Code', 'Amount (${printConfig.currencySymbol})']);
    for (final eq in report.equities) {
      rows.add([eq.account.name, eq.account.code, eq.amount.toStringAsFixed(2)]);
    }
    rows.add(['Current Period Net Income', '', report.currentPeriodNetIncome.toStringAsFixed(2)]);
    rows.add(['TOTAL LIABILITIES & EQUITY', '', report.totalLiabilitiesAndEquity.toStringAsFixed(2)]);
    rows.add([]);
    rows.add(['IS BALANCED', '', report.isBalanced ? 'YES' : 'NO']);
    rows.add([]);
    rows.add([printConfig.footerNote]);

    final csvString = _convertToCsv(rows);
    final fileName = 'balance_sheet_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
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
}
