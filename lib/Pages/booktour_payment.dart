import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studhome/constants/app_colors.dart';
import 'dart:convert';
import 'package:studhome/constants/backend_url.dart';

class BookTourPayment extends StatefulWidget {
  final String houseId;

  const BookTourPayment({Key? key, required this.houseId}) : super(key: key);

  @override
  _BookTourPaymentState createState() => _BookTourPaymentState();
}

class _BookTourPaymentState extends State<BookTourPayment> {
  String? selectedPaymentMethod;
  final TextEditingController _paymentNumberController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _paymentNumberController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    final paymentNumber = _paymentNumberController.text.trim();

    if (selectedPaymentMethod == null) {
      setState(() => _errorMessage = 'Select a payment method');
      return;
    }
    if (paymentNumber.isEmpty || !paymentNumber.startsWith('+')) {
      setState(
        () => _errorMessage = 'Enter valid phone number with country code',
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
      'amount': 100,
      'phone_number': paymentNumber,
      'transaction_type': 'tour',
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
          response = await http
              .post(
                url,
                headers: {
                  'Authorization': 'Bearer $accessToken',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 30));
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
            content: Text('Please complete payment via mobile money'),
          ),
        );
        await _verifyPayment(reference);
      } else {
        setState(() {
          _errorMessage = 'Failed to initiate payment: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
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
                },
              )
              .timeout(const Duration(seconds: 30));
        } else {
          setState(() {
            _errorMessage = 'Session expired. Please log in again.';
            _isLoading = false;
          });
          return;
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'SUCCESSFUL') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful! Tour booked.')),
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
          _errorMessage = 'Failed to verify payment: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Book Tour Payment",
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 25),
                    Text(
                      "Select your Payment Method.",
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
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
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
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
                            labelStyle: TextStyle(
                              color: textTheme.bodyMedium?.color,
                            ),
                            hintText: 'e.g., +2376XXXXXXXX',
                          ),
                          style: textTheme.bodyLarge,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: width * 0.8,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
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
    final textTheme = Theme.of(context).textTheme;

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
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
