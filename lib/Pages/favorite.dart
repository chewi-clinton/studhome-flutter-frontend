import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/Pages/home_detail.dart';
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin, sin;

import 'package:studhome/constants/backend_url.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> savedHomes = [];
  bool _isLoading = true;
  String? _errorMessage;

  final double schoolLat = 3.949730;
  final double schoolLng = 11.514695;

  @override
  void initState() {
    super.initState();
    _fetchSavedHomes();
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

  Future<void> _fetchSavedHomes() async {
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

    final url = Uri.parse('${Constants.baseUrl}/api/user/saved-homes/');

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

      print('Saved Homes Response: ${response.statusCode} - ${response.body}');

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
          print(
            'Retry Saved Homes Response: ${response.statusCode} - ${response.body}',
          );
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
          savedHomes = data.map((savedHome) {
            final house = savedHome['house'];
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
              'isSaved': true,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load saved homes: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to connect to server. $e';
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> _toggleBookmark(String houseId, bool isSaved, int index) async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Not authenticated. Please log in.';
      });
      return;
    }

    final url = Uri.parse('${Constants.baseUrl}/api/house/$houseId/unsave/');

    try {
      final response = await http
          .delete(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print(
        'Toggle Bookmark Response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          accessToken = prefs.getString('access_token');
          final retryResponse = await http
              .delete(
                url,
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 10));
          print(
            'Retry Toggle Response: ${retryResponse.statusCode} - ${retryResponse.body}',
          );
          if (retryResponse.statusCode == 204) {
            setState(() {
              savedHomes.removeAt(index);
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('House unsaved')));
          } else {
            setState(() {
              _errorMessage = 'Failed to unsave: ${retryResponse.statusCode}';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Session expired. Please log in again.';
          });
          return;
        }
      }

      if (response.statusCode == 204) {
        setState(() {
          savedHomes.removeAt(index);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('House unsaved')));
      } else {
        setState(() {
          _errorMessage = 'Failed to unsave: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to connect to server. $e';
      });
      print('Error: $e');
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
        toolbarHeight: 40,
        automaticallyImplyLeading: false,
        title: Text(
          "Favorites",
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
      backgroundColor: scaffoldColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(_errorMessage!, style: TextStyle(color: textColor)),
            )
          : savedHomes.isEmpty
          ? Center(
              child: Text('No saved homes', style: TextStyle(color: textColor)),
            )
          : ListView.builder(
              itemCount: savedHomes.length,
              itemBuilder: (context, index) {
                final home = savedHomes[index];
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
                            HomeDetailPage(houseId: home['house_id']),
                      ),
                    ),
                    child: Card(
                      color: cardColor,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              home['image'],
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    home['title'],
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  home['distance'],
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: dividerColor,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.bookmark,
                                    color: primaryColor,
                                    size: screenWidth * 0.06,
                                  ),
                                  onPressed: () => _toggleBookmark(
                                    home['house_id'],
                                    true,
                                    index,
                                  ),
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
    );
  }
}
