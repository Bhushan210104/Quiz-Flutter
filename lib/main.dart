import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:quizzify/signin_page.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCaTORhxt803qUAFt1VwbrMJ_KCLASmtqY",
        authDomain: "quizzify-31260.firebaseapp.com",
        projectId: "quizzify-31260",
        storageBucket: "quizzify-31260.appspot.com",
        messagingSenderId: "1001986032286",
        appId: "1:1001986032286:web:588c1fed7e4d7df335318f",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quizzify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SignInPage(), // Set Sign-In Page as the home screen
    );
  }
}
