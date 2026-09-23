import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../logic/settings/settings_cubit.dart';
import '../../../../logic/settings/settings_state.dart';

class PrintConfigScreen extends StatefulWidget {
  const PrintConfigScreen({super.key});

  @override
  State<PrintConfigScreen> createState() => _PrintConfigScreenState();
}

class _PrintConfigScreenState extends State<PrintConfigScreen> {
  late TextEditingController _companyCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _sloganCtrl;
  late TextEditingController _headerNoteCtrl;
  late TextEditingController _footerNoteCtrl;
  late String _paperFormat;
  late bool _showSignatures;
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    final config = context.read<SettingsCubit>().state.printConfig;
    _companyCtrl = TextEditingController(text: config.companyName);
    _titleCtrl = TextEditingController(text: config.title);
    _sloganCtrl = TextEditingController(text: config.slogan);
    _headerNoteCtrl = TextEditingController(text: config.headerNote);
    _footerNoteCtrl = TextEditingController(text: config.footerNote);
    _paperFormat = config.paperFormat;
    _showSignatures = config.showSignatures;
    _currencySymbol = config.currencySymbol;
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _titleCtrl.dispose();
    _sloganCtrl.dispose();
    _headerNoteCtrl.dispose();
    _footerNoteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = context.read<SettingsCubit>().state.printConfig.copyWith(
          companyName: _companyCtrl.text.trim(),
          title: _titleCtrl.text.trim(),
          slogan: _sloganCtrl.text.trim(),
          headerNote: _headerNoteCtrl.text.trim(),
          footerNote: _footerNoteCtrl.text.trim(),
          paperFormat: _paperFormat,
          showSignatures: _showSignatures,
          currencySymbol: _currencySymbol,
        );

    context.read<SettingsCubit>().savePrintConfig(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ပုံနှိပ်ပုံစံ ဆက်တင်များ သိမ်းဆည်းပြီးပါပြီ။ (Print settings saved)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Configuration (ပုံနှိပ်ပုံစံ ဆက်တင်)'),
        actions: [
          IconButton(
            tooltip: 'Save Settings',
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('Company Header Name (ပုံနှိပ်ခေါင်းစီး အမည်)', _companyCtrl),
                const SizedBox(height: 16),
                _buildField('Company Slogan (ကြွေးကြော်သံ/ဆောင်ပုဒ်)', _sloganCtrl),
                const SizedBox(height: 16),
                _buildField('Report / Voucher Title (စာရွက်ခေါင်းစဉ်)', _titleCtrl),
                const SizedBox(height: 16),
                _buildField('Header Confidential Note (အပေါ်မှတ်ချက်)', _headerNoteCtrl),
                const SizedBox(height: 16),
                _buildField('Footer Notes (အောက်ခြေ နှုတ်ခွန်းဆက်/မှတ်ချက်)', _footerNoteCtrl, maxLines: 2),
                const SizedBox(height: 20),

                // Paper Format Selector
                const Text('Paper Size & Layout (စက္ကူအရွယ်အစား ရွေးချယ်မှု)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paperFormat,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A4', child: Text('Standard A4 Paper (Full Report Table)')),
                    DropdownMenuItem(value: '80mm', child: Text('80mm Thermal POS Receipt Paper')),
                    DropdownMenuItem(value: '58mm', child: Text('58mm Mobile Thermal Paper')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paperFormat = val);
                  },
                ),

                const SizedBox(height: 20),

                // Signature lines toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Signatures Lines (လက်မှတ်ထိုးကွက်များ ထည့်သွင်းမည်)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Prepared By / Approved By လက်မှတ်ထိုးကွက်များ ထည့်ပေးမည်', style: TextStyle(fontSize: 11)),
                  value: _showSignatures,
                  onChanged: (val) => setState(() => _showSignatures = val),
                ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Print Configuration'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
