import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../config/routes.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_message.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and App Name
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gestion de Projets Collaboratifs',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Form Fields
                  Obx(() => ErrorMessage(
                    message: authController.errorMessage.value,
                    isVisible: authController.errorMessage.isNotEmpty,
                  )),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  Obx(() => CustomTextField(
                    controller: passwordController,
                    hintText: 'Mot de passe',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !authController.isPasswordVisible.value,
                    suffixIcon: authController.isPasswordVisible.value
                        ? Icons.visibility_off  // Remplacer IconButton par IconData
                        : Icons.visibility,
                    onSuffixIconPressed: authController.togglePasswordVisibility, // Assurez-vous d'avoir une méthode pour gérer le clic
                    validator: Validators.validatePassword,
                  )),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                      child: Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Button
                  Obx(() => authController.isLoading.value
                      ? const LoadingIndicator()
                      : CustomButton(
                    text: 'Se connecter',
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        authController.signIn(
                          emailController.text.trim(),
                          passwordController.text,
                        );
                      }
                    },
                  ),
                  ),

                  const SizedBox(height: 16),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.register),
                        child: Text(
                          'S\'inscrire',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}