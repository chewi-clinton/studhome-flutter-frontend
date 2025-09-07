StudHome
StudHome is a web and mobile application designed to help users find and reserve student accommodations. It features a Django REST Framework backend with a PostgreSQL database and a Flutter frontend for a seamless cross-platform experience. The application supports house listings, payment processing via CamPay, and media management with Cloudinary. Administrators can manage house listings, including marking houses for removal, through the Django admin interface.
Table of Contents

Features
Tech Stack
Prerequisites
Installation
Backend Setup
Frontend Setup

Configuration
Running the Application
API Endpoints
Database Schema
Testing
Troubleshooting
Contributing
License

Features

House Listings: Browse and filter houses by name, room type, and availability.
Payment Processing: Initiate and verify payments for house reservations and tours using CamPay.
User Authentication: Secure user login with JWT tokens and refresh token support.
Media Management: Upload up to 6 images and one 3D model per house using Cloudinary.
Admin Interface: Manage houses, users, reservations, and transactions via Django admin.
Remove Functionality: Mark houses for removal from the frontend without deleting them from the database.
Email Notifications: Send confirmation emails for approved reservations.

Tech Stack

Backend: Django 5.2.6, Django REST Framework, PostgreSQL
Frontend: Flutter 3.x
Payment Gateway: CamPay
Media Storage: Cloudinary
Authentication: Simple JWT
Other Libraries: phonenumber_field, cloudinary_storage, corsheaders

Prerequisites

Python 3.12+
Node.js (for development tools, if needed)
Flutter 3.x
PostgreSQL 15+
Cloudinary account
CamPay account
Git
Virtual environment tool (e.g., venv)

Installation
Backend Setup

Clone the Repository:
git clone https://github.com/yourusername/studhome.git
cd studhome/Backend/Studhome

Create a Virtual Environment:
python -m venv .venv
source .venv/bin/activate # On Windows: .venv\Scripts\activate

Install Dependencies:
pip install django==5.2.6 djangorestframework django-phonenumber-field[phonenumbers] cloudinary django-cloudinary-storage psycopg2-binary djangorestframework-simplejwt corsheaders requests

Set Up PostgreSQL:

Create a database named studhome_db:psql -U postgres
CREATE DATABASE studhome_db;

Configure Environment Variables:Create a .env file in the Studhome directory:
DATABASE_URL=postgresql://yxngac:your_password@localhost:5432/studhome_db
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CAMPAY_USERNAME=your_campay_username
CAMPAY_PASSWORD=your_campay_password
EMAIL_HOST=smtp.gmail.com
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_app_password
DEFAULT_FROM_EMAIL=your_email@gmail.com
SECRET_KEY=your_django_secret_key

Update settings.py:Ensure Studhome/settings.py includes:
from pathlib import Path
import os
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(**file**).resolve().parent.parent

SECRET_KEY = os.getenv('SECRET_KEY')
DEBUG = True
ALLOWED_HOSTS = ['192.168.137.91', '127.0.0.1', 'localhost', '192.168.1.181']
CORS_ALLOW_ALL_ORIGINS = True

INSTALLED_APPS = [
'django.contrib.admin',
'django.contrib.auth',
'django.contrib.contenttypes',
'django.contrib.sessions',
'django.contrib.messages',
'django.contrib.staticfiles',
'StudHomeApi',
'rest_framework',
'phonenumber_field',
'cloudinary_storage',
'cloudinary',
'corsheaders',
]

MIDDLEWARE = [
'corsheaders.middleware.CorsMiddleware',
'django.middleware.security.SecurityMiddleware',
'django.contrib.sessions.middleware.SessionMiddleware',
'django.middleware.common.CommonMiddleware',
'django.middleware.csrf.CsrfViewMiddleware',
'django.contrib.auth.middleware.AuthenticationMiddleware',
'django.contrib.messages.middleware.MessageMiddleware',
'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

DATABASES = {
'default': {
'ENGINE': 'django.db.backends.postgresql',
'NAME': 'input your postgresql db database name',
'USER': 'input your postgresql db username',
'PASSWORD': os.getenv('DATABASE_PASSWORD'),
'HOST': 'localhost',
'PORT': '5432',
}
}

AUTH_USER_MODEL = 'StudHomeApi.User'
REST_FRAMEWORK = {
'DEFAULT_AUTHENTICATION_CLASSES': [
'rest_framework_simplejwt.authentication.JWTAuthentication',
],
'DEFAULT_PERMISSION_CLASSES': [
'rest_framework.permissions.IsAuthenticated',
]
}
SIMPLE_JWT = {'USER_ID_FIELD': 'user_id'}

CLOUDINARY_STORAGE = {
'CLOUD_NAME': os.getenv('CLOUDINARY_CLOUD_NAME'),
'API_KEY': os.getenv('CLOUDINARY_API_KEY'),
'API_SECRET': os.getenv('CLOUDINARY_API_SECRET'),
}
DEFAULT_FILE_STORAGE = 'cloudinary_storage.storage.MediaCloudinaryStorage'

CAMPAY_USERNAME = os.getenv('CAMPAY_USERNAME')
CAMPAY_PASSWORD = os.getenv('CAMPAY_PASSWORD')
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = os.getenv('EMAIL_HOST')
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.getenv('EMAIL_HOST_USER')
EMAIL_HOST_PASSWORD = os.getenv('EMAIL_HOST_PASSWORD')
DEFAULT_FROM_EMAIL = os.getenv('DEFAULT_FROM_EMAIL')

Apply Migrations:
python manage.py makemigrations
python manage.py migrate

Create Superuser:
python manage.py createsuperuser

Frontend Setup

Navigate to Frontend Directory:
cd path/to/studhome/Frontend

Install Dependencies:
flutter pub add flutter http shared_preferences
flutter pub get

Configure Backend URL:Create lib/constants/backend_url.dart:
class Constants {
static const String baseUrl = 'http://127.0.0.1:8000';
}

Ensure Flutter Environment:Verify Flutter setup:
flutter doctor

Configuration

CamPay: Register at https://www.campay.net and set up a webhook (http://127.0.0.1:8000/api/payment/webhook/) for payment status updates. Use ngrok for local testing:ngrok http 8000

Cloudinary: Configure in settings.py and .env with your Cloudinary credentials.
Email: Use an SMTP provider (e.g., Gmail) and configure credentials in .env.

Running the Application

Backend:
cd studhome/Backend/Studhome
source .venv/bin/activate
python manage.py runserver

Access the admin interface at http://127.0.0.1:8000/admin/.

Frontend:
cd studhome/Frontend
flutter run

Run on a connected device or emulator.

API Endpoints

GET /api/houses/: List all houses.
GET /api/house/uuid:house_id/: Retrieve house details.
POST /api/house/uuid:house_id/initiate-payment/: Initiate payment (reserve/tour).
GET /api/payment/verify/str:reference/: Verify payment status.
POST /api/payment/webhook/: CamPay webhook for payment updates.
POST /api/token/: Obtain JWT token.
POST /api/token/refresh/: Refresh JWT token.

Database Schema

User: Custom user model with user_id (UUID), username, email, phone_number.
House: Stores house details with house_id (UUID), house_name, room_type, availability, is_reserved, remove (boolean), price, lat, lng, media (JSON for images/models).
Transaction: Tracks payments with transaction_id (UUID), user, house, amount_paid, transaction_type (reserve/tour), payment_status.
Reservation: Manages reservations with reservation_id (UUID), user, house, reservation_date, expiry_date, is_active.
SavedHome: Links users to saved houses.

Testing

Backend:

Test migrations:python manage.py makemigrations
python manage.py migrate

Test payment initiation:curl -X POST http://127.0.0.1:8000/api/house/<uuid>/initiate-payment/ \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer <access_token>" \
 -d '{"amount": 100, "phone_number": "+237670123456", "transaction_type": "reserve"}'

Test webhook:curl -X POST http://127.0.0.1:8000/api/payment/webhook/ \
 -H "Content-Type: application/json" \
 -d '{"reference": "<campay_reference>", "status": "SUCCESSFUL"}'

Frontend:

Run Flutter tests:flutter test

Test ReservePayment and BookTourPayment screens with valid/invalid phone numbers.

Admin:

Access http://127.0.0.1:8000/admin/ to verify house listings and toggle the remove field.

Troubleshooting

Database Errors:
If column StudHomeApi_house.remove does not exist occurs:python manage.py makemigrations
python manage.py migrate

Check schema: python manage.py dbshell, then \d StudHomeApi_house.

Payment Failures:
Verify CamPay credentials in .env.
Check webhook setup in CamPay dashboard.
Inspect Django logs: tail -f Studhome.log.

Frontend Errors:
Ensure baseUrl in backend_url.dart matches backend (http://127.0.0.1:8000).
Check Flutter console for HTTP errors.

Contributing

Fork the repository.
Create a feature branch: git checkout -b feature-name.
Commit changes: git commit -m "Add feature".
Push to branch: git push origin feature-name.
Open a pull request.

License
This project is licensed under the MIT License.
