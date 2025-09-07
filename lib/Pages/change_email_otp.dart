import 'package:email_otp/email_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/Pages/navigation.dart';
import 'package:studhome/constants/app_colors.dart';
import 'package:studhome/constants/backend_url.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final Map<String, String> userData;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.userData,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String _errorMessage = '';
  bool get _isUpdate => widget.userData.containsKey('is_update');

  @override
  void initState() {
    super.initState();
    EmailOTP.config(
      appName: 'StudHome',
      otpType: OTPType.numeric,
      expiry: 60000,
      emailTheme: EmailTheme.v6,
      appEmail: 'Suhchenwi48@gmail.com',
      otpLength: 4,
    );
    _emailController.text = widget.email;
    _sendOTP();
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      bool result = await EmailOTP.sendOTP(email: _emailController.text);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result) {
          _isOtpSent = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully!')),
          );
        } else {
          _errorMessage = 'Failed to send OTP. Please try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _verifyOTP(String otp) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      bool result = EmailOTP.verifyOTP(otp: otp);
      if (!mounted) return;
      if (result) {
        if (_isUpdate) {
          // Update existing user profile with new email
          await _updateUserProfile();
        } else {
          // Register new user
          await _registerUser();
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _registerUser() async {
    final url = Uri.parse('${Constants.baseUrl}/api/user/register/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.userData['username'],
        'email': widget.userData['email'],
        'phone_number': widget.userData['phone_number'],
        'password': widget.userData['password'],
      }),
    );

    if (response.statusCode == 201) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Navigation()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
      }
    } else {
      final errorData = jsonDecode(response.body);
      String errorMsg = 'Registration failed: ';
      if (errorData.containsKey('username')) {
        errorMsg += errorData['username'].join(' ');
      } else if (errorData.containsKey('email')) {
        errorMsg += errorData['email'].join(' ');
      } else if (errorData.containsKey('phone_number')) {
        errorMsg += errorData['phone_number'].join(' ');
      } else {
        errorMsg += 'Unknown error.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login again';
        });
        return;
      }

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/api/user/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': widget.userData['username'],
          'email': widget.userData['email'],
          'phone_number': widget.userData['phone_number'],
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = 'Failed to update profile';
        if (errorData is Map) {
          errorMessage = errorData.values.first.toString();
        }

        setState(() {
          _isLoading = false;
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdate ? 'Verify New Email' : 'Email Verification'),
        backgroundColor: bgColor,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.05),
                Text(
                  _isUpdate ? 'Verify your new email' : 'Verify your email',
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                if (!_isOtpSent) ...[
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Your Email',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    enabled: false,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.04,
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator.adaptive(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            )
                          : Text(
                              'Send OTP',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'A 4-digit code has been sent to ${_emailController.text}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  OtpTextField(
                    numberOfFields: 4,
                    borderColor: textColor ?? Colors.black,
                    fieldWidth: screenWidth * 0.12,
                    showFieldAsBox: true,
                    onSubmit: _verifyOTP,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendOTP,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_errorMessage.isNotEmpty) ...[
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
