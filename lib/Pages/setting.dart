import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:studhome/Auth_Pages/login_page.dart';
import 'package:studhome/Pages/profile_page.dart';
import 'package:studhome/constants/app_colors.dart';
import 'package:studhome/constants/backend_url.dart';
import 'package:studhome/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late bool status;
  late String modeText;

  String userName = 'Not logged in';
  String userEmail = 'Please login';

  String dropdownvalue = 'Eng';
  var languages = [
    {'code': 'Eng', 'flag': 'assets/images/eng_flag.png'},
    {'code': 'Fr', 'flag': 'assets/images/fr_flag.png'},
  ];

  List<Map<String, String>> faqs = [
    {
      'question': 'Is there a refund policy?',
      'answer':
          'Unfortunately, we do not offer refunds after payment, except in the rare case where a booking for a house tour has been made by another user.',
    },
    {
      'question': 'What is the difference between "Book Tour" and "Reserve"?',
      'answer':
          'When you "Book Tour," you are making a payment solely for our agents to show you the house, and this payment is valid for 48 hours. Conversely, when you "Reserve" a home, it becomes unbookable or unreserverable for other users, and this reservation is valid for a period of one week.',
    },
    {
      'question': 'Do ICT University students receive any discounts?',
      'answer':
          'Yes, students with an ICT University email can enjoy a 20% discount on their reservations or Tour booking, making it more affordable for you to secure your desired home.',
    },
    {
      'question': 'How can I apply my student discount?',
      'answer':
          'To apply your 20% student discount, please enter your ICT University email during the registration of your account or still you can go to edit profile and change current email to an ICT university email, and the discount will be automatically applied.',
    },
  ];

  @override
  void initState() {
    super.initState();

    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    status = isDarkMode.value;
    if (!isDarkMode.value && brightness == Brightness.dark) {
      status = true;
      isDarkMode.value = true;
    }
    modeText = status ? "Dark Mode" : "Light Mode";

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null) {
        setState(() {
          userName = 'Not logged in';
          userEmail = 'Please login';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/api/user/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        setState(() {
          userName = userData['username'] ?? 'Unknown User';
          userEmail = userData['email'] ?? 'No email';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          userName = 'Session expired';
          userEmail = 'Please login again';
        });
      } else {
        setState(() {
          userName = 'Error loading data';
          userEmail = 'Please try again';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Network error';
        userEmail = 'Check connection';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                "General Settings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/person.jpg",
                          height: 120,
                          width: 120,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileEditPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: textColor,
                      ),
                      child: SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Edit Profile",
                              style: TextStyle(fontSize: 19),
                            ),
                            Icon(Icons.arrow_forward_ios, color: textColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Text(
                    "Preferences",
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status ? Icons.dark_mode : Icons.light_mode,
                              color: textColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              modeText,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        FlutterSwitch(
                          width: 70,
                          height: 40,
                          toggleSize: 45,
                          value: status,
                          borderRadius: 30,
                          padding: 2,
                          activeToggleColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          inactiveToggleColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.primary,
                          activeIcon: const Icon(
                            Icons.nightlight_round,
                            color: Colors.white,
                          ),
                          inactiveIcon: const Icon(
                            Icons.wb_sunny,
                            color: Colors.white,
                          ),
                          onToggle: (val) {
                            setState(() {
                              status = val;
                              isDarkMode.value = val;
                              modeText = val ? "Dark Mode" : "Light Mode";
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 10),

                    // Language Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(CupertinoIcons.globe, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              "Language",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: dropdownvalue,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: languages.map((Map<String, String> lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Row(
                                children: [
                                  Image.asset(
                                    lang['flag']!,
                                    height: 30,
                                    width: 30,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    lang['code']!,
                                    style: TextStyle(color: textColor),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownvalue = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // FAQs
              Row(
                children: [
                  Text(
                    "FAQs",
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: List.generate(faqs.length, (index) {
                    return ExpansionTile(
                      title: Text(
                        faqs[index]['question']!,
                        style: TextStyle(fontSize: 18, color: textColor),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            faqs[index]['answer']!,
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 15),

              // About App (Dropdown)
              ExpansionTile(
                title: Text(
                  "About Our App",
                  style: TextStyle(fontSize: 18, color: textColor),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "This application is designed to provide users with a seamless experience in managing their settings and preferences. Our goal is to make it easy for users to customize their experience.",
                      style: TextStyle(fontSize: 16, color: textColor),
                    ),
                  ),
                ],
              ),

              // Contact info (outside dropdown)
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Contact Information",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Email: suhchenwi48@gmail.com",
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  Text(
                    "Phone: +237 (653) 82-8738",
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () async {
                  // Clear stored tokens on logout
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('access_token');
                  await prefs.remove('refresh_token');

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Loginpage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 100,
                  ),
                  foregroundColor: textColor,
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
