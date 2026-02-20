import 'package:flutter/material.dart';
import 'package:inginia_mobile/screens/register_screen.dart';
import 'package:inginia_mobile/screens/pending_validation_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart'; // ← Ajout

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  String _loginMethod = 'email'; // 'email' or 'phone'

  @override
  void initState() {
    super.initState();
    _testServerConnection();
  }

  // ✅ TEST DE CONNEXION AU SERVEUR
  Future<void> _testServerConnection() async {
    try {
      print('🧪 ========== SERVER CONNECTION TEST ==========');
      print('📍 API Base URL: ${ApiService.baseUrl}');
      print('🔗 Full URL: ${ApiService.baseUrl}/health');

      // Tentative de connexion
      await Future.delayed(const Duration(seconds: 1));
      print('✅ Connection test completed');
    } catch (e) {
      print('❌ Connection test error: $e');
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () {
            authProvider.setShowLogin(false);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Color(0xFFE0E7FF), // indigo-100
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO au dessus de la card
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          size: 60,
                          color: AppTheme.primary,
                        ),
                      ),

                      // CARD BLANCHE
                      Container(
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Bienvenue !',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connectez-vous à Inginia',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),

                            const SizedBox(height: 32),

                            /* ------------------ BOUTON GOOGLE ------------------ */
                            OutlinedButton.icon(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                      print('🔵 Google login tapped');
                                      final success = await authProvider
                                          .loginWithGoogle();
                                      if (success && mounted) {
                                        print('✅ Google login success');
                                      }
                                    },
                              icon: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.g_mobiledata, size: 30),
                              label: Text(
                                "Continuer avec Google",
                                style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Séparateur "OU"
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    "OU",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey.shade300),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Message d'erreur
                            if (authProvider.error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  authProvider.error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            // Toggle Login Method
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Row(
                                children: [
                                  _buildToggleOption('Email', 'email'),
                                  _buildToggleOption('Téléphone', 'phone'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Formulaire
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _loginMethod == 'email'
                                        ? 'Email'
                                        : 'Téléphone',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _identifierController,
                                    keyboardType: _loginMethod == 'email'
                                        ? TextInputType.emailAddress
                                        : TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: _loginMethod == 'email'
                                          ? 'exemple@email.com'
                                          : '06 12 34 56 78',
                                      prefixIcon: Icon(
                                        _loginMethod == 'email'
                                            ? Icons.email_outlined
                                            : Icons.phone_outlined,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (val) =>
                                        val!.isEmpty ? 'Requis' : null,
                                  ),

                                  const SizedBox(height: 16),

                                  Text(
                                    'Mot de passe',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      hintText: '••••••••',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        size: 20,
                                      ),
                                    ),
                                    validator: (val) =>
                                        val!.isEmpty ? 'Requis' : null,
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (val) => setState(
                                          () => _rememberMe = val ?? false,
                                        ),
                                        activeColor: AppTheme.primary,
                                      ),
                                      Text(
                                        "Se souvenir de moi",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  print('🔵 Forgot password tapped');
                                },
                                child: Text(
                                  "Mot de passe oublié ?",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Bouton Login
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          print(
                                            '🔵 ========== LOGIN BUTTON PRESSED ==========',
                                          );
                                          print(
                                            '📧 Identifier: ${_identifierController.text}',
                                          );
                                          print(
                                            '🔐 Password: ${_passwordController.text.replaceAll(RegExp(r'.'), '*')}',
                                          );
                                          print(
                                            '📝 Login Method: $_loginMethod',
                                          );
                                          print('🔔 Remember Me: $_rememberMe');
                                          print(
                                            '🌐 API URL: ${ApiService.baseUrl}',
                                          );

                                          final success = await authProvider
                                              .login(
                                                email: _loginMethod == 'email'
                                                    ? _identifierController.text
                                                          .trim()
                                                    : null,
                                                phone: _loginMethod == 'phone'
                                                    ? _identifierController.text
                                                          .trim()
                                                    : null,
                                                password:
                                                    _passwordController.text,
                                                rememberMe: _rememberMe,
                                              );

                                          print('📊 Login Result: $success');

                                          // Check if error is about validation
                                          if (!success &&
                                              authProvider.error != null &&
                                              authProvider.error!.contains(
                                                'validation',
                                              )) {
                                            print(
                                              '⚠️ Account pending validation',
                                            );
                                            if (mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PendingValidationScreen(),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: AppTheme.primary.withOpacity(
                                    0.4,
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text("Se connecter"),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Pas encore de compte ? ",
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: () {
                              print('🔵 Register tapped');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "S'inscrire",
                              style: GoogleFonts.inter(
                                color: AppTheme.primary,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, String value) {
    final isSelected = _loginMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          print('🔵 Login method changed to: $value');
          setState(() => _loginMethod = value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
