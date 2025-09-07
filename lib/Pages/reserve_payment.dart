import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/constants/app_colors.dart';
import 'package:studhome/constants/backend_url.dart';
import 'dart:convert';

class ReservePayment extends StatefulWidget {
  final String houseId;

  const ReservePayment({super.key, required this.houseId});

  @override
  State<ReservePayment> createState() => _ReservePaymentState();
}

class _ReservePaymentState extends State<ReservePayment> {
  String? selectedPaymentMethod;
  final TextEditingController _paymentNumberController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  double? housePrice;

  @override
  void initState() {
    super.initState();
    _fetchHousePrice();
  }

  @override
  void dispose() {
    _paymentNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchHousePrice() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Not authenticated. Please log in.';
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
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          housePrice = double.parse(data['price'].toString());
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch house price: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to connect to server. $e';
      });
    }
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
    } catch (_) {
      return false;
    }
  }

  Future<void> _submit() async {
    final paymentNumber = _paymentNumberController.text.trim();

    if (selectedPaymentMethod == null) {
      setState(() => _errorMessage = 'Please select a payment method.');
      return;
    }
    if (paymentNumber.isEmpty) {
      setState(() => _errorMessage = 'Please enter your payment number.');
      return;
    }
    if (housePrice == null) {
      setState(
        () => _errorMessage = 'House price not loaded. Please try again.',
      );
      return;
    }

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

    final url = Uri.parse(
      '${Constants.baseUrl}/api/house/${widget.houseId}/initiate-payment/',
    );
    final payload = {
      'amount': '100',
      'phone_number': paymentNumber,
      'transaction_type': 'reserve',
    };

    try {
      var response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          accessToken = prefs.getString('access_token');
          response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          );
        } else {
          setState(() {
            _errorMessage = 'Session expired. Please log in again.';
            _isLoading = false;
          });
          return;
        }
      }

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final reference = data['reference'];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete payment via mobile money.'),
          ),
        );
        await _verifyPayment(reference);
      } else {
        setState(() {
          _errorMessage =
              'Failed to initiate payment: ${response.statusCode} - ${response.body}';
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

  Future<void> _verifyPayment(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access_token');

    final url = Uri.parse(
      '${Constants.baseUrl}/api/payment/verify/$reference/',
    );

    try {
      var response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'SUCCESSFUL') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Reservation confirmed.'),
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          setState(() {
            _errorMessage = 'Payment not completed. Status: ${data['status']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to verify payment: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: Unable to verify payment. $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: const Text(
          "Reserve Payment",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 25),
                  Text(
                    "Select your Payment Method",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 25),
                  _PaymentOptionRow(
                    label: "MTN MOMO",
                    assetPath: "assets/images/momo.png",
                    value: "momo",
                    groupValue: selectedPaymentMethod,
                    onChanged: (val) =>
                        setState(() => selectedPaymentMethod = val),
                  ),
                  const SizedBox(height: 20),
                  _PaymentOptionRow(
                    label: "Orange Money",
                    assetPath: "assets/images/orange_money.png",
                    value: "orange",
                    groupValue: selectedPaymentMethod,
                    onChanged: (val) =>
                        setState(() => selectedPaymentMethod = val),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Input Payment Number",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: width * 0.8,
                      child: TextField(
                        controller: _paymentNumberController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelText: 'Payment Number',
                          labelStyle: TextStyle(color: textColor),
                          hintText: 'e.g., +2376XXXXXXXX',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: SizedBox(
                      width: width * 0.8,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: const Text(
                          "Pay FCFA 100",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _PaymentOptionRow extends StatelessWidget {
  final String label;
  final String assetPath;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOptionRow({
    required this.label,
    required this.assetPath,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(assetPath, height: 60, width: 60),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
