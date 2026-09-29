# Accounting Articles & Guides System (ဆောင်းပါးနှင့် လမ်းညွှန်များ)

## 📌 ခြုံငုံသုံးသပ်ချက် (Executive Overview)
Accounting Myanmar အပလီကေးရှင်းတွင် စာရင်းကိုင်အခြေခံသဘောတရားများ မရင်းနှီးသေးသူများ၊ အစပြုသူများ (Beginners)၊ SME စီးပွားရေးလုပ်ငန်းရှင်များ (Business Owners)၊ စာရင်းကိုင်သစ်များ (Fresh Accountants) နှင့် ဆော့ဖ်ဝဲလ် တီထွင်သူများ (Software Developers) အတွက် ရည်ရွယ်၍ **"Accounting Articles & Guides" (ဗဟုသုတ ဆောင်းပါးများ)** ကဏ္ဍကို စနစ်တကျ တည်ဆောက်ထည့်သွင်းပြီး ဖြစ်ပါသည်။

ကျွမ်းကျင်ပြီးသား စာရင်းကိုင်ပညာရှင်များ (Expert Users) အတွက် နေ့စဉ်စာရင်းသွင်းမှု လုပ်ငန်းစဉ်များကို မနှောင့်ယှက်စေဘဲ၊ လိုအပ်သူများသာ ဝင်ရောက်ဖတ်ရှုလေ့လာနိုင်သည့် (Non-intrusive & Optional) ချဉ်းကပ်မှုဖြင့် ပုံဖော်ထားပါသည်။

---

## 🗂️ ဖိုင်တွဲ တည်ဆောက်ပုံနှင့် နည်းပညာ ဗိသုကာ (Folder & File Architecture)

ဆောင်းပါး အချက်အလက်များနှင့် Markdown ဖိုင်များကို Dart Code ထဲတွင် Hardcode ရေးသားခြင်း မပြုဘဲ Assets အဖြစ် သီးခြားဖွဲ့စည်းထားသဖြင့် နောင်တစ်ချိန်တွင် အခြားနေရာများ၌ ပြန်လည်အသုံးပြုနိုင်ပြီး ဆောင်းပါးအသစ်များကို Code မထိဘဲ အလွယ်တကူ ထပ်မံဖြည့်စွက်နိုင်ပါသည်:

```
accountingmyanmar/
├── assets/
│   └── articles/
│       ├── articles_index.json              # ဆောင်းပါး စာရင်းချုပ်နှင့် Metadata အညွှန်း
│       ├── 01_what_is_accounting.md         # စာရင်းကိုင်ပညာဆိုတာဘာလဲ
│       ├── 02_accounting_equation.md        # စာရင်းကိုင်ညီမျှခြင်း (Assets = Liabilities + Equity)
│       ├── 03_debit_and_credit.md           # Debit နှင့် Credit (DEALER စည်းမျဉ်း)
│       ├── 04_five_major_account_types.md   # အဓိက စာရင်းအမျိုးအစား ၅ မျိုး
│       ├── 05_double_entry_workflow.md      # နှစ်ထပ်ကွမ်း စာရင်းကိုင်စနစ် လုပ်ငန်းစဉ်
│       ├── 06_chart_of_accounts.md          # စာရင်းဇယား ရေးဆွဲသတ်မှတ်ခြင်း (COA)
│       ├── 07_balance_sheet.md              # လက်ကျန်ရှင်းတမ်းကို နားလည်ခြင်း
│       ├── 08_profit_and_loss.md            # အမြတ်အရှုံးစာရင်း ခွဲခြမ်းစိတ်ဖြာခြင်း
│       ├── 09_cash_flow_vs_profit.md        # ငွေသားစီးဆင်းမှု နှင့် အမြတ် ကွာခြားချက်
│       └── 10_accounting_for_developers.md  # Developers များအတွက် စနစ်တည်ဆောက်မှု
│
├── lib/
│   ├── data/
│   │   ├── models/
│   │   │   └── article_model.dart           # Article JSON Model
│   │   └── repositories/articles/
│   │       ├── article_repository_interface.dart
│   │       └── article_repository_impl.dart # Asset Bundle Loading & In-Memory Cache
│   ├── logic/articles/
│   │   ├── articles_state.dart              # Filter, Search, Categorization State
│   │   └── articles_cubit.dart              # Real-time search & Category management
│   └── ui/screens/articles/
│       ├── articles_list_screen.dart        # Search, Category pills, Responsive grid/list
│       ├── article_detail_screen.dart       # Markdown viewer, Font Scaling (A-/A+), Next/Prev Nav
│       └── widgets/
│           └── article_card.dart            # Interactive card with badges, read-time, tags
│
└── test/
    └── articles_test.dart                   # Unit tests (7 passing test cases)
```

---

## 📚 ဆောင်းပါးများ စာရင်းနှင့် အဓိကပါဝင်သော အကြောင်းအရာများ (Article Catalog)

| No | ဆောင်းပါး ခေါင်းစဉ် (Title) | အမျိုးအစား (Category) | ပစ်မှတ် (Target Audience) | ကြာချိန် |
| :-: | :--- | :--- | :--- | :-: |
| **01** | **စာရင်းကိုင်ပညာဆိုတာဘာလဲ**<br>*(What is Accounting?)* | Foundations<br>(အခြေခံ) | Beginners, SMEs, Fresh Accountants | ၅ မိနစ် |
| **02** | **စာရင်းကိုင်ညီမျှခြင်း**<br>*(The Accounting Equation)* | Foundations<br>(အခြေခံ) | Beginners, Developers, Accountants | ၆ မိနစ် |
| **03** | **Debit နှင့် Credit အမှန်တကယ် နားလည်ခြင်း**<br>*(Debit vs Credit - Golden Rules)* | Core Concepts<br>(အဓိက သဘောတရား) | Beginners, Developers, Accountants | ၇ မိနစ် |
| **04** | **အဓိက စာရင်းအမျိုးအစား ၅ မျိုး**<br>*(The 5 Major Account Types)* | Core Concepts<br>(အဓိက သဘောတရား) | Beginners, Accountants, SMEs | ၆ မိနစ် |
| **05** | **နှစ်ထပ်ကွမ်း စာရင်းကိုင်စနစ် လုပ်ငန်းစဉ်**<br>*(Double-Entry Bookkeeping Flow)* | Practical Workflows<br>(လက်တွေ့လုပ်ငန်းစဉ်) | Business Owners, Accountants, Devs | ၇ မိနစ် |
| **06** | **စာရင်းဇယား ရေးဆွဲသတ်မှတ်ခြင်း**<br>*(Chart of Accounts - COA Guide)* | Practical Workflows<br>(လက်တွေ့လုပ်ငန်းစဉ်) | Business Owners, Accountants, Devs | ၆ မိနစ် |
| **07** | **လက်ကျန်ရှင်းတမ်းကို နားလည်ခြင်း**<br>*(Understanding the Balance Sheet)* | Financial Statements<br>(ဘဏ္ဍာရေးရှင်းတမ်း) | Business Owners, Investors, Accountants | ၇ မိနစ် |
| **08** | **အမြတ်အရှုံးစာရင်းကို ခွဲခြမ်းစိတ်ဖြာခြင်း**<br>*(Profit and Loss Statement - P&L)* | Financial Statements<br>(ဘဏ္ဍာရေးရှင်းတမ်း) | Business Owners, SMEs, Beginners | ၆ မိနစ် |
| **09** | **ငွေသားစီးဆင်းမှု နှင့် အမြတ်အစွန်း ကွာခြားချက်**<br>*(Cash Flow vs Profit)* | Business Management<br>(စီးပွားရေးစီမံခန့်ခွဲမှု) | SME Owners, Beginners, Entrepreneurs | ၇ မိနစ် |
| **10** | **Developers များအတွက် စာရင်းကိုင် စနစ်တည်ဆောက်မှု**<br>*(Accounting for Software Developers)* | Software Architecture<br>(နည်းပညာနှင့် စနစ်) | Software Developers, Architects, CTOs | ၈ မိနစ် |

---

## 🎨 အသုံးပြုသူ မျက်နှာပြင်နှင့် အင်္ဂါရပ်များ (UI/UX Features)

1. **စမတ်ကျသော စာဖတ်ကိရိယာ (Markdown Viewer & Typography):**
   * မြန်မာစာ ယူနီကုဒ် ဖောင့်ဖြစ်သော `Pyidaungsu` ဖောင့်ဖြင့် စာသား၊ ခေါင်းစဉ်ကြီး/ငယ်၊ ဇယားများနှင့် စာရင်းမှတ်တမ်းများကို သေသပ်လှပစွာ ဖော်ပြထားပါသည်။
   * **Font Scaling Controls (A- / A+):** စာဖတ်သူ၏ အမြင်အာရုံ အဆင်ပြေစေရန် စာလုံးအရွယ်အစားကို စိတ်ကြိုက် ချိန်ညှိနိုင်သည့် ခလုတ်များ ထည့်သွင်းထားပါသည်။
   * **Previous / Next Navigation:** ဆောင်းပါးတစ်ခု ဖတ်ရှုပြီးပါက နောက်တစ်ပုဒ်သို့ ချောမွေ့စွာ ကူးပြောင်းနိုင်သော အောက်ခြေ လမ်းညွှန်ခလုတ်များ ပါဝင်ပါသည်။

2. **တုံ့ပြန်မှု ကောင်းမွန်သော ဒီဇိုင်း (Mobile & Wide-Screen Responsive):**
   * **Mobile Display:** အလွယ်တကူ လက်တစ်ဖက်တည်း ဖတ်ရှုနိုင်သော ကတ်ပြားပုံစံ (Single Column List)။
   * **Tablet / Desktop Display:** မျက်နှာပြင်အကျယ်ပေါ် မူတည်၍ ၂ ကော်လံ ပြကွက် (Adaptive 2-column Grid) အဖြစ် အလိုအလျောက် ပြောင်းလဲပေးခြင်း။
   * စာဖတ်မျက်နှာပြင်တွင် စာမျက်နှာ အလွန်အကျွံ ပြန့်ကားမသွားစေရန် Max-Width (860px) ဖြင့် ဗဟိုပြု ထိန်းကျောင်းထားပါသည်။

3. **ရှာဖွေခြင်းနှင့် စစ်ထုတ်ခြင်း (Search & Filtering System):**
   * **Real-time Search:** မြန်မာစာ (သို့မဟုတ်) အင်္ဂလိပ်စာလုံးများဖြင့် ဆောင်းပါးခေါင်းစဉ်၊ အနှစ်ချုပ်နှင့် သဘောတရားများကို ချက်ချင်း ရှာဖွေနိုင်ခြင်း။
   * **Category Chips:** အခြေခံ၊ အဓိကသဘောတရား၊ လက်တွေ့လုပ်ငန်းစဉ်၊ ဘဏ္ဍာရေးရှင်းတမ်း၊ စီးပွားရေးစီမံခန့်ခွဲမှု၊ နည်းပညာ စသည့် ကဏ္ဍအလိုက် စစ်ထုတ်ဖတ်ရှုနိုင်ခြင်း။
   * **Audience Filter:** မိမိနှင့် ကိုက်ညီသော ပစ်မှတ် (Beginners, SMEs, Accountants, Developers) အလိုက် သီးခြား ရွေးချယ်နိုင်ခြင်း။

---

## 🧭 အက်ပ်အတွင်း နေရာချထားမှု (Application Entry Points)

အတွေ့အကြုံရှိပြီးသော စာရင်းကိုင်များ၏ ပုံမှန်အလုပ်ကို အနှောင့်အယှက်မဖြစ်စေဘဲ လိုအပ်သူများ အလွယ်တကူ ရှာဖွေနိုင်ရန် အောက်ပါနေရာများတွင် လမ်းကြောင်းဖွင့်လှစ်ပေးထားပါသည်-

1. **Mobile Drawer Navigation:**
   * Drawer မီနူးတွင် `Articles & Guides (ဆောင်းပါးနှင့် လမ်းညွှန်)` ခေါင်းစဉ်ဖြင့် `Learn` တံဆိပ်အသေးလေး ကပ်ကာ ဖော်ပြထားပါသည်။
2. **Dashboard Screen:**
   * AppBar တွင် စာအုပ်ပုံ သင်္ကေတ (`Icons.auto_stories_outlined`) ထည့်သွင်းထားပါသည်။
   * KPI ကတ်များအောက်တွင် အစပြုသူများ တွေ့ရှိလေ့လာနိုင်မည့် အနှောင့်အယှက်မဖြစ်သော Guides Banner ကတ်ပြားတစ်ခု ထည့်သွင်းထားပါသည်။
3. **Settings Screen:**
   * Settings မျက်နှာပြင်တွင် `KNOWLEDGE BASE & GUIDES (ဗဟုသုတနှင့် လမ်းညွှန်များ)` သီးသန့်ကဏ္ဍ ဖွင့်လှစ်ပေးထားပါသည်။
4. **Desktop / Tablet Navigation Rail:**
   * Navigation Rail ၏ အောက်ခြေတွင် Guides ခလုတ် ထည့်သွင်းထားသဖြင့် ကွန်ပျူတာ/တက်ဘလက် အသုံးပြုသူများလည်း တိုက်ရိုက်ဝင်ရောက်နိုင်ပါသည်။

---

## 🧪 စမ်းသပ်စစ်ဆေးခြင်း (Testing & Quality Assurance)

* **Unit Testing (`test/articles_test.dart`):**
  * `ArticleModel.fromJson` deserialization တိကျမှု စစ်ဆေးခြင်း။
  * `ArticlesCubit` ၏ စာရင်းရယူမှု၊ အမျိုးအစား ခွဲထုတ်မှု စစ်ဆေးခြင်း။
  * မြန်မာစာနှင့် အင်္ဂလိပ်စာ နှစ်မျိုးစလုံးဖြင့် Search စစ်ထုတ်နိုင်မှု စစ်ဆေးခြင်း။
  * Category Filter နှင့် Audience Filter စစ်ဆေးခြင်း။
  * Clear Filters ပြန်လည်ရှင်းထုတ်မှု စစ်ဆေးခြင်း။
  * **ရလဒ်: All 7 unit tests passed! (0 errors)**

* **Code Lint Analysis (`flutter analyze`):**
  * သက်ဆိုင်ရာ Model, Repository, Cubit, Screen, Widget ဖိုင်များအားလုံး zero issues ဖြင့် အောင်မြင်စွာ စစ်ဆေးပြီး ဖြစ်ပါသည်။

---

## 🛠️ Layout & Responsive Overflow Fixes
* **Tablet (2-Column) နှင့် Wider Screen (3-Column) Grid Overflow ပြဿနာ ဖြေရှင်းချက်:**
  * ပြဿနာ: ခေါင်းစဉ်ရှည်သော ဆောင်းပါးများတွင် စာကြောင်း ၂ ကြောင်း ပြောင်းလဲသွားခြင်းနှင့် Target Audience တံဆိပ်များ အောက်သို့ ခေါက်ချိုးဆင်းသွားခြင်းကြောင့် `ArticleCard` တွင် 22px အောက်ခြေ overflow ဖြစ်ပေါ်ခဲ့ခြင်း။
  * ဖြေရှင်းချက်:
    1. [`article_card.dart`](file:///d:/Thanwanna/StudioProjects/accountingmyanmar/lib/ui/screens/articles/widgets/article_card.dart) တွင် မြန်မာခေါင်းစဉ်အား `maxLines: 2, overflow: ellipsis`၊ အင်္ဂလိပ်ခေါင်းစဉ်အား `maxLines: 1`၊ အနှစ်ချုပ်စာသားအား `maxLines: 2` သတ်မှတ်ခြင်း။
    2. အောက်ခြေ Target Audience တံဆိပ်များကို `Wrap` အစား `SingleChildScrollView(scrollDirection: Axis.horizontal)` ဖြင့် Single-line စနစ်သို့ ပြောင်းလဲ၍ ညာဘက်ရှိ "ဖတ်ရှုရန်" ခလုတ်အား အမြဲတန်း အညီအမျှ ပေါ်လွင်စေခြင်း။
    3. [`articles_list_screen.dart`](file:///d:/Thanwanna/StudioProjects/accountingmyanmar/lib/ui/screens/articles/articles_list_screen.dart) ရှိ `SliverGridDelegateWithMaxCrossAxisExtent` တွင် `mainAxisExtent` ကို 230px မှ 255px သို့ တိုးမြှင့်ကာ ကတ်များကြား အကွာအဝေးကို 12px သို့ ညှိယူပေးခဲ့သဖြင့် 2 ကော်လံ နှင့် 3 ကော်လံ မျက်နှာပြင်အားလုံးတွင် overflow ကင်းစင်စွာ ပြသနိုင်ပြီ ဖြစ်ပါသည်။

* **Mobile Filter Bar Compaction & Responsive Padding Standardization:**
  * **ပြဿနာ:** Mobile Screen တွင် Banner၊ Search Box၊ Category Chips နှင့် Target Audience တံဆိပ်များ အဆင့်ဆင့် ဒေါင်လိုက် ထပ်နေသဖြင့် 320px ကျော် နေရာယူကာ ဆောင်းပါးကတ်ပြားများကို အောက်သို့ တွန်းချထားခဲ့ရခြင်း၊ အချို့နေရာများတွင် Hardcoded Padding (16px) သုံးထားခြင်း။
  * **ဖြေရှင်းချက်:**
    1. **Unified Filter Toolbar:** Category Chips နှင့် Target Audience Filter တို့အား သီးခြားအလျားလိုက်အတန်း ၂ တန်းအဖြစ် မခွဲထားတော့ဘဲ၊ တန်းတူ Single-row Horizontal Scroll Bar အဖြစ် ပေါင်းစည်းလိုက်ပါသည်။
    2. **Audience Popup Selector:** အစပိုင်းတွင် `PopupMenuButton` သုံး၍ `[ 👥 ပစ်မှတ် (Audience) ▾ ]` အဖြစ် စမတ်ကျစွာ ထည့်သွင်းထားပြီး၊ ပစ်မှတ် ရွေးချယ်ထားပါက Active ဖြစ်ကာ `✕` ဖြင့် အလွယ်တကူ ပြန်ဖျက်နိုင်ပါသည်။ ၎င်းနောက်တွင် ပါးလွှာသော Vertical Divider ဖြင့် Category Filter Chips များကို ကပ်လျက် ပြသပေးထားပါသည်။
    3. **Compact Mobile Banner:** Mobile မျက်နှာပြင်တွင် Knowledge Hub Banner အား 1-line icon + title + short subtitle ဖြင့် နေရာချုံ့ပေးခဲ့ရာ ဒေါင်လိုက်နေရာယူမှုကို 320px+ မှ ~145px သို့ 55% ကျော် လျှော့ချပေးနိုင်ခဲ့ပါသည်။
    4. **Standard Responsive Padding:** App တစ်ခုလုံး၏ UI/UX စံနှုန်းနှင့်အညီ `EdgeInsets.symmetric(horizontal: MediaQuery.sizeOf(context).width * 0.05, ...)` ကို `articles_list_screen.dart` နှင့် `article_detail_screen.dart` ရှိ အစိတ်အပိုင်းအားလုံးတွင် တပြေးညီ အစားထိုး အသုံးပြုထားပါသည်။

* **Markdown Package Migration (`flutter_markdown_plus`) & Content Rendering Polish:**
  * **Package Migration:** Discontinued ဖြစ်သွားသော Google ၏ `flutter_markdown` အား Foresight Mobile မှ တက်ကြွစွာ ထိန်းသိမ်းထားသော တရားဝင် ဆက်ခံသူ `flutter_markdown_plus: ^1.0.12` သို့ အောင်မြင်စွာ ပြောင်းလဲရွှေ့ပြောင်းပြီးဖြစ်ပါသည်။
  * **Table Horizontal Scroll Support:** `02_accounting_equation.md` ကဲ့သို့သော ဇယားရှည်များတွင် Mobile မျက်နှာပြင် ကျဉ်းမြောင်းမှုကြောင့် စာလုံးများ ညှပ်ဖိသွားခြင်း မဖြစ်စေရန် `MarkdownStyleSheet` တွင် `tableColumnWidth: const IntrinsicColumnWidth()` နှင့် `tableScrollbarThumbVisibility: true` ကို သတ်မှတ်ပေးခဲ့ရာ Mobile တွင် အလျားလိုက် သဘာဝအတိုင်း ချောမွေ့စွာ Scroll ဆွဲဖတ်ရှုနိုင်ပြီ ဖြစ်ပါသည်။
  * **Clean Markdown Syntax (LaTeX & `<br>` Cleanup):** ဇယားကွက်များအတွင်းရှိ `<br>` HTML tags များနှင့် `$$\text{...}$$` ကဲ့သို့သော unparsed LaTeX သင်္ကေတများအား ဖယ်ရှား၍ လှပသော Native Markdown Callout Quote (`> 💡 **Formula**`) များအဖြစ် အစားထိုးပြင်ဆင်ပေးခဲ့ပါသည်။ ထို့အပြင် `article_detail_screen.dart` တွင် အနာဂတ်အတွက်ပါ Regex Defensive Preprocessor ထည့်သွင်းထားသဖြင့် Syntax အမှားများ မည်သည့်အခါမျှ အသုံးပြုသူထံ မရောက်ရှိနိုင်ပါ။
  * **Responsive Previous / Next Bottom Navigation:** မျက်နှာပြင်ကျဉ်းသော Mobile View တွင် အလျားလိုက် ခလုတ် ၂ ခု ညှပ်သွားခြင်းကို ကာကွယ်ရန် Full-width ဒေါင်လိုက်ခလုတ်များ (`width: double.infinity`) အဖြစ် ပြောင်းလဲပေးထားပြီး၊ Tablet / Wide Screen များတွင် မူလအတိုင်း ဘေးချင်းယှဉ် (Side-by-side Row) အဖြစ် အလိုအလျောက် Adaptive ဖြစ်စေပါသည်။



