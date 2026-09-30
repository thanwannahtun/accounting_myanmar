# Accounting Myanmar - SQLite DATA_EXPORT_IMPORT & Persistence History

**Feature**: SQLite Database Backup / Restore & CSV Import/Export Suite  
**Execution Date**: September 30, 2026  
**Target Screen**: `StorageSettingsScreen` (`lib/ui/screens/settings/screens/storage_settings_screen.dart`), `GeneralLedgerScreen`, `FinancialReportsScreen`, and `ExportDialog`  
**Packages Utilized**:
- `file_picker` (v13.1.0) - Native platform file picker and "Save As" destination selector
- `sqflite` (v2.4.4) & `sqflite_common_ffi` (v2.4.3) - SQLite local relational engine
- `path_provider` (v2.1.6) - Canonical application storage directories across Windows, Android, and Desktop
- `path` (v1.9.1) - Cross-platform path normalization and manipulation

---

## 1. 🎯 Overview & Objectives

This implementation delivers robust database and CSV backup, restore, and persistence features for the **Accounting Myanmar** system:

1. **SQLite Database Backup & Restore in `storage_settings_screen.dart`**:
   - **Export**: Users can backup their main SQLite database (`accounting_myanmar.db`) and save it to any directory on their device or computer (e.g., Google Drive, Downloads, USB, External Storage).
   - **Import**: Users can select an existing `.db` or `.sqlite` backup file, validate its structure, and restore their complete database into the application.
2. **CSV Export & Import Enhancements**:
   - Enhanced `ExportDialog` with a **"Save As..." (`ဖိုင်သိမ်းဆည်းမည် (Save As)`)** option powered by `FilePicker.saveFile` with automatic UTF-8 BOM (`0xEF, 0xBB, 0xBF`) encoding for flawless Microsoft Excel rendering of Burmese Unicode text.
   - Added **"Import CSV" (`ဖိုင်မှ စာရင်းသွင်းမည်`)** file-picking capability directly to the AppBar of both **General Ledger** and **Financial Reports**, as well as the **Storage & Database settings** screen.
3. **Protective Sample Data Warning Dialog**:
   - Replaced direct, silent seeding in `StorageSettingsScreen` with a clear, localized confirmation modal explaining that loading sample data will merge or overwrite existing accounts and records.
4. **App Version Update Persistence Guarantee**:
   - Resolved the issue where app updates caused the application to appear in a fresh, empty state. Consolidated SQLite database storage paths, prevented downgrade deletion, and mirrored initialization flags into SQLite's persistent `app_settings` table.

---

## 2. 🏛️ Architecture & Component Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                          UI LAYER                                      │
│  - StorageSettingsScreen (DB Export/Import, CSV Management, Warning)   │
│  - GeneralLedgerScreen & FinancialReportsScreen (CSV Import Button)    │
│  - ExportDialog (Copy CSV + Save As with FilePicker)                   │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────────────┐
│                         LOGIC / CUBIT LAYER                            │
│  - SettingsCubit: exportDatabaseBackup(), importDatabaseBackup()       │
│                   importCsvFile(), refreshDatabaseStats()              │
│  - Zero data loss on version update in init()                          │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────────────┐
│                       REPOSITORY LAYER                                 │
│  - SettingsRepositoryInterface & SettingsLocalRepository               │
│    (exportDatabaseBytes, importDatabaseFromBytes, getDatabasePath)     │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
┌─────────────────────────────────▼──────────────────────────────────────┐
│                        SERVICES LAYER                                  │
│  - SqliteDatabaseService (WAL checkpointer, byte backup, magic header) │
│  - ExportService (RFC 4180 CSV parser, type detector, BOM encoder)     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. 💾 SQLite Database Export & Import Implementation

### A. Database Export (`exportDatabaseBackup`)
1. Flushes uncommitted Write-Ahead Logging (WAL) pages to disk using `PRAGMA wal_checkpoint(TRUNCATE)`.
2. Reads the database file as raw bytes (`Uint8List`).
3. Formats default timestamped filename: `accounting_myanmar_backup_yyyyMMdd_HHmmss.db`.
4. Opens the system "Save As" file picker via `FilePicker.saveFile(...)` allowing the user to select any destination folder.
5. On Windows and desktop systems, validates that the file has been written to the target location.

### B. Database Import & Integrity Validation (`importDatabaseFromBytes`)
1. **Magic Header Inspection**: Checks the first 16 bytes of the picked file against the SQLite 3 specification header:
   ```dart
   [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00]
   // "SQLite format 3\0"
   ```
   Rejects invalid or truncated files with an informative `FormatException` before touching user data.
2. **Rollback Safeguard**: Copies current database to `accounting_myanmar.db.rollback.bak` before making changes.
3. **Atomic Replacement**:
   - Closes current database connection.
   - Deletes companion `-wal` and `-shm` temporary files to prevent state mismatch.
   - Writes imported bytes into the canonical database location.
   - Re-opens the database connection and runs a verification query (`SELECT 1 FROM accounts LIMIT 1`).
   - Automatically rolls back to the backup if verification fails.
4. **State Synchronization**: Re-reads Chart of Accounts and Journal Entries, refreshing all Bloc/Cubit states (`AccountCubit`, `JournalEntryCubit`, `GeneralLedgerCubit`, `FinancialReportsCubit`, `CashFlowCubit`).

---

## 4. 🛡️ Data Persistence Across App Version Updates

### Why Data Appeared Lost Previously:
1. **Path Variance on Windows**:
   - When the Windows product name in `windows/runner/Runner.rc` differed between builds (`accountingmyanmar` vs `Accounting Myanmar`), `path_provider` pointed to different roaming AppData directories.
2. **First-Time Flag Vulnerability**:
   - `has_prompted_first_time_load` was stored only in `FlutterSecureStorage`. On Android APK updates or keystore changes, secure storage reads can reset to `null`, triggering the initial "Start Fresh / Load Sample" dialog.
3. **Downgrade Wiping Risk**:
   - Sqflite default configuration deletes databases upon schema mismatch or downgrade if `onDowngrade` is omitted.

### Permanent Safeguards Implemented:
- **Legacy Path Auto-Migration**:
  In `SqliteDatabaseService._checkAndMigrateLegacyDatabase(...)`, before opening the database, the app scans alternative support directories (`accountingmyanmar`, `Accounting Myanmar`, root support dir). If an existing database with data is detected, it is automatically migrated forward to the canonical location.
- **SQLite-Backed Settings (`app_settings`)**:
  `first_time_prompted` and `last_app_version` are saved in SQLite itself. If `hasData` is true or `last_app_version` exists, the app never treats the launch as a first-time install.
- **Downgrade Protection**:
  Added explicit `onDowngrade: (db, oldVersion, newVersion) async { ... }` so databases are never wiped by the runtime.

---

## 5. 📊 CSV Export & File Picking Import

### A. "Save As..." in `ExportDialog`
- Added a `Save As...` button in `ExportDialog` (both mobile and desktop layouts).
- Appends UTF-8 Byte Order Mark (`0xEF, 0xBB, 0xBF`) to ensure Microsoft Excel correctly parses Burmese text without encoding corruption.
- Uses `FilePicker.saveFile` to let the user select their destination folder.

### B. Intelligent CSV Parser & Importer (`ExportService`)
- **RFC 4180 Parsing**: Handles quotes, escaped quotes (`""`), commas within cells, and `\r\n` line breaks.
- **Auto-Type Detection (`detectCsvType`)**:
  - Detects **Chart of Accounts** (columns: Code, Name, Type).
  - Detects **Journal Entries** (columns: Date, Description, Code/Account, Debit, Credit, Remark).
- **Auto-Account Creation**: When importing journal entries, if an account code does not exist, an account is automatically registered so entries maintain relational integrity.
- **Unified AppBar Action**: An `IconButton` with `Icons.file_upload_outlined` is placed on `GeneralLedgerScreen` and `FinancialReportsScreen`, as well as full controls on `StorageSettingsScreen`.

---

## 6. ⚠️ Sample Data Load Warning

In `StorageSettingsScreen`:
- Clicking **"Load Sample Data"** displays a warning modal:
  > **သတိပြုရန် (Warning)**  
  > နမူနာဒေတာများ ထည့်သွင်းပါက လက်ရှိဒေတာများနှင့် ပေါင်းစပ်ခြင်း သို့မဟုတ် ထပ်တူကျသော အကောင့်နံပါတ်များအပေါ် အစားထိုးခြင်း (Override / Erase) ဖြစ်ပေါ်နိုင်ပါသည်။  
  > အရေးကြီးသည်: မိမိ၏ လက်ရှိစာရင်းများ မပျောက်ပျက်စေရန် မထည့်သွင်းမီ "Export Database Backup" ဖြင့် ကြိုတင် အရန်သိမ်းဆည်းထားရန် အထူးလိုအပ်ပါသည်။
- Execution only proceeds if the user taps **"နမူနာဒေတာ ထည့်သွင်းမည် (Confirm Load)"**.

---

## 7. 🧪 Verification & Test Results

A dedicated test suite was created in `test/data_export_import_test.dart` and executed alongside all existing project tests.

### Test Coverage Highlights:
1. `exportDatabaseBytes` exports valid SQLite 3 bytes with `"SQLite format 3\0"` header.
2. `importDatabaseFromBytes` rejects invalid/corrupted files (< 100 bytes or invalid header) with `FormatException`.
3. `importDatabaseFromBytes` restores original data accurately after database wipe.
4. `parseCsv` handles quotes, commas, multiline values, and CRLF cleanly.
5. `detectCsvType` accurately distinguishes Accounts from Journal Entries.
6. `importCsvContent` imports and updates Accounts and Journal Entries in SQLite.
7. `exportAccountsToCsv` and `exportJournalEntriesToCsv` generate files with UTF-8 BOM headers.
8. `SettingsCubit` guarantees `isFirstTime == false` on app version updates even when secure storage is uninitialized or reset.

### Execution Output:
```
00:06 +38: All tests passed!
```
- Total tests: **38 passed (100% pass rate)**.
- Static analysis: **0 issues found**.

---

## 8. 🤖 AI Model Selection & AI Assistant Screen Enhancements

**Execution Date**: September 30, 2026  
**Target Screens**:
- `AiSettingsScreen` (`lib/ui/screens/settings/screens/ai_settings_screen.dart`)
- `AiAssistantScreen` (`lib/ui/screens/ai_assistant/ai_assistant_screen.dart`)

### Root Cause of Previous AI Model Issues:
1. In `AiSettingsScreen`, `_selectedModel` was purely a local widget state variable initialized statically. It was never written to `SettingsCubit`, SQLite `app_settings`, or `SecureStorage`.
2. When navigating away and returning, the selection reverted to default.
3. `AiAssistantCubit.submitPrompt` did not forward any selected model to `AiAssistantRepositoryInterface.sendMessage`, causing the repository to permanently fallback to hardcoded default.
4. Model responses in `AiAssistantScreen` used plain `SelectableText`, leaving raw markdown (`###`, `**`, `-`, tables) unformatted and hard to read.

### Enhancements Implemented:
1. **Full-Stack AI Model Persistence**:
   - Added `getSelectedModel()` and `saveSelectedModel(String model)` to `AiAssistantRepositoryInterface` and `AiAssistantRepositoryImpl`.
   - Wired model persistence in both `SettingsCubit` (`selectAiModel`) and `AiAssistantCubit` (`setModel`), persisting both to encrypted storage and `app_settings`.
   - `AiAssistantCubit.submitPrompt` dynamically passes `state.selectedModel` to `sendMessage`.
   - `AiSettingsScreen` dropdown allows selection across recommended tiers (`gemini-3.8-flash` recommended flagship, `gemini-3.7-flash`, `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite`), and supports custom model IDs safely without dropdown crashes.
2. **Rich Markdown Formatting (`flutter_markdown_plus`)**:
   - Upgraded AI responses with `MarkdownBody` with Myanmar Unicode font (`Pyidaungsu`) and Latin font typography.
   - Beautiful bold text, headings (`h1`–`h4`), formatted double-entry accounting tables, blockquotes with primary green borders, and monospace code blocks.
   - Interactive link clicks launch external URLs using `url_launcher`.
3. **Copy & Action Suite**:
   - Added a **"Copy"** button on each AI response bubble with temporary checkmark feedback and floating SnackBar.
   - Added a **"Regenerate"** button on the latest AI message to re-submit with the active model.
   - Added an interactive **"Clear Conversation"** confirmation dialog to prevent accidental chat history loss.
   - Added active model chip in AppBar allowing direct navigation to AI settings.
   - Added quick Burmese accounting prompt suggestion chips (`Double-entry`, `COGS`, `Balance Sheet`, `Prepaid Expense`, etc.).
   - Desktop and keyboard friendly: Enter key sends prompt; Shift+Enter creates a new line.
   - Added scroll-to-bottom Floating Action Button when reviewing previous messages.
4. **Zero-Warning Static Analysis & 38 Passing Tests**:
   - Eliminated deprecated `value` and `withOpacity` calls in favor of `initialValue` and `withValues(alpha: ...)`.
   - 38 automated unit and widget tests passing cleanly.

