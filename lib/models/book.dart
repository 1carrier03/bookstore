import 'package:flutter/material.dart';

class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String isbn;
  final String imageUrl;
  final List<String> categories;
  final double rating;
  final int ratingsCount;
  final DateTime? publishedDate;
  final String publisher;
  final int? pageCount;
  final String language;
  final double price;
  final int stock;
  final bool isBestseller;
  final bool isNewArrival;

  const Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.isbn,
    required this.imageUrl,
    required this.categories,
    required this.rating,
    required this.ratingsCount,
    required this.publishedDate,
    required this.publisher,
    required this.pageCount,
    required this.language,
    required this.price,
    required this.stock,
    required this.isBestseller,
    required this.isNewArrival,
  });

  String get authorLabel => authors.isEmpty ? 'Unknown author' : authors.join(', ');

  factory Book.fromGoogleJson(Map<String, dynamic> json) {
    final info = _map(json['volumeInfo']);
    final sale = _map(json['saleInfo']);
    final imageLinks = _map(info['imageLinks']);
    final identifiers = (info['industryIdentifiers'] as List?) ?? const [];
    final isbn = identifiers
        .map((value) => _map(value))
        .firstWhere((value) => value['type'] == 'ISBN_13' || value['type'] == 'ISBN_10', orElse: () => {})['identifier'] as String? ?? '';
    final amount = _map(sale['listPrice'])['amount'];
    final rawDate = info['publishedDate'] as String?;

    return Book(
      id: json['id'] as String? ?? '',
      title: info['title'] as String? ?? 'Untitled',
      authors: ((info['authors'] as List?) ?? const []).map((value) => value.toString()).toList(),
      description: _stripHtml(info['description'] as String? ?? 'No description available.'),
      isbn: isbn,
      imageUrl: ((imageLinks['thumbnail'] ?? imageLinks['smallThumbnail']) as String? ?? '').replaceFirst('http://', 'https://'),
      categories: ((info['categories'] as List?) ?? const []).map((value) => value.toString()).toList(),
      rating: (info['averageRating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (info['ratingsCount'] as num?)?.toInt() ?? 0,
      publishedDate: rawDate == null ? null : DateTime.tryParse(rawDate),
      publisher: info['publisher'] as String? ?? 'Unknown publisher',
      pageCount: (info['pageCount'] as num?)?.toInt(),
      language: info['language'] as String? ?? 'en',
      price: (amount as num?)?.toDouble() ?? 0,
      stock: 0,
      isBestseller: false,
      isNewArrival: false,
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      authors: ((json['authors'] as List?) ?? const []).map((value) => value.toString()).toList(),
      description: json['description'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      categories: ((json['categories'] as List?) ?? const []).map((value) => value.toString()).toList(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      publishedDate: DateTime.tryParse(json['publishedDate'] as String? ?? ''),
      publisher: json['publisher'] as String? ?? '',
      pageCount: (json['pageCount'] as num?)?.toInt(),
      language: json['language'] as String? ?? 'en',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isBestseller: json['isBestseller'] as bool? ?? false,
      isNewArrival: json['isNewArrival'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authors': authors,
        'description': description,
        'isbn': isbn,
        'imageUrl': imageUrl,
        'categories': categories,
        'rating': rating,
        'ratingsCount': ratingsCount,
        'publishedDate': publishedDate?.toIso8601String(),
        'publisher': publisher,
        'pageCount': pageCount,
        'language': language,
        'price': price,
        'stock': stock,
        'isBestseller': isBestseller,
        'isNewArrival': isNewArrival,
      };

  Book copyWith({double? price, int? stock, bool? isBestseller, bool? isNewArrival}) => Book(
        id: id, title: title, authors: authors, description: description, isbn: isbn,
        imageUrl: imageUrl, categories: categories, rating: rating, ratingsCount: ratingsCount,
        publishedDate: publishedDate, publisher: publisher, pageCount: pageCount, language: language,
        price: price ?? this.price, stock: stock ?? this.stock,
        isBestseller: isBestseller ?? this.isBestseller,
        isNewArrival: isNewArrival ?? this.isNewArrival,
      );

  static Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
  static String _stripHtml(String value) => value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

class BookCategory {
  final String name;
  final int bookCount;
  const BookCategory({required this.name, this.bookCount = 0});
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
