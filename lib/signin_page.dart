import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'homepage.dart';
import 'signuppage.dart';
import 'admin.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await _navigateToHome(userCredential.user);
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Login failed.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await _saveGoogleUserToFirestore(userCredential);
      await _navigateToHome(userCredential.user);
    } catch (e) {
      _showErrorDialog("Google Sign-In failed: $e");
    }
  }

  Future<void> _saveGoogleUserToFirestore(UserCredential userCredential) async {
    if (userCredential.user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'username': userCredential.user!.displayName ?? "User",
        'email': userCredential.user!.email,
        'role': 'user',
      });
    }
  }

  Future<void> _navigateToHome(User? user) async {
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      String role = userDoc['role'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                role == 'admin' ? const AdminPage() : const HomePage()),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/images/quizzify_logo.png", height: 100),
                  const SizedBox(height: 10),
                  const Text(
                    "QUIZZIFY",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text("Welcome Back",
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Text("Enter your credentials to login",
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                  const SizedBox(height: 30),

                  // Email Field
                  _buildTextField(
                      _emailController, "Email", Icons.email, false),
                  const SizedBox(height: 15),

                  // Password Field
                  _buildTextField(
                      _passwordController, "Password", Icons.lock, true),
                  const SizedBox(height: 20),

                  // Login Button
                  _buildButton(
                      "Login", _signIn, Colors.white, Colors.deepPurple),
                  const SizedBox(height: 10),

                  // Google Sign-In Button
                  _buildButton("Sign in with Google", _signInWithGoogle,
                      Colors.white, Colors.black,
                      icon: Icons.g_mobiledata),
                  const SizedBox(height: 10),

                  // Sign-Up Navigation
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpPage()));
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, bool isPassword) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 18),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your $label";
        }
        if (label == "Email" &&
            (!value.contains('@') || !value.contains('.'))) {
          return "Enter a valid email";
        }
        if (label == "Password" && (value.length < 4 || value.length > 8)) {
          return "Password must be 4-8 characters";
        }
        return null;
      },
    );
  }

  Widget _buildButton(
      String text, Function() onPressed, Color bgColor, Color fgColor,
      {IconData? icon}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: fgColor),
            if (icon != null) const SizedBox(width: 10),
            Text(text,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
