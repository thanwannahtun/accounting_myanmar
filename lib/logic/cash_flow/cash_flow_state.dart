import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/account.dart';
import '../../data/models/journal_entry.dart';

class CashFlowActivityItem extends Equatable {
  final JournalEntry entry;
  final String cashAccountId;
  final String cashAccountName;
  final double inflowAmount;
  final double outflowAmount;
  final double netAmount;
  final bool isInflow;

  const CashFlowActivityItem({
    required this.entry,
    required this.cashAccountId,
    required this.cashAccountName,
    required this.inflowAmount,
    required this.outflowAmount,
    required this.netAmount,
    required this.isInflow,
  });

  @override
  List<Object?> get props => [
        entry,
        cashAccountId,
        cashAccountName,
        inflowAmount,
        outflowAmount,
        netAmount,
        isInflow,
      ];
}

class CashFlowState extends Equatable {
  final BlocStatus status;
  final List<JournalEntry> allEntries;
  final List<Account> accounts;
  final String flowTypeFilter; // 'all', 'inflow', 'outflow'
  final bool isAscending; // false = descending (newest first), true = ascending
  final String? startDate; // 'yyyy-MM-dd'
  final String? endDate; // 'yyyy-MM-dd'
  final String searchQuery;
  final int pageLimit;

  const CashFlowState({
    this.status = BlocStatus.initial,
    this.allEntries = const [],
    this.accounts = const [],
    this.flowTypeFilter = 'all',
    this.isAscending = false,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.pageLimit = 20,
  });

  static bool isCashAccount(Account a) {
    if (a.id == 'a1000' || a.code == '1000') return true;
    final nameLower = a.name.toLowerCase();
    return nameLower.contains('cash') ||
        nameLower.contains('bank') ||
        a.name.contains('ငွေသား') ||
        a.name.contains('ဘဏ်');
  }

  List<CashFlowActivityItem> get allActivities {
    final cashAccountMap = {
      for (final a in accounts)
        if (isCashAccount(a)) a.id: a,
    };

    final List<CashFlowActivityItem> items = [];

    for (final tx in allEntries) {
      if (tx.isDraft) continue;

      double inflow = 0.0;
      double outflow = 0.0;
      String cashAccountId = '';
      String cashAccountName = '';

      for (final line in tx.lines) {
        final acc = cashAccountMap[line.accountId];
        final isCash = acc != null ||
            line.accountId == 'a1000' ||
            line.accountId.toLowerCase().contains('cash') ||
            line.accountId.toLowerCase().contains('bank');

        if (isCash) {
          inflow += line.debit;
          outflow += line.credit;
          if (cashAccountId.isEmpty) {
            cashAccountId = line.accountId;
            cashAccountName = acc != null
                ? '${acc.code} - ${acc.name}'
                : (line.accountId == 'a1000'
                    ? '1000 - Cash / Bank'
                    : line.accountId);
          }
        }
      }

      if (inflow == 0.0 && outflow == 0.0) continue;

      final net = inflow - outflow;
      final isInflow = net >= 0;

      items.add(CashFlowActivityItem(
        entry: tx,
        cashAccountId: cashAccountId,
        cashAccountName: cashAccountName,
        inflowAmount: inflow,
        outflowAmount: outflow,
        netAmount: net,
        isInflow: isInflow,
      ));
    }

    return items;
  }

  List<CashFlowActivityItem> get filteredActivities {
    final query = searchQuery.trim().toLowerCase();
    final list = allActivities.where((item) {
      // 1. Flow type filter
      if (flowTypeFilter == 'inflow' && item.netAmount <= 0) {
        return false;
      }
      if (flowTypeFilter == 'outflow' && item.netAmount >= 0) {
        return false;
      }

      // 2. Date range filter
      if (startDate != null && item.entry.date.compareTo(startDate!) < 0) {
        return false;
      }
      if (endDate != null && item.entry.date.compareTo(endDate!) > 0) {
        return false;
      }

      // 3. Search query
      if (query.isNotEmpty) {
        final descMatches =
            item.entry.description.toLowerCase().contains(query);
        final remarkMatches =
            item.entry.remark?.toLowerCase().contains(query) ?? false;
        final idMatches = item.entry.id.toLowerCase().contains(query);
        final accMatches = item.cashAccountName.toLowerCase().contains(query);
        final amountMatches = item.netAmount.abs().toString().contains(query);
        if (!descMatches &&
            !remarkMatches &&
            !idMatches &&
            !accMatches &&
            !amountMatches) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date (and createdAt)
    list.sort((a, b) {
      final dateCmp = a.entry.date.compareTo(b.entry.date);
      if (dateCmp != 0) {
        return isAscending ? dateCmp : -dateCmp;
      }
      final createdCmp =
          (a.entry.createdAt ?? 0).compareTo(b.entry.createdAt ?? 0);
      return isAscending ? createdCmp : -createdCmp;
    });

    return list;
  }

  List<CashFlowActivityItem> get visibleActivities {
    final filtered = filteredActivities;
    if (pageLimit >= filtered.length) return filtered;
    return filtered.take(pageLimit).toList();
  }

  bool get hasMore => visibleActivities.length < filteredActivities.length;
  int get totalFilteredCount => filteredActivities.length;

  double get totalInflow => filteredActivities.fold(
      0.0, (sum, item) => sum + (item.netAmount > 0 ? item.netAmount : 0.0));

  double get totalOutflow => filteredActivities.fold(
      0.0, (sum, item) => sum + (item.netAmount < 0 ? -item.netAmount : 0.0));

  double get netCashFlow => totalInflow - totalOutflow;

  CashFlowState copyWith({
    BlocStatus? status,
    List<JournalEntry>? allEntries,
    List<Account>? accounts,
    String? flowTypeFilter,
    bool? isAscending,
    String? startDate,
    String? endDate,
    bool clearDates = false,
    String? searchQuery,
    int? pageLimit,
  }) {
    return CashFlowState(
      status: status ?? this.status,
      allEntries: allEntries ?? this.allEntries,
      accounts: accounts ?? this.accounts,
      flowTypeFilter: flowTypeFilter ?? this.flowTypeFilter,
      isAscending: isAscending ?? this.isAscending,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
      pageLimit: pageLimit ?? this.pageLimit,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allEntries,
        accounts,
        flowTypeFilter,
        isAscending,
        startDate,
        endDate,
        searchQuery,
        pageLimit,
      ];
}
