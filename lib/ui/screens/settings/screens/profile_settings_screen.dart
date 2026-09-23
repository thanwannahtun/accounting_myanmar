import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../logic/settings/settings_cubit.dart';
import '../../../../logic/settings/settings_state.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _ownerCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _businessTypeCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _fiscalYearCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<SettingsCubit>().state.userProfile;
    _ownerCtrl = TextEditingController(text: profile.ownerName);
    _companyCtrl = TextEditingController(text: profile.companyName);
    _phoneCtrl = TextEditingController(text: profile.phone);
    _emailCtrl = TextEditingController(text: profile.email);
    _businessTypeCtrl = TextEditingController(text: profile.businessType);
    _currencyCtrl = TextEditingController(text: profile.currency);
    _fiscalYearCtrl = TextEditingController(text: profile.fiscalYear);
  }

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _businessTypeCtrl.dispose();
    _currencyCtrl.dispose();
    _fiscalYearCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = context.read<SettingsCubit>().state.userProfile.copyWith(
          ownerName: _ownerCtrl.text.trim(),
          companyName: _companyCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          businessType: _businessTypeCtrl.text.trim(),
          currency: _currencyCtrl.text.trim(),
          fiscalYear: _fiscalYearCtrl.text.trim(),
        );

    context.read<SettingsCubit>().saveUserProfile(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('လုပ်ငန်းပရိုဖိုင် သိမ်းဆည်းပြီးပါပြီ။ (Profile saved)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile (လုပ်ငန်းပရိုဖိုင်)'),
        actions: [
          IconButton(
            tooltip: 'Save Profile',
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
                _buildField('Company / Business Name (ကုမ္ပဏီ/လုပ်ငန်းအမည်)', _companyCtrl),
                const SizedBox(height: 16),
                _buildField('Owner / Manager Name (ပိုင်ရှင်/မန်နေဂျာအမည်)', _ownerCtrl),
                const SizedBox(height: 16),
                _buildField('Phone Number (ဖုန်းနံပါတ်)', _phoneCtrl, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildField('Email Address (အီးမေးလ်)', _emailCtrl, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField('Business Category (လုပ်ငန်းအမျိုးအစား)', _businessTypeCtrl),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildField('Currency Symbol (ငွေကြေး)', _currencyCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField('Fiscal Year (ဘဏ္ဍာရေးနှစ်)', _fiscalYearCtrl)),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Profile Details'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
