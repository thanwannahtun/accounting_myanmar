# SQLite Database Migration History

This document tracks all SQLite database schema versions, architectural migration scripts, and integrity safeguards for the Accounting Myanmar application.

---

## 🏛️ Migration Philosophy & Integrity Principles

1. **Zero Data Loss Guarantee**: Upgrades must never wipe, drop, or corrupt existing user financial records.
2. **Standard Non-Breaking Alterations**: Incremental schema changes utilize SQLite's `ALTER TABLE ADD COLUMN` with safe defaults (`DEFAULT 'active'`, nullable columns for optional metadata).
3. **Idempotent Version Dispatch**: The `onUpgrade(Database db, int oldVersion, int newVersion)` handler sequentially processes migrations step-by-step (`oldVersion < 2`, `oldVersion < 3`, etc.) so users upgrading from any previous version reach the latest schema safely.
4. **Fresh Install Synchronization**: The `onCreate` script is updated alongside `onUpgrade` so new app installations start directly on the latest schema with identical table structures.

---

## 📜 Migration Version History

### Version 1 (Baseline Release)
- **Database Version**: `1`
- **Engine**: SQLite / `sqflite` (Mobile) & `sqflite_common_ffi` (Desktop / Windows)
- **Tables Created**:
  1. `accounts`:
     - `id TEXT PRIMARY KEY`
     - `code TEXT UNIQUE NOT NULL`
     - `name TEXT NOT NULL`
     - `type TEXT NOT NULL` (Asset, Liability, Equity, Revenue, Expense)
     - `created_at TEXT NOT NULL`
  2. `journal_entries`:
     - `id TEXT PRIMARY KEY`
     - `date TEXT NOT NULL`
     - `description TEXT NOT NULL`
     - `created_at TEXT NOT NULL`
  3. `journal_entry_lines`:
     - `id TEXT PRIMARY KEY`
     - `journal_entry_id TEXT NOT NULL`
     - `account_id TEXT NOT NULL`
     - `debit REAL NOT NULL`
     - `credit REAL NOT NULL`

---

### Version 2 (Audit Trail, Reverse Entry Mechanism & Remarks)
- **Database Version**: `2`
- **Release Phase**: Phase 2
- **Objective**: 
  1. Support IFRS / GAAP international accounting standard **Reverse Entry Mechanism** (`reverse_entry_mechanism`) to preserve immutable audit trails instead of destructive entry deletion or direct edits.
  2. Add optional multiline **"remark"** (`မှတ်စု`) field to journal entries for invoices, notes, and auxiliary metadata.

#### Schema Changes:
Table `journal_entries` altered with three new columns:
| Column | Type | Constraints / Default | Description |
|---|---|---|---|
| `remark` | `TEXT` | `NULL` | Optional multiline notes, memo, voucher # |
| `status` | `TEXT` | `NOT NULL DEFAULT 'active'` | State of entry (`'active'`, `'reversed'`, `'reversal'`) |
| `linked_transaction_id` | `TEXT` | `NULL` | ID of the paired reversal or reversed counterpart entry |

#### Migration Script (`onUpgrade` in `SqliteDatabaseService`):
```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // 1. Add remark column
    await db.execute('ALTER TABLE journal_entries ADD COLUMN remark TEXT;');
    // 2. Add status column with default 'active'
    await db.execute(
      "ALTER TABLE journal_entries ADD COLUMN status TEXT NOT NULL DEFAULT 'active';",
    );
    // 3. Add linked_transaction_id column
    await db.execute(
      'ALTER TABLE journal_entries ADD COLUMN linked_transaction_id TEXT;',
    );
  }
}
```

#### Updated `onCreate` Baseline:
```sql
CREATE TABLE journal_entries (
  id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  description TEXT NOT NULL,
  remark TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  linked_transaction_id TEXT,
  created_at TEXT NOT NULL
);
```

#### Backward Compatibility & Integrity Assurance:
- Existing user journal entries automatically inherit `status = 'active'`, `remark = NULL`, and `linked_transaction_id = NULL` without manual data backfilling.
- The `JournalEntry.fromMap()` parser safely handles existing records or missing keys, defaulting `status` to `'active'`.
- Counterpart reversal entries invert Debits and Credits, ensuring that the General Ledger and Financial Statements naturally net to zero while keeping the complete audit history visible.
