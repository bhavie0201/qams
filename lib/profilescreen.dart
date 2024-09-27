import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginscreen.dart'; // Import the login screen
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'model/user.dart'; // Import the user model (assuming the user class is imported this way)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = const Color(0xffeef444c); // Corrected color code
  String birth = "Date of birth";

  // Country Code and Mobile Number Variables
  String selectedCountryCode = "+1"; // Default country code
  TextEditingController mobileNumberController = TextEditingController();

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  List<String> countryCodes = ["+1", "+91", "+44", "+61", "+81"]; // Example country codes

  // Logout function to remove employeeId and navigate to login screen
  Future<void> _logout() async {
    //SharedPreferences sharedPreferences = SharedPreferences.getInstance();
    //sharedPreferences.clear(); // Clear shared preferences

    // Navigate to login screen after logging out
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void pickUploadProfilePic() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxHeight: 512,
      maxWidth: 512,
      imageQuality: 90,
    );

    Reference ref = FirebaseStorage.instance
        .ref().child("${User.employeeId?.toLowerCase()}_profilepic.jpg");

    if (image != null) {
      await ref.putFile(File(image.path));

      ref.getDownloadURL().then((value) async {
        setState(() {
          User.profilePicLink = value;
        });

        await FirebaseFirestore.instance.collection("Employee").doc(User.id).update({
          'profilePic': value,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                pickUploadProfilePic();
              },
              child: Container(
                margin: const EdgeInsets.only(top: 80, bottom: 24),
                height: 120,
                width: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: primary,
                ),
                child: Center(
                  child: User.profilePicLink == " " ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 80,
                  ) : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(User.profilePicLink),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "${User.employeeId}",
                style: const TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 24,),
            User.canEdit ? textField("First Name", "First name", firstNameController) : field("First Name", User.firstName),
            User.canEdit ? textField("Last Name", "Last name", lastNameController) : field("Last Name", User.lastName),

            // New Mobile Number Field with Country Code Dropdown
            User.canEdit ? mobileNumberField() : field("Mobile Number", "${User.countryCode} ${User.mobileNumber}"),

            User.canEdit ? GestureDetector(
              onTap: () {
                showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: primary,
                            secondary: primary,
                            onSecondary: Colors.white,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                            ),
                          ),
                          textTheme: const TextTheme(
                            headlineMedium: TextStyle(
                              fontFamily: "NexaBold",
                            ),
                            labelSmall: TextStyle(
                              fontFamily: "NexaBold",
                            ),
                            labelLarge: TextStyle(
                              fontFamily: "NexaBold",
                            ),
                          ),
                        ),
                        child: child!,
                      );
                    }
                ).then((value) {
                  setState(() {
                    birth = DateFormat("MM/dd/yyyy").format(value!);
                  });
                });
              },
              child: field("Date of Birth", birth),
            ) : field("Date of Birth", User.birthDate),
            User.canEdit ? textField("Address", "Address", addressController) : field("Address", User.address),

            // Save Button
            User.canEdit ? GestureDetector(
              onTap: () async {
                String firstName = firstNameController.text;
                String lastName = lastNameController.text;
                String birthDate = birth;
                String address = addressController.text;
                String mobileNumber = mobileNumberController.text;

                if (User.canEdit) {
                  if (firstName.isEmpty) {
                    showSnackBar("Please enter your first name!");
                  } else if (lastName.isEmpty) {
                    showSnackBar("Please enter your last name!");
                  } else if (birthDate.isEmpty) {
                    showSnackBar("Please enter your birth date!");
                  } else if (address.isEmpty) {
                    showSnackBar("Please enter your address!");
                  } else if (mobileNumber.isEmpty || !RegExp(r'^[0-9]{10}$').hasMatch(mobileNumber)) {
                    showSnackBar("Please enter a valid mobile number!");
                  } else {
                    await FirebaseFirestore.instance.collection("Employee").doc(User.id).update({
                      'firstName': firstName,
                      'lastName': lastName,
                      'birthDate': birthDate,
                      'address': address,
                      'mobileNumber': mobileNumber,
                      'countryCode': selectedCountryCode,
                      'canEdit': false,
                    }).then((value) {
                      setState(() {
                        User.canEdit = false;
                        User.firstName = firstName;
                        User.lastName = lastName;
                        User.birthDate = birthDate;
                        User.address = address;
                        User.mobileNumber = mobileNumber;
                        User.countryCode = selectedCountryCode;
                      });
                    });
                  }
                } else {
                  showSnackBar("You can't edit anymore, please contact support team.");
                }
              },
              child: Container(
                height: kToolbarHeight,
                width: screenWidth,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: primary,
                ),
                child: const Center(
                  child: Text(
                    "SAVE",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "NexaBold",
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ) : const SizedBox(),

            // Logout Button
            GestureDetector(
              onTap: () {
                _logout(); // Call the logout function
              },
              child: Container(
                height: kToolbarHeight,
                width: screenWidth,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red, // Red color for logout
                ),
                child: const Center(
                  child: Text(
                    "LOGOUT",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "NexaBold",
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget mobileNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Mobile Number",
            style: TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            // Country Code Dropdown
            Container(
              width: 100,
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
              ),
              child: DropdownButton<String>(
                value: selectedCountryCode,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                underline: Container(), // Remove underline
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCountryCode = newValue!;
                  });
                },
                items: countryCodes.map((String code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(code),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 8),
            // Mobile Number Text Field
            Expanded(
              child: TextField(
                controller: mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Enter Mobile Number",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Standard field widget for consistency in UI
  Widget field(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          width: screenWidth,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12),
          height: 45,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey.shade400,
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontFamily: "NexaRegular",
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget textField(String title, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "NexaBold",
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          width: screenWidth,
          margin: const EdgeInsets.only(bottom: 12),
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.grey.shade400,
            ),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // SnackBar function to display errors or feedback
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
