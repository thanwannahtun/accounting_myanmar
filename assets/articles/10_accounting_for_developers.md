# Developers များအတွက် စာရင်းကိုင် စနစ်တည်ဆောက်မှု လမ်းညွှန် (Accounting for Software Developers)

> **"Financial software ရေးဆွဲရာတွင် `user.balance = user.balance + amount` ဟု ရေးသားခြင်းသည် အကြီးမားဆုံး အမှားတစ်ခု ဖြစ်သည်။"**

---

## ၁။ Software Developers များ အဘယ်ကြောင့် Double-Entry ကို နားလည်ရမည်နည်း

POS၊ E-commerce၊ Wallet သို့မဟုတ် ERP စနစ်များ ရေးသားရာတွင် ငွေကြေးဆိုင်ရာ feature များကို ထည့်သွင်းရလေ့ရှိသည်။

အစပြု Developer အများစုသည် Database တွင် `users` သို့မဟုတ် `wallets` table ဆောက်ပြီး `balance` column တစ်ခုတည်း ထားရှိကာ အရောင်းအဝယ်ဖြစ်တိုင်း `UPDATE` လုပ်လေ့ရှိကြသည်။

```sql
-- ❌ မသုံးသင့်သော ရိုးရှင်းသည့် နည်းလမ်း (Anti-Pattern)
UPDATE accounts SET balance = balance + 50000 WHERE id = 101;
```

### ဤနည်းလမ်း၏ ဆိုးကျိုးများ-
1. **Audit Trail မရှိခြင်း:** ငွေလက်ကျန် ၅၀,၀၀၀ တက်သွားသော်လည်း အဘယ်ကြောင့် တက်သွားသည်၊ မည်သူက လွှဲလိုက်သည်၊ မည်သည့်အချိန်က ဖြစ်ခဲ့သည်ကို သက်သေခြေရာ မကျန်ရစ်ပါ။
2. **Race Conditions & Concurrency Bugs:** Request နှစ်ခု တစ်ပြိုင်နက် ရောက်လာပါက လက်ကျန်ငွေ မှားယွင်းသွားနိုင်သည်။
3. **ငွေလိမ်လည်မှု မသိရှိနိုင်ခြင်း:** Database အား Admin တစ်ဦးဦးက ဝင်ရောက်ပြင်ဆင်လိုက်ပါက မည်သည့်နေရာမှ စစ်ဆေးမရနိုင်ပါ။

---

## ၂။ စာရင်းကိုင် စနစ် တည်ဆောက်ခြင်း၏ ရွှေစည်းမျဉ်း (၄) ရပ်

### ၁။ Ledger Immutability (စာရင်းဖျက်ခြင်း/ပြင်ခြင်း လုံးဝ မပြုလုပ်ရ)
ငွေကြေးစနစ်တွင် `UPDATE` သို့မဟုတ် `DELETE` query များကို Ledger table ပေါ်တွင် လုံးဝ Run ခွင့်မပြုရပါ။
* အကယ်၍ စာရင်းတစ်ခု မှားယွင်းသွင်းမိပါက ထိုအတန်းကို ဖျက်မပစ်ဘဲ ဆန့်ကျင်ဘက် တန်ဖိုးဖြင့် **ပြန်လည်ချေဖျက်သော စာရင်း (Reversing Entry)** အသစ်တစ်ခုကို ထပ်မံ `INSERT` လုပ်ရပါမည်။

### ၂။ Zero-Sum Verification (Debit စုစုပေါင်း = Credit စုစုပေါင်း)
အရောင်းအဝယ်တစ်ခု (Transaction) တွင် အနည်းဆုံး လိုင်း (၂) လိုင်း ပါဝင်ရမည်ဖြစ်ပြီး အမြဲတမ်း-

> 💡 **Total Debit = Total Credit** &nbsp;&nbsp; *(သို့မဟုတ်)* &nbsp;&nbsp; **∑(Debit - Credit) = 0**

ဖြစ်နေရမည်။ Database Constraint သို့မဟုတ် Application Layer တွင် ဤအချက်ကို မဖြစ်မနေ စစ်ဆေးရပါမည်။

### ၃။ The Floating-Point Catastrophe (Float / Double လုံးဝ မသုံးပါနှင့်)
Programming language အများစုတွင် `0.1 + 0.2 = 0.30000000000000004` ဟု ဖြစ်ပေါ်လေ့ရှိသည်။
* ငွေကြေးတန်ဖိုးအတွက် `float` သို့မဟုတ် `double` ကို သုံးပါက နှစ်ကုန်ချိန်တွင် ပြားဂဏန်းများ လေလွင့်ပျောက်ဆုံးသွားနိုင်သည်။
* **အဖြေ:** Database တွင် `DECIMAL(19, 4)` သုံးပါ သို့မဟုတ် အသေးငယ်ဆုံး ယူနစ်ဖြစ်သော **"ပြား / Cents"** အဖြစ် ပြောင်းလဲကာ `BIGINT / INTEGER` ဖြင့် သိမ်းဆည်းပါ။ (ဥပမာ- ၁၀,၀၀၀ ကျပ်ကို ၁,၀၀၀,၀၀၀ ပြား အဖြစ် သိမ်းခြင်း)။

### ၄။ Idempotency Keys (ငွေလွှဲမှု မထပ်စေရန်)
Network နှောင့်နှေးမှုကြောင့် Client က Request ကို (၂) ကြိမ် ပို့မိသည့်တိုင်အောင် ငွေနှစ်ခါ မဖြတ်သွားစေရန် Transaction တိုင်းတွင် တစ်မူထူးခြားသော **`idempotency_key` (UUID)** ထည့်သွင်းရပါမည်။

---

## ၃။ အကြံပြု Database Schema ဒီဇိုင်း (Clean Architecture)

အောက်ပါ Schema သည် Accounting Myanmar App တွင် အသုံးပြုထားသော SQLite/MySQL စံပြ ဒီဇိုင်းဖြစ်သည်-

```sql
-- ၁။ စာရင်းခေါင်းစဉ်များ ဇယား
CREATE TABLE accounts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    account_code VARCHAR(20) UNIQUE NOT NULL, -- e.g. '1010'
    name_en VARCHAR(100) NOT NULL,
    name_mm VARCHAR(100) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE'
    normal_balance VARCHAR(6) NOT NULL -- 'DEBIT' or 'CREDIT'
);

-- ၂။ နေ့စဉ်စာရင်း ခေါင်းစဉ် (Transaction Header)
CREATE TABLE journal_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entry_number VARCHAR(50) UNIQUE NOT NULL, -- e.g. 'JE-2026-0001'
    entry_date DATE NOT NULL,
    description TEXT,
    reference VARCHAR(100),
    idempotency_key VARCHAR(64) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ၃။ စာရင်းအသေးစိတ် လိုင်းများ (Journal Lines)
CREATE TABLE journal_entry_lines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    journal_entry_id INTEGER NOT NULL REFERENCES journal_entries(id) ON DELETE RESTRICT,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    debit_amount DECIMAL(18, 4) DEFAULT 0.0000,
    credit_amount DECIMAL(18, 4) DEFAULT 0.0000,
    line_description VARCHAR(255)
);
```

---

## ၄။ Developer Implementation Checklist

* [ ] Database Transaction (ACID) အသုံးပြုထားပြီး Entry နှင့် Lines အားလုံး အောင်မြင်မှသာ Commit ပြုလုပ်ခြင်း။
* [ ] Database Trigger သို့မဟုတ် Code level တွင် `sum(debit) == sum(credit)` စစ်ဆေးထားခြင်း။
* [ ] Ledger rows များကို `UPDATE` နှင့် `DELETE` လုပ်ခွင့် မပြုထားခြင်း။
* [ ] Currency field များတွင် Floating-point မသုံးဘဲ Decimal သို့မဟုတ် Integer Pyas သုံးစွဲထားခြင်း။
* [ ] API endpoints များတွင် Idempotency header ကို ထောက်ပံ့ထားခြင်း။
