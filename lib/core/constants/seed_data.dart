import '../../data/models/account.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/journal_entry_line.dart';
import 'account_types.dart';

class SeedData {
  static List<Account> get initialAccounts => [
    const Account(
      id: 'a1000',
      code: '1000',
      name: 'Cash / Bank (လက်ငင်းငွေ/ဘဏ်)',
      type: AccountTypes.asset,
    ),
    const Account(
      id: 'a1200',
      code: '1200',
      name: 'Accounts Receivable (AR - ရရန်ရှိ)',
      type: AccountTypes.asset,
    ),
    const Account(
      id: 'a1300',
      code: '1300',
      name: 'Inventory (ကုန်ပစ္စည်းလက်ကျန်)',
      type: AccountTypes.asset,
    ),
    const Account(
      id: 'a1400',
      code: '1400',
      name: 'Prepaid Expenses (ကြိုတင်ပေးစရိတ်)',
      type: AccountTypes.asset,
    ),
    const Account(
      id: 'a2000',
      code: '2000',
      name: 'Accounts Payable (AP - ပေးရန်ရှိ)',
      type: AccountTypes.liability,
    ),
    const Account(
      id: 'a3000',
      code: '3000',
      name: 'Owner Equity (ပိုင်ရှင်အရင်းအနှီး)',
      type: AccountTypes.equity,
    ),
    const Account(
      id: 'a4000',
      code: '4000',
      name: 'Gross Sales Revenue (စုစုပေါင်းအရောင်းရငွေ)',
      type: AccountTypes.revenue,
    ),
    const Account(
      id: 'a4100',
      code: '4100',
      name: 'Sales Discounts (အရောင်းလျှော့ဈေး)',
      type: AccountTypes.revenue,
    ),
    const Account(
      id: 'a5000',
      code: '5000',
      name: 'Cost of Goods Sold (COGS - ရောင်းကုန်ကျစရိတ်)',
      type: AccountTypes.expense,
    ),
    const Account(
      id: 'a5100',
      code: '5100',
      name: 'FOC & Loss/Damages (အခမဲ့ပေးနှင့် ပျက်စီးဆုံးရှုံး)',
      type: AccountTypes.expense,
    ),
    const Account(
      id: 'a6001',
      code: '6001',
      name: 'Salaries & Commissions (လစာနှင့် ကော်မရှင်)',
      type: AccountTypes.expense,
    ),
    const Account(
      id: 'a6003',
      code: '6003',
      name: 'Warehouse & Office Rent (ရုံးခန်း/ဂိုဒေါင်ငှားရမ်းခ)',
      type: AccountTypes.expense,
    ),
    const Account(
      id: 'a8000',
      code: '8000',
      name: 'Other Income / FOC Income (အခြားဝင်ငွေ)',
      type: AccountTypes.revenue,
    ),
  ];

  static List<JournalEntry> get initialTransactions => [
    const JournalEntry(
      id: 't0',
      date: '2026-09-01',
      description: 'Initial Investment (အရင်းအနှီးထည့်ဝင်ခြင်း)',
      lines: [
        JournalEntryLine(
          id: 'l0a',
          journalEntryId: 't0',
          accountId: 'a1000',
          debit: 100000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l0b',
          journalEntryId: 't0',
          accountId: 'a3000',
          debit: 0,
          credit: 100000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't1_1',
      date: '2026-09-02',
      description: '၁.၁ ငွေအပြည့်ချေပြီး ဝယ်ယူခြင်း (Fully Paid Purchase)',
      lines: [
        JournalEntryLine(
          id: 'l1a',
          journalEntryId: 't1_1',
          accountId: 'a1300',
          debit: 10000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l1b',
          journalEntryId: 't1_1',
          accountId: 'a1000',
          debit: 0,
          credit: 10000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't1_2',
      date: '2026-09-03',
      description: '၁.၂ အကြွေးဖြင့် ဝယ်ယူခြင်း (Purchase on Debt)',
      lines: [
        JournalEntryLine(
          id: 'l2a',
          journalEntryId: 't1_2',
          accountId: 'a1300',
          debit: 20000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l2b',
          journalEntryId: 't1_2',
          accountId: 'a2000',
          debit: 0,
          credit: 20000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't1_3',
      date: '2026-09-04',
      description: '၁.၃ တစ်စိတ်တစ်ပိုင်းသာ ငွေချေပြီး ဝယ်ယူခြင်း (Partial Payment Purchase)',
      lines: [
        JournalEntryLine(
          id: 'l3a',
          journalEntryId: 't1_3',
          accountId: 'a1300',
          debit: 15000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l3b',
          journalEntryId: 't1_3',
          accountId: 'a1000',
          debit: 0,
          credit: 5000000,
        ),
        JournalEntryLine(
          id: 'l3c',
          journalEntryId: 't1_3',
          accountId: 'a2000',
          debit: 0,
          credit: 10000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't2_1',
      date: '2026-09-05',
      description: '၂.၁ ငွေအပြည့်ရပြီး ရောင်းချခြင်း (Fully Paid Sale)',
      lines: [
        JournalEntryLine(
          id: 'l4a',
          journalEntryId: 't2_1',
          accountId: 'a1000',
          debit: 15000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l4b',
          journalEntryId: 't2_1',
          accountId: 'a4000',
          debit: 0,
          credit: 15000000,
        ),
        JournalEntryLine(
          id: 'l4c',
          journalEntryId: 't2_1',
          accountId: 'a5000',
          debit: 8000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l4d',
          journalEntryId: 't2_1',
          accountId: 'a1300',
          debit: 0,
          credit: 8000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't2_2',
      date: '2026-09-06',
      description: '၂.၂ အကြွေးဖြင့် ရောင်းချခြင်း (Sale on Debt)',
      lines: [
        JournalEntryLine(
          id: 'l5a',
          journalEntryId: 't2_2',
          accountId: 'a1200',
          debit: 20000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l5b',
          journalEntryId: 't2_2',
          accountId: 'a4000',
          debit: 0,
          credit: 20000000,
        ),
        JournalEntryLine(
          id: 'l5c',
          journalEntryId: 't2_2',
          accountId: 'a5000',
          debit: 11000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l5d',
          journalEntryId: 't2_2',
          accountId: 'a1300',
          debit: 0,
          credit: 11000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't2_3',
      date: '2026-09-07',
      description: '၂.၃ တစ်စိတ်တစ်ပိုင်းသာ ငွေရပြီး ရောင်းချခြင်း (Partial Payment Sale)',
      lines: [
        JournalEntryLine(
          id: 'l6a',
          journalEntryId: 't2_3',
          accountId: 'a1000',
          debit: 10000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l6b',
          journalEntryId: 't2_3',
          accountId: 'a1200',
          debit: 15000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l6c',
          journalEntryId: 't2_3',
          accountId: 'a4000',
          debit: 0,
          credit: 25000000,
        ),
        JournalEntryLine(
          id: 'l6d',
          journalEntryId: 't2_3',
          accountId: 'a5000',
          debit: 14000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l6e',
          journalEntryId: 't2_3',
          accountId: 'a1300',
          debit: 0,
          credit: 14000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't3',
      date: '2026-09-08',
      description:
          '၃။ ဝန်ထမ်းများကို နေ့စားလစာ ပေးချေခြင်း (Paying Daily Salaries)',
      lines: [
        JournalEntryLine(
          id: 'l7a',
          journalEntryId: 't3',
          accountId: 'a6001',
          debit: 2000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l7b',
          journalEntryId: 't3',
          accountId: 'a1000',
          debit: 0,
          credit: 2000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't4',
      date: '2026-09-09',
      description: '၄။ အရောင်းတွင် လျှော့ဈေးပေးခြင်း (Sales Discount Given)',
      lines: [
        JournalEntryLine(
          id: 'l8a',
          journalEntryId: 't4',
          accountId: 'a4100',
          debit: 500000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l8b',
          journalEntryId: 't4',
          accountId: 'a1200',
          debit: 0,
          credit: 500000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't5_1',
      date: '2026-09-10',
      description: '၅.၁ ဝယ်ယူသူအား မိမိဘက်မှ FOC ပေးခြင်း (FOC Given on Sale)',
      lines: [
        JournalEntryLine(
          id: 'l9a',
          journalEntryId: 't5_1',
          accountId: 'a5100',
          debit: 300000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l9b',
          journalEntryId: 't5_1',
          accountId: 'a1300',
          debit: 0,
          credit: 300000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't5_2',
      date: '2026-09-11',
      description:
          '၅.၂ Supplier ထံမှ မိမိက FOC ရရှိခြင်း (FOC Received on Purchase)',
      lines: [
        JournalEntryLine(
          id: 'l10a',
          journalEntryId: 't5_2',
          accountId: 'a1300',
          debit: 400000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l10b',
          journalEntryId: 't5_2',
          accountId: 'a8000',
          debit: 0,
          credit: 400000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't6_1',
      date: '2026-09-12',
      description:
          '၆.၁ ဖောက်သည်က အကြွေးလာဆပ်ခြင်း (Collecting Payment from AR)',
      lines: [
        JournalEntryLine(
          id: 'l11a',
          journalEntryId: 't6_1',
          accountId: 'a1000',
          debit: 8000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l11b',
          journalEntryId: 't6_1',
          accountId: 'a1200',
          debit: 0,
          credit: 8000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't6_2',
      date: '2026-09-13',
      description: '၆.၂ Supplier ကို အကြွေးသွားဆပ်ခြင်း (Making Payment to AP)',
      lines: [
        JournalEntryLine(
          id: 'l12a',
          journalEntryId: 't6_2',
          accountId: 'a2000',
          debit: 12000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l12b',
          journalEntryId: 't6_2',
          accountId: 'a1000',
          debit: 0,
          credit: 12000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't6_3',
      date: '2026-09-14',
      description: '၆.၃ ရုံးခန်းငှားရမ်းခ ကြိုပေးခြင်း (Prepaid Rent - ၆ လစာ)',
      lines: [
        JournalEntryLine(
          id: 'l13a',
          journalEntryId: 't6_3',
          accountId: 'a1400',
          debit: 6000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l13b',
          journalEntryId: 't6_3',
          accountId: 'a1000',
          debit: 0,
          credit: 6000000,
        ),
      ],
    ),
    const JournalEntry(
      id: 't6_3b',
      date: '2026-09-30',
      description:
          'ရုံးခန်းငှားရမ်းခ ၁ လစာ စာရင်းပြောင်းခြင်း (Amortize 1 month Rent)',
      lines: [
        JournalEntryLine(
          id: 'l14a',
          journalEntryId: 't6_3b',
          accountId: 'a6003',
          debit: 1000000,
          credit: 0,
        ),
        JournalEntryLine(
          id: 'l14b',
          journalEntryId: 't6_3b',
          accountId: 'a1400',
          debit: 0,
          credit: 1000000,
        ),
      ],
    ),
  ];
}
