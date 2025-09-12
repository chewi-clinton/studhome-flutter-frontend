import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/constants/app_colors.dart';
import 'package:studhome/constants/backend_url.dart';
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  Future<void> _fetchData() async {
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

    try {
      await _fetchTransactions(accessToken);
      await _fetchReservations(accessToken);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to connect to server. $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTransactions(String? accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/user/transactions/');

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
          accessToken = (await SharedPreferences.getInstance()).getString(
            'access_token',
          );
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
          transactions = data.map((transaction) {
            Map<String, dynamic>? house;
            try {
              house = transaction['house'] is String
                  ? jsonDecode(transaction['house']) as Map<String, dynamic>?
                  : transaction['house'] as Map<String, dynamic>?;
            } catch (e) {
              house = null;
            }
            return {
              'house_name': house?['house_name']?.toString() ?? 'Unknown',
              'room_type': house?['room_type']?.toString() ?? 'Unknown',
              'transaction_type':
                  transaction['transaction_type']?.toString() ?? 'Unknown',
              'payment_date':
                  transaction['payment_date']?.toString() ?? 'Unknown',
              'payment_status':
                  transaction['payment_status']?.toString() ?? 'Unknown',
              'house_id':
                  house?['house_id']?.toString() ??
                  transaction['house']?.toString() ??
                  'Unknown',
            };
          }).toList();
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load transactions: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to load transactions. $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchReservations(String? accessToken) async {
    final url = Uri.parse('${Constants.baseUrl}/api/user/reservations/');

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
          accessToken = (await SharedPreferences.getInstance()).getString(
            'access_token',
          );
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
          reservations = data.map((reservation) {
            Map<String, dynamic>? house;
            try {
              house = reservation['house'] is String
                  ? jsonDecode(reservation['house']) as Map<String, dynamic>?
                  : reservation['house'] as Map<String, dynamic>?;
            } catch (e) {
              house = null;
            }
            return {
              'house_id':
                  house?['house_id']?.toString() ??
                  reservation['house']?.toString() ??
                  'Unknown',
              'is_active': reservation['is_active'] ?? false,
              'expiry_date': reservation['expiry_date']?.toString(),
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load reservations: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to load reservations. $e';
        _isLoading = false;
      });
    }
  }

  String _getReservationStatus(String houseId) {
    final reservation = reservations.firstWhere(
      (res) => res['house_id'] == houseId,
      orElse: () => {'is_active': false, 'expiry_date': null},
    );
    if (reservation['is_active'] == true &&
        reservation['expiry_date'] != null) {
      try {
        final expiryDate = DateTime.parse(reservation['expiry_date']);
        if (expiryDate.isAfter(DateTime.now())) {
          return 'Active until ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
        }
      } catch (e) {
        return 'Not reserved';
      }
    }
    return 'Not reserved';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = Theme.of(context).textTheme.bodyLarge!.color!;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  color: textColor,
                ),
              ),
            )
          : transactions.isEmpty
          ? Center(
              child: Text(
                "No notifications available",
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final reservationStatus =
                    transaction['transaction_type'] == 'reserve'
                    ? _getReservationStatus(transaction['house_id'])
                    : 'N/A';
                return Card(
                  color: cardColor,
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['house_name'],
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Room Type: ${transaction['room_type']}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color,
                          ),
                        ),
                        Text(
                          'Payment Type: ${transaction['transaction_type']}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color,
                          ),
                        ),
                        Text(
                          'Payment Date: ${transaction['payment_date'] != 'Unknown' ? DateTime.parse(transaction['payment_date']).toLocal().toString().split('.')[0] : 'Unknown'}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color,
                          ),
                        ),
                        Text(
                          'Payment Status: ${transaction['payment_status']}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: transaction['payment_status'] == 'SUCCESSFUL'
                                ? AppColors.secondary
                                : AppColors.error,
                          ),
                        ),
                        Text(
                          'Reservation Status: $reservationStatus',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: reservationStatus.startsWith('Active')
                                ? AppColors.secondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
