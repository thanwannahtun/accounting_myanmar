import 'package:intl/intl.dart';
import '../../models/account.dart';
import '../../models/financial_report.dart';
import '../../models/print_config.dart';

class FormattedPrintDocument {
  final String title;
  final String content;
  final String paperFormat;
  final DateTime generatedAt;

  const FormattedPrintDocument({
    required this.title,
    required this.content,
    required this.paperFormat,
    required this.generatedAt,
  });
}

class PrintService {
  static final PrintService instance = PrintService._();
  PrintService._();

  final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  FormattedPrintDocument generateGeneralLedgerPrintDocument({
    required Account account,
    required List<LedgerEntry> entries,
    required PrintConfig config,
  }) {
    final now = DateTime.now();
    final buffer = StringBuffer();
    final width = _getColumnWidthForFormat(config.paperFormat);
    final divider = '=' * width;
    final thinDivider = '-' * width;

    // Header
    buffer.writeln(divider);
    buffer.writeln(_centerText(config.companyName.toUpperCase(), width));
    if (config.slogan.isNotEmpty) {
      buffer.writeln(_centerText(config.slogan, width));
    }
    buffer.writeln(_centerText('GENERAL LEDGER REPORT', width));
    buffer.writeln(divider);
    buffer.writeln('Account: ${account.code} - ${account.name}');
    buffer.writeln('Type   : ${account.type}');
    buffer.writeln('Date   : ${_dateFormat.format(now)}');
    buffer.writeln('Note   : ${config.headerNote}');
    buffer.writeln(thinDivider);

    // Columns
    if (config.paperFormat == '58mm' || config.paperFormat == '80mm') {
      // POS format: compact
      for (final e in entries) {
        buffer.writeln('[${e.date}] ${e.description}');
        final debitStr = e.debit > 0 ? '+${_currencyFormat.format(e.debit)}' : '';
        final creditStr = e.credit > 0 ? '-${_currencyFormat.format(e.credit)}' : '';
        buffer.writeln(' Debit: $debitStr  Credit: $creditStr');
        buffer.writeln(' Running Bal: ${_currencyFormat.format(e.balance)} ${config.currencySymbol}');
        buffer.writeln(thinDivider);
      }
    } else {
      // A4 format: tabular
      buffer.writeln(
        '${'Date'.padRight(12)} | ${'Description'.padRight(30)} | ${'Debit'.padLeft(14)} | ${'Credit'.padLeft(14)} | ${'Balance'.padLeft(16)}',
      );
      buffer.writeln(thinDivider);
      for (final e in entries) {
        final dStr = e.debit > 0 ? _currencyFormat.format(e.debit) : '-';
        final cStr = e.credit > 0 ? _currencyFormat.format(e.credit) : '-';
        final bStr = _currencyFormat.format(e.balance);
        final desc = e.description.length > 30 ? '${e.description.substring(0, 27)}...' : e.description.padRight(30);
        buffer.writeln(
          '${e.date.padRight(12)} | $desc | ${dStr.padLeft(14)} | ${cStr.padLeft(14)} | ${bStr.padLeft(16)}',
        );
      }
    }

    final endingBalance = entries.isNotEmpty ? entries.last.balance : 0.0;
    buffer.writeln(divider);
    buffer.writeln(
      'ENDING BALANCE: ${_currencyFormat.format(endingBalance)} ${config.currencySymbol}',
    );
    buffer.writeln(divider);

    if (config.showSignatures) {
      buffer.writeln();
      buffer.writeln(_generateSignatureBlock(width));
    }

    buffer.writeln();
    buffer.writeln(_centerText(config.footerNote, width));
    buffer.writeln(divider);

    return FormattedPrintDocument(
      title: 'General Ledger - ${account.code}',
      content: buffer.toString(),
      paperFormat: config.paperFormat,
      generatedAt: now,
    );
  }

  FormattedPrintDocument generateIncomeStatementPrintDocument({
    required IncomeStatementReport report,
    required PrintConfig config,
  }) {
    final now = DateTime.now();
    final buffer = StringBuffer();
    final width = _getColumnWidthForFormat(config.paperFormat);
    final divider = '=' * width;
    final thinDivider = '-' * width;

    buffer.writeln(divider);
    buffer.writeln(_centerText(config.companyName.toUpperCase(), width));
    buffer.writeln(_centerText('INCOME STATEMENT (PROFIT & LOSS)', width));
    buffer.writeln(_centerText('As of ${_dateFormat.format(now)}', width));
    buffer.writeln(divider);

    // Revenue
    buffer.writeln('1. REVENUE:');
    for (final r in report.revenues) {
      buffer.writeln(
        '   ${r.account.code} - ${r.account.name.padRight(30)}: ${_currencyFormat.format(r.amount).padLeft(15)}',
      );
    }
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   TOTAL NET REVENUE: ${_currencyFormat.format(report.totalRevenue).padLeft(26)} ${config.currencySymbol}',
    );
    buffer.writeln();

    // COGS
    buffer.writeln('2. COST OF GOODS SOLD (COGS):');
    for (final c in report.costOfGoodsSold) {
      buffer.writeln(
        '   ${c.account.code} - ${c.account.name.padRight(30)}: (${_currencyFormat.format(c.amount).padLeft(13)})',
      );
    }
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   TOTAL COGS       : (${_currencyFormat.format(report.totalCogs).padLeft(24)}) ${config.currencySymbol}',
    );
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   GROSS PROFIT     : ${_currencyFormat.format(report.grossProfit).padLeft(26)} ${config.currencySymbol}',
    );
    buffer.writeln();

    // Operating Expenses
    buffer.writeln('3. OPERATING EXPENSES:');
    for (final o in report.operatingExpenses) {
      buffer.writeln(
        '   ${o.account.code} - ${o.account.name.padRight(30)}: (${_currencyFormat.format(o.amount).padLeft(13)})',
      );
    }
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   TOTAL OP. EXPENSES: (${_currencyFormat.format(report.totalOperatingExpenses).padLeft(22)}) ${config.currencySymbol}',
    );
    buffer.writeln(divider);

    // Net Profit
    final netLabel = report.netProfit >= 0 ? 'NET PROFIT' : 'NET LOSS';
    buffer.writeln(
      '   $netLabel: ${_currencyFormat.format(report.netProfit).padLeft(28)} ${config.currencySymbol}',
    );
    buffer.writeln(divider);

    if (config.showSignatures) {
      buffer.writeln();
      buffer.writeln(_generateSignatureBlock(width));
    }

    buffer.writeln();
    buffer.writeln(_centerText(config.footerNote, width));
    buffer.writeln(divider);

    return FormattedPrintDocument(
      title: 'Income Statement (P&L)',
      content: buffer.toString(),
      paperFormat: config.paperFormat,
      generatedAt: now,
    );
  }

  FormattedPrintDocument generateBalanceSheetPrintDocument({
    required BalanceSheetReport report,
    required PrintConfig config,
  }) {
    final now = DateTime.now();
    final buffer = StringBuffer();
    final width = _getColumnWidthForFormat(config.paperFormat);
    final divider = '=' * width;
    final thinDivider = '-' * width;

    buffer.writeln(divider);
    buffer.writeln(_centerText(config.companyName.toUpperCase(), width));
    buffer.writeln(_centerText('BALANCE SHEET STATEMENT', width));
    buffer.writeln(_centerText('As of ${_dateFormat.format(now)}', width));
    buffer.writeln(divider);

    // Assets
    buffer.writeln('ASSETS:');
    for (final a in report.assets) {
      buffer.writeln(
        '   ${a.account.code} - ${a.account.name.padRight(30)}: ${_currencyFormat.format(a.amount).padLeft(15)}',
      );
    }
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   TOTAL ASSETS: ${_currencyFormat.format(report.totalAssets).padLeft(31)} ${config.currencySymbol}',
    );
    buffer.writeln();

    // Liabilities
    buffer.writeln('LIABILITIES:');
    for (final l in report.liabilities) {
      buffer.writeln(
        '   ${l.account.code} - ${l.account.name.padRight(30)}: ${_currencyFormat.format(l.amount).padLeft(15)}',
      );
    }
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   TOTAL LIABILITIES: ${_currencyFormat.format(report.totalLiabilities).padLeft(26)} ${config.currencySymbol}',
    );
    buffer.writeln();

    // Equities
    buffer.writeln('EQUITY:');
    for (final eq in report.equities) {
      buffer.writeln(
        '   ${eq.account.code} - ${eq.account.name.padRight(30)}: ${_currencyFormat.format(eq.amount).padLeft(15)}',
      );
    }
    buffer.writeln(
      '   Current Period Net Income: ${_currencyFormat.format(report.currentPeriodNetIncome).padLeft(18)}',
    );
    buffer.writeln(thinDivider);
    buffer.writeln(
      '   TOTAL LIABILITIES & EQUITY: ${_currencyFormat.format(report.totalLiabilitiesAndEquity).padLeft(18)} ${config.currencySymbol}',
    );
    buffer.writeln(divider);

    final statusText = report.isBalanced ? 'BALANCE STATUS: [ BALANCED OK ]' : 'BALANCE STATUS: [ OUT OF BALANCE! ]';
    buffer.writeln(_centerText(statusText, width));
    buffer.writeln(divider);

    if (config.showSignatures) {
      buffer.writeln();
      buffer.writeln(_generateSignatureBlock(width));
    }

    buffer.writeln();
    buffer.writeln(_centerText(config.footerNote, width));
    buffer.writeln(divider);

    return FormattedPrintDocument(
      title: 'Balance Sheet Statement',
      content: buffer.toString(),
      paperFormat: config.paperFormat,
      generatedAt: now,
    );
  }

  int _getColumnWidthForFormat(String format) {
    switch (format) {
      case '58mm':
        return 38;
      case '80mm':
        return 48;
      case 'A4':
      default:
        return 80;
    }
  }

  String _centerText(String text, int width) {
    if (text.length >= width) return text;
    final leftPadding = (width - text.length) ~/ 2;
    return ' ' * leftPadding + text;
  }

  String _generateSignatureBlock(int width) {
    if (width < 60) {
      return 'Prepared By: __________________\nApproved By: __________________';
    }
    return 'Prepared By: ______________________          Approved By: ______________________';
  }
}
