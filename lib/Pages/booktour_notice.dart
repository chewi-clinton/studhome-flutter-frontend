import 'package:flutter/material.dart';
import 'package:studhome/Pages/booktour_payment.dart';
import 'package:studhome/constants/app_colors.dart';

class BookTourNoticePage extends StatelessWidget {
  final String houseId;

  const BookTourNoticePage({super.key, required this.houseId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.lightBackground),
        title: Text(
          "Tour Booking Notice",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06,
            color: AppColors.lightBackground,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              Center(
                child: Image.asset(
                  "assets/images/notice.png",
                  height: screenHeight * 0.15,
                  width: screenHeight * 0.15,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Thank you for considering a tour of your future home! Please read the following important details regarding your booking:",
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "• Booking Fee: A fee of 2000 XAF is required to secure your tour reservation. This fee is valid for 48 hours and is non-refundable.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              Text(
                "• Availability: The home will remain available to other potential renters until the full rental payment is made.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              Text(
                "• Next Steps: After your tour, if you decide to proceed with the rental, prompt payment is required to ensure the home is secured exclusively for you.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              Text(
                "• Email Notification: An email will be sent once your payment is approved, containing the contact details of the house agent who will take you on the tour.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              Text(
                "• Tour Timing: Tours are available from 10 AM to 4 PM.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "Please take a moment to review these details before proceeding. If you have any questions or need assistance, feel free to reach out to our support team.",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              SizedBox(height: screenHeight * 0.04),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.018,
                        ),
                      ),
                      child: Text(
                        "Back",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookTourPayment(houseId: houseId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.018,
                        ),
                      ),
                      child: Text(
                        "Proceed",
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
}
