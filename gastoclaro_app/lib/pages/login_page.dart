import 'package:flutter/material.dart';

import '../models/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_tokens.dart';
import '../utils/app_validators.dart';
import '../widgets/app_surface_card.dart';

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
    } catch (_) {
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
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.05,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFF),
              Color(0xFFF3F6FB),
              Color(0xFFF4F7FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 860;

                    if (compact) {
                      return Column(
                        children: [
                          const _LoginHero(),
                          const SizedBox(height: 20),
                          _LoginFormCard(
                            formKey: formKey,
                            emailController: emailController,
                            passwordController: passwordController,
                            obscurePassword: obscurePassword,
                            isLoading: isLoading,
                            serverError: serverError,
                            onTogglePassword: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            onSubmit: submit,
                            inputDecoration: inputDecoration,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: 18),
                            child: _LoginHero(),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18),
                            child: _LoginFormCard(
                              formKey: formKey,
                              emailController: emailController,
                              passwordController: passwordController,
                              obscurePassword: obscurePassword,
                              isLoading: isLoading,
                              serverError: serverError,
                              onTogglePassword: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              onSubmit: submit,
                              inputDecoration: inputDecoration,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontSize: 36,
      fontWeight: FontWeight.w900,
      height: 1.05,
    );

    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white.withValues(alpha: 0.82),
    );

    return AppSurfaceCard(
      radius: AppTokens.radiusLg,
      gradient: AppTokens.heroGradient,
      border: BorderSide.none,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Controla tu mes con más claridad',
            style: titleStyle,
          ),
          const SizedBox(height: 12),
          Text(
            'GastoClaro te ayuda a ordenar pagos, vencimientos, ingresos y obligaciones sin perder contexto.',
            style: bodyStyle,
          ),
          const SizedBox(height: 24),
          const _HeroFeature(
            icon: Icons.calendar_month_outlined,
            title: 'Vista mensual real',
            subtitle: 'Entiende qué te presiona hoy y qué viene después.',
          ),
          const SizedBox(height: 14),
          const _HeroFeature(
            icon: Icons.payments_outlined,
            title: 'Pagos y seguimiento',
            subtitle: 'Registra movimientos y conserva el estado del periodo.',
          ),
          const SizedBox(height: 14),
          const _HeroFeature(
            icon: Icons.auto_graph_outlined,
            title: 'Lectura rápida',
            subtitle: 'Detecta pendientes, vencimientos y flujo con menos esfuerzo.',
          ),
        ],
      ),
    );
  }
}

class _HeroFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeroFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? serverError;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final InputDecoration Function({
  required String label,
  String? hint,
  Widget? suffixIcon,
  }) inputDecoration;

  const _LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.serverError,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.inputDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      radius: AppTokens.radiusLg,
      padding: const EdgeInsets.all(26),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iniciar sesión',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa con tu cuenta del backend de GastoClaro.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTokens.ink500,
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDecoration(
                label: 'Correo',
                hint: 'correo@ejemplo.com',
              ),
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
                hint: 'Tu contraseña',
                suffixIcon: IconButton(
                  onPressed: isLoading ? null : onTogglePassword,
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
              onFieldSubmitted: (_) => onSubmit(),
            ),
            if (serverError != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTokens.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(
                    color: AppTokens.danger.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  serverError!,
                  style: const TextStyle(
                    color: AppTokens.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onSubmit,
                icon: isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.login),
                label: Text(isLoading ? 'Ingresando...' : 'Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}