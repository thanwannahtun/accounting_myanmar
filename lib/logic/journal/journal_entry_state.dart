import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/journal_entry.dart';

class JournalEntryState extends Equatable {
  final BlocStatus status;
  final List<JournalEntry> entries;
  final String? errorMessage;
  final String lifecycleFilter; // 'all', 'posted', 'draft'
  final bool isAscending; // false = descending (newest first), true = ascending
  final String? startDate; // 'yyyy-MM-dd'
  final String? endDate; // 'yyyy-MM-dd'
  final String searchQuery;
  final int pageLimit;

  const JournalEntryState({
    this.status = BlocStatus.initial,
    this.entries = const [],
    this.errorMessage,
    this.lifecycleFilter = 'all',
    this.isAscending = false,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.pageLimit = 20,
  });

  List<JournalEntry> get filteredEntries {
    final query = searchQuery.trim().toLowerCase();
    final list = entries.where((e) {
      // 1. Lifecycle filter
      if (lifecycleFilter == 'posted' &&
          !(e.isPosted || e.isReversed || e.isReversal)) {
        return false;
      }
      if (lifecycleFilter == 'draft' && !e.isDraft) {
        return false;
      }

      // 2. Date range filter
      if (startDate != null && e.date.compareTo(startDate!) < 0) {
        return false;
      }
      if (endDate != null && e.date.compareTo(endDate!) > 0) {
        return false;
      }

      // 3. Search query
      if (query.isNotEmpty) {
        final descMatches = e.description.toLowerCase().contains(query);
        final remarkMatches = e.remark?.toLowerCase().contains(query) ?? false;
        final idMatches = e.id.toLowerCase().contains(query);
        if (!descMatches && !remarkMatches && !idMatches) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort entries by date (and createdAt as secondary tiebreaker)
    list.sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      if (dateCmp != 0) {
        return isAscending ? dateCmp : -dateCmp;
      }
      final createdCmp = (a.createdAt ?? 0).compareTo(b.createdAt ?? 0);
      return isAscending ? createdCmp : -createdCmp;
    });

    return list;
  }

  List<JournalEntry> get visibleEntries {
    final filtered = filteredEntries;
    if (pageLimit >= filtered.length) return filtered;
    return filtered.take(pageLimit).toList();
  }

  bool get hasMore => visibleEntries.length < filteredEntries.length;
  int get totalFilteredCount => filteredEntries.length;
  int get postedCount =>
      entries.where((e) => e.isPosted || e.isReversed || e.isReversal).length;
  int get draftCount => entries.where((e) => e.isDraft).length;

  JournalEntryState copyWith({
    BlocStatus? status,
    List<JournalEntry>? entries,
    String? errorMessage,
    String? lifecycleFilter,
    bool? isAscending,
    String? startDate,
    String? endDate,
    bool clearDates = false,
    String? searchQuery,
    int? pageLimit,
  }) {
    return JournalEntryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
      lifecycleFilter: lifecycleFilter ?? this.lifecycleFilter,
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
        entries,
        errorMessage,
        lifecycleFilter,
        isAscending,
        startDate,
        endDate,
        searchQuery,
        pageLimit,
      ];
}
