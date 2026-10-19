import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/popup.dart';
import '../widgets/ui.dart';

/// First screen: sign in with Google or Facebook, or continue without login.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _busy; // 'google' | 'facebook' | 'email'
  bool _register = false;
  bool _hide = true;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(
      'email',
      () => _register ? widget.auth.registerWithEmail(_name.text, _email.text, _pass.text) : widget.auth.signInWithEmail(_email.text, _pass.text),
      loading: _register ? 'ກຳລັງສ້າງບັນຊີ…' : 'ກຳລັງເຂົ້າສູ່ລະບົບ…',
    );
  }

  Future<void> _forgot() async {
    final mail = _email.text.trim();
    if (mail.isEmpty || !mail.contains('@')) {
      await showAppPopup(context, kind: PopupKind.warning, title: 'ໃສ່ອີເມລກ່ອນ', message: 'ພິມອີເມລຂອງທ່ານໃນຊ່ອງ ແລ້ວກົດ "ລືມລະຫັດຜ່ານ" ອີກຄັ້ງ');
      return;
    }
    final err = await runWithLoading(context, () => widget.auth.resetPassword(mail), message: 'ກຳລັງສົ່ງລິ້ງ…');
    if (!mounted) return;
    if (err == null) {
      await showAppPopup(context, kind: PopupKind.success, title: 'ສົ່ງລິ້ງແລ້ວ', message: 'ເປີດອີເມລ $mail ແລ້ວກົດລິ້ງເພື່ອຕັ້ງລະຫັດຜ່ານໃໝ່ (ກວດ Spam ນຳ)');
    } else if (_isNetwork(err)) {
      if (await problemPopup(context, message: err)) await _forgot();
    } else {
      await showAppPopup(context, kind: PopupKind.error, title: 'ສົ່ງບໍ່ສຳເລັດ', message: err);
    }
  }

  Widget _input(String label, TextEditingController c, {bool password = false, TextInputType? keyboard, String? Function(String?)? validator, bool last = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: sans(size: 12, color: AppColors.muted)),
          TextFormField(
            controller: c,
            obscureText: password && _hide,
            keyboardType: keyboard,
            autocorrect: false,
            enableSuggestions: !password,
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: last ? (_) => _submit() : null,
            validator: validator,
            style: sans(size: 17),
            cursorColor: AppColors.butter,
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 6),
              suffixIcon: password
                  ? IconButton(
                      icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.muted),
                      onPressed: () => setState(() => _hide = !_hide),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    Widget item(String label, bool reg) {
      final on = _register == reg;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _register = reg),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? AppColors.glass2 : Colors.transparent, borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: sans(size: 15, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? AppColors.text : AppColors.muted)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.glass, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.line)),
      child: Row(children: [item('ເຂົ້າສູ່ລະບົບ', false), item('ສະໝັກໃໝ່', true)]),
    );
  }

  Widget _emailForm() {
    final loading = _busy == 'email';
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modeToggle(),
          const SizedBox(height: 14),
          if (_register) _input('ຊື່', _name, validator: (v) => (v == null || v.trim().isEmpty) ? 'ໃສ່ຊື່' : null),
          _input('ອີເມລ', _email,
              keyboard: TextInputType.emailAddress,
              validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'ຮູບແບບອີເມລບໍ່ຖືກຕ້ອງ' : null),
          _input('ລະຫັດຜ່ານ', _pass,
              password: true,
              last: !_register,
              validator: (v) => (v == null || v.length < 6) ? 'ຢ່າງໜ້ອຍ 6 ຕົວ' : null),
          if (_register)
            _input('ຢືນຢັນລະຫັດຜ່ານ', _pass2,
                password: true,
                last: true,
                validator: (v) => v != _pass.text ? 'ລະຫັດຜ່ານບໍ່ກົງກັນ' : null),
          if (!_register)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _forgot, child: Text('ລືມລະຫັດຜ່ານ?', style: sans(size: 14, color: AppColors.muted))),
            ),
          const SizedBox(height: 6),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.magenta,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(58),
              shape: const StadiumBorder(),
            ),
            onPressed: _busy == null ? _submit : null,
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(_register ? 'ສະໝັກ' : 'ເຂົ້າສູ່ລະບົບ', style: sans(size: 17, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _isNetwork(String err) => err.contains('ອິນເຕີເນັດ');

  /// Runs a login action. Email actions show the loading animation (and the
  /// "slow network" hint); every error becomes a popup, network errors get "retry".
  Future<void> _run(String which, Future<String?> Function() action, {String loading = 'ກຳລັງເຂົ້າສູ່ລະບົບ…'}) async {
    if (_busy != null) return;
    setState(() => _busy = which);
    try {
      while (mounted) {
        final err = which == 'email' ? await runWithLoading(context, action, message: loading) : await action();
        if (!mounted || err == null) return;
        if (_isNetwork(err)) {
          if (!await problemPopup(context, message: err)) return;
          continue; // retry
        }
        await showAppPopup(context, kind: PopupKind.error, title: 'ເຂົ້າສູ່ລະບົບບໍ່ສຳເລັດ', message: err);
        return;
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _providerButton({
    required String id,
    required String label,
    required Color bg,
    required Color fg,
    required Widget mark,
    required VoidCallback onTap,
    Color? border,
  }) {
    final loading = _busy == id;
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border ?? Colors.transparent)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _busy == null ? onTap : null,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 12),
              mark,
              Expanded(
                child: Center(
                  child: loading
                      ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
                      : Text(label, style: sans(size: 17, weight: FontWeight.w600, color: fg)),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    // Decorative preview card, same look as the overview page.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.line),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x26FFFFFF), Color(0x0AFFFFFF)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ກຳໄລສຸດທິ', style: sans(size: 15, color: AppColors.muted)),
              const ButterChip('+68.4%', small: true),
            ],
          ),
          const SizedBox(height: 4),
          const AmountText(1250000, 'LAK', signed: true, size: 40, weight: FontWeight.w300),
          const SizedBox(height: 16),
          Row(
            children: [
              const Coin('Free Fire', size: 40),
              Transform.translate(offset: const Offset(-10, 0), child: const Coin('PUBG Mobile', size: 40)),
              Transform.translate(offset: const Offset(-20, 0), child: const Coin('Mobile Legends', size: 40)),
              Transform.translate(offset: const Offset(-20, 0), child: Text('+12 ໄອດີ', style: sans(size: 13, color: AppColors.muted))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
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
                      const SizedBox(height: 12),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF5CF6), Color(0xFF7B21D6)]),
                          boxShadow: const [BoxShadow(color: Color(0x47FF14F0), blurRadius: 24, offset: Offset(0, 8))],
                        ),
                        child: const Icon(Icons.sports_esports_outlined, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 28),
                      _hero(),
                      const SizedBox(height: 32),
                      Text('ຍິນດີຕ້ອນຮັບ', style: sans(size: 34, weight: FontWeight.w300, height: 1.15)),
                      const SizedBox(height: 8),
                      Text('ບັນທຶກການຂາຍໄອດີເກມຂອງທ່ານ ເບິ່ງກຳໄລໄດ້ທຸກເວລາ.', style: sans(size: 16, color: AppColors.muted, height: 1.45)),
                      const SizedBox(height: 28),
                      _providerButton(
                        id: 'google',
                        label: 'ສືບຕໍ່ດ້ວຍ Google',
                        bg: Colors.white,
                        fg: const Color(0xFF1B1B1F),
                        mark: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F1F4)),
                          child: Text('G', style: sans(size: 20, weight: FontWeight.w800, color: const Color(0xFF4285F4))),
                        ),
                        onTap: () => _run('google', auth.signInWithGoogle),
                      ),
                      const SizedBox(height: 12),
                      _providerButton(
                        id: 'facebook',
                        label: 'ສືບຕໍ່ດ້ວຍ Facebook',
                        bg: const Color(0xFF1877F2),
                        fg: Colors.white,
                        mark: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Text('f', style: sans(size: 24, weight: FontWeight.w800, color: const Color(0xFF1877F2))),
                        ),
                        onTap: () => _run('facebook', auth.signInWithFacebook),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.line)),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('ຫຼື ໃຊ້ອີເມລ', style: sans(size: 13, color: AppColors.faint))),
                          const Expanded(child: Divider(color: AppColors.line)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _emailForm(),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: _busy == null ? auth.continueAsGuest : null,
                          child: Text('ໃຊ້ໂດຍບໍ່ເຂົ້າສູ່ລະບົບ', style: sans(size: 15, weight: FontWeight.w500, color: AppColors.magentaText)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'ຂໍ້ມູນເກັບໃນເຄື່ອງນີ້ ແຍກຕາມບັນຊີທີ່ເຂົ້າ.\nການເຂົ້າສູ່ລະບົບໃຊ້ພຽງເພື່ອຢືນຢັນຕົວຕົນ.',
                          textAlign: TextAlign.center,
                          style: sans(size: 12, color: AppColors.faint, height: 1.5),
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
