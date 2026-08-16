import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_plant_care/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created successfully!',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF134E39),
        ),
      );

      // Go to dashboard after successful registration
      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4EDE6),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // =================================================
                    // LOGO
                    // =================================================

                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD0E2D4),
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 40,
                          color: Color(0xFF134E39),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // TITLE
                    // =================================================

                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF134E39),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Create your Smart Plant Care account to start monitoring your plants.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5A7865),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // =================================================
                    // NAME
                    // =================================================

                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF134E39),
                      ),
                      decoration: _inputDecoration(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // EMAIL
                    // =================================================

                    TextFormField(
                      controller: _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF134E39),
                      ),
                      decoration: _inputDecoration(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Please enter your email';
                        }

                        if (!value.contains('@') ||
                            !value.contains('.')) {
                          return 'Please enter a valid email';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // PASSWORD
                    // =================================================

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF134E39),
                      ),
                      decoration: _inputDecoration(
                        label: 'Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF5A7865),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please enter a password';
                        }

                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // CONFIRM PASSWORD
                    // =================================================

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF134E39),
                      ),
                      decoration: _inputDecoration(
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF5A7865),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Please confirm your password';
                        }

                        if (value !=
                            _passwordController.text) {
                          return 'Passwords do not match';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // CREATE ACCOUNT
                    // =================================================

                    ElevatedButton(
                      onPressed:
                          _isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF134E39),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // LOGIN
                    // =================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color:
                                const Color(0xFF5A7865),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.go('/login');
                          },
                          child: Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  const Color(0xFF134E39),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF5A7865),
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF5A7865),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF134E39),
          width: 1.5,
        ),
      ),
    );
  }
}