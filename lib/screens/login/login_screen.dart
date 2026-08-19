import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_plant_care/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final AuthService _authService =
      AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService
          .signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              e.toString(),
              style:
                  GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
            backgroundColor:
                Colors.red[700],
          ),
        );
      }
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
      backgroundColor:
          const Color(0xFFE4EDE6),

      body: Center(
        child: Container(
          constraints:
              const BoxConstraints(
            maxWidth: 480,
          ),

          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 24,
              ),

              child:
                  SingleChildScrollView(
                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,

                    children: [
                      const SizedBox(
                        height: 40,
                      ),

                      // =================================================
                      // LOGO
                      // =================================================

                      Center(
                        child: Container(
                          width: 100,
                          height: 100,

                          decoration:
                              const BoxDecoration(
                            shape:
                                BoxShape.circle,
                            color:
                                Color(
                              0xFFD0E2D4,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons.eco,
                            size: 45,
                            color:
                                Color(
                              0xFF134E39,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =================================================
                      // TITLE
                      // =================================================

                      Text(
                        'Welcome Back!',
                        textAlign:
                            TextAlign.center,

                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 26,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              const Color(
                            0xFF134E39,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        'Sign in to monitor your plants',
                        textAlign:
                            TextAlign.center,

                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 14,
                          fontWeight:
                              FontWeight
                                  .w500,
                          color:
                              const Color(
                            0xFF5A7865,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 36,
                      ),

                      // =================================================
                      // EMAIL
                      // =================================================

                      TextFormField(
                        controller:
                            _emailController,

                        keyboardType:
                            TextInputType
                                .emailAddress,

                        enabled:
                            !_isLoading,

                        decoration:
                            InputDecoration(
                          labelText:
                              'Email',

                          prefixIcon:
                              const Icon(
                            Icons
                                .email_outlined,
                            color:
                                Color(
                              0xFF134E39,
                            ),
                          ),

                          filled: true,

                          fillColor:
                              Colors.white,

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                BorderSide
                                    .none,
                          ),

                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFF134E39,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Please enter your email';
                          }

                          if (!value
                              .contains(
                            '@',
                          )) {
                            return 'Please enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =================================================
                      // PASSWORD
                      // =================================================

                      TextFormField(
                        controller:
                            _passwordController,

                        obscureText:
                            _obscurePassword,

                        enabled:
                            !_isLoading,

                        decoration:
                            InputDecoration(
                          labelText:
                              'Password',

                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline,
                            color:
                                Color(
                              0xFF134E39,
                            ),
                          ),

                          suffixIcon:
                              IconButton(
                            icon:
                                Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off
                                  : Icons
                                      .visibility,
                              color:
                                  const Color(
                                0xFF5A7865,
                              ),
                            ),
                            onPressed:
                                () {
                              setState(
                                () {
                                  _obscurePassword =
                                      !_obscurePassword;
                                },
                              );
                            },
                          ),

                          filled: true,

                          fillColor:
                              Colors.white,

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                BorderSide
                                    .none,
                          ),

                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                            borderSide:
                                const BorderSide(
                              color:
                                  Color(
                                0xFF134E39,
                              ),
                              width: 1.5,
                            ),
                          ),
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .isEmpty) {
                            return 'Please enter your password';
                          }

                          if (value.length <
                              6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // =================================================
                      // FORGOT PASSWORD
                      // =================================================

                      Align(
                        alignment:
                            Alignment
                                .centerRight,

                        child:
                            TextButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () {
                                      context.go(
                                        '/forgot-password',
                                      );
                                    },

                          child: Text(
                            'Forgot Password?',
                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  const Color(
                                0xFF134E39,
                              ),
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =================================================
                      // LOGIN BUTTON
                      // =================================================

                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : _handleLogin,

                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              const Color(
                            0xFF134E39,
                          ),

                          disabledBackgroundColor:
                              const Color(
                            0xFF8AA99A,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 16,
                          ),

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),

                        child:
                            _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          Colors
                                              .white,
                                    ),
                                  ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // =================================================
                      // REGISTER
                      // =================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          Text(
                            "Don't have an account? ",

                            style:
                                GoogleFonts
                                    .poppins(
                              color:
                                  const Color(
                                0xFF5A7865,
                              ),
                            ),
                          ),

                          GestureDetector(
                            onTap:
                                _isLoading
                                    ? null
                                    : () {
                                        context.go(
                                          '/register',
                                        );
                                      },

                            child: Text(
                              'Register',
                              style:
                                  GoogleFonts
                                      .poppins(
                                color:
                                    const Color(
                                  0xFF134E39,
                                ),
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}