import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoa_application/core/utils/message_alert.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      UserModel? user = await authRepo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (user == null) {
        _showError('User not found', Colors.orange);
        return;
      }

      // Check verification status
      if (user.verificationStatus == VerificationStatus.pending) {
        _showError(
            'Your Account is still Pending Verification.', Colors.orange);
        await authRepo.signOut();
        return;
      }

      if (user.verificationStatus == VerificationStatus.rejected) {
        _showError(
            'Your account is frozen. Please contact the admin.', Colors.orange);
        await authRepo.signOut();
        return;
      }

      // Navigate based on role
      if (user.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showError('Please try again.', Colors.orange);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = context.read<AuthRepository>();
      UserModel? user = await authRepo.signInWithGoogle();

      if (!mounted) return;

      if (user == null) {
        // New user - redirect to registration
        Navigator.pushNamed(context, '/register');
        return;
      }

      // Check verification status
      if (user.verificationStatus == VerificationStatus.pending) {
        _showError(
            'Your Account is still Pending Verification.', Colors.orange);
        await authRepo.signOut();
        return;
      }

      // Navigate based on role
      if (user.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/user-dashboard');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error can\'t signing in with Google!', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message, Color? color) {
    showMessage(context, message, bgColor: color ?? Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo and Title
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group,
                    size: 40,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 40),

                // Login Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          label: AppStrings.emailLabel,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.errorRequiredField;
                            }
                            if (!value.contains('@')) {
                              return AppStrings.errorInvalidEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: AppStrings.passwordLabel,
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppStrings.errorRequiredField;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const LoadingIndicator()
                            : CustomButton(
                                text: AppStrings.signIn,
                                onPressed: _handleLogin,
                              ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.grey)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                AppStrings.or,
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.grey)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: AppStrings.continueWithGoogle,
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          isOutlined: true,
                          icon: Icons.g_mobiledata,
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            AppStrings.dontHaveAccount,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
