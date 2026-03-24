// ignore_for_file: unused_local_variable, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fitness_app/features/auth/services/auth_service.dart';
import 'package:fitness_app/routes/app_routes.dart';
import 'package:fitness_app/core/widgets/loading_dots_text.dart';
import 'package:fitness_app/core/widgets/responsive_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _signupEmail;

  bool _obscurePassword = true;
  bool rememberPassword = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSignupEmail();
  }

  Future<void> _loadSignupEmail() async {
    final signupEmail = await _authService.getSignupEmail();
    if (!mounted) return;
    setState(() => _signupEmail = signupEmail?.trim());
    if ((_signupEmail ?? '').isNotEmpty) {
      emailController.text = _signupEmail!;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================= LOCAL LOGIN =================
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    final email = emailController.text.trim();
    final expectedEmail = (_signupEmail ?? '').trim();
    if (expectedEmail.isNotEmpty &&
        email.toLowerCase() != expectedEmail.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please login with the same email used during signup".tr,
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    final result = await _authService.login(
      email: email,
      password: passwordController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
    if (result.success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 600;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ResponsivePage(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: isDesktop ? 100 : 80,
                    height: isDesktop ? 100 : 80,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    "Welcome Back".tr,
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _inputField(
                  "Email",
                  emailController,
                  keyboard: TextInputType.emailAddress,
                ),

                _inputField("Password", passwordController, isPassword: true),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Checkbox(
                      value: rememberPassword,
                      onChanged: (value) {
                        setState(() {
                          rememberPassword = value ?? false;
                        });
                      },
                    ),
                    Text("Remember password".tr),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.forgotPassword);
                      },
                      child: Text(
                        "Forgot Password?".tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _loginUser,
                    child: _loading
                        ? LoadingDotsText(
                            label: "Signing in".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          )
                        : Text(
                            "Continue".tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text("Or With".tr),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _socialIcon(Icons.g_mobiledata, Colors.red),
                    _socialIcon(Icons.facebook, Colors.blue),
                    _socialIcon(Icons.apple, Colors.purple),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("If you do not have account ".tr),
                    GestureDetector(
                      onTap: () {
                        Get.offNamed(AppRoutes.createAccount);
                      },
                      child: Text(
                        "Sign up".tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboard,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$hint is required";
          }
          if (hint == "Email" && !value.contains("@")) {
            return "Enter a valid email";
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: hint.tr,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

Widget _socialIcon(IconData icon, Color color, {double radius = 22}) {
  return CircleAvatar(
    radius: radius,
    backgroundColor: color.withOpacity(0.1),
    child: IconButton(
      icon: Icon(icon, color: color, size: radius),
      onPressed: () {},
    ),
  );
}
