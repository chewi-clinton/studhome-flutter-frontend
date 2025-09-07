import 'package:flutter/material.dart';
import 'package:studhome/Pages/reserve_payment.dart';
import 'package:studhome/constants/app_colors.dart';

class ReservationNoticePage extends StatelessWidget {
  final String houseId;

  const ReservationNoticePage({super.key, required this.houseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Reservation Fee Notice",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/notice.png",
                    height: 120,
                    width: 120,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Thank you for choosing to reserve your home with us! Please be aware of the following details regarding your reservation fee:",
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                "• Reservation Fee: A fee of 5000 XAF is required to secure your home reservation. This fee grants you the right to hold the reservation for one week and is non-refundable.",
                style: TextStyle(fontSize: 16),
              ),
              const Text(
                "• Payment Options: You have the option to proceed with the payment or cancel your reservation at this stage.",
                style: TextStyle(fontSize: 16),
              ),
              const Text(
                "• Cancellation: If you choose to cancel, your reservation will not be secured, and the home will be available for other guests.",
                style: TextStyle(fontSize: 16),
              ),
              const Text(
                "• Payment Confirmation: Once payment is made, your reservation will be confirmed, ensuring that the home is held exclusively for you for the duration of the week.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                "Please take a moment to review these details before proceeding. If you have any questions or need assistance, feel free to reach out to our support team.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 150,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ReservePayment(houseId: houseId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: const Text(
                        "Proceed",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
