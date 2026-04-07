// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Drop-in replacement for the Loginscreen.
//  Deps: flutter_screenutil, google_fonts
//  Replace the AuthService import & call to match your project.
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ── State ─────────────────────────────────────────────────
  bool _loading = false;
  bool _obscure = true;
  bool _isDark = true;
  String? _emailErr;
  String? _passErr;

  // ── Animation controllers ─────────────────────────────────
  late final AnimationController _orbAnim; // slow float
  late final AnimationController _cardAnim; // fade+slide in on mount
  late final AnimationController _btnAnim; // press pulse

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _btnScale;

  // ── Palette ───────────────────────────────────────────────
  Color get bg => _isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF0F2F8);
  Color get cardBg =>
      _isDark ? const Color(0xFF111118) : const Color(0xFFFFFFFF);
  Color get surface2 =>
      _isDark ? const Color(0xFF16161F) : const Color(0xFFEEF0F6);
  Color get bdr => _isDark ? const Color(0x18FFFFFF) : const Color(0x20000000);
  Color get bdrFocus =>
      _isDark ? const Color(0x40FF3B3B) : const Color(0x60FF3B3B);
  Color get textClr =>
      _isDark ? const Color(0xFFF0EFF8) : const Color(0xFF0F0F1A);
  Color get textMuted =>
      _isDark ? const Color(0x80F0EFF8) : const Color(0x80000000);
  Color get textDim =>
      _isDark ? const Color(0x44F0EFF8) : const Color(0x44000000);
  Color get orbA => _isDark ? const Color(0x30FF3B3B) : const Color(0x18FF3B3B);
  Color get orbB => _isDark ? const Color(0x18991B1B) : const Color(0x10991B1B);
  Color get orbC => _isDark ? const Color(0x10FF3B3B) : const Color(0x08FF3B3B);

  static const Color red = Color(0xFFFF3B3B);
  static const Color redDim = Color(0x1FFF3B3B);
  static const Color redGlow = Color(0x50FF3B3B);
  static const Color deepRed = Color(0xFF991B1B);
  static const Color green = Color(0xFF22C55E);

  TextStyle get display => GoogleFonts.syne(color: textClr);
  TextStyle get mono => GoogleFonts.dmMono(color: textClr);
  TextStyle get body => GoogleFonts.dmSans(color: textClr);

  @override
  void initState() {
    super.initState();

    // Orb slow float — continuous 8-second loop
    _orbAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Card entrance — 600ms ease-out
    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));

    // Button press scale
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _btnScale = _btnAnim;

    // Trigger entrance after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _cardAnim.forward());
  }

  @override
  void dispose() {
    _orbAnim.dispose();
    _cardAnim.dispose();
    _btnAnim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth ──────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    // Clear inline errors
    setState(() {
      _emailErr = null;
      _passErr = null;
    });

    if (!_formKey.currentState!.validate()) return;

    // Button press animation
    await _btnAnim.reverse();
    await _btnAnim.forward();

    setState(() => _loading = true);

    // ── Replace with your AuthService call ──────────────────
    await Future.delayed(const Duration(seconds: 2)); // simulate network
    const String? errorMessage = null; // null = success
    // ────────────────────────────────────────────────────────

    if (!mounted) return;
    setState(() => _loading = false);

    if (errorMessage == null) {
      _toast('Access Granted', green, Icons.check_circle_rounded);
      // Navigator.pushReplacementNamed(context, Routes.homeScreen);
    } else {
      _toast(errorMessage, red, Icons.error_outline_rounded);
    }
  }

  void _toast(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20.w),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              msg,
              style: body.copyWith(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Layer 1: Animated mesh orbs ───────────────────
          _buildOrbs(),
          // ── Layer 2: Subtle grid texture overlay ─────────
          _buildGridOverlay(),
          // ── Layer 3: Login card ───────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return isWide
                    ? _wideLayout(constraints)
                    : _narrowLayout(constraints);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ORB BACKGROUND
  // ─────────────────────────────────────────────────────────
  Widget _buildOrbs() {
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, _) {
        final t = _orbAnim.value;
        return Stack(
          children: [
            // Top-left large orb — floats slightly
            Positioned(
              top: -120 + (t * 30),
              left: -80 + (t * 20),
              child: _orb(380, orbA),
            ),
            // Bottom-right orb
            Positioned(
              bottom: -80 - (t * 20),
              right: -120 + (t * 15),
              child: _orb(420, orbB),
            ),
            // Center accent
            Positioned(
              top: 200 + (t * 40),
              right: 80 - (t * 10),
              child: _orb(200, orbC),
            ),
            // Small top-right
            Positioned(
              top: 60 - (t * 15),
              right: 200 + (t * 10),
              child: _orb(120, orbA.withOpacity(0.5)),
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
      gradient: RadialGradient(
        colors: [color, color.withOpacity(0)],
        stops: const [0.0, 1.0],
      ),
    ),
  );

  // ── Subtle dot-grid texture ───────────────────────────────
  Widget _buildGridOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _DotGridPainter(
          color: _isDark ? const Color(0x08FFFFFF) : const Color(0x08000000),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  WIDE LAYOUT (desktop: split left brand / right card)
  // ─────────────────────────────────────────────────────────
  Widget _wideLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Left — brand panel
        Expanded(flex: 5, child: _brandPanel()),
        // Right — card
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(40.w),
              child: _animatedCard(maxW: 420),
            ),
          ),
        ),
      ],
    );
  }

  // ── Narrow layout (mobile / tablet) ──────────────────────
  Widget _narrowLayout(BoxConstraints constraints) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniLogo(),
            SizedBox(height: 32.h),
            _animatedCard(maxW: 420),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  LEFT BRAND PANEL (wide only)
  // ─────────────────────────────────────────────────────────
  Widget _brandPanel() {
    return Padding(
      padding: EdgeInsets.all(52.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: 52.w,
            height: 52.w,
            decoration: BoxDecoration(
              color: red,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [BoxShadow(color: redGlow, blurRadius: 24)],
            ),
            child: Icon(Icons.bolt_rounded, color: Colors.white, size: 26.sp),
          ),
          SizedBox(height: 32.h),
          // Brand name
          Text(
            'VORA',
            style: display.copyWith(
              fontSize: 48.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              height: 1,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Point of Sale System',
            style: mono.copyWith(
              fontSize: 13.sp,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 48.h),
          // Feature bullets
          _bullet(Icons.point_of_sale_rounded, 'Fast Terminal Processing'),
          SizedBox(height: 14.h),
          _bullet(Icons.inventory_2_outlined, 'Real-Time Inventory'),
          SizedBox(height: 14.h),
          _bullet(Icons.bar_chart_rounded, 'Live Sales Analytics'),
          SizedBox(height: 14.h),
          _bullet(Icons.people_alt_outlined, 'Customer Management'),
          const Spacer(),
          // Theme toggle
          GestureDetector(
            onTap: () => setState(() => _isDark = !_isDark),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: surface2,
                border: Border.all(color: bdr),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 14.sp,
                    color: _isDark ? const Color(0xFFF5C842) : textMuted,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _isDark ? 'Light Mode' : 'Dark Mode',
                    style: mono.copyWith(fontSize: 10.5.sp, color: textMuted),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'v2.4.1  ·  © 2025 Vora Systems',
            style: mono.copyWith(fontSize: 9.sp, color: textDim),
          ),
        ],
      ),
    );
  }

  Widget _bullet(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 28.w,
          height: 28.w,
          decoration: BoxDecoration(
            color: redDim,
            borderRadius: BorderRadius.circular(7.r),
          ),
          child: Icon(icon, size: 13.sp, color: red),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: body.copyWith(
            fontSize: 13.sp,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _miniLogo() {
    return Column(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color: red,
            borderRadius: BorderRadius.circular(13.r),
            boxShadow: [BoxShadow(color: redGlow, blurRadius: 20)],
          ),
          child: Icon(Icons.bolt_rounded, color: Colors.white, size: 22.sp),
        ),
        SizedBox(height: 12.h),
        Text(
          'VORA',
          style: display.copyWith(
            fontSize: 22.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
            height: 1,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Point of Sale System',
          style: mono.copyWith(fontSize: 10.sp, color: textMuted),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ANIMATED LOGIN CARD
  // ─────────────────────────────────────────────────────────
  Widget _animatedCard({required double maxW}) {
    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: _loginCard(),
        ),
      ),
    );
  }

  Widget _loginCard() {
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
          BoxShadow(
            color: red.withOpacity(0.04),
            blurRadius: 80,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Card header ───────────────────────────────
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SYSTEM AUTH',
                      style: mono.copyWith(
                        fontSize: 8.5.sp,
                        color: red,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Sign In',
                      style: display.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Compact theme toggle for narrow
                GestureDetector(
                  onTap: () => setState(() => _isDark = !_isDark),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: surface2,
                      border: Border.all(color: bdr),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: Icon(
                      _isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 15.sp,
                      color: _isDark ? const Color(0xFFF5C842) : textMuted,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32.h),

            // ── Email field ───────────────────────────────
            _fieldLabel('EMAIL ADDRESS'),
            SizedBox(height: 6.h),
            _inputField(
              controller: _emailCtrl,
              hint: 'you@company.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              error: _emailErr,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            SizedBox(height: 18.h),

            // ── Password field ────────────────────────────
            _fieldLabel('PASSWORD'),
            SizedBox(height: 6.h),
            _inputField(
              controller: _passCtrl,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscure,
              error: _passErr,
              suffix: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16.sp,
                  color: textDim,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            SizedBox(height: 10.h),

            // ── Forgot password ───────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot password?',
                  style: mono.copyWith(
                    fontSize: 10.sp,
                    color: red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.h),

            // ── AUTHORIZE button ──────────────────────────
            ScaleTransition(
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
                        : const LinearGradient(
                            colors: [red, deepRed],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                    borderRadius: BorderRadius.circular(12.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: _loading ? null : _handleLogin,
                      child: Center(
                        child: _loading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'AUTHORIZE',
                                    style: display.copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 15.sp,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 28.h),

            // ── Divider ───────────────────────────────────
            Row(
              children: [
                Expanded(child: Divider(color: bdr, height: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    'OR',
                    style: mono.copyWith(fontSize: 9.sp, color: textDim),
                  ),
                ),
                Expanded(child: Divider(color: bdr, height: 1)),
              ],
            ),
            SizedBox(height: 20.h),

            // ── PIN login quick button ────────────────────
            GestureDetector(
              onTap: () {},
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: surface2,
                  border: Border.all(color: bdr),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pin_outlined, size: 16.sp, color: textMuted),
                    SizedBox(width: 8.w),
                    Text(
                      'Sign in with PIN',
                      style: mono.copyWith(
                        fontSize: 11.sp,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // ── Footer ────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────
  //  FIELD COMPONENTS
  // ─────────────────────────────────────────────────────────
  Widget _fieldLabel(String label) => Text(
    label,
    style: mono.copyWith(
      fontSize: 8.5.sp,
      color: textDim,
      letterSpacing: 0.12,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? error,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: body.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w500),
      cursorColor: red,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: body.copyWith(fontSize: 12.sp, color: textDim),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 14.w, right: 10.w),
          child: Icon(icon, size: 16.sp, color: textMuted),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: suffix != null
            ? Padding(
                padding: EdgeInsets.only(right: 14.w),
                child: suffix,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(),
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
          borderSide: BorderSide(color: bdrFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11.r),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11.r),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
        errorStyle: mono.copyWith(fontSize: 9.5.sp, color: red),
        errorText: error,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DOT GRID PAINTER  — subtle texture layer
// ─────────────────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  final Color color;
  const _DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    const radius = 1.0;
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.color != color;
}
