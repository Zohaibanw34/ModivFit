import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubscriptionTabSwitcher extends StatelessWidget {
  final bool isBasicSelected;
  final VoidCallback onBasicTap;
  final VoidCallback onPremiumTap;

  const SubscriptionTabSwitcher({
    super.key,
    required this.isBasicSelected,
    required this.onBasicTap,
    required this.onPremiumTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 345,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Basic',
            selected: isBasicSelected,
            onTap: onBasicTap,
          ),
          _TabItem(
            label: 'Premium',
            selected: !isBasicSelected,
            onTap: onPremiumTap,
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class SubscriptionFeatureContainer extends StatelessWidget {
  final String title;
  final List<String> included;
  final List<String> excluded;

  const SubscriptionFeatureContainer({
    super.key,
    required this.title,
    required this.included,
    this.excluded = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361,
      height: 504,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.tr,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...included.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Text(
                        '? ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.tr,
                        style: const TextStyle(fontSize: 13, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...excluded.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Text(
                        '? ',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.tr,
                        style: const TextStyle(fontSize: 13, height: 1.25),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SubscriptionPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 301,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Text(label.tr, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class PremiumPlansDialog extends StatelessWidget {
  final Future<bool> Function(String planName)? onPlanSelected;

  const PremiumPlansDialog({super.key, this.onPlanSelected});

  @override
  Widget build(BuildContext context) {
    return _PremiumPlansDialogBody(onPlanSelected: onPlanSelected);
  }
}

class _PremiumPlansDialogBody extends StatefulWidget {
  final Future<bool> Function(String planName)? onPlanSelected;

  const _PremiumPlansDialogBody({required this.onPlanSelected});

  @override
  State<_PremiumPlansDialogBody> createState() =>
      _PremiumPlansDialogBodyState();
}

class _PremiumPlansDialogBodyState extends State<_PremiumPlansDialogBody> {
  String _selectedPlan = 'Monthly';
  bool _busy = false;

  Future<void> _submit() async {
    if (_busy) return;
    if (widget.onPlanSelected == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.onPlanSelected!(_selectedPlan);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 361,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Premium Plan'.tr,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _planTile(
                'Monthly',
                '\$9.99/month',
                'All features, no ads',
                selected: _selectedPlan == 'Monthly',
                onTap: () => setState(() => _selectedPlan = 'Monthly'),
              ),
              const SizedBox(height: 10),
              _planTile(
                'Quarterly',
                '\$24.99 every 3 months',
                'Save 15%',
                selected: _selectedPlan == 'Quarterly',
                onTap: () => setState(() => _selectedPlan = 'Quarterly'),
              ),
              const SizedBox(height: 10),
              _planTile(
                'Yearly',
                '\$89.99/year',
                'Save 25% + 2 bonus months + premium badge',
                selected: _selectedPlan == 'Yearly',
                onTap: () => setState(() => _selectedPlan = 'Yearly'),
              ),
              const SizedBox(height: 14),
              SubscriptionPrimaryButton(
                label: _busy ? 'Please wait...' : 'Subscribe Now',
                onTap: _busy ? () {} : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planTile(
    String label,
    String price,
    String desc, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 301,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF4E97FF) : Colors.transparent,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.tr,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              price.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc.tr,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
