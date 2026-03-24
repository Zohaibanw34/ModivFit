import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitness_app/core/localization/app_language.dart';
import 'package:fitness_app/layout/main_layout.dart';

class LanguagePreferencesScreen extends StatefulWidget {
  const LanguagePreferencesScreen({super.key});

  @override
  State<LanguagePreferencesScreen> createState() =>
      _LanguagePreferencesScreenState();
}

class _LanguagePreferencesScreenState extends State<LanguagePreferencesScreen> {
  late final List<_LanguageOption> _languages;
  late _LanguageOption _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _languages = [
      const _LanguageOption(name: 'English', isoCode: AppLanguage.englishCode),
      const _LanguageOption(name: 'Arabic', isoCode: AppLanguage.arabicCode),
      const _LanguageOption(name: 'Urdu', isoCode: AppLanguage.urduCode),
    ];
    final currentCode = Get.locale?.languageCode ?? AppLanguage.englishCode;
    _selectedLanguage = _languages.firstWhere(
      (e) => e.isoCode == currentCode,
      orElse: () => _languages.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Language',
      showAppBar: true,
      showBackButton: true,
      currentIndex: 5,
      body: Container(
        width: double.infinity,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 23, top: 85, right: 23),
            child: SizedBox(width: 345, child: _buildLanguageTile(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openLanguageList(context),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedLanguage.isoCode == AppLanguage.englishCode
                        ? 'Select Language'.tr
                        : _selectedLanguage.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguageList(BuildContext context) async {
    final selected = await showModalBottomSheet<_LanguageOption>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final language = _languages[index];
              final isSelected = language == _selectedLanguage;
              return ListTile(
                dense: true,
                leading: Text(
                  _flagForIso(language.isoCode),
                  style: const TextStyle(fontSize: 14),
                ),
                title: Text(
                  language.name,
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.black)
                    : null,
                onTap: () => Navigator.of(context).pop(language),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    await AppLanguage.changeLocale(selected.isoCode);
    if (!mounted) return;
    setState(() => _selectedLanguage = selected);
  }

  String _flagForIso(String isoCode) {
    const flags = {
      'ar': 'SA',
      'bn': 'BD',
      'en': 'US',
      'fr': 'FR',
      'de': 'DE',
      'hi': 'IN',
      'it': 'IT',
      'ja': 'JP',
      'jv': 'ID',
      'ko': 'KR',
      'mr': 'IN',
      'pt': 'PT',
      'ru': 'RU',
      'es': 'ES',
      'sw': 'KE',
      'ta': 'IN',
      'te': 'IN',
      'tr': 'TR',
      'ur': 'PK',
    };

    final countryCode = flags[isoCode] ?? 'US';
    return _countryCodeToFlag(countryCode);
  }

  String _countryCodeToFlag(String countryCode) {
    final upper = countryCode.toUpperCase();
    if (upper.length != 2) return '';
    final first = upper.codeUnitAt(0) + 127397;
    final second = upper.codeUnitAt(1) + 127397;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }
}

class _LanguageOption {
  final String name;
  final String isoCode;

  const _LanguageOption({required this.name, required this.isoCode});
}
