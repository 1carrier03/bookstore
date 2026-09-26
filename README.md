# bookstore

Book e-commerce catalog with real book API integration, categories, bestsellers, new arrivals, and CRUD support.

## Features

- Real book catalog data from Google Books API
- Fetch books by search term and categories
- Book details screen with publication, rating, price, publisher, and stock info
- Genre/category browsing
- Bestseller and new-arrival sections
- Add, update, and delete support via the service layer
- Flutter UI integration to display catalog content in a bookstore storefront

## Tech stack

- Dart
- Flutter
- Google Books API
- HTTP service layer

## Run locally

1. Install Flutter.
2. Run:

   flutter pub get
   flutter run -d chrome

## Notes

This project uses Google Books API as the real catalog data source. The service layer is structured so it can be swapped to a custom backend or REST API when available.
