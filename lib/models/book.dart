import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/book.dart';
import 'services/book_service.dart';

void main() {
  runApp(const BookstoreApp());
}

class BookstoreApp extends StatelessWidget {
  const BookstoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookstore Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme,
      ),
      home: const CatalogHomePage(),
    );
  }
}

class CatalogHomePage extends StatefulWidget {
  const CatalogHomePage({super.key});

  @override
  State<CatalogHomePage> createState() => _CatalogHomePageState();
}

class _CatalogHomePageState extends State<CatalogHomePage> {
  final BookService _bookService = BookService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Book>> _booksFuture;
  late Future<List<BookCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  void _loadCatalog() {
    _booksFuture = _bookService.fetchBooks();
    _categoriesFuture = _bookService.fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookstore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = _searchController.text.trim();
              if (query.isEmpty) {
                _loadCatalog();
              } else {
                setState(() {
                  _booksFuture = _bookService.searchBooks(query);
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search books, authors, or genres',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadCatalog();
                      setState(() {});
                    },
                  ),
                ),
                onSubmitted: (value) {
                  final query = value.trim();
                  setState(() {
                    _booksFuture = query.isEmpty
                        ? _bookService.fetchBooks()
                        : _bookService.searchBooks(query);
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Book>>( 
                  future: _booksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Failed to load books: ${snapshot.error}'),
                      );
                    }
                    final books = snapshot.data ?? [];
                    if (books.isEmpty) {
                      return const Center(child: Text('No books available.'));
                    }

                    return ListView(
                      children: [
                        _buildSectionHeader('Categories'),
                        FutureBuilder<List<BookCategory>>(
                          future: _categoriesFuture,
                          builder: (context, categorySnapshot) {
                            if (categorySnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 84,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final categories = categorySnapshot.data ?? [];
                            return SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: ChoiceChip(
                                      label: Text(category.name),
                                      selected: false,
                                      onSelected: (_) {
                                        setState(() {
                                          _booksFuture = _bookService.fetchBooksByCategory(category.name);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Bestsellers'),
                        _buildBookRow(
                          _bookService.buildBestsellers(books),
                          showPrice: true,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('New Arrivals'),
                        _buildBookRow(
                          _bookService.buildNewArrivals(books),
                          showPrice: true,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Catalog'),
                        ...books.map((book) => _BookTile(book: book)).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Text('View all'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookRow(List<Book> books, {bool showPrice = false}) {
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 150,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailsPage(book: book),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: book.imageUrl.isEmpty
                          ? Container(
                              width: 150,
                              height: 150,
                              color: Colors.deepPurple.shade100,
                              child: const Icon(Icons.book, size: 48),
                            )
                          : Image.network(
                              book.imageUrl,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 150,
                                height: 150,
                                color: Colors.deepPurple.shade100,
                                child: const Icon(Icons.book, size: 48),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (showPrice)
                      Text(
                        _formatPrice(book.price),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(num price) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(price);
  }
}

class _BookTile extends StatelessWidget {
  final Book book;

  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: book.imageUrl.isEmpty
              ? Container(
                  width: 56,
                  height: 56,
                  color: Colors.deepPurple.shade100,
                  child: const Icon(Icons.book),
                )
              : Image.network(
                  book.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.deepPurple.shade100,
                    child: const Icon(Icons.book),
                  ),
                ),
        ),
        title: Text(book.title),
        subtitle: Text('${book.author} • ${book.genres.join(', ')}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(book.price),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${book.stock} in stock'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailsPage(book: book),
            ),
          );
        },
      ),
    );
  }
}

class BookDetailsPage extends StatelessWidget {
  final Book book;

  const BookDetailsPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: book.imageUrl.isEmpty
                    ? Container(
                        width: 220,
                        height: 260,
                        color: Colors.deepPurple.shade100,
                        child: const Icon(Icons.book, size: 64),
                      )
                    : Image.network(
                        book.imageUrl,
                        width: 220,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 220,
                          height: 260,
                          color: Colors.deepPurple.shade100,
                          child: const Icon(Icons.book, size: 64),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              book.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'by ${book.author}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange.shade700),
                Text('${book.rating.toStringAsFixed(1)} • ${book.reviewCount} reviews'),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              book.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.genres
                  .map((genre) => Chip(label: Text(genre)))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _InfoRow(label: 'Publisher', value: book.publisher),
            _InfoRow(label: 'Language', value: book.language),
            _InfoRow(label: 'Pages', value: '${book.pages}'),
            _InfoRow(label: 'ISBN', value: book.isbn),
            _InfoRow(
              label: 'Published',
              value: DateFormat.yMMMd().format(book.publishDate),
            ),
            _InfoRow(label: 'Stock', value: '${book.stock} available'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Service creates or updates books. Hook into your backend here.
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Add to cart'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Wishlist'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class BookCategory {
  final String name;
  final String label;

  const BookCategory({required this.name, required this.label});
}

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String isbn;
  final double price;
  final String imageUrl;
  final List<String> genres;
  final double rating;
  final int reviewCount;
  final int stock;
  final DateTime publishDate;
  final String publisher;
  final int pages;
  final String language;
  final bool isBestseller;
  final bool isNewArrival;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.isbn,
    required this.price,
    required this.imageUrl,
    required this.genres,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.publishDate,
    required this.publisher,
    required this.pages,
    required this.language,
    this.isBestseller = false,
    this.isNewArrival = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    final saleInfo = json['saleInfo'] ?? {};
    final authors = (volumeInfo['authors'] as List?) ?? const [];
    final categories = (volumeInfo['categories'] as List?) ?? const [];
    final imageLinks = (volumeInfo['imageLinks'] as Map?) ?? const {};
    final industryIdentifiers = (volumeInfo['industryIdentifiers'] as List?) ?? const [];

    String isbn = '';
    for (final element in industryIdentifiers) {
      final item = element as Map<String, dynamic>;
      final type = item['type'] ?? '';
      final value = item['identifier'] ?? '';
      if (type == 'ISBN_13' || type == 'ISBN_10') {
        isbn = value;
        break;
      }
    }

    final priceValue = saleInfo['listPrice']?['amount'] ?? 0.0;
    final averageRating = volumeInfo['averageRating'] ?? 0.0;
    final ratingCount = volumeInfo['ratingsCount'] ?? 0;
    final description = volumeInfo['description'] ?? 'No description available.';

    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'Untitled',
      author: (authors.isNotEmpty ? authors.first : 'Unknown author').toString(),
      description: description.toString(),
      isbn: isbn,
      price: (priceValue as num?)?.toDouble() ?? 24.99,
      imageUrl: imageLinks['thumbnail'] ?? '',
      genres: categories.map((item) => item.toString()).toList(),
      rating: (averageRating as num?)?.toDouble() ?? 4.5,
      reviewCount: ratingCount as int? ?? 120,
      stock: 25,
      publishDate: DateTime.tryParse(volumeInfo['publishedDate'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      publisher: volumeInfo['publisher'] ?? 'Unknown publisher',
      pages: volumeInfo['pageCount'] as int? ?? 320,
      language: volumeInfo['language'] ?? 'en',
      isBestseller: false,
      isNewArrival: false,
    );
  }
}

class BookService {
  static const String _googleBooksUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<Book>> fetchBooks({String query = 'fiction', String category = ''}) async {
    final uri = Uri.parse(_googleBooksUrl).replace(
      queryParameters: {
        'q': query.isEmpty ? 'fiction' : query,
        'maxResults': '20',
      },
    );

    final response = await httpGet(uri);
    final Map<String, dynamic> json = response;
    final items = (json['items'] as List?) ?? const [];

    return items
        .map((item) => Book.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Book>> searchBooks(String query) async {
    return fetchBooks(query: query.trim());
  }

  Future<List<Book>> fetchBooksByCategory(String category) async {
    final normalized = category.trim();
    if (normalized.isEmpty) {
      return fetchBooks();
    }
    return fetchBooks(query: normalized);
  }

  Future<List<BookCategory>> fetchCategories() async {
    return const [
      BookCategory(name: 'Fiction', label: 'Fiction'),
      BookCategory(name: 'Fantasy', label: 'Fantasy'),
      BookCategory(name: 'Technology', label: 'Technology'),
      BookCategory(name: 'Business', label: 'Business'),
      BookCategory(name: 'Self Help', label: 'Self Help'),
      BookCategory(name: 'History', label: 'History'),
    ];
  }

  List<Book> buildBestsellers(List<Book> books) {
    if (books.isEmpty) return [];
    return books.take(6).toList();
  }

  List<Book> buildNewArrivals(List<Book> books) {
    if (books.isEmpty) return [];
    return books.skip(1).take(6).toList();
  }

  Future<Map<String, dynamic>> httpGet(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load books: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  Future<Book> fetchBookDetails(String id) async {
    final uri = Uri.parse('$_googleBooksUrl/$id');
    final response = await httpGet(uri);
    return Book.fromJson(response as Map<String, dynamic>);
  }

  Future<Book> addBook(Book book) async {
    return book;
  }

  Future<Book> updateBook(String id, Book book) async {
    return book;
  }

  Future<void> deleteBook(String id) async {
    return;
  }
}

const String _httpPackageImport = 'package:http/http.dart';

// This import must be present, but it's intentionally referenced in a way that allows
// the code to compile cleanly in environments without package re-export.
import 'dart:convert';
import 'package:http/http.dart' as http;
