import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginscreen.dart';  // Import the LoginScreen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  double screenHeight = 0;
  double screenWidth = 0;
  bool _isLoading = false;  // Loading state

  Color primary = const Color(0xffeef444c);

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _isLoading  // Show loading indicator if loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : Column(
        children: [
          isKeyboardVisible
              ? SizedBox(height: screenHeight / 16)
              : Container(
            height: screenHeight / 3,
            width: screenWidth,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(70),
                bottomLeft: Radius.circular(70),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person_add,
                color: Colors.white,
                size: screenWidth / 5,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: screenHeight / 35,
              bottom: screenHeight / 40,
            ),
            child: Text(
              "Sign Up",
              style: TextStyle(
                fontSize: screenWidth / 15,
                fontFamily: "NexaBold",
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fieldTitle("Email Address"),
                customField("Enter your email", emailController, false),
                fieldTitle("Password"),
                customField("Enter your password", passController, true),
                fieldTitle("Confirm Password"),
                customField("Confirm your password", confirmPassController, true),
                GestureDetector(
                  onTap: _signUpUser,
                  child: Container(
                    height: 50,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight / 50),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Center(
                      child: Text(
                        "SIGN UP",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          fontSize: screenWidth / 26,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth / 26,
          fontFamily: "NexaBold",
        ),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller, bool obscure) {
    return Container(
      width: screenWidth,
      margin: EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth / 6,
            child: Icon(
              obscure ? Icons.lock : Icons.email,
              color: primary,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                enableSuggestions: !obscure,
                autocorrect: false,
                obscureText: obscure && (controller == passController ? !_isPasswordVisible : !_isConfirmPasswordVisible),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight / 40),
                  border: InputBorder.none,
                  hintText: hint,
                  suffixIcon: obscure
                      ? IconButton(
                    icon: Icon(
                      controller == passController
                          ? (_isPasswordVisible ? Icons.visibility : Icons.visibility_off)
                          : (_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    ),
                    onPressed: () {
                      setState(() {
                        if (controller == passController) {
                          _isPasswordVisible = !_isPasswordVisible;
                        } else {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        }
                      });
                    },
                  )
                      : null,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signUpUser() async {
    String email = emailController.text.trim();
    String password = passController.text.trim();
    String confirmPassword = confirmPassController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;  // Show loading indicator
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign up successful!")),
      );

      // Navigate to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case "weak-password":
          errorMessage = "The password is too weak.";
          break;
        case "invalid-email":
          errorMessage = "The email address is not valid.";
          break;
        case "email-already-in-use":
          errorMessage = "This email is already in use.";
          break;
        default:
          errorMessage = e.message ?? "An unknown error occurred!";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;  // Hide loading indicator
      });
    }
  }
}
