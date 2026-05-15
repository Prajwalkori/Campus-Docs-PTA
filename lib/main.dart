import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:file_picker/file_picker.dart';
import 'src/upload_helper.dart';


final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ikdnjepfbpgmapugavkk.supabase.co',
    anonKey: 'sb_publishable_wuAfvHZpkInnin-zICK3Gw_7z_Js66j',
  );

  runApp(const CampusDocsApp());
}

/* ---------------- APP ROOT ---------------- */
class CampusDocsApp extends StatelessWidget {
  const CampusDocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Docs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B46C1),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: const Color(0xFF1F2937),
                displayColor: const Color(0xFF1F2937),
              ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}





/* ---------------- AUTH GATE ---------------- */
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (mounted) {
        if (session == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const UnifiedLoginScreen()),
            (r) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleRouter()),
            (r) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check current session
    final session = supabase.auth.currentSession;

    if (session == null) {
      return const UnifiedLoginScreen();
    }

    return const RoleRouter();
  }
}

// Simple: Get user role (admin or student)
Future<String> getUserRole() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return 'student';
    
    // Failsafe: Always treat the default admin email as admin
    // This bypasses potential RLS/database sync issues
    if (user.email == 'admin@campusdocs.com') return 'admin';
    
    // Get role from profile
    final res = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    
    if (res != null && res['role'] is String) {
      return res['role'] as String;
    }
    
    // No profile found - default to student
    return 'student';
  } catch (_) {
    return 'student';
  }
}



/* ---------------- SPLASH SCREEN ---------------- */
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _fadeController.forward();
    _scaleController.forward();
    _rotateController.repeat();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7F3CFF), Color(0xFFAB47BC), Color(0xFF6B46C1)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 70,
                      color: Color(0xFF6B46C1),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Campus Docs',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Academic Resources Hub',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                RotationTransition(
                  turns: _rotateAnimation,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
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

/* ---------------- SIMPLE LOGIN SCREEN ---------------- */
/* ---------------- SIMPLE LOGIN SCREEN (Removed) ---------------- */
// class LoginScreen has been removed as part of the auth refactor.


/* ---------------- UNIFIED LOGIN SCREEN ---------------- */
class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter User ID and password')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Construct email from User ID
      final email = '${_emailCtrl.text.trim()}@campusdocs.com';
      
      await supabase.auth.signInWithPassword(
        email: email,
        password: _passCtrl.text,
      );

      if (context.mounted) {
         Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleRouter()),
            (r) => false,
          );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().toLowerCase();
        String errorMsg = 'Login failed. Please check your credentials.';
        
        if (msg.contains('confirm') || msg.contains('verify')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Supabase Config Required'),
              content: const Text('Please disable "Confirm email" in your Supabase Dashboard -> Authentication -> Providers -> Email.\n\nSince we are using User IDs, email confirmation must be turned off.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
          return;
        }

        if (msg.contains('invalid') || msg.contains('wrong')) {
          errorMsg = 'Invalid User ID or password.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickAdminLogin() async {
    // 1. Ask for Admin Key first
    final keyController = TextEditingController();
    final bool? authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter the Admin Secret Key to continue:'),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Secret Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Use the same key as the Sign Up screen
              if (keyController.text.trim() == 'CAMPUS_ADMIN_2024') {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Invalid Admin Key')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (authorized != true) return;

    // 2. Proceed with Quick Login
    _emailCtrl.text = 'admin'; 
    _passCtrl.text = 'admin123';
    
    setState(() => _loading = true);
    
    try {
      final email = 'admin@campusdocs.com';
      try {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: _passCtrl.text,
        );
        
        if (response.user == null) throw Exception('Login failed');

        if (mounted) {
           Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const RoleRouter()), 
            (r) => false
          );
        }
      } catch (loginError) {
         final msg = loginError.toString().toLowerCase();
         if (msg.contains('invalid') || msg.contains('credential')) {
             final signUpRes = await supabase.auth.signUp(
                 email: email,
                 password: _passCtrl.text,
                 data: {'name': 'Administrator'}
             );
             
             if (signUpRes.user != null) {
                 try {
                   await supabase.from('profiles').upsert({
                       'id': signUpRes.user!.id,
                       'email': email,
                       'name': 'Administrator',
                       'role': 'admin'
                   });
                 } catch (postgrestErr) {
                   print('Profile setup warning: $postgrestErr');
                 }
                 
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin login successful!')),
                    );
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (_) => const RoleRouter()), 
                      (r) => false
                    );
                 }
                 return;
             }
         }
         throw loginError;
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('confirm') || msg.contains('verify')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Supabase Config Required'),
              content: const Text('Please disable "Confirm email" in your Supabase Dashboard -> Authentication -> Providers -> Email.\n\nSince we are using User IDs, email confirmation must be turned off.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quick login error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF6B46C1),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 50,
                      color: Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome Back',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your User ID to continue',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _emailCtrl,
                          // textInputAction: TextInputAction.next, // Optional improvement
                          decoration: InputDecoration(
                            labelText: 'User ID',
                            hintText: 'e.g. student123',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                          SizedBox(
                            height: 45,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _quickAdminLogin,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B46C1),
                                side: const BorderSide(color: Color(0xFF6B46C1), width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.flash_on, size: 18),
                              label: Text(
                                'Quick Login (Default Admin)',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B46C1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account? ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UnifiedSignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B46C1),
                                ),
                              ),
                            ),
                          ],
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
}

/* ---------------- UNIFIED SIGN UP SCREEN ---------------- */
class UnifiedSignUpScreen extends StatefulWidget {
  const UnifiedSignUpScreen({super.key});

  @override
  State<UnifiedSignUpScreen> createState() => _UnifiedSignUpScreenState();
}

class _UnifiedSignUpScreenState extends State<UnifiedSignUpScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _adminKeyCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'student'; // Default role

  // Admin key for security (change this to your preferred key)
  static const String adminSecretKey = 'CAMPUS_ADMIN_2024';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nameCtrl.dispose();
    _adminKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validation
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Admin key verification
    if (_selectedRole == 'admin') {
      if (_adminKeyCtrl.text != adminSecretKey) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid admin key. Please contact system administrator.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      // Create email from User ID
      final email = '${_emailCtrl.text.trim()}@campusdocs.com';
      
      // Create account
      final response = await supabase.auth.signUp(
        email: email,
        password: _passCtrl.text,
        data: {'name': _nameCtrl.text.trim()},
      );

      if (response.user == null) {
        throw Exception('Failed to create account');
      }

      // Create profile with selected role
      await supabase.from('profiles').upsert({
        'id': response.user!.id,
        'email': email,
        'name': _nameCtrl.text.trim(),
        'role': _selectedRole,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! You can now login.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const UnifiedLoginScreen(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().toLowerCase();
        String errorMsg = 'Sign up failed. Please try again.';
        
        if (msg.contains('already registered') || msg.contains('user already exists')) {
          errorMsg = 'User ID already exists. Please login or choose another.';
        } else if (msg.contains('invalid email')) {
          errorMsg = 'Invalid User ID format.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: const Color(0xFF6B46C1),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 50,
                      color: Color(0xFF6B46C1),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join Campus Docs today',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Role',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: const [
                            DropdownMenuItem(value: 'student', child: Text('Student')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                        if (_selectedRole == 'admin') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _adminKeyCtrl,
                            decoration: InputDecoration(
                              labelText: 'Admin Key',
                              prefixIcon: const Icon(Icons.vpn_key_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailCtrl,
                          // keyboardType: TextInputType.emailAddress, // No longer email
                          decoration: InputDecoration(
                            labelText: 'User ID',
                            hintText: 'Create a unique User ID',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'At least 6 characters',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B46C1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Sign Up',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UnifiedLoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B46C1),
                                ),
                              ),
                            ),
                          ],
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
}


// ... Keep your DepartmentScreen, HomeScreen, SubjectsScreen, 
// DocumentsScreen, and SubjectsData classes as they were ...
// Ensure you don't duplicate any of them.
// ---------------- ROUTING & DASHBOARDS ----------------

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? 'student';
        if (role == 'admin') {
          return const AdminDashboardScreen();
        } else {
          return const StudentDashboardScreen();
        }
      },
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late Animation<double> _listAnimation;

  // Reusing the same departments list for now
  static const List<Map<String, dynamic>> departments = _StudentDashboardScreenState.departments;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _listAnimation = CurvedAnimation(parent: _listController, curve: Curves.easeOutCubic);
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)]), 
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF3B82F6), // Blue for Admin
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await supabase.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthGate()), (r) => false);
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Admin Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                  ),
                  child: const Center(child: Icon(Icons.admin_panel_settings, size: 90, color: Colors.white54)),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                   // ... Reusing logic for list items ...
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 12),
                     child: DepartmentCard(
                       department: departments[index],
                       onTap: () {
                          // Admin Navigates to Home Screen too, where they can edit/add
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(department: departments[index]['name'])));
                       },
                     ),
                   );
                }, childCount: departments.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late Animation<double> _listAnimation;

  static const List<Map<String, dynamic>> departments = [
    {
      'name': 'Computer Science',
      'icon': Icons.computer,
      'color': Color(0xFF6B46C1),
      'gradient': [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
    },
    {
      'name': 'Artificial Intelligence & Data Science',
      'icon': Icons.psychology,
      'color': Color(0xFF10B981),
      'gradient': [Color(0xFF10B981), Color(0xFF34D399)],
    },
    {
      'name': 'Electrical Engineering',
      'icon': Icons.electrical_services,
      'color': Color(0xFFF59E0B),
      'gradient': [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    },
    {
      'name': 'Mechanical Engineering',
      'icon': Icons.engineering,
      'color': Color(0xFF8B5A2B),
      'gradient': [Color(0xFF8B5A2B), Color(0xFFD97706)],
    },
    {
      'name': 'Civil Engineering',
      'icon': Icons.foundation,
      'color': Color(0xFF059669),
      'gradient': [Color(0xFF059669), Color(0xFF10B981)],
    },
    {
      'name': 'Energy Engineering',
      'icon': Icons.energy_savings_leaf,
      'color': Color(0xFF7C3AED),
      'gradient': [Color(0xFF7C3AED), Color(0xFFD6BCFA)],
    },
    {
      'name': 'Electronics Engineering',
      'icon': Icons.memory,
      'color': Color(0xFFDC2626),
      'gradient': [Color(0xFFDC2626), Color(0xFFF87171)],
    },
    {
      'name': 'Architecture Engineering',
      'icon': Icons.architecture,
      'color': Color(0xFF1E293B),
      'gradient': [Color(0xFF1E293B), Color(0xFF64748B)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _listAnimation = CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF6B46C1),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    try {
                      await supabase.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthGate()),
                          (r) => false,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Logout error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  tooltip: 'Logout',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Select Department',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 90,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AnimatedBuilder(
                animation: _listAnimation,
                builder: (context, child) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final delay = index * 0.08;
                      final rawValue = _listAnimation.value - delay;
                      final curvedValue = Curves.easeOutCubic.transform(
                        rawValue.clamp(0.0, 1.0),
                      );
                      final animationValue = curvedValue.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 40 * (1 - animationValue)),
                        child: Opacity(
                          opacity: animationValue,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DepartmentCard(
                              department: departments[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) =>
                                        HomeScreen(
                                      department: departments[index]['name'],
                                    ),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    }, childCount: departments.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DepartmentCard extends StatefulWidget {
  final Map<String, dynamic> department;
  final VoidCallback onTap;

  const DepartmentCard({
    super.key,
    required this.department,
    required this.onTap,
  });

  @override
  State<DepartmentCard> createState() => _DepartmentCardState();
}

class _DepartmentCardState extends State<DepartmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _hoverAnimation,
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) => _hoverController.reverse(),
        onTapCancel: () => _hoverController.reverse(),
        onTap: widget.onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.department['gradient'],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.department['color'].withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.department['icon'],
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    widget.department['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String department;
  const HomeScreen({super.key, required this.department});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _gridController;
  late Animation<double> _gridAnimation;

  final List<Map<String, dynamic>> semesters = [
    {
      'name': '1st',
      'color': Color(0xFF6B46C1),
      'icon': Icons.looks_one_rounded,
    },
    {
      'name': '2nd',
      'color': Color(0xFF8B5CF6),
      'icon': Icons.looks_two_rounded,
    },
    {'name': '3rd', 'color': Color(0xFF06B6D4), 'icon': Icons.looks_3_rounded},
    {'name': '4th', 'color': Color(0xFF10B981), 'icon': Icons.looks_4_rounded},
    {'name': '5th', 'color': Color(0xFFF59E0B), 'icon': Icons.looks_5_rounded},
    {'name': '6th', 'color': Color(0xFFEF4444), 'icon': Icons.looks_6_rounded},
    {'name': '7th', 'color': Color(0xFF8B5A2B), 'icon': Icons.filter_7_rounded},
    {'name': '8th', 'color': Color(0xFF7C3AED), 'icon': Icons.filter_8_rounded},
    {'name': '9th', 'color': Color(0xFFEC4899), 'icon': Icons.filter_9_rounded},
    {
      'name': '10th',
      'color': Color(0xFF1E293B),
      'icon': Icons.filter_9_plus_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridController,
      curve: Curves.easeOutCubic,
    );
    _gridController.forward();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semesterCount =
        widget.department == 'Architecture Engineering' ? 10 : 8;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FE)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF6B46C1),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.department,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.book_rounded,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AnimatedBuilder(
                animation: _gridAnimation,
                builder: (context, child) {
                  return SliverToBoxAdapter(
                    child: StaggeredGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: List.generate(semesterCount, (index) {
                        final delay = index * 0.08;
                        final animationValue = Curves.easeOutCubic.transform(
                          (_gridAnimation.value - delay).clamp(0.0, 1.0),
                        );
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - animationValue)),
                          child: Opacity(
                            opacity: animationValue,
                            child: SemesterCard(
                              semester: semesters[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) =>
                                        SubjectsScreen(
                                      semester: semesters[index]['name'],
                                      department: widget.department,
                                    ),
                                    transitionsBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SemesterCard extends StatefulWidget {
  final Map<String, dynamic> semester;
  final VoidCallback onTap;

  const SemesterCard({super.key, required this.semester, required this.onTap});

  @override
  State<SemesterCard> createState() => _SemesterCardState();
}

class _SemesterCardState extends State<SemesterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: GestureDetector(
        onTapDown: (_) => _bounceController.forward(),
        onTapUp: (_) => _bounceController.reverse(),
        onTapCancel: () => _bounceController.reverse(),
        onTap: widget.onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.semester['color'],
                        widget.semester['color'].withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.semester['color'].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      widget.semester['icon'],
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.semester['name']} Semester',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.semester['color'],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectsScreen extends StatefulWidget {
  final String semester;
  final String department;

  const SubjectsScreen({
    super.key,
    required this.semester,
    required this.department,
  });

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen>
    with TickerProviderStateMixin {
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController.forward();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departmentSubjects = SubjectsData.subjects[widget.department] ?? {};
    final subjects = departmentSubjects[widget.semester] ?? [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF3B82F6),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '${widget.semester} Semester',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.book_rounded,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
            subjects.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No subjects available',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: AnimatedBuilder(
                      animation: _listController,
                      builder: (context, child) {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final delay = index * 0.08;
                            final rawValue = _listController.value - delay;
                            final curvedValue = Curves.easeOutCubic.transform(
                              rawValue.clamp(0.0, 1.0),
                            );
                            final animationValue = curvedValue.clamp(0.0, 1.0);

                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - animationValue)),
                              child: Opacity(
                                opacity: animationValue,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SubjectCard(
                                    subject: subjects[index],
                                    index: index,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) =>
                                              DocumentsScreen(
                                            subject: subjects[index],
                                          ),
                                          transitionsBuilder: (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          }, childCount: subjects.length),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class SubjectCard extends StatefulWidget {
  final String subject;
  final int index;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  final List<Color> cardColors = [
    Color(0xFF6B46C1),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = cardColors[widget.index % cardColors.length];

    return ScaleTransition(
      scale: _pressAnimation,
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) => _pressController.reverse(),
        onTapCancel: () => _pressController.reverse(),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.subject,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentsScreen extends StatefulWidget {
  final String subject;
  const DocumentsScreen({super.key, required this.subject});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _docs = [];
  bool _docsLoading = true;
  bool _isAdmin = false;
  
  // Admin Upload Controllers
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  PlatformFile? _selectedFile;
  String _selectedType = 'Notes'; // Default type
  final List<String> _docTypes = ['Notes', 'PYQ', 'Lecture Material', 'Internal Paper', 'Test Paper', 'Lab Manual'];

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _fetchDocs();
  }

  Future<void> _checkRole() async {
    final role = await getUserRole();
    if (mounted) setState(() => _isAdmin = role == 'admin');
  }

  Future<void> _fetchDocs() async {
    setState(() => _docsLoading = true);
    try {
      final res = await supabase
          .from('documents')
          .select()
          .eq('subject', widget.subject)
          .order('created_at', ascending: false);
      if (res is List) {
        setState(() => _docs = List<Map<String, dynamic>>.from(res));
      } else {
        setState(() => _docs = []);
      }
    } catch (e) {
      if (mounted) setState(() => _docs = []);
    } finally {
      if (mounted) setState(() => _docsLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _showAddDocumentDialog() {
    _titleCtrl.clear();
    _urlCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _selectedFile = null;
      _selectedType = 'Notes';
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Upload Material', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => _selectedType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_selectedFile != null)
                              ListTile(
                                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                title: Text(_selectedFile!.name, overflow: TextOverflow.ellipsis),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setDialogState(() => _selectedFile = null),
                                ),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final res = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                    withData: true,
                                  );
                                  if (res != null) {
                                    setDialogState(() => _selectedFile = res.files.first);
                                  }
                                },
                                icon: const Icon(Icons.upload),
                                label: const Text('Select PDF'),
                              ),
                            const Divider(),
                            TextField(
                              controller: _urlCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Or Enter URL',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.link),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _uploadDocument(context),
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadDocument(BuildContext dialogContext) async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    
    // Check if we have file or URL
    if (_selectedFile == null && _urlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a File or URL')));
      return;
    }

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading...')));
    
    try {
      String? finalUrl = _urlCtrl.text.trim();
      
      if (_selectedFile != null) {
        final pf = _selectedFile!;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${pf.name.replaceAll(' ', '_')}';
        final bytes = await readPlatformFileBytes(pf);
        
        if (bytes != null) {
           try {
             await supabase.storage.from('documents').uploadBinary(
                fileName,
                Uint8List.fromList(bytes),
                fileOptions: const FileOptions(upsert: false),
             );
           } catch (storageError) {
             // If bucket not found, try to create it (public by default for simplicity here)
             // Note: This often requires higher privileges, so if it fails we notify the user.
             if (storageError.toString().contains('bucket') || storageError.toString().contains('not found')) {
                try {
                  await supabase.storage.createBucket('documents', const BucketOptions(public: true));
                  // Retry upload
                  await supabase.storage.from('documents').uploadBinary(
                    fileName,
                    Uint8List.fromList(bytes),
                    fileOptions: const FileOptions(upsert: false),
                  );
                } catch (createErr) {
                   throw Exception('Storage bucket "documents" not found. Please create it in your Supabase Dashboard -> Storage.');
                }
             } else {
               rethrow;
             }
           }
           finalUrl = supabase.storage.from('documents').getPublicUrl(fileName);
        }
      }

      await supabase.from('documents').insert({
        'title': _titleCtrl.text.trim(),
        'description': '[${_selectedType}] ${_descCtrl.text.trim()}',
        'url': finalUrl,
        'subject': widget.subject,
        'uploaded_by': supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (dialogContext.mounted) Navigator.pop(dialogContext);
      _fetchDocs();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload Successful!')));

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // 1. Delete from Storage if it's a hosted file
      final String? url = doc['url'];
      if (url != null && url.contains('/storage/v1/object/public/documents/')) {
        try {
          final uri = Uri.parse(url);
          // specific to supabase public url structure
          final int documentsIndex = uri.pathSegments.indexOf('documents');
          if (documentsIndex != -1 && documentsIndex < uri.pathSegments.length - 1) {
             final fileName = uri.pathSegments.sublist(documentsIndex + 1).join('/');
             await supabase.storage.from('documents').remove([fileName]);
          }
        } catch (_) {
          // Ignore parsing errors, just proceed to DB delete
        }
      }

      // 2. Delete from DB
      // Use select() to get back the deleted row. If RLS blocks it, this list will be empty.
      final List<dynamic> deletedRows = await supabase
          .from('documents')
          .delete()
          .eq('id', doc['id'])
          .select();

      if (deletedRows.isEmpty) {
        throw Exception('Delete failed. You may not have permission (Check RLS policies).');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted successfully')),
        );
        _fetchDocs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: ${e.toString().replaceAll('Exception:', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isAdmin 
          ? FloatingActionButton.extended(
              onPressed: _showAddDocumentDialog,
              label: const Text('Add Material'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF3B82F6),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF3B82F6),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '${widget.subject} Documents',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.folder_open_rounded,
                      size: 90,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _fadeController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                      child: Column(
                        children: _docsLoading
                            ? [const SizedBox(height: 48), const Center(child: CircularProgressIndicator())]
                            : _docs.isEmpty
                                ? [Center(child: Text('No documents available for this subject', style: GoogleFonts.poppins(fontSize: 16)))]
                                : _docs.map((doc) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: DocumentCard(
                                        document: {
                                          'name': doc['title'] ?? 'Untitled',
                                          'description': doc['description'] ?? '',
                                          'color': const Color(0xFF3B82F6),
                                          'url': doc['url'],
                                        },
                                        index: 0,
                                        showDelete: _isAdmin,
                                        onDelete: () => _deleteDocument(doc),
                                        onTap: () {
                                          final url = doc['url'] as String?;
                                          if (url != null && url.isNotEmpty) launchUrlString(url);
                                        },
                                      ),
                                    );
                                  }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)), // Space for FAB
          ],
        ),
      ),
    );
  }
}

class DocumentCard extends StatefulWidget {
  final Map<String, dynamic> document;
  final int index;
  final bool showDelete;
  final VoidCallback? onDelete;
  final VoidCallback onTap;

  const DocumentCard({
    super.key,
    required this.document,
    required this.index,
    this.showDelete = false,
    this.onDelete,
    required this.onTap,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value,
            child: Transform.scale(
              scale: 1.0 - (_hoverAnimation.value * 0.015),
                child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.document['color'] as Color? ?? Colors.blue).withOpacity(
                        0.25 + (_hoverAnimation.value * 0.15),
                      ),
                      blurRadius: 12 + (_hoverAnimation.value * 8),
                      offset: Offset(0, 6 + (_hoverAnimation.value * 3)),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(-2, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (widget.document['color'] as Color?) ?? Colors.blue,
                            ((widget.document['color'] as Color?) ?? Colors.blue).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        (widget.document['icon'] as IconData?) ?? Icons.picture_as_pdf_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.document['name'] ?? 'Untitled',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.document['description'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        children: [
                          if (widget.showDelete && widget.onDelete != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: widget.onDelete,
                              ),
                            ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: widget.document['color'],
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String assetPath;
  final String documentName;

  const PdfViewerScreen({
    super.key,
    required this.assetPath,
    required this.documentName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _rotateController;
  // late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF475569), Color(0xFF64748B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.documentName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'PDF Viewer',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Coming Soon',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Integrating PDF viewer functionality...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectsData {
  static const Map<String, Map<String, List<String>>> subjects = {
    'Computer Science': {
      '1st': [
        'Mathematics 1',
        'Physics',
        'Computer Programming',
        'Digital Logic',
        'Communication Skills',
      ],
      '2nd': [
        'Mathematics 2',
        'Chemistry',
        'C Programming',
        'Data Structures',
        'Circuit Theory',
      ],
      '3rd': [
        'Mathematics 3',
        'Data Structures',
        'OOPs using C++',
        'Computer Architecture',
        'Discrete Mathematics',
      ],
      '4th': [
        'Mathematics 4',
        'Operating System',
        'DBMS',
        'Algorithms',
        'Computer Networks',
      ],
      '5th': [
        'Data Science',
        'Programming with Java',
        'Management & Entrepreneurship',
        'Software Engineering',
        'Web Technologies',
      ],
      '6th': [
        'Software Engineering',
        'Internet Of Things',
        'Big Data Analytics',
        'Computer Graphics',
        'Cyber Security',
      ],
      '7th': [
        'Machine Learning',
        'Artificial Intelligence',
        'Project Management',
        'Cloud Computing',
        'Mobile Computing',
      ],
      '8th': [
        'Blockchain Technology',
        'Cloud Computing',
        'Final Year Project',
        'Advanced Algorithms',
        'Ethics in Computing',
      ],
    },
    'Artificial Intelligence & Data Science': {
      '1st': [
        'Mathematics 1',
        'AI Fundamentals',
        'Computer Programming',
        'Statistics',
        'Linear Algebra',
      ],
      '2nd': [
        'Mathematics 2',
        'Data Structures',
        'Python Programming',
        'Probability',
        'Database Systems',
      ],
      '3rd': [
        'Statistics',
        'Machine Learning',
        'Database Management',
        'Data Visualization',
        'Optimization Techniques',
      ],
      '4th': [
        'Deep Learning',
        'Big Data Analytics',
        'Cloud Computing',
        'Computer Vision',
        'Data Mining',
      ],
      '5th': [
        'Natural Language Processing',
        'Computer Vision',
        'AI Ethics',
        'Reinforcement Learning',
        'Time Series Analysis',
      ],
      '6th': [
        'Robotics',
        'Reinforcement Learning',
        'AI Security',
        'Distributed Systems',
        'Knowledge Representation',
      ],
      '7th': [
        'Advanced ML Algorithms',
        'Neural Networks',
        'Data Mining',
        'AI for Healthcare',
        'Graph Theory',
      ],
      '8th': [
        'AI Research Project',
        'Industry Internship',
        'Thesis',
        'Big Data Systems',
        'AI Policy',
      ],
    },
    'Electrical Engineering': {
      '1st': [
        'Circuit Analysis',
        'Digital Logic Design',
        'Electromagnetics',
        'Mathematics 1',
        'Physics',
      ],
      '2nd': [
        'Power Systems',
        'Control Systems',
        'Electronics',
        'Mathematics 2',
        'Signals and Systems',
      ],
      '3rd': [
        'Signals and Systems',
        'Communication Systems',
        'Microprocessors',
        'Network Analysis',
        'Electrical Machines',
      ],
      '4th': [
        'Power Electronics',
        'Renewable Energy',
        'Electric Machines',
        'Control Engineering',
        'Electromagnetic Fields',
      ],
      '5th': [
        'Embedded Systems',
        'VLSI Design',
        'Robotics',
        'Digital Signal Processing',
        'Power System Analysis',
      ],
      '6th': [
        'High Voltage Engineering',
        'Power System Protection',
        'Digital Signal Processing',
        'Microcontrollers',
        'Energy Systems',
      ],
      '7th': [
        'Smart Grid Technology',
        'Electric Vehicle Systems',
        'Advanced Control',
        'Power Quality',
        'Instrumentation',
      ],
      '8th': [
        'Power System Optimization',
        'Industrial Automation',
        'Final Project',
        'Renewable Energy Systems',
        'HVDC Systems',
      ],
    },
    'Mechanical Engineering': {
      '1st': [
        'Engineering Mechanics',
        'Thermodynamics',
        'Manufacturing Processes',
        'Mathematics 1',
        'Engineering Drawing',
      ],
      '2nd': [
        'Fluid Mechanics',
        'Heat Transfer',
        'Machine Design',
        'Materials Science',
        'Mathematics 2',
      ],
      '3rd': [
        'Kinematics of Machines',
        'Dynamics of Machines',
        'Materials Science',
        'Strength of Materials',
        'Thermal Engineering',
      ],
      '4th': [
        'Metrology and Instrumentation',
        'Automobile Engineering',
        'CAD/CAM',
        'Fluid Dynamics',
        'Manufacturing Technology',
      ],
      '5th': [
        'Production Technology',
        'Robotics',
        'Renewable Energy',
        'Finite Element Analysis',
        'Heat Exchangers',
      ],
      '6th': [
        'Mechanical Vibrations',
        'Finite Element Analysis',
        'Mechatronics',
        'Refrigeration and AC',
        'Industrial Engineering',
      ],
      '7th': [
        'Advanced Manufacturing',
        'Automotive Systems',
        'Design Optimization',
        'Tribology',
        'Computational Fluid Dynamics',
      ],
      '8th': [
        'Industrial Engineering',
        'Quality Control',
        'Capstone Project',
        'Additive Manufacturing',
        'Energy Management',
      ],
    },
    'Civil Engineering': {
      '1st': [
        'Engineering Drawing',
        'Surveying',
        'Material Science',
        'Mathematics 1',
        'Mechanics',
      ],
      '2nd': [
        'Structural Analysis',
        'Concrete Technology',
        'Geotechnical Engineering',
        'Mathematics 2',
        'Fluid Mechanics',
      ],
      '3rd': [
        'Transportation Engineering',
        'Environmental Engineering',
        'Hydraulics',
        'Structural Design',
        'Surveying II',
      ],
      '4th': [
        'Construction Management',
        'Building Materials',
        'Water Resources Engineering',
        'Soil Mechanics',
        'Steel Structures',
      ],
      '5th': [
        'Project Management',
        'Urban Planning',
        'Soil Mechanics',
        'Environmental Impact Assessment',
        'Construction Techniques',
      ],
      '6th': [
        'Foundation Engineering',
        'Irrigation Engineering',
        'Structural Design',
        'Pavement Design',
        'Geotechnical Analysis',
      ],
      '7th': [
        'Earthquake Engineering',
        'Bridge Engineering',
        'Advanced Concrete',
        'Hydrology',
        'Construction Economics',
      ],
      '8th': [
        'Infrastructure Development',
        'Sustainable Construction',
        'Major Project',
        'Advanced Structural Analysis',
        'Smart Cities',
      ],
    },
    'Energy Engineering': {
      '1st': [
        'Energy Resources',
        'Thermodynamics',
        'Fluid Mechanics',
        'Mathematics 1',
        'Physics',
      ],
      '2nd': [
        'Heat Transfer',
        'Power Plant Engineering',
        'Electrical Machines',
        'Mathematics 2',
        'Energy Materials',
      ],
      '3rd': [
        'Renewable Energy',
        'Energy Management',
        'Energy Auditing',
        'Solar Thermal Systems',
        'Wind Energy Systems',
      ],
      '4th': [
        'Solar Energy',
        'Wind Energy',
        'Bioenergy',
        'Energy Storage Systems',
        'Power Electronics',
      ],
      '5th': [
        'Energy Storage',
        'Smart Grid',
        'Energy Economics',
        'Fuel Cells',
        'Energy Efficiency',
      ],
      '6th': [
        'Hydropower',
        'Nuclear Energy',
        'Fuel Cells',
        'Energy Policy Analysis',
        'Thermal Energy Systems',
      ],
      '7th': [
        'Energy Policy',
        'Carbon Management',
        'Sustainable Energy',
        'Energy Modeling',
        'Renewable Integration',
      ],
      '8th': [
        'Energy System Integration',
        'Research Methods',
        'Thesis Project',
        'Advanced Energy Systems',
        'Energy Analytics',
      ],
    },
    'Electronics Engineering': {
      '1st': [
        'Basic Electronics',
        'Circuit Theory',
        'Digital Electronics',
        'Mathematics 1',
        'Physics',
      ],
      '2nd': [
        'Microprocessors',
        'Analog Circuits',
        'Communication Systems',
        'Mathematics 2',
        'Signals and Systems',
      ],
      '3rd': [
        'Control Systems',
        'Signal Processing',
        'Embedded Systems',
        'Digital Design',
        'Network Analysis',
      ],
      '4th': [
        'VLSI Design',
        'Power Electronics',
        'Instrumentation',
        'Microcontrollers',
        'Analog Communication',
      ],
      '5th': [
        'Robotics',
        'Wireless Communication',
        'IoT',
        'Digital Signal Processing',
        'Embedded Programming',
      ],
      '6th': [
        'Image Processing',
        'Microwave Engineering',
        'Nanoelectronics',
        'Optoelectronics',
        'Sensor Networks',
      ],
      '7th': [
        'Advanced Communication',
        'RF Engineering',
        'System Design',
        'Antenna Design',
        'VLSI Fabrication',
      ],
      '8th': [
        'Industry 4.0',
        'Advanced Projects',
        'Professional Practice',
        'AI in Electronics',
        'Cyber-Physical Systems',
      ],
    },
    'Architecture Engineering': {
      '1st': [
        'Architectural Design 1',
        'Building Construction',
        'History of Architecture',
        'Mathematics 1',
        'Graphics and Visualization',
      ],
      '2nd': [
        'Architectural Design 2',
        'Materials and Methods',
        'Environmental Studies',
        'Structural Mechanics',
        'Drawing Techniques',
      ],
      '3rd': [
        'Structural Systems',
        'Urban Design',
        'Computer Applications',
        'Building Physics',
        'Architectural History II',
      ],
      '4th': [
        'Landscape Architecture',
        'Building Services',
        'Architectural Detailing',
        'Construction Technology',
        'Site Planning',
      ],
      '5th': [
        'Advanced Design',
        'Project Planning',
        'Sustainable Architecture',
        'Interior Design',
        'Urban Planning Principles',
      ],
      '6th': [
        'Professional Practice',
        'Heritage Conservation',
        'Research Methodology',
        'Building Information Modeling',
        'Acoustics Design',
      ],
      '7th': [
        'Contemporary Architecture',
        'Green Building Design',
        'Portfolio Development',
        'Advanced Structures',
        'Urban Regeneration',
      ],
      '8th': [
        'Architectural Thesis',
        'Internship',
        'Professional Certification',
        'Smart Building Design',
        'Construction Management',
      ],
      '9th': [
        'Advanced Urban Design',
        'Disaster-Resilient Architecture',
        'Building Automation',
        'Architectural Criticism',
        'Sustainable Materials',
      ],
      '10th': [
        'Capstone Project',
        'Professional Ethics',
        'Advanced BIM',
        'Global Architecture Trends',
        'Thesis Presentation',
      ],
    },
  };
}
