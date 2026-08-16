import 'package:flutter/material.dart';
import 'package:smartcare/core/auth_service.dart';
import 'package:smartcare/screens/hospital_dashboard_screen.dart';
import 'package:smartcare/screens/patient_hospital_list_screen.dart';
import 'package:smartcare/screens/admin_hospital_approval_screen.dart';

void main() {
  runApp(const SmartCareApp());
}

// ============================================================================
// APP ROOT
// ============================================================================

class SmartCareApp extends StatelessWidget {
  const SmartCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCare',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A896),
          brightness: Brightness.dark,
          primary: const Color(0xFF00A896),
          secondary: const Color(0xFF028090),
          tertiary: const Color(0xFFF0F3F4),
          surface: const Color(0xFF131B2E),
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF00A896),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================================
// AUTH GATE - Checks saved token and routes accordingly
// ============================================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}

// ============================================================================
// LOGIN SCREEN
// ============================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        // Fetch user profile after login
        final meResult = await AuthService.getMe();
        if (meResult['success'] == true && mounted) {
          final role = meResult['data']['role'] as String;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RoleBasedHome(role: role, userData: meResult['data']),
            ),
          );
        }
      } else {
        setState(() => _errorMessage = result['error'] as String?);
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Connection error. Is the backend running?',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Brand
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00A896,
                              ).withOpacity(0.2 * _glowController.value),
                              blurRadius: 20.0 * _glowController.value,
                              spreadRadius: 5.0 * _glowController.value,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Color(0xFF00A896),
                          size: 56,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00A896), Color(0xFF028090)],
                    ).createShader(bounds),
                    child: const Text(
                      'SMARTCARE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      'Email Address',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Password', Icons.lock_outline)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white38,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A896),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'SIGN IN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white38),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            color: Color(0xFF00A896),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF131B2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00A896), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

// ============================================================================
// REGISTER SCREEN
// ============================================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'patient';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  final List<Map<String, String>> _roles = [
    {'value': 'patient', 'label': 'Patient', 'icon': 'person'},
    {
      'value': 'hospital_staff',
      'label': 'Hospital Staff',
      'icon': 'local_hospital',
    },
    {
      'value': 'hospital_admin',
      'label': 'Hospital Admin',
      'icon': 'admin_panel_settings',
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
      );

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful! Please sign in.'),
            backgroundColor: const Color(0xFF00A896),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _errorMessage = result['error'] as String?);
      }
    } catch (e) {
      setState(
        () => _errorMessage = 'Connection error. Is the backend running?',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00A896), Color(0xFF028090)],
                  ).createShader(bounds),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join the SmartCare network',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // Error
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Full Name',
                    Icons.person_outline,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Full name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Email Address',
                    Icons.email_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Phone Number',
                    Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Password', Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _inputDecoration(
                        'Confirm Password',
                        Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white38,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Role Selection
                const Text(
                  'Select your role',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role['value'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRole = role['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00A896).withOpacity(0.15)
                              : const Color(0xFF131B2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00A896)
                                : const Color(0xFF1E293B),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              role['value'] == 'patient'
                                  ? Icons.person_rounded
                                  : role['value'] == 'hospital_staff'
                                  ? Icons.local_hospital_rounded
                                  : Icons.admin_panel_settings_rounded,
                              color: isSelected
                                  ? const Color(0xFF00A896)
                                  : Colors.white38,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              role['label']!,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF00A896)
                                    : Colors.white54,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A896),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login CTA
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(color: Colors.white38),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFF00A896),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF131B2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00A896), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

// ============================================================================
// ROLE-BASED HOME - Routes to role-specific dashboards
// ============================================================================

class RoleBasedHome extends StatelessWidget {
  final String role;
  final Map<String, dynamic> userData;

  const RoleBasedHome({super.key, required this.role, required this.userData});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'patient':
        return PatientDashboard(userData: userData);
      case 'hospital_staff':
        return HospitalStaffDashboard(userData: userData);
      case 'hospital_admin':
        return HospitalAdminDashboard(userData: userData);
      case 'system_admin':
        return SystemAdminDashboard(userData: userData);
      default:
        return PatientDashboard(userData: userData);
    }
  }
}

// ============================================================================
// SHARED DASHBOARD SHELL
// ============================================================================

class _DashboardShell extends StatelessWidget {
  final String title;
  final String roleLabel;
  final Color accentColor;
  final IconData roleIcon;
  final Map<String, dynamic> userData;
  final List<_DashboardTile> tiles;

  const _DashboardShell({
    required this.title,
    required this.roleLabel,
    required this.accentColor,
    required this.roleIcon,
    required this.userData,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B2E),
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.health_and_safety_rounded,
              color: const Color(0xFF00A896),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'SmartCare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.clearAuth();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.15),
                      const Color(0xFF131B2E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accentColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(roleIcon, color: accentColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['full_name'] ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Dashboard Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Tiles Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) {
                  final tile = tiles[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF131B2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (tile.onTap != null) {
                          tile.onTap!();
                        } else {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${tile.label} will be implemented in Phase 4+',
                              ),
                              backgroundColor: const Color(0xFF131B2E),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: tile.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                tile.icon,
                                color: tile.color,
                                size: 24,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tile.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tile.subtitle,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTile {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _DashboardTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

// ============================================================================
// PATIENT DASHBOARD
// ============================================================================

class PatientDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const PatientDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return _DashboardShell(
      title: 'Patient Services',
      roleLabel: 'PATIENT',
      accentColor: const Color(0xFF00A896),
      roleIcon: Icons.person_pin_circle_rounded,
      userData: userData,
      tiles: [
        _DashboardTile(
          label: 'Nearby Hospitals',
          subtitle: 'Find hospitals near you',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF00A896),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PatientHospitalListScreen(),
              ),
            );
          },
        ),
        const _DashboardTile(
          label: 'Bed Availability',
          subtitle: 'Real-time bed status',
          icon: Icons.bed_rounded,
          color: Colors.blue,
        ),
        const _DashboardTile(
          label: 'Emergency',
          subtitle: 'Request emergency help',
          icon: Icons.emergency_rounded,
          color: Colors.redAccent,
        ),
        const _DashboardTile(
          label: 'My Requests',
          subtitle: 'Track your requests',
          icon: Icons.history_rounded,
          color: Colors.orange,
        ),
        const _DashboardTile(
          label: 'Resources',
          subtitle: 'View hospital resources',
          icon: Icons.inventory_2_rounded,
          color: Colors.purple,
        ),
        const _DashboardTile(
          label: 'Profile',
          subtitle: 'Manage your profile',
          icon: Icons.account_circle_rounded,
          color: Colors.teal,
        ),
      ],
    );
  }
}

// ============================================================================
// HOSPITAL STAFF DASHBOARD
// ============================================================================

class HospitalStaffDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const HospitalStaffDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return _DashboardShell(
      title: 'Hospital Operations',
      roleLabel: 'HOSPITAL STAFF',
      accentColor: Colors.blue,
      roleIcon: Icons.local_hospital_rounded,
      userData: userData,
      tiles: const [
        _DashboardTile(
          label: 'Bed Management',
          subtitle: 'Update bed statuses',
          icon: Icons.bed_rounded,
          color: Colors.blue,
        ),
        _DashboardTile(
          label: 'Resources',
          subtitle: 'Update resource counts',
          icon: Icons.inventory_2_rounded,
          color: Color(0xFF00A896),
        ),
        _DashboardTile(
          label: 'Emergencies',
          subtitle: 'Handle incoming requests',
          icon: Icons.emergency_rounded,
          color: Colors.redAccent,
        ),
        _DashboardTile(
          label: 'Ward Overview',
          subtitle: 'View all wards',
          icon: Icons.dashboard_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }
}

// ============================================================================
// HOSPITAL ADMIN DASHBOARD
// ============================================================================

class HospitalAdminDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const HospitalAdminDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return HospitalDashboardScreen(userData: userData);
  }
}

// ============================================================================
// SYSTEM ADMIN DASHBOARD
// ============================================================================

class SystemAdminDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  const SystemAdminDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return _DashboardShell(
      title: 'System Control Panel',
      roleLabel: 'SYSTEM ADMIN',
      accentColor: Colors.amber,
      roleIcon: Icons.shield_rounded,
      userData: userData,
      tiles: [
        _DashboardTile(
          label: 'Verify Hospitals',
          subtitle: 'Review pending hospitals',
          icon: Icons.verified_rounded,
          color: Colors.amber,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminHospitalApprovalScreen(),
              ),
            );
          },
        ),
        const _DashboardTile(
          label: 'User Management',
          subtitle: 'Manage all users',
          icon: Icons.people_alt_rounded,
          color: Colors.blue,
        ),
        _DashboardTile(
          label: 'All Hospitals',
          subtitle: 'View & manage hospitals',
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFF00A896),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminHospitalApprovalScreen(),
              ),
            );
          },
        ),
        const _DashboardTile(
          label: 'System Monitoring',
          subtitle: 'View system health',
          icon: Icons.monitor_heart_rounded,
          color: Colors.redAccent,
        ),
        const _DashboardTile(
          label: 'Analytics',
          subtitle: 'Platform-wide metrics',
          icon: Icons.analytics_rounded,
          color: Colors.purple,
        ),
        const _DashboardTile(
          label: 'Audit Logs',
          subtitle: 'View activity logs',
          icon: Icons.history_rounded,
          color: Colors.orange,
        ),
      ],
    );
  }
}
