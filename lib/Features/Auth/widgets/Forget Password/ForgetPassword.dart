// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── State ─────────────────────────────────────────────────
  bool _loading = false;
  final bool _isDark = true;
  bool _otpSent = false;

  // ── Animation controllers ─────────────────────────────────
  late final AnimationController _orbAnim;
  late final AnimationController _cardAnim;
  late final AnimationController _btnAnim;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _btnScale;

  // ── Palette (Matching Login Design) ───────────────────────
  Color get bg => _isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF0F2F8);
  Color get cardBg =>
      _isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      _isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr => _isDark ? const Color(0x18FFFFFF) : const Color(0x20000000);
  Color get textClr =>
      _isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMuted =>
      _isDark ? const Color(0x80F0EFF8) : const Color(0x80000000);
  Color get textDim =>
      _isDark ? const Color(0x44F0EFF8) : const Color(0x44000000);
  Color get orbA => _isDark ? const Color(0x30FF3B3B) : const Color(0x18FF3B3B);
  Color get orbB => _isDark ? const Color(0x18991B1B) : const Color(0x10991B1B);

  static const Color red = Color(0xFFFF3B3B);
  static const Color redGlow = Color(0x50FF3B3B);
  static const Color deepRed = Color(0xFF991B1B);

  TextStyle get display => GoogleFonts.syne(color: textClr);
  TextStyle get mono => GoogleFonts.dmMono(color: textClr);
  TextStyle get body => GoogleFonts.dmSans(color: textClr);

  @override
  void initState() {
    super.initState();
    _orbAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _btnScale = _btnAnim;

    WidgetsBinding.instance.addPostFrameCallback((_) => _cardAnim.forward());
  }

  @override
  void dispose() {
    _orbAnim.dispose();
    _cardAnim.dispose();
    _btnAnim.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    await _btnAnim.reverse();
    await _btnAnim.forward();

    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate network

    if (!mounted) return;
    setState(() {
      _loading = false;
      _otpSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          _buildOrbs(),
          _buildGridOverlay(),
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: _animatedCard(maxW: 420),
                  ),
                );
              },
            ),
          ),
          Positioned(top: 20, left: 20, child: _backButton()),
        ],
      ),
    );
  }

  Widget _backButton() {
    return IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        color: textMuted,
        size: 18.sp,
      ),
    );
  }

  Widget _animatedCard({required double maxW}) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: _resetCard(),
        ),
      ),
    );
  }

  Widget _resetCard() {
    return Container(
      padding: EdgeInsets.all(36.w),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: bdr),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.4 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'RECOVERY MODE',
              style: mono.copyWith(
                fontSize: 8.5.sp,
                color: red,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              _otpSent ? 'Check Mail' : 'Reset Password',
              style: display.copyWith(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _otpSent
                  ? 'We have sent a recovery link to ${_emailCtrl.text}.'
                  : 'Enter your verified email and we will send you a system override link.',
              style: body.copyWith(fontSize: 12.sp, color: textMuted),
            ),
            SizedBox(height: 32.h),

            if (!_otpSent) ...[
              _fieldLabel('EMAIL ADDRESS'),
              SizedBox(height: 6.h),
              _inputField(
                controller: _emailCtrl,
                hint: 'you@company.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
              SizedBox(height: 28.h),
              _actionButton(label: 'SEND LINK', onTap: _handleReset),
            ] else ...[
              _actionButton(
                label: 'OPEN MAIL APP',
                onTap: () {
                  /* Logic to open mail */
                },
              ),
              SizedBox(height: 16.h),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: Text(
                    "Didn't receive code? Resend",
                    style: mono.copyWith(fontSize: 10.sp, color: red),
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
            Center(
              child: Text(
                'v2.4.1  ·  © 2025 Vora Systems',
                style: mono.copyWith(fontSize: 9.sp, color: textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback onTap}) {
    return ScaleTransition(
      scale: _btnScale,
      child: GestureDetector(
        onTapDown: (_) => _btnAnim.reverse(),
        onTapUp: (_) => _btnAnim.forward(),
        onTapCancel: () => _btnAnim.forward(),
        child: Container(
          height: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: _loading
                ? null
                : const LinearGradient(colors: [red, deepRed]),
            color: _loading ? const Color(0xFF1C1C28) : null,
            boxShadow: _loading
                ? []
                : [
                    BoxShadow(
                      color: redGlow,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loading ? null : onTap,
              borderRadius: BorderRadius.circular(12.r),
              child: Center(
                child: _loading
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        label,
                        style: display.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.8,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(
    label,
    style: mono.copyWith(fontSize: 8.5.sp, color: textDim, letterSpacing: 0.12),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: body.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w500),
      cursorColor: red,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: body.copyWith(fontSize: 12.sp, color: textDim),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Icon(icon, size: 16.sp, color: textMuted),
        ),
        prefixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: surface2,
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11.r),
          borderSide: BorderSide(color: bdr),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11.r),
          borderSide: BorderSide(color: bdr),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11.r),
          borderSide: BorderSide(color: red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildOrbs() {
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, _) {
        final t = _orbAnim.value;
        return Stack(
          children: [
            Positioned(
              top: -120 + (t * 30),
              left: -80 + (t * 20),
              child: _orb(380, orbA),
            ),
            Positioned(
              bottom: -80 - (t * 20),
              right: -120 + (t * 15),
              child: _orb(420, orbB),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
    ),
  );

  Widget _buildGridOverlay() => Positioned.fill(
    child: CustomPaint(
      painter: _DotGridPainter(
        color: _isDark ? const Color(0x08FFFFFF) : const Color(0x08000000),
      ),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  final Color color;
  _DotGridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
