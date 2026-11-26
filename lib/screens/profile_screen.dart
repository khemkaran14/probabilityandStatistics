import 'package:flutter/material.dart';

import 'package:chance/services/account_service.dart';
import 'package:chance/state/app_state.dart';
import 'package:chance/theme/app_theme.dart';
import 'package:chance/widgets/common.dart';
import 'package:chance/widgets/user_avatar.dart';

/// Shown once after sign-in until the profile is complete: name, verified
/// mobile number, photo and consent for offers.
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Text('Complete your profile', style: kDisplay.copyWith(fontSize: 28)),
              const SizedBox(height: 6),
              const Text(
                'Just once. We\'ll verify your mobile number with a code by SMS.',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              const ProfileForm(setup: true),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => AppScope.read(context).signOut(),
                  child: const Text('Use a different Google account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The learner's profile, from Settings: edit it, sign out, delete account.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const ProfileScreen());

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text('This permanently deletes your account, profile, photo and the progress saved in it. '
            'Your purchase is kept by Google Play.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await AppScope.read(context).deleteAccount();
      navigator.popUntil((r) => r.isFirst);
      messenger.showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Your account has been deleted.'),
      ));
    } on AccountException catch (e) {
      messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile'), backgroundColor: AppColors.bg),
      body: SafeArea(
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const ProfileForm(setup: false),
              const SizedBox(height: 24),
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      key: const ValueKey('sign-out'),
                      leading: const Icon(Icons.logout_rounded, color: AppColors.blue),
                      title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800)),
                      onTap: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        AppScope.read(context).signOut();
                      },
                    ),
                    ListTile(
                      key: const ValueKey('delete-account'),
                      leading: const Icon(Icons.person_remove_rounded, color: AppColors.pink),
                      title: const Text('Delete account', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('Permanently removes your account and its data'),
                      onTap: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Photo, name, email, verified mobile and consent, with a save button.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.setup});

  /// First-time setup (button says "Start learning") or editing.
  final bool setup;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name;

  /// The typed mobile number, when SMS verification is off.
  late final TextEditingController _phoneText;
  String? _photoUrl;
  bool _optIn = false;
  bool _saving = false;
  bool _uploading = false;
  bool _changingPhone = false;

  @override
  void initState() {
    super.initState();
    final draft = AppScope.read(context).draftProfile;
    _name = TextEditingController(text: draft.name);
    final saved = draft.phone ?? '';
    _phoneText = TextEditingController(text: saved.startsWith('+91') ? saved.substring(3) : saved);
    _photoUrl = draft.photoUrl;
    _optIn = draft.marketingOptIn;
  }

  @override
  void dispose() {
    _name.dispose();
    _phoneText.dispose();
    super.dispose();
  }

  void _show(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));

  Future<void> _changePhoto() async {
    setState(() => _uploading = true);
    try {
      final url = await AppScope.read(context).pickPhoto();
      if (url != null && mounted) setState(() => _photoUrl = url);
    } on AccountException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final state = AppScope.read(context);
    setState(() => _saving = true);
    try {
      await state.saveProfile(state.draftProfile.copyWith(
        name: _name.text,
        phone: state.accounts.verifiesPhone ? null : _phoneText.text,
        photoUrl: _photoUrl,
        marketingOptIn: _optIn,
      ));
      if (!widget.setup) _show('Profile saved.');
    } on AccountException catch (e) {
      _show(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final verifies = state.accounts.verifiesPhone;
    final phone = state.user?.phone;
    final typedOk = normalizePhone(_phoneText.text) != null;
    final phoneOk = verifies ? phone != null : typedOk;
    final canSave = _name.text.trim().isNotEmpty && phoneOk && !_saving && !_uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              UserAvatar(name: _name.text, photoUrl: _photoUrl, radius: 48),
              const SizedBox(height: 8),
              if (state.accounts.canUploadPhoto)
                TextButton.icon(
                  key: const ValueKey('change-photo'),
                  onPressed: _uploading ? null : _changePhoto,
                  icon: _uploading
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_camera_rounded),
                  label: Text(_photoUrl == null ? 'Add a photo' : 'Change photo'),
                )
              else
                const Text('Photo from your Google account', style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('profile-name'),
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: 60,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Your name', border: OutlineInputBorder(), counterText: ''),
        ),
        const SizedBox(height: 14),
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Email (from Google)', border: OutlineInputBorder()),
          child: Text(state.user?.email ?? '', style: const TextStyle(color: AppColors.muted)),
        ),
        const SizedBox(height: 14),
        if (!verifies)
          TextField(
            key: const ValueKey('phone-number'),
            controller: _phoneText,
            keyboardType: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mobile number',
              prefixText: '+91 ',
              helperText: 'For other countries, start with + and the country code',
              errorText: _phoneText.text.trim().isEmpty || typedOk ? null : 'Enter a valid 10-digit mobile number',
              border: const OutlineInputBorder(),
            ),
          )
        else if (phone != null && !_changingPhone)
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              leading: const Icon(Icons.verified_rounded, color: AppColors.green),
              title: Text(phone, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Mobile number verified'),
              trailing: TextButton(
                onPressed: () => setState(() => _changingPhone = true),
                child: const Text('Change'),
              ),
            ),
          )
        else
          _PhoneVerifier(onVerified: () => setState(() => _changingPhone = false)),
        const SizedBox(height: 14),
        CheckboxListTile(
          key: const ValueKey('marketing-consent'),
          value: _optIn,
          onChanged: (v) => setState(() => _optIn = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('Send me offers and updates from Divyrs'),
          subtitle: const Text('By email, SMS or WhatsApp. You can turn this off any time.'),
        ),
        const SizedBox(height: 14),
        BigButton(
          key: const ValueKey('save-profile'),
          label: widget.setup ? 'Start learning' : 'Save changes',
          color: AppColors.green,
          onPressed: canSave ? _save : null,
        ),
        if (!phoneOk)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              verifies ? 'Verify your mobile number to continue.' : 'Enter your mobile number to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

/// Mobile number → "Send code" → 6-digit code → "Verify".
class _PhoneVerifier extends StatefulWidget {
  const _PhoneVerifier({required this.onVerified});
  final VoidCallback onVerified;

  @override
  State<_PhoneVerifier> createState() => _PhoneVerifierState();
}

class _PhoneVerifierState extends State<_PhoneVerifier> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AccountException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        final state = AppScope.read(context);
        final id = await state.sendPhoneCode(_phone.text);
        if (!mounted) return;
        if (id == null) {
          // Verified automatically from the SMS.
          widget.onVerified();
        } else {
          setState(() => _verificationId = id);
        }
      });

  Future<void> _verify() => _run(() async {
        await AppScope.read(context).confirmPhoneCode(_verificationId!, _code.text);
        if (mounted) widget.onVerified();
      });

  @override
  Widget build(BuildContext context) {
    final sent = _verificationId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('phone-number'),
                controller: _phone,
                enabled: !sent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixText: '+91 ',
                  helperText: 'For other countries, start with + and the country code',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: FilledButton(
                key: const ValueKey('send-code'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                onPressed: _busy
                    ? null
                    : sent
                        ? () => setState(() {
                              _verificationId = null;
                              _code.clear();
                            })
                        : _send,
                child: Text(sent ? 'Edit' : 'Send code'),
              ),
            ),
          ],
        ),
        if (sent) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('sms-code'),
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit code from SMS',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: FilledButton(
                  key: const ValueKey('verify-code'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                  onPressed: _busy ? null : _verify,
                  child: const Text('Verify'),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _busy ? null : _send, child: const Text('Resend code')),
          ),
        ],
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: const TextStyle(color: AppColors.pink, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
