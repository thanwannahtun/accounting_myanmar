# Application Version Updates & Release Lifecycle Guide
*(အက်ပ် ဗားရှင်း အဆင့်မြှင့်တင်ခြင်းနှင့် GitHub Release စီမံခန့်ခွဲမှု လမ်းညွှန်)*

ဤလမ်းညွှန်သည် **Accounting Myanmar** နှင့် အခြားသော Flutter Projects များတွင် Hardcoded version များ မသုံးတော့ဘဲ Package Version ကို Dynamic ဖြစ်စေရန်၊ GitHub Latest Release API နှင့် ချိတ်ဆက်၍ အပတ်စဉ် (Weekly) ဗားရှင်းအသစ် စစ်ဆေးရန်၊ Mini Badge Alert ပြသရန်နှင့် `ota_update` ဖြင့် Background APK Download ပြုလုပ်ကာ တိုက်ရိုက် Install ပြုလုပ်နိုင်သော Decoupled Architecture အကြောင်း ရှင်းလင်းဖော်ပြထားပါသည်။

---

## ၁။ စနစ် ဗိသုကာနှင့် ဒီဇိုင်းစည်းမျဉ်း (Clean & Decoupled Architecture)

Business Logic နှင့် UI ကို သီးခြားစီ ခွဲထုတ်ထားပြီး Single Responsibility Principle (SRP) နှင့် Dependency Inversion ကို လိုက်နာထားသောကြောင့် ဤ Module ကို အခြားမည်သည့် Flutter Project မဆို Copy ကူးယူကာ ချက်ချင်း အသုံးပြုနိုင်ပါသည်။

```
lib/core/update/
├── models/
│   ├── app_version_info.dart       # Dynamic App Version Model (Name, Version, Build Number)
│   ├── update_config.dart          # Project Configuration (Owner, Repo, Interval, Asset Pattern)
│   ├── update_info.dart            # GitHub Release Metadata & APK Asset Data
│   ├── update_check_result.dart    # Check Outcome (HasUpdate, LatestVersion, Error)
│   └── update_progress.dart        # Real-time Download Percentage & Status
├── services/
│   ├── app_update_service_interface.dart # Clean Open Essential Interface
│   ├── version_comparator.dart     # Pure Semantic Versioning Comparison Logic
│   ├── update_storage.dart         # Pluggable Storage (Memory/DB/SharedPrefs)
│   ├── repository_update_storage.dart # Key-Value Persistence Adapter
│   └── github_app_update_service.dart # Production GitHub & OTA Implementation
├── ui/
│   ├── update_badge.dart           # Mini Alert Badge Widget (NEW / UPDATE)
│   └── update_dialog.dart          # Release Notes & Progress Indicator Modal Dialog
└── app_update.dart                 # Clean Barrel Export File
```

---

## ၂။ ပင်မ Essential Methods များ (Core Service API)

`AppUpdateServiceInterface` မှ ပေးထားသော Reusable Methods များ-

| Method အမည် | တာဝန်နှင့် အသုံးဝင်ပုံ |
| :--- | :--- |
| `checkCurrentApkVersion()` | `package_info_plus` ကို သုံးပြီး လက်ရှိ Run နေသော အက်ပ်၏ Version, Build Number ကို Dynamic ဆွဲထုတ်ပေးခြင်း။ |
| `checkForVersionUpdate({bool force})` | GitHub Releases API သို့ မေးမြန်း၍ ဗားရှင်းအသစ် ရှိ/မရှိ စစ်ဆေးပေးခြင်း။ (`force: false` ဖြစ်ပါက ၇ ရက်တစ်ကြိမ်သာ Net သုံးပြီး စစ်ဆေးသည်) |
| `shouldPerformPeriodicCheck()` | နောက်ဆုံး စစ်ဆေးခဲ့သည့် အချိန်မှ သတ်မှတ်ထားသော Interval (ဥပမာ - ၇ ရက်) ပြည့်/မပြည့် စစ်ဆေးပေးခြင်း။ |
| `downloadLatestAPK(apkUrl, ...)` | `ota_update` ဖြင့် APK ကို Background တွင် ဒေါင်းလုဒ်ဆွဲကာ Package Installer ပို့ပေးခြင်း (Percentage Stream ထုတ်ပေးသည်)။ |
| `openReleaseInBrowser(url)` | Windows Desktop သို့မဟုတ် Platform ချို့ယွင်းချက်များအတွက် Browser မှ တိုက်ရိုက်ဒေါင်းလုဒ်ဆွဲနိုင်စေမည့် Fallback Method။ |

---

## ၃။ အခြား Project များသို့ ကူးယူအသုံးပြုနည်း (Reusability Guide)

တန်ဖိုးများကို Hardcode မလုပ်ထားသောကြောင့် အခြားမည်သည့် GitHub Repo မဆို `UpdateConfig` တွင် ပြောင်းရုံဖြင့် အလုပ်လုပ်ပါသည်-

```dart
final updateService = GithubAppUpdateService(
  config: UpdateConfig(
    githubOwner: 'your_username',          // သင့် GitHub Username
    githubRepo: 'your_repository_name',     // သင့် GitHub Repo အမည်
    destinationFilename: 'MyApp-update.apk', // Local သိမ်းမည့် APK အမည်
    checkInterval: const Duration(days: 7), // အပတ်စဉ် စစ်ဆေးမည့် သတ်မှတ်ရက်
  ),
  storage: RepositoryUpdateStorage(
    reader: (key) => myStorage.read(key),
    writer: (key, val) => myStorage.write(key, val),
  ),
);
```

---

## ၄။ GitHub Release ထုတ်ဝေခြင်း အဆင့်ဆင့် (Release Workflow)

### အဆင့် (၁) - `pubspec.yaml` တွင် Version တိုးမြှင့်ခြင်း
ဥပမာ Version 1.0.0+2 မှ 1.0.1+3 သို့ တိုးမြှင့်ပါ-
```yaml
version: 1.0.1+3
```
*(1.0.1 သည် App Version ဖြစ်ပြီး +3 သည် Android Build Number ဖြစ်သည်)*

### အဆင့် (၂) - Release APK တည်ဆောက်ခြင်း (Build Command)
Terminal သို့မဟုတ် PowerShell တွင် အောက်ပါ command ကို Run ပါ-
```bash
flutter build apk --release
```
တည်ဆောက်ပြီးပါက ဖိုင်တည်နေရာ:
`build/app/outputs/flutter-apk/app-release.apk`

အမည်ပြောင်းလဲခြင်း (ဥပမာ- `AccountingMyanmar-v1.0.1.apk` ဟု နာမည်ပေးနိုင်သည်)။

### အဆင့် (၃) - GitHub တွင် Release အသစ်တင်ခြင်း
1. သင့် GitHub Repository ၏ **Releases** ကဏ္ဍသို့ သွားပါ:
   `https://github.com/thanwannahtun/accounting_myanmar/releases`
2. **"Draft a new release"** ကို နှိပ်ပါ။
3. **Choose a tag**: `v1.0.1` ဟု ရိုက်ထည့်ပြီး **Create new tag on publish** ကို ရွေးပါ။
4. **Release title**: `Accounting Myanmar v1.0.1`
5. **Release Notes (Changelog)**: ဗားရှင်းအသစ်တွင် ပြင်ဆင်ထားသည်များကို Markdown ဖြင့် ရေးသားပါ။
6. **Attach binaries by dropping them here**: Build လုပ်ထားသော `AccountingMyanmar-v1.0.1.apk` ဖိုင်ကို Drag & Drop ဆွဲထည့်ပါ။
7. **"Publish release"** ခလုတ်ကို နှိပ်ပါ။

> **မှတ်ချက်:** GitHub Public Repository ဖြစ်ပါက `https://api.github.com/repos/{owner}/{repo}/releases/latest` endpoint မှ Release metadata နှင့် APK Download link ကို Authentication Token မလိုဘဲ အလိုအလျောက် ရယူနိုင်ပါသည်။

---

## ၅။ အက်ပ်အတွင်း အလုပ်လုပ်ပုံ အဆင့်ဆင့် (App Runtime Behavior)

1. **App စတင်ဖွင့်ချိန် (Dynamic Version Loading)**:
   - `package_info_plus` မှတစ်ဆင့် လက်ရှိဗားရှင်းကို ရယူပြီး Settings Screen၊ Drawer နှင့် About Dialog များတွင် ဖော်ပြပေးသည်။
   - နောက်ဆုံးစစ်ဆေးခဲ့သည့်အချိန်သည် ၇ ရက်ကျော်လွန်ပါက Background တွင် တိတ်တဆိတ် GitHub Latest Release ကို လှမ်းစစ်သည်။
2. **ဗားရှင်းအသစ် တွေ့ရှိချိန် (Mini Badge Alert)**:
   - Version အသစ်ထွက်ရှိနေပါက Drawer နှင့် Settings ကဏ္ဍရှိ Version ဘေးတွင် လိမ္မော်ရောင် **`UPDATE`** သို့မဟုတ် **`NEW`** Mini Badge လေး ပေါ်လာမည်ဖြစ်သည်။
3. **အသုံးပြုသူမှ ကိုယ်တိုင် စစ်ဆေးချိန် (Manual Check)**:
   - Footer သို့မဟုတ် Settings ရှိ **"Check for Updates (ဗားရှင်း စစ်ဆေးမည်)"** ကို နှိပ်ပါက:
     - နောက်ဆုံးဗားရှင်း ဖြစ်နေပါက: *"နောက်ဆုံးထွက် ဗားရှင်းကို အသုံးပြုနေပါသည်"* ဟူသော အသိပေးချက် ပေါ်လာမည်။
     - ဗားရှင်းအသစ် ရှိနေပါက: **UpdateDialog** အလိုအလျောက် ပွင့်လာမည်ဖြစ်ပြီး Version အသစ်၊ ဖိုင်အရွယ်အစား (Size) နှင့် Changelog များကို ဖော်ပြပေးမည်။
4. **ဒေါင်းလုဒ်နှင့် အင်စတော (Background OTA Update)**:
   - **"Update Now (အဆင့်မြှင့်မည်)"** ကို နှိပ်ပါက `ota_update` မှ APK ကို Background ဒေါင်းလုဒ်ဆွဲပြီး `0% မှ 100%` တိုးတက်မှုကို Progress Bar ဖြင့် ပြသပေးမည်။
   - ဒေါင်းလုဒ်ပြီးသည်နှင့် Android System Package Installer ကို ချက်ချင်း ခေါ်ယူကာ Install ပြုလုပ်ပေးမည် ဖြစ်ပါသည်။
   - Windows Desktop သို့မဟုတ် အခြား Platform ဖြစ်ပါက Browser ဖြင့် ဒေါင်းလုဒ်ဆွဲနိုင်စေမည့် Safe Fallback အလိုအလျောက် ပါဝင်ပါသည်။

---

## ၆။ Android Setup စစ်ဆေးချက်များ (Configuration Requirements)

`ota_update` အောင်မြင်စွာ အလုပ်လုပ်ရန် အောက်ပါ Setup များကို ထည့်သွင်းဖွဲ့စည်းထားပြီး ဖြစ်ပါသည်-

1. **`android/app/src/main/AndroidManifest.xml`**:
   - Permission: `<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />`
   - Provider:
     ```xml
     <provider
         android:name="sk.fourq.otaupdate.OtaUpdateFileProvider"
         android:authorities="${applicationId}.ota_update_provider"
         android:exported="false"
         android:grantUriPermissions="true">
         <meta-data
             android:name="android.support.FILE_PROVIDER_PATHS"
             android:resource="@xml/filepaths" />
     </provider>
     ```
2. **`android/app/src/main/res/xml/filepaths.xml`**:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <paths xmlns:android="http://schemas.android.com/apk/res/android">
       <files-path name="internal_apk_storage" path="ota_update/" />
   </paths>
   ```

---

## ၇။ နိဂုံး (Summary)

ဤစနစ်သည် Flutter ၏ Clean Architecture စံနှုန်းများနှင့်အညီ ရေးသားထားပြီး မည်သည့် Hardcoded Version တန်ဖိုးမှ မကျန်ရှိတော့သည့်အပြင်၊ GitHub Releases ကို အသုံးပြု၍ အလိုအလျောက် အဆင့်မြှင့်တင်နိုင်သော ပရော်ဖက်ရှင်နယ် Mobile ERP အတွေ့အကြုံကို အပြည့်အဝ ပေးစွမ်းနိုင်ပြီ ဖြစ်ပါသည်။
