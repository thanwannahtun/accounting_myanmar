import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/account.dart';
import '../../data/models/journal_entry.dart';
import 'cash_flow_state.dart';

class CashFlowCubit extends Cubit<CashFlowState> {
  CashFlowCubit() : super(const CashFlowState());

  void updateData({
    required List<Account> accounts,
    required List<JournalEntry> transactions,
  }) {
    emit(state.copyWith(
      status: BlocStatus.success,
      accounts: accounts,
      allEntries: transactions,
    ));
  }

  void setFlowTypeFilter(String filter) {
    emit(state.copyWith(flowTypeFilter: filter, pageLimit: 20));
  }

  void setSortOrder(bool isAscending) {
    emit(state.copyWith(isAscending: isAscending, pageLimit: 20));
  }

  void setDateRange(String? start, String? end) {
    emit(state.copyWith(
      startDate: start,
      endDate: end,
      pageLimit: 20,
    ));
  }

  void clearDateRange() {
    emit(state.copyWith(
      clearDates: true,
      pageLimit: 20,
    ));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(
      searchQuery: query,
      pageLimit: 20,
    ));
  }

  void loadMore() {
    if (!state.hasMore) return;
    emit(state.copyWith(pageLimit: state.pageLimit + 20));
  }
}
