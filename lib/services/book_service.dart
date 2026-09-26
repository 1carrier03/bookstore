import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookService {
  BookService({http.Client? client, this.catalogBaseUrl}) : _client = client ?? http.Client();

  static const googleBooksBaseUrl = 'https://www.googleapis.com/books/v1/volumes';
  final http.Client _client;
  final String? catalogBaseUrl;

  Future<List<Book>> fetchBooks({String query = 'subject:fiction', int limit = 20}) async {
    final data = await _get(Uri.parse(googleBooksBaseUrl).replace(queryParameters: {
      'q': query.isEmpty ? 'subject:fiction' : query,
      'maxResults': '${limit.clamp(1, 40)}',
      'orderBy': 'relevance',
      'printType': 'books',
    }));
    return _googleItems(data).map(Book.fromGoogleJson).toList();
  }

  Future<Book> fetchBookDetails(String id) async {
    final data = await _get(Uri.parse('$googleBooksBaseUrl/${Uri.encodeComponent(id)}'));
    return Book.fromGoogleJson(data);
  }

  Future<List<Book>> searchBooks(String query, {int limit = 20}) => fetchBooks(query: query, limit: limit);

  Future<List<Book>> fetchBooksByCategory(String category, {int limit = 20}) => fetchBooks(query: 'subject:${Uri.encodeQueryComponent(category)}', limit: limit);

  Future<List<Book>> fetchBestsellers({int limit = 10}) => fetchBooks(query: 'bestseller', limit: limit);

  Future<List<Book>> fetchNewArrivals({int limit = 10}) => fetchBooks(query: 'new releases', limit: limit);

  Future<List<BookCategory>> fetchCategories() async => const [
        BookCategory(name: 'Fiction'), BookCategory(name: 'Fantasy'),
        BookCategory(name: 'Technology'), BookCategory(name: 'Business'),
        BookCategory(name: 'History'), BookCategory(name: 'Self-help'),
        BookCategory(name: 'Science'),
      ];

  /// CRUD endpoints belong to the store's authenticated catalog backend.
  /// Set catalogBaseUrl to e.g. https://api.example.com/catalog.
  Future<Book> addBook(Book book) => _catalogRequest('POST', '/books', book: book);
  Future<Book> updateBook(String id, Book book) => _catalogRequest('PUT', '/books/${Uri.encodeComponent(id)}', book: book);
  Future<void> deleteBook(String id) async {
    final response = await _client.delete(_catalogUri('/books/${Uri.encodeComponent(id)}'));
    _check(response, expected: {200, 204});
  }

  Future<Book> _catalogRequest(String method, String path, {required Book book}) async {
    final response = method == 'POST'
        ? await _client.post(_catalogUri(path), headers: _headers, body: jsonEncode(book.toJson()))
        : await _client.put(_catalogUri(path), headers: _headers, body: jsonEncode(book.toJson()));
    _check(response, expected: {200, 201});
    return Book.fromJson(_unwrap(response));
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await _client.get(uri, headers: {'Accept': 'application/json'});
    _check(response, expected: {200});
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _googleItems(Map<String, dynamic> data) =>
      ((data['items'] as List?) ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList();

  Uri _catalogUri(String path) {
    if (catalogBaseUrl == null) {
      throw const ApiException('CRUD operations require a catalogBaseUrl backend URL.');
    }
    return Uri.parse('${catalogBaseUrl!.replaceFirst(RegExp(r'/$'), '')}$path');
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json', 'Accept': 'application/json'};

  Map<String, dynamic> _unwrap(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
  }

  void _check(http.Response response, {required Set<int> expected}) {
    if (!expected.contains(response.statusCode)) {
      throw ApiException('Book API request failed (${response.statusCode})', statusCode: response.statusCode);
    }
  }
}
