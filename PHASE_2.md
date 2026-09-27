# PHASE 2: Responsive Mobile & Tablet Layout, UI/UX Refinement & Standard Accounting Integrity

## Overview
Phase 2 elevates Accounting Myanmar from a basic accounting prototype into an adaptive, cross-platform (Mobile, Tablet, Desktop) application adhering strictly to International Accounting Standards (IFRS / GAAP) for data integrity, audit trails, and modern Material 3 typography.

---

## 📐 Responsive Layout Architecture

Every screen implements a layout-aware dynamic horizontal padding formula ensuring optimal legibility across compact phones, foldable screens, tablets, and wide desktop displays:

```dart
// Dynamic horizontal padding formula across screens:
EdgeInsets.symmetric(
  horizontal: MediaQuery.sizeOf(context).width * 0.05, // Adaptive: 5% padding on wide, scaled on mobile
  vertical: 16, // Or 8 based on screen density & keyboard presence
)
```

---

## 📋 Comprehensive Execution History of Phase 2 Tasks

### Task 1: Global Typography & Design Token System (`AppTheme`)
- **Objective**: Standardize M3 typography scale across all screen densities instead of hardcoding text sizes in widgets.
- **Implementation**:
  - Configured `ThemeData.textTheme` with balanced, human-friendly scales inspired by modern mobile UI standards (M3, iOS, MIUI/HyperOS).
  - Defined explicit scales for `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`, `titleLarge/Medium/Small`, `bodyLarge/Medium/Small`, and `labelLarge/Medium/Small`.
  - Added semantic theme colors in `AppColors`: `primaryGold` (`Color(0xFFD97706)`) for standard reversal workflows, `creditRose`, `debitGreen`, `lightNeutralContainer`, and `darkNeutralContainer`.
- **Files Touched**:
  - `lib/core/theme/app_theme.dart`
  - `lib/core/theme/app_colors.dart`

---

### Task 2: Adaptive Navigation Architecture (Option C Selected)
- **Objective**: Provide mobile-first ergonomics and desktop productivity in unified navigation.
- **Implementation**:
  - **Compact Screens (< 640px)**: Bottom Navigation Bar with Quick Actions for primary tabs (`Dashboard`, `Journal`, `Accounts`, `Ledger`, `Reports`, `Settings`).
  - **Medium / Wide Screens (≥ 640px)**: Persistent Navigation Rail / Sidebar with full labels, collapsed states, and fluid window scaling.
- **Files Touched**:
  - `lib/ui/screens/home/home_screen.dart`

---

### Task 3: Fullscreen & Responsive `AddJournalEntryDialog`
- **Objective**: Prevent keyboard obstruction and provide natural mobile and tablet entry experiences.
- **Implementation**:
  - **Mobile (< 640px)**: Fullscreen layout with persistent, keyboard-aware bottom action bar (`SafeArea` + `viewInsets.bottom` padding). Single-column card layout for entry lines with instant Debit/Credit balancing indicator.
  - **Tablet / Desktop (≥ 640px)**: Centered multi-column dialog with tabular row editors, fast date-picker, and real-time total balances.
  - **Form Validation**: Blocks submission if debits and credits do not balance (`isBalanced == false`) or if descriptions are blank.
- **Files Touched**:
  - `lib/ui/screens/journal/add_journal_entry_dialog.dart`

---

### Task 4: Responsive `JournalEntryDetailDialog`
- **Objective**: View transaction details with full line breakdown, audit references, and balanced verification badge.
- **Implementation**:
  - Shows voucher metadata: Entry ID, Transaction Date, Description, Status Pill (`Active`, `Reversed`, `Reversal`), and Linked Transaction Reference.
  - Dedicated multiline display for entry Remarks (`မှတ်စု / မှတ်ချက်`).
  - Integrated with the **Reverse Entry Mechanism** (`onReverse` callback).
- **Files Touched**:
  - `lib/ui/screens/journal/journal_entry_detail_dialog.dart`

---

### Task 5: Chart of Accounts Editing & Data-Aware Deletion
- **Objective**: Allow users to edit account names/types, while safely blocking deletion of accounts that have existing journal entry references.
- **Implementation**:
  - **Account Editing**: `EditAccountDialog` allowing modification of account name and category, synced via `AccountCubit.updateAccount`.
  - **Data-Aware Deletion Guard**: Before deleting an account, checks whether any posted journal entry line references the account ID or code:
    - If referenced: Displays an educational warning dialog explaining why the account cannot be deleted to protect past financial statements.
    - If unreferenced: Prompts standard confirmation and securely deletes.
- **Files Touched**:
  - `lib/logic/account/account_cubit.dart`
  - `lib/ui/screens/accounts/chart_of_accounts_screen.dart`

---

### Task 6: General Ledger Horizontal Overflow Fix & Data Density
- **Objective**: Prevent RenderFlex overflow errors when inspecting wide accounts or deep credit/debit balances.
- **Implementation**:
  - Implemented bidirectional scrolling (`SingleChildScrollView(scrollDirection: Axis.horizontal)`) with fixed min-width table boundaries.
  - Formatted currency values in fixed-width monospace font (`Courier`) to keep columns perfectly aligned.
- **Files Touched**:
  - `lib/ui/screens/ledger/general_ledger_screen.dart`

---

### Task 7: Minimalist Financial Reports (Trial Balance, P&L, Balance Sheet)
- **Objective**: Elevate financial reports with a clean, executive-ready presentation.
- **Implementation**:
  - Replaced bulky cards with high-density minimalist tables, subtle alternating row fills, and clear Net Profit / Loss badges.
  - Implemented responsive tabular layouts that automatically expand to full width on desktop while scrolling smoothly on compact mobile screens.
- **Files Touched**:
  - `lib/ui/screens/reports/financial_reports_screen.dart`

---

### Task 8: Standard Reverse Entry Mechanism (`reverse_entry_mechanism`)
- **Objective**: Comply with international standards (`workflows-references/journal_entry_standards.md` & `reverse_entry_mechanism.md`) — never hard-delete or directly mutate posted journal entries.
- **Accounting & Data Flow**:
  1. **Audit Trail Preservation**: When a user needs to fix or void an entry, the system generates an exact counterpart **Reversal Entry**.
  2. **Debit / Credit Swap**:
     $$\text{Reversal Debit} = \text{Original Credit}$$
     $$\text{Reversal Credit} = \text{Original Debit}$$
  3. **Automatic Audit Reference**: Counterpart entry is labeled `"Reversal of Entry #<ID> (<Description>)"` with `status = 'reversal'`.
  4. **Status Transition**: Original entry status changes to `'reversed'`.
  5. **Cross-Linking**: Both entries store the counterpart's ID in `linked_transaction_id`.
  6. **General Ledger Neutralization**: The sum of Original + Reversal balances naturally cancels to $0.00$, keeping all books balanced and preserving the audit trail for auditors.
  7. **Visual Feedback in UI**:
     - Reversed entries display an amber `REVERSED / ပြယ်ပြီး` pill with strikethrough text on description.
     - Reversal entries display an indigo `REVERSAL / ပြန်လှန်ချက်` pill.
- **Files Touched**:
  - `lib/data/models/journal_entry.dart`
  - `lib/logic/journal/journal_entry_cubit.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`
  - `lib/ui/screens/journal/journal_entry_detail_dialog.dart`

---

### Task 9: Optional Multiline "Remark" (မှတ်စု) Field
- **Objective**: Allow users to add optional notes, invoice numbers, or voucher memos to journal entries.
- **Implementation**:
  - Added multiline `TextField` in both Mobile and Tablet/Desktop layouts of `AddJournalEntryDialog`.
  - Persisted in SQLite `journal_entries.remark`.
  - Displayed in `JournalEntryDetailDialog` and as a preview card note in `JournalEntriesScreen`.
- **Files Touched**:
  - `lib/data/models/journal_entry.dart`
  - `lib/ui/screens/journal/add_journal_entry_dialog.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`
  - `lib/ui/screens/journal/journal_entry_detail_dialog.dart`

---

### Task 10: Non-Breaking SQLite Database Migration (v1 -> v2)
- **Objective**: Ensure seamless app upgrades without losing existing user databases.
- **Implementation**:
  - Bumped database version to `2` in `SqliteDatabaseService`.
  - Added `onUpgrade` script with safe, non-destructive `ALTER TABLE` statements:
    ```sql
    ALTER TABLE journal_entries ADD COLUMN remark TEXT;
    ALTER TABLE journal_entries ADD COLUMN status TEXT NOT NULL DEFAULT 'active';
    ALTER TABLE journal_entries ADD COLUMN linked_transaction_id TEXT;
    ```
  - Synchronized `onCreate` baseline schema.
  - Comprehensive migration documentation cataloged in `SQLITE_DATABASE_MIGRATION_HISTORY.md`.
- **Files Touched**:
  - `lib/data/services/database/sqlite_database_service.dart`
  - `SQLITE_DATABASE_MIGRATION_HISTORY.md`

---

### Task 11: Draft (မူကြမ်း) vs Posted (အတည်ပြုပြီး) Lifecycle & Elimination of Posted Deletion
- **Objective**: Implement international GAAP/IFRS standards by eliminating destructive deletion on posted records and adding provisional Draft workflows.
- **Implementation**:
  - **Direct Choice on Entry Creation**: `AddJournalEntryDialog` now provides dual submission actions in both Mobile and Tablet/Desktop layouts:
    - **"Save as Draft" (မူကြမ်းသိမ်းမည်)**: Allows saving provisional entries for later review.
    - **"Post Entry" (စာရင်းအတည်ပြုသွင်းမည်)**: Requires debits and credits to be balanced and posts directly to the ledger.
  - **Accounting Isolation**:
    - `GeneralLedgerCubit` & `FinancialReportsCubit` explicitly filter out drafts (`if (t.isDraft) continue;`). Drafts do not impact running balances or financial statements.
  - **Prohibition of Posted Deletion**:
    - **Completely removed** destructive deletion for posted entries from entry cards and detail dialogs.
    - Posted entries can ONLY be voided via **Reverse Entry**.
    - Draft entries can be edited, posted (`postDraftEntry`), or deleted (`_confirmDeleteDraft`).
  - **Lifecycle Segmented Filter**: Top bar in `JournalEntriesScreen` with chips for "အားလုံး (All)", "အတည်ပြုပြီး (Posted)", and "မူကြမ်းများ (Drafts)".
- **Files Touched**:
  - `lib/data/models/journal_entry.dart`
  - `lib/logic/journal/journal_entry_cubit.dart`
  - `lib/logic/ledger/general_ledger_cubit.dart`
  - `lib/logic/reports/financial_reports_cubit.dart`
  - `lib/ui/screens/journal/add_journal_entry_dialog.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`
  - `lib/ui/screens/journal/journal_entry_detail_dialog.dart`

---

### Task 12: Layout-Aware Responsive Dialogs for Export & Print Preview
- **Objective**: Standardize `ExportDialog` and `PrintPreviewDialog` to follow the responsive full-screen mobile vs centered desktop modal pattern established in `AddJournalEntryDialog`.
- **Implementation**:
  - **Mobile (< 640px)**:
    - Renders as `Dialog.fullscreen` with Scaffold, custom AppBar, scrollable content area, and safe-area sticky bottom action bar.
    - Eliminates cramped dialog scaling and keyboard/overflow issues on small screens.
  - **Tablet / Desktop (≥ 640px)**:
    - Bounded modal `Dialog` with constrained maximum widths (`520px` for Export, `680px` for Print Preview).
    - Modern Material 3 cards, rounded corners (`16px`), and copy-to-clipboard integration.
- **Files Touched**:
  - `lib/ui/widgets/export_dialog.dart`
  - `lib/ui/widgets/print_preview_dialog.dart`

---

### Task 13: Mobile Fullscreen Detail Dialog & Card Header Overflow Fix
- **Objective**: Display `JournalEntryDetailDialog` as a full-screen native view on mobile screens (< 640px) while maintaining the desktop modal layout, and resolve RenderFlex "RIGHT OVERFLOW" errors on narrow mobile viewports.
- **Implementation**:
  - **Mobile Fullscreen `JournalEntryDetailDialog`**:
    - Converted mobile rendering to `Dialog.fullscreen` with `Scaffold`, dedicated `AppBar` with close action, scrollable body containing entry metadata cards, multiline description/remark cards, line item breakdowns, and a sticky `bottomNavigationBar` with live totals and contextual actions (`Reverse Entry`, `Post Entry`, `Delete Draft`, `Close`).
    - Tablet and Desktop continues to use centered, constrained modal dialog (`maxWidth: 640`, `maxHeight: 850`).
  - **Resolution of Right Overflow on Entry Cards**:
    - Replaced rigid `Row` containing date and status pill with dynamic `Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, ...)` inside `JournalEntriesScreen`. On narrow devices (320px–380px), status badges seamlessly wrap below the date without any pixel clipping.
    - Set compact visual density (`VisualDensity.compact`), zero-constraint bounding boxes, and 4px padding on right-side action icon buttons, saving over 60px of horizontal space.
- **Files Touched**:
  - `lib/ui/screens/journal/journal_entry_detail_dialog.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`

---

### Task 14: App Shell Back-Button Elimination & Root Navigation Stacking Fix
- **Objective**: Fix the root navigation stack issue where a back button appeared on the AppBar of main root tabs (`Dashboard`, `Journal`, `Accounts`, `Ledger`, `Reports`) after the splash screen completed.
- **Root Cause**: When `initialRoute` was `"/splash"`, Flutter's `defaultGenerateInitialRoutes` automatically generated `"/"` first (which hit the default case pushing `MainShellScreen`), and then pushed `SplashScreen` on top. When `SplashScreen` completed and popped or navigated, `MainShellScreen` was already at the bottom of the stack, leaving `Navigator.canPop(context) == true`.
- **Implementation**:
  - `lib/core/route_util/route_names.dart`: Re-mapped `splashScreen = "/"`.
  - `lib/core/route_util/route_generator.dart`: Handled both `"/"` and `"/splash"` pointing to `SplashScreen`.
  - `lib/main.dart`: Implemented `onGenerateInitialRoutes` to only generate the exact initial route without slash-splitting.
  - `lib/ui/screens/splash/splash_screen.dart`: Used `Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.app, (route) => false)`.
  - Root screen AppBars: Added `automaticallyImplyLeading: false` to `DashboardScreen`, `JournalEntriesScreen`, `ChartOfAccountsScreen`, `GeneralLedgerScreen`, and `FinancialReportsScreen`.
- **Files Touched**:
  - `lib/core/route_util/route_names.dart`
  - `lib/core/route_util/route_generator.dart`
  - `lib/main.dart`
  - `lib/ui/screens/splash/splash_screen.dart`
  - `lib/ui/screens/dashboard/dashboard_screen.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`
  - `lib/ui/screens/accounts/chart_of_accounts_screen.dart`
  - `lib/ui/screens/ledger/general_ledger_screen.dart`
  - `lib/ui/screens/reports/financial_reports_screen.dart`

---

### Task 15: Fix 5.3px Bottom RenderFlex Overflow on Mobile Virtual Keyboard
- **Objective**: Prevent the bottom overflow when virtual keyboard appears while filling out the "New Journal Entry" dialog form.
- **Root Cause**: In `AddJournalEntryDialog`, fixed layout non-scrollable containers inside `Dialog` caused child vertical constraints to squeeze when the software keyboard was displayed (`RenderFlex overflowed by 5.3 pixels on the bottom`).
- **Implementation**:
  - Re-architected `AddJournalEntryDialog` with `Expanded(child: SingleChildScrollView(child: Column(...)))`.
  - Pinned only the top Header and the bottom live totals & action bar (`Save as Draft` and `Post Entry`).
  - Added bottom padding responsive to `MediaQuery.of(context).viewInsets.bottom` ensuring all input fields remain comfortably visible above the keyboard.
- **Files Touched**:
  - `lib/ui/screens/journal/add_journal_entry_dialog.dart`

---

### Task 16: Draft Entry Re-Editing Form & Standard Guard Architecture
- **Objective**: Allow users to re-open and edit draft journal entries in `AddJournalEntryDialog`, while strictly preventing edits to posted records to maintain audit trail integrity.
- **Implementation**:
  - `AddJournalEntryDialog`: Added `initialEntry` parameter to pre-populate entry date, description, remark, and lines into controllers.
  - `JournalEntryCubit.updateJournalEntry`: Verifies `existing.canEdit` (i.e. `isDraft == true`) before performing updates; rejects edits to posted records with a clear security exception.
  - `JournalEntriesScreen`: Added "Edit Draft (မူကြမ်းပြင်ဆင်ရန်)" icon button directly onto draft cards and wired `onEditDraft` in `JournalEntryDetailDialog`.
  - Automatically re-syncs accounts, transactions, `GeneralLedgerCubit`, `FinancialReportsCubit`, and `CashFlowCubit`.
- **Files Touched**:
  - `lib/logic/journal/journal_entry_cubit.dart`
  - `lib/ui/screens/journal/add_journal_entry_dialog.dart`
  - `lib/ui/screens/journal/journal_entry_detail_dialog.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`

---

### Task 17: Unified Bloc-Powered Lazy Pagination, Date-Range & Sorting
- **Objective**: Implement clean, powerful, unified scroll-to-fetch lazy pagination (limit 20 per fetch), date-range filtering, and sort orders across `JournalEntriesScreen` and `CashFlowActivityScreen`.
- **Implementation**:
  - **State Architecture**: `JournalEntryState` and `CashFlowState` encapsulate `pageLimit` (20), `startDate`, `endDate`, `searchQuery`, `isAscending`, and computed getters (`visibleEntries` / `visibleActivities`, `hasMore`, `totalFilteredCount`).
  - **Scroll Listener**: `ScrollController` detects when user scrolls within 200px of bottom and calls `cubit.loadMore()`, incrementing `pageLimit` by 20.
  - **Date Range UX**: Clean ActionChip with `showDateRangePicker` and one-tap clear button (`clearDateRange()`).
  - **Sort Order**: ActionChip toggle between Descending (Newest first) and Ascending (Oldest first).
  - **Pagination Footers**: Displays live spinner when fetching more or an elegant end-of-list message (`✓ အားလုံး (${total}) ခု ဖော်ပြပြီးပါပြီ`).
- **Files Touched**:
  - `lib/logic/journal/journal_entry_state.dart`
  - `lib/logic/journal/journal_entry_cubit.dart`
  - `lib/ui/screens/journal/journal_entries_screen.dart`

---

### Task 18: Dedicated Cash Flow Activity Screen & Dashboard Expansion (Limit 20)
- **Objective**: Expand Dashboard cash flow activities to show the latest 20 items, provide a "View All (အားလုံးကြည့်ရန်)" action navigating to a dedicated screen with pagination, sort orders, KPI metrics, and full transaction details.
- **Implementation**:
  - **New Business Logic**: Created `CashFlowState` and `CashFlowCubit` providing filtering (Inflow, Outflow, All), date range, search, sort order, and pagination.
  - **New Screen (`CashFlowActivityScreen`)**:
    - Top KPI summary banner (Total Inflow, Total Outflow, Net Cash Flow).
    - Flow type filter chips ("အားလုံး", "ငွေဝင် (+)", "ငွေထွက် (-)"), Date Range picker, Sort toggle, and Search bar.
    - Lazy scroll-to-fetch ListView (20 per page).
    - Tapping an item opens `JournalEntryDetailDialog`.
  - **Dashboard Updates**:
    - Increased cash flow display limit from 8 to 20 items.
    - Added "View All (အားလုံးကြည့်ရန်)" action button navigating to `RouteNames.cashFlowActivity`.
    - Made list items clickable to open `JournalEntryDetailDialog`.
- **Files Touched**:
  - `lib/logic/cash_flow/cash_flow_state.dart` [NEW]
  - `lib/logic/cash_flow/cash_flow_cubit.dart` [NEW]
  - `lib/ui/screens/dashboard/cash_flow_activity_screen.dart` [NEW]
  - `lib/core/route_util/route_names.dart`
  - `lib/core/route_util/route_generator.dart`
  - `lib/main.dart`
  - `lib/ui/screens/splash/splash_screen.dart`
  - `lib/ui/screens/dashboard/dashboard_screen.dart`

---

## 🧪 Verification & Test Suite Results

All automated unit tests pass with zero regression across 14 test suites:
- `Seed Data integrity check`: **PASSED**
- `Financial Statements & Balance Sheet equation test`: **PASSED**
- `CSV Export content format test`: **PASSED**
- `SqliteDatabaseService initializes on Windows FFI and performs CRUD`: **PASSED**
- `Account update and data-aware deletion protection`: **PASSED**
- `Journal entry remark and status serialization`: **PASSED**
- `Standard Reversal Mechanism swaps Dr/Cr & links counterpart entries`: **PASSED**
- `Draft vs Posted lifecycle: Drafts do NOT affect General Ledger & Reports`: **PASSED**
- `JournalEntryCubit allows updating draft entries but guards posted entries`: **PASSED**
- `JournalEntryState handles lazy pagination, sort order, and date-range filters`: **PASSED**
- `CashFlowCubit and CashFlowState filter inflow/outflow, sort, and paginate`: **PASSED**
- `App smoke test`: **PASSED**
- Static Analysis (`flutter analyze`): **0 errors** across all modified files.