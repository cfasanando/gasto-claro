import 'package:flutter/material.dart';

import '../models/api_exception.dart';
import '../services/auth_service.dart';
import '../utils/app_validators.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscurePassword = true;
  String? serverError;

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      isLoading = true;
      serverError = null;
    });

    try {
      await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) {
        return;
      }

      widget.onLoginSuccess();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        serverError = e.message;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        serverError = 'No se pudo iniciar sesión. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Usa tu cuenta del backend de GastoClaro.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDecoration(label: 'Correo'),
                        validator: AppValidators.email,
                        enabled: !isLoading,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: inputDecoration(
                          label: 'Contraseña',
                          suffixIcon: IconButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => AppValidators.requiredText(
                          value,
                          label: 'La contraseña',
                          minLength: 6,
                        ),
                        enabled: !isLoading,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        onFieldSubmitted: (_) => submit(),
                      ),
                      if (serverError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            serverError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : submit,
                          icon: isLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.login),
                          label: Text(
                            isLoading ? 'Ingresando...' : 'Entrar',
                          ),
                        ),
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