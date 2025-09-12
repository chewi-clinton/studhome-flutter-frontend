import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/Pages/home_detail.dart';
import 'package:studhome/Pages/notificationpage.dart';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;
import 'package:studhome/constants/backend_url.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> houses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? selectedCategory;

  final double schoolLat = 3.949730;
  final double schoolLng = 11.514695;

  @override
  void initState() {
    super.initState();
    _fetchHouses();
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return false;

    final url = Uri.parse('${Constants.baseUrl}/api/token/refresh/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final newAccessToken = jsonDecode(response.body)['access'];
        await prefs.setString('access_token', newAccessToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchHouses({String? roomType}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Not authenticated. Please log in.';
        _isLoading = false;
      });
      return;
    }

    final url = roomType != null && roomType.isNotEmpty
        ? Uri.parse('${Constants.baseUrl}/api/houses/?room_type=$roomType')
        : Uri.parse('${Constants.baseUrl}/api/houses/');

    try {
      var response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          accessToken = prefs.getString('access_token');
          response = await http
              .get(
                url,
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 10));
        } else {
          setState(() {
            _errorMessage = 'Session expired. Please log in again.';
            _isLoading = false;
          });
          return;
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          houses = data.map((house) {
            final media = house['media'] as List<dynamic>;
            final firstImage = media.firstWhere(
              (item) => item['media_type'] == 'image',
              orElse: () => {'file_url': 'assets/images/roomimage.jpg'},
            )['file_url'];

            final distance = _calculateDistance(
              house['lat'],
              house['lng'],
              schoolLat,
              schoolLng,
            );

            return {
              'house_id': house['house_id'],
              'title': house['room_type'],
              'distance':
                  '${(distance / 1000).toStringAsFixed(1)}km from school',
              'image': firstImage,
              'isSaved': house['is_saved'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load houses: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to connect to server. $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark(int index) async {
    final house = houses[index];
    final houseId = house['house_id'];
    final isSaved = house['isSaved'];
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Not authenticated. Please log in.';
      });
      return;
    }

    final url = Uri.parse(
      '${Constants.baseUrl}/api/house/$houseId/${isSaved ? 'unsave' : 'save'}/',
    );

    try {
      final response = isSaved
          ? await http
                .delete(
                  url,
                  headers: {
                    'Authorization': 'Bearer $accessToken',
                    'Content-Type': 'application/json',
                  },
                )
                .timeout(const Duration(seconds: 10))
          : await http
                .post(
                  url,
                  headers: {
                    'Authorization': 'Bearer $accessToken',
                    'Content-Type': 'application/json',
                  },
                )
                .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          accessToken = prefs.getString('access_token');
          final retryResponse = isSaved
              ? await http
                    .delete(
                      url,
                      headers: {
                        'Authorization': 'Bearer $accessToken',
                        'Content-Type': 'application/json',
                      },
                    )
                    .timeout(const Duration(seconds: 10))
              : await http
                    .post(
                      url,
                      headers: {
                        'Authorization': 'Bearer $accessToken',
                        'Content-Type': 'application/json',
                      },
                    )
                    .timeout(const Duration(seconds: 10));
          if (retryResponse.statusCode == 200 ||
              retryResponse.statusCode == 201 ||
              retryResponse.statusCode == 204) {
            setState(() {
              houses[index]['isSaved'] = !isSaved;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isSaved ? 'House unsaved' : 'House saved'),
              ),
            );
          } else {
            setState(() {
              _errorMessage =
                  'Failed to toggle save: ${retryResponse.statusCode}';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Session expired. Please log in again.';
          });
          return;
        }
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        setState(() {
          houses[index]['isSaved'] = !isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSaved ? 'House unsaved' : 'House saved')),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to toggle save: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to connect to server. $e';
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }

  void _onCategorySelected(String? category) {
    setState(() {
      selectedCategory = category;
    });
    _fetchHouses(roomType: category);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).dividerColor;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 45,
        leading: Padding(
          padding: EdgeInsets.all(screenWidth * 0.0001),
          child: Image.asset("assets/icon/launcher_icon.png"),
        ),
        title: Text(
          "StudHome",
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: textColor,
              size: screenWidth * 0.06,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: scaffoldColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(_errorMessage!, style: TextStyle(color: textColor)),
            )
          : ListView(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.04,
                    screenHeight * 0.02,
                    screenWidth * 0.04,
                    screenHeight * 0.01,
                  ),
                  child: Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Row(
                    children: [
                      _buildCategoryButton(
                        "All",
                        screenWidth,
                        screenHeight,
                        primaryColor,
                        '',
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      _buildCategoryButton(
                        "Single room",
                        screenWidth,
                        screenHeight,
                        primaryColor,
                        'single',
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      _buildCategoryButton(
                        "Double room",
                        screenWidth,
                        screenHeight,
                        primaryColor,
                        'double',
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      _buildCategoryButton(
                        "Apartment",
                        screenWidth,
                        screenHeight,
                        primaryColor,
                        'apartment',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: houses.length,
                  itemBuilder: (context, index) {
                    final house = houses[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.01,
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomeDetailPage(houseId: house['house_id']),
                          ),
                        ),
                        child: Card(
                          color: cardColor,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  house["image"],
                                  height: screenHeight * 0.25,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                        'assets/images/roomimage.jpg',
                                        height: screenHeight * 0.25,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        house["title"],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.045,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      house["distance"],
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: dividerColor,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        house["isSaved"]
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color: house["isSaved"]
                                            ? primaryColor
                                            : dividerColor,
                                        size: screenWidth * 0.06,
                                      ),
                                      onPressed: () => _toggleBookmark(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryButton(
    String label,
    double screenWidth,
    double screenHeight,
    Color primaryColor,
    String categoryValue,
  ) {
    final isSelected = selectedCategory == categoryValue;
    return GestureDetector(
      onTap: () => _onCategorySelected(categoryValue),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.015,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
      ),
    );
  }
}
