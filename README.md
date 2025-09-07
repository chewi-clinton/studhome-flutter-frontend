StudHome Frontend
The StudHome frontend is a Flutter application for a student accommodation platform, enabling users to browse houses, view locations on Google Maps, save homes, and make payments for reservations or tours using CamPay. It integrates with a Django REST Framework backend.
Table of Contents

Features
Tech Stack
Prerequisites
Installation
Configuration
Running the Application
Testing
Troubleshooting
Contributing
License

Features

Browse and filter house listings.
View house locations using Google Maps.
Save favorite homes for later viewing.
Initiate payments for reservations (FCFA 100) and tours (FCFA 100) via CamPay.
User authentication with JWT tokens.
Display house media (images and 3D models) from Cloudinary.
Responsive UI for mobile devices.

Tech Stack

Flutter 3.x
Dart
Google Maps Flutter
Libraries: http, shared_preferences, google_maps_flutter

Prerequisites

Flutter 3.x
Dart
Android Studio or VS Code with Flutter extensions
Google Maps API key
Git
Backend running at http://127.0.0.1:8000

Installation

Clone the Repository:
git clone https://github.com/yourusername/studhome.git
cd studhome/Frontend

Install Dependencies:
flutter pub add flutter http shared_preferences google_maps_flutter
flutter pub get

Configure Google Maps:

Obtain a Google Maps API key from https://console.cloud.google.com.
Update android/app/src/main/AndroidManifest.xml:<application>
<meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="your_google_maps_api_key"/>
</application>

Update ios/Runner/AppDelegate.swift (for iOS):import GoogleMaps
GMSServices.provideAPIKey("your_google_maps_api_key")

Configuration

Set Backend URL:Create lib/constants/backend_url.dart:
class Constants {
static const String baseUrl = 'http://127.0.0.1:8000';
}

Update pubspec.yaml:Ensure dependencies:
dependencies:
flutter:
sdk: flutter
http: ^1.2.2
shared_preferences: ^2.3.0
google_maps_flutter: ^2.9.0

Running the Application

Ensure Backend is Running:
cd studhome/Backend/Studhome
python manage.py runserver

Run Flutter App:
cd studhome/Frontend
flutter run

Select a connected device or emulator.

Testing

Run Tests:flutter test

Manual Testing:
Browse houses and verify Google Maps displays correct locations using lat and lng.
Test payment flows (ReservePayment, BookTourPayment) with valid/invalid phone numbers.
Save a house and check if it appears in the saved homes list.
Verify authentication and token refresh.

Troubleshooting

Google Maps Issues:
Ensure API key is valid and enabled for Google Maps SDK (Android/iOS).
Check AndroidManifest.xml and AppDelegate.swift for correct API key.

Backend Connection Errors:
Verify baseUrl in backend_url.dart matches backend address.
Check Flutter console for HTTP errors (e.g., No host specified).

Payment Failures:
Ensure CamPay phone number format (+2376xxxxxxxx).
Verify backend webhook logs for payment status updates.

Contributing

Fork the repository.
Create a feature branch: git checkout -b feature-name.
Commit changes: git commit -m "Add feature".
Push to branch: git push origin feature-name.
Open a pull request.

License
MIT License
