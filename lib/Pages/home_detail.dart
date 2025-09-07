import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/Pages/booktour_notice.dart';
import 'package:studhome/Pages/fullscreen_image.dart';
import 'package:studhome/Pages/map_page.dart';
import 'package:studhome/Pages/model_viewer.dart';
import 'package:studhome/Pages/reservation_notice.dart';
import 'package:studhome/constants/app_colors.dart';
import 'dart:convert';
import 'dart:math';

import 'package:studhome/constants/backend_url.dart';

class HomeDetailPage extends StatefulWidget {
  final String houseId;

  const HomeDetailPage({super.key, required this.houseId});

  @override
  State<HomeDetailPage> createState() => _HomeDetailPageState();
}

class _HomeDetailPageState extends State<HomeDetailPage> {
  Map<String, dynamic>? house;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, String>> galleryImages = [];

  final double schoolLat = 3.949730;
  final double schoolLng = 11.514695;

  @override
  void initState() {
    super.initState();
    _fetchHouseDetails();
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

  Future<void> _fetchHouseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Not authenticated. Please log in.';
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${Constants.baseUrl}/api/house/${widget.houseId}/');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final newAccessToken = prefs.getString('access_token');
          final retryResponse = await http
              .get(
                url,
                headers: {
                  'Authorization': 'Bearer $newAccessToken',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 30));
          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            final media = data['media'] as List<dynamic>;
            final images = media
                .asMap()
                .entries
                .where((entry) => entry.value['media_type'] == 'image')
                .map<Map<String, String>>(
                  (entry) => {
                    'file_url': entry.value['file_url'] as String,
                    'caption':
                        (entry.value['caption'] as String?) ??
                        'Image ${entry.key + 1}',
                  },
                )
                .toList();

            setState(() {
              house = data;
              galleryImages = images.isNotEmpty
                  ? images
                  : [
                      {
                        'file_url': 'assets/images/roomimage.jpg',
                        'caption': 'Default Image',
                      },
                    ];
              _isLoading = false;
            });
            return;
          }
        }
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final media = data['media'] as List<dynamic>;
        final images = media
            .asMap()
            .entries
            .where((entry) => entry.value['media_type'] == 'image')
            .map<Map<String, String>>(
              (entry) => {
                'file_url': entry.value['file_url'] as String,
                'caption':
                    (entry.value['caption'] as String?) ??
                    'Image ${entry.key + 1}',
              },
            )
            .toList();

        setState(() {
          house = data;
          galleryImages = images.isNotEmpty
              ? images
              : [
                  {
                    'file_url': 'assets/images/roomimage.jpg',
                    'caption': 'Default Image',
                  },
                ];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load house details: ${response.statusCode}';
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
    return degrees * (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 1,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          ElevatedButton(
            onPressed:
                house != null &&
                    house!['media'].any(
                      (item) => item['media_type'] == '3d_model',
                    )
                ? () {
                    final modelUrl =
                        house!['media'].firstWhere(
                              (item) => item['media_type'] == '3d_model',
                            )['file_url']
                            as String;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ModelViewerPage(modelUrl: modelUrl),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("See 3D"),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(_errorMessage!, style: TextStyle(color: textColor)),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Image.network(
                      galleryImages[0]['file_url']!,
                      height: screenHeight * 0.3,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/roomimage.jpg',
                        height: screenHeight * 0.3,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            house!['room_type'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            house!['house_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: screenWidth * 0.05,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                child: Image.asset(
                                  'assets/images/distance_icon.png',
                                  height: screenWidth * 0.1,
                                  width: screenWidth * 0.1,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MapPage(
                                        latitude: house!['lat'],
                                        longitude: house!['lng'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                '${(_calculateDistance(house!['lat'], house!['lng'], schoolLat, schoolLng) / 1000).toStringAsFixed(1)}km from ICTU',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w300,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${house!['price']} FCFA/Month',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w300,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'House details and Images',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      child: Text(
                        house!['description'] ?? 'No description available',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: galleryImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final imageData = entry.value;
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                            ),
                            child: _buildImageTile(
                              context,
                              image: imageData['file_url']!,
                              label: imageData['caption']!,
                              index: index,
                              screenWidth: screenWidth,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.42,
                          height: screenHeight * 0.07,
                          child: ElevatedButton(
                            onPressed:
                                house!['reservation_status']['is_reserved'] &&
                                    !house!['reservation_status']['reserved_by_user']
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookTourNoticePage(
                                              houseId: widget.houseId,
                                            ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Book Tour',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.42,
                          height: screenHeight * 0.07,
                          child: ElevatedButton(
                            onPressed:
                                house!['reservation_status']['is_reserved'] &&
                                    !house!['reservation_status']['reserved_by_user']
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ReservationNoticePage(
                                              houseId: widget.houseId,
                                            ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'Reserve',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageTile(
    BuildContext context, {
    required String image,
    required String label,
    required int index,
    required double screenWidth,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FullScreenImagePage(images: galleryImages, initialIndex: index),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              child: Image.network(
                image,
                height: screenWidth * 0.28,
                width: screenWidth * 0.28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/roomimage.jpg',
                  height: screenWidth * 0.28,
                  width: screenWidth * 0.28,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: screenWidth * 0.035),
            ),
          ],
        ),
      ),
    );
  }
}
