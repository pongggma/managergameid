import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

/// Shown after registering (or logging in) with an unconfirmed email.
/// It checks by itself every few seconds, so it closes as soon as the link is tapped.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.auth});

  final AuthService auth;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _poll;
  Timer? _tick;
  int _cooldown = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => widget.auth.checkVerified());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final ok = await widget.auth.checkVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!ok) showToast(context, 'ຍັງບໍ່ໄດ້ຢືນຢັນ ເປີດອີເມລແລ້ວກົດລິ້ງກ່ອນ');
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    final err = await widget.auth.resendVerification();
    if (!mounted) return;
    showToast(context, err ?? 'ສົ່ງອີເມລຢືນຢັນອີກຄັ້ງແລ້ວ');
    if (err != null) return;
    setState(() => _cooldown = 60);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.auth.account?.email ?? '';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AppBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF5CF6), Color(0xFF7B21D6)]),
                          boxShadow: const [BoxShadow(color: Color(0x47FF14F0), blurRadius: 28, offset: Offset(0, 10))],
                        ),
                        child: const Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 28),
                      Text('ຢືນຢັນອີເມລຂອງທ່ານ', style: sans(size: 32, weight: FontWeight.w300, height: 1.15)),
                      const SizedBox(height: 12),
                      Text('ເຮົາສົ່ງລິ້ງຢືນຢັນໄປທີ່', style: sans(size: 16, color: AppColors.muted, height: 1.45)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                        child: Text(email, style: mono(size: 15)),
                      ),
                      const SizedBox(height: 12),
                      Text('ເປີດອີເມລ ແລ້ວກົດລິ້ງ ຈາກນັ້ນກັບມາທີ່ແອັບ. ຖ້າບໍ່ເຫັນ ໃຫ້ກວດໂຟລເດີ Spam.', style: sans(size: 14, color: AppColors.muted, height: 1.5)),
                      const SizedBox(height: 28),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.magenta,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(58),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _checking ? null : _check,
                        child: _checking
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : Text('ຂ້ອຍຢືນຢັນແລ້ວ', style: sans(size: 17, weight: FontWeight.w600, color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: const StadiumBorder(),
                          side: const BorderSide(color: AppColors.line),
                          backgroundColor: AppColors.glass2,
                        ),
                        onPressed: _cooldown > 0 ? null : _resend,
                        child: Text(_cooldown > 0 ? 'ສົ່ງອີກຄັ້ງໄດ້ໃນ $_cooldown ວິນາທີ' : 'ສົ່ງອີເມລອີກຄັ້ງ', style: sans(size: 16, weight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: widget.auth.signOut,
                          child: Text('ໃຊ້ອີເມລອື່ນ / ອອກຈາກລະບົບ', style: sans(size: 15, color: AppColors.magentaText)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
