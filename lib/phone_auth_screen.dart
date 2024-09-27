import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homescreen.dart'; // Import HomeScreen

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({Key? key}) : super(key: key);

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String verificationId = "";
  bool otpSent = false;
  bool loading = false;
  double screenHeight = 0;
  double screenWidth = 0;

  Color primary = const Color(0xffeef444c);

  String errorMessage = ''; // For displaying specific error messages

  // Default selected country code
  String selectedCountryCode = '+1';  // Default is USA

  // List of country codes
  final List<String> countryCodes = ['+1', '+91', '+44', '+61', '+81', '+33', '+49'];

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom != 0;
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
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
                Icons.phone,
                color: Colors.white,
                size: screenWidth / 5,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: screenHeight / 15,
              bottom: screenHeight / 20,
            ),
            child: Text(
              "Phone Authentication",
              style: TextStyle(
                fontSize: screenWidth / 18,
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
                fieldTitle("Phone Number"),
                Row(
                  children: [
                    // Country code dropdown
                    DropdownButton<String>(
                      value: selectedCountryCode,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCountryCode = newValue!;
                        });
                      },
                      items: countryCodes.map<DropdownMenuItem<String>>((String code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(code),
                        );
                      }).toList(),
                    ),
                    Expanded(
                      child: customField("Enter your phone number", phoneController, false, errorMessage), // Error handling
                    ),
                  ],
                ),
                if (otpSent) ...[
                  fieldTitle("OTP"),
                  customField("Enter the OTP", otpController, false, errorMessage), // Error handling
                ],
                GestureDetector(
                  onTap: otpSent ? _verifyOTP : _sendOTP,
                  child: Container(
                    height: 60,
                    width: screenWidth,
                    margin: EdgeInsets.only(top: screenHeight / 40),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.all(Radius.circular(30)),
                    ),
                    child: Center(
                      child: loading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        otpSent ? "VERIFY OTP" : "SEND OTP",
                        style: TextStyle(
                          fontFamily: "NexaBold",
                          fontSize: screenWidth / 26,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
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

  Widget customField(String hint, TextEditingController controller, bool obscure, String errorText) {
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
              obscure ? Icons.lock : Icons.phone,
              color: primary,
              size: screenWidth / 15,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                controller: controller,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight / 35,
                  ),
                  border: InputBorder.none,
                  hintText: hint,
                  errorText: errorText.isNotEmpty ? errorText : null, // Display error text
                ),
                maxLines: 1,
                obscureText: obscure,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOTP() async {
    String phone = phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        errorMessage = "Phone number is required!";
      });
      return;
    }

    setState(() {
      errorMessage = '';
      loading = true;
    });

    String fullPhoneNumber = "$selectedCountryCode$phone";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number automatically verified")),
        );
        setState(() {
          loading = false;
        });
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          errorMessage = _getFirebaseErrorMessage(e.code);
          loading = false;
        });
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP has been sent!")),
        );
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
        setState(() {
          loading = false;
        });
      },
    );
  }

  Future<void> _verifyOTP() async {
    String otp = otpController.text.trim();
    if (otp.isEmpty) {
      setState(() {
        errorMessage = "OTP is required!";
      });
      return;
    }

    setState(() {
      errorMessage = '';
      loading = true;
    });

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number verified successfully!")),
      );
      setState(() {
        loading = false;
      });

      // Navigate to HomeScreen after successful verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        errorMessage = _getFirebaseErrorMessage((e as FirebaseAuthException).code);
        loading = false;
      });
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return "The phone number you entered is invalid. Please check and try again.";
      case 'too-many-requests':
        return "You have attempted too many times. Please try again later.";
      case 'invalid-verification-code':
        return "The OTP you entered is incorrect. Please check and try again.";
      case 'session-expired':
        return "Your session has expired. Please request a new OTP.";
      default:
        return "An unexpected error occurred. Please try again.";
    }
  }
}
