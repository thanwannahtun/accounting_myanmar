import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/route_util/route_names.dart';
import '../../../../core/theme/app_colors.dart';

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AboutAppDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? 40 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header with Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accounting Myanmar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ဗားရှင်း v1.0.0 • Modern ERP System',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'ပိတ်မည်',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content Body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vision & Tagline Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withValues(alpha: 0.14),
                            AppColors.primaryGreen.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryGreen.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: AppColors.primaryGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'စာရင်းကိုင်ပညာရပ်နှင့် လက်တွေ့လုပ်ငန်းသုံး ပေါင်းကူးစနစ်',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accounting Myanmar သည် မြန်မာနိုင်ငံရှိ စီးပွားရေးလုပ်ငန်းများ၊ စာရင်းကိုင်ပညာရှင်များနှင့် စာရင်းကိုင်ပညာကို အစပြုလေ့လာလိုသူများအတွက် နိုင်ငံတကာ စံချိန်မီ "နှစ်ထပ်ကွမ်း စာရင်းကိုင်စနစ် (Double-Entry Bookkeeping)" ဖြင့် အစအဆုံး တည်ဆောက်ထားသော ခေတ်မီ ဘဏ္ဍာရေး အက်ပလီကေးရှင်း ဖြစ်ပါသည်။',
                            style: TextStyle(
                              fontFamily: 'Pyidaungsu',
                              fontSize: 12.5,
                              height: 1.6,
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Section Title: Who is this app for?
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 18,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ဤအက်ပ်သည် မည်သူတွေအတွက် ရည်ရွယ်ပါသနည်း?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[200]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 1. Beginners & Learners
                    _buildAudienceCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.school_outlined,
                      iconColor: AppColors.assetBlue,
                      title: '၁။ စာရင်းကိုင် အစပြု လေ့လာသူများ (Learners & Beginners)',
                      description: 'စာရင်းကိုင် အတွေ့အကြုံ မရှိသေးသူများအတွက် Debit / Credit၊ စာရင်းကိုင်ညီမျှခြင်း (Accounting Equation)၊ စာရင်းဇယား (COA) နှင့် ဘဏ္ဍာရေးရှင်းတမ်းများ ဖတ်ရှုနည်းတို့ကို မြန်မာလို အခြေခံမှစ၍ လေ့လာနိုင်သော Knowledge Articles လမ်းညွှန်များ ပါရှိပါသည်။',
                    ),

                    const SizedBox(height: 10),

                    // 2. Business Owners & SMEs
                    _buildAudienceCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.storefront_outlined,
                      iconColor: AppColors.primaryGreen,
                      title: '၂။ စီးပွားရေးလုပ်ငန်းရှင်များ (Business Owners & SMEs)',
                      description: 'နေ့စဉ် အရောင်းအဝယ်၊ ငွေသားစီးဆင်းမှု၊ ကုန်ပစ္စည်းလက်ကျန်နှင့် ကြွေးမြီများကို တကယ့်ငွေသား (Real Money & Transactions) ဖြင့် အမှန်တကယ် စာရင်းသွင်းနိုင်ပြီး မိမိလုပ်ငန်း အမှန်တကယ် အမြတ်ကျန်/မကျန်ကို P&L၊ Balance Sheet နှင့် Cash Flow အစီရင်ခံစာများဖြင့် အချိန်နှင့်တပြေးညီ သိရှိနိုင်ပါသည်။',
                    ),

                    const SizedBox(height: 10),

                    // 3. Junior & Senior Accountants
                    _buildAudienceCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.receipt_long_outlined,
                      iconColor: Colors.deepPurple,
                      title: '၃။ စာရင်းကိုင် ပညာရှင်များ (Junior & Expert Accountants)',
                      description: 'စံပြု ၄ လုံးကုဒ် Chart of Accounts (COA)၊ General Journal၊ General Ledger (T-Account)၊ Trial Balance (စမ်းသပ်ရှင်းတမ်း)၊ စာရင်းပိတ်ခြင်းနှင့် Reversal Entry စနစ်များ အပြည့်အစုံ ပါဝင်သဖြင့် ပရော်ဖက်ရှင်နယ် စာရင်းစစ်ဆေး ထိန်းကျောင်းမှုများကို အပြည့်အဝ ဆောင်ရွက်နိုင်ပါသည်။',
                    ),

                    const SizedBox(height: 10),

                    // 4. Software Developers
                    _buildAudienceCard(
                      context: context,
                      isDark: isDark,
                      icon: Icons.code_outlined,
                      iconColor: Colors.teal,
                      title: '၄။ နည်းပညာ တီထွင်သူများ (Software Developers)',
                      description: 'Financial & ERP software များ တည်ဆောက်ရာတွင် မရှိမဖြစ် လိုအပ်သော Double-Entry Architecture၊ Ledger Immutability (စာရင်းမဖျက်ရမူ)၊ Floating-point အမှား ကာကွယ်မှုနှင့် SQLite Clean Architecture စံနှုန်းများကို လက်တွေ့ စူးစမ်းလေ့လာနိုင်ပါသည်။',
                    ),

                    const SizedBox(height: 18),

                    // Section Title: Core Highlights
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'အဓိက စနစ်အားသာချက်များ (Core Features)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Feature Chips Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFeatureBadge(
                          icon: Icons.cloud_off,
                          label: '100% Offline-First (အင်တာနက် မလိုပါ)',
                          color: AppColors.primaryGreen,
                          isDark: isDark,
                        ),
                        _buildFeatureBadge(
                          icon: Icons.balance,
                          label: 'Zero-Sum Accuracy (Debit = Credit တိကျမှု)',
                          color: AppColors.assetBlue,
                          isDark: isDark,
                        ),
                        _buildFeatureBadge(
                          icon: Icons.table_chart_outlined,
                          label: 'Excel / CSV ဒေတာ ထုတ်ယူနိုင်မှု',
                          color: Colors.orange,
                          isDark: isDark,
                        ),
                        _buildFeatureBadge(
                          icon: Icons.security,
                          label: 'သီးသန့် ကိုယ်ပိုင်ဒေတာ လုံခြုံမှု (Data Privacy)',
                          color: Colors.purple,
                          isDark: isDark,
                        ),
                        _buildFeatureBadge(
                          icon: Icons.auto_stories,
                          label: 'ဆောင်းပါး လမ်းညွှန်များ အပြည့်အစုံ',
                          color: Colors.teal,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Developer Attribution Card
                    _buildDeveloperCard(context, isDark),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Modal Footer Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed(RouteNames.articles);
                      },
                      icon: const Icon(Icons.auto_stories, size: 16),
                      label: const Text(
                        'ဆောင်းပါးများ ဖတ်မည်',
                        style: TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'နားလည်ပါပြီ (OK)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconColor.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Pyidaungsu',
                    fontSize: 11.5,
                    height: 1.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static const String _githubUrl = 'https://github.com/thanwannahtun';

  Widget _buildDeveloperCard(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchGitHub(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.8)
                : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Developed by Thanwanna',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'github.com/thanwannahtun',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        decoration: TextDecoration.underline,
                        decorationColor: isDark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Open GitHub Profile',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GitHub',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: AppColors.primaryGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchGitHub(BuildContext context) async {
    final uri = Uri.parse(_githubUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        await _fallbackClipboard(context);
      }
    } catch (_) {
      if (context.mounted) {
        await _fallbackClipboard(context);
      }
    }
  }

  Future<void> _fallbackClipboard(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _githubUrl));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Link copied: $_githubUrl',
            style: TextStyle(fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }
}
