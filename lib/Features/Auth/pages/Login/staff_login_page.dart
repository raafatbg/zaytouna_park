// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:zaytouna_park/Core/Routers/routes.dart';
import 'package:zaytouna_park/Core/Routers/route_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _stayLoggedIn = false;

  // Theme Colors
  final Color primaryGreen = const Color(0xFF10B981);
  final Color darkText = const Color(0xFF1E293B);
  final Color lightText = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    _checkStayLoggedIn();
  }

  Future<void> _checkStayLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool('stayLoggedIn') ?? false;
    final email = prefs.getString('email');
    final password = prefs.getString('password');
    if (stayLoggedIn && email != null && password != null) {
      _emailController.text = email;
      _passwordController.text = password;
      setState(() {
        _stayLoggedIn = true;
      });
      await _handleLogin(auto: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({bool auto = false}) async {
    if (!_formKey.currentState!.validate() && !auto) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await RouteGuard.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _errorMessage = result.message ?? 'Login failed. Please try again.';
        });
        return;
      }

      final user = RouteGuard.user;

      if (user == null) {
        setState(() {
          _errorMessage = 'Failed to load user profile. Please try again.';
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (_stayLoggedIn) {
        await prefs.setBool('stayLoggedIn', true);
        await prefs.setString('email', _emailController.text.trim());
        await prefs.setString('password', _passwordController.text);
      } else {
        await prefs.remove('stayLoggedIn');
        await prefs.remove('email');
        await prefs.remove('password');
      }

      String navigationRoute;
      switch (user.role.toLowerCase()) {
        case 'admin':
          navigationRoute = Routes.adminDashboard;
          break;
        case 'cashier':
          navigationRoute = Routes.cashierDashboard;
          break;
        case 'kitchen':
        case 'chef':
          navigationRoute = Routes.kitchenDashboard;
          break;
        default:
          navigationRoute = Routes.cashierDashboard;
      }

      if (mounted && !auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${user.fullName}!'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(navigationRoute);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Very light clean background
      body: Stack(
        children: [
          // Background decorative elements (Light Theme)
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryGreen.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.08),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF34D399).withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.08),
                    blurRadius: 150,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 24.0 : 48.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isMobile
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Branding
        Expanded(
          flex: 5,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(right: 64.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Logo Area
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Z',
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'DM Serif Display',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'Zaytouna Park',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                        letterSpacing: -1,
                        fontFamily: 'DM Serif Display',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Premium point-of-sale management\nfor modern retail spaces.',
                      style: TextStyle(
                        fontSize: 18,
                        color: lightText,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 64),
                    _FeatureItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Real-time Inventory',
                      description: 'Track stock seamlessly across your store.',
                      iconColor: primaryGreen,
                      textColor: darkText,
                      subTextColor: lightText,
                    ),
                    const SizedBox(height: 32),
                    _FeatureItem(
                      icon: Icons.trending_up_outlined,
                      title: 'Smart Analytics',
                      description: 'Deep insights into sales and performance.',
                      iconColor: primaryGreen,
                      textColor: darkText,
                      subTextColor: lightText,
                    ),
                    const SizedBox(height: 32),
                    _FeatureItem(
                      icon: Icons.security_outlined,
                      title: 'Enterprise Security',
                      description: 'Bank-grade encryption and access control.',
                      iconColor: primaryGreen,
                      textColor: darkText,
                      subTextColor: lightText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Right side: Clean White Login Form
        Expanded(flex: 4, child: _buildCleanLoginForm()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mobile Header
        FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'DM Serif Display',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Zaytouna Park',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  fontFamily: 'DM Serif Display',
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        _buildCleanLoginForm(),
      ],
    );
  }

  Widget _buildCleanLoginForm() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // Semi-transparent white
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 40,
                spreadRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with your staff account to continue.',
                    style: TextStyle(fontSize: 14, color: lightText),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFECACA)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB91C1C),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStyledInput(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildStyledInput(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _stayLoggedIn,
                                activeColor: primaryGreen,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                onChanged: _isLoading
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _stayLoggedIn = value ?? false;
                                        });
                                      },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Stay logged in',
                              style: TextStyle(
                                fontSize: 14,
                                color: darkText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Green Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleLogin(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              disabledBackgroundColor: primaryGreen.withOpacity(
                                0.5,
                              ),
                              elevation: 0,
                              shadowColor: primaryGreen.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: darkText),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: lightText, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: lightText,
                      size: 20,
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF1F5F9), // Very light slate gray
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryGreen, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            errorStyle: const TextStyle(color: Color(0xFFEF4444)),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color textColor;
  final Color subTextColor;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Center(child: Icon(icon, size: 24, color: iconColor)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
