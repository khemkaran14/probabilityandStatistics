import 'package:flutter/material.dart';

import 'package:chance/data/catalogue.dart';
import 'package:chance/services/purchase_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';

/// One-time "unlock everything" purchase.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});

  /// The locked lesson that brought the learner here, if any.
  final String? reason;

  static Route<void> route({String? reason}) => MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PaywallScreen(reason: reason),
      );

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _price;
  bool _available = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final purchases = AppScope.read(context).purchases;
    purchases.isAvailable().then((ok) async {
      final price = ok ? await purchases.price() : null;
      if (!mounted) return;
      setState(() {
        _available = ok && price != null;
        _price = price;
      });
    });
  }

  Future<void> _run(Future<PurchaseOutcome> Function() action) async {
    setState(() => _busy = true);
    final outcome = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final message = switch (outcome) {
      PurchaseOutcome.purchased => 'Unlocked! Thank you for supporting Chance.',
      PurchaseOutcome.restored => 'Purchase restored. Everything is unlocked.',
      PurchaseOutcome.pending => 'Payment pending. Lessons unlock as soon as it clears.',
      PurchaseOutcome.cancelled => 'No purchase found to restore.',
      PurchaseOutcome.failed => 'Something went wrong. Please try again.',
      PurchaseOutcome.unavailable => 'The store isn\'t available on this device.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    if (outcome == PurchaseOutcome.purchased || outcome == PurchaseOutcome.restored) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final lockedChapters = kChapters.where((c) => !c.free).length;
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.violet, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_open_rounded, size: 48, color: Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                state.premium ? 'Everything is unlocked' : 'Unlock all of Chance',
                textAlign: TextAlign.center,
                style: kDisplay,
              ),
              if (widget.reason != null && !state.premium) ...[
                const SizedBox(height: 8),
                Text(
                  '"${widget.reason}" is part of the full course.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 22),
              SoftCard(
                child: Column(
                  children: [
                    _Perk(Icons.auto_stories_rounded, AppColors.pink,
                        '$lockedChapters more chapters, from counting to Bayes'),
                    _Perk(Icons.animation_rounded, AppColors.orange, 'Every new animated lesson as it ships'),
                    const _Perk(Icons.all_inclusive_rounded, AppColors.green, 'One payment. No subscription, no ads'),
                    const _Perk(Icons.favorite_rounded, AppColors.violet, 'Support an indie learning app'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (state.premium)
                BigButton(
                  label: 'Back to learning',
                  color: AppColors.green,
                  onPressed: () => Navigator.of(context).pop(),
                )
              else ...[
                BigButton(
                  label: _busy
                      ? 'Working…'
                      : _available
                          ? 'Unlock everything${_price == null ? '' : ' · $_price'}'
                          : 'Store unavailable',
                  color: AppColors.violet,
                  icon: Icons.lock_open_rounded,
                  onPressed: _busy || !_available ? null : () => _run(state.buyPremium),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => _run(state.restorePurchases),
                  child: const Text('Restore purchase'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.icon, this.color, this.text);
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
