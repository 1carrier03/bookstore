import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/book.dart';
import 'services/book_service.dart';

void main() => runApp(const BookstoreApp());

class BookstoreApp extends StatelessWidget {
  const BookstoreApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bookstore',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
        home: const CatalogPage(),
      );
}

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final service = BookService();
  final search = TextEditingController();
  late Future<List<Book>> catalog;
  late Future<List<BookCategory>> categories;
  late Future<List<Book>> bestsellers;
  late Future<List<Book>> arrivals;

  @override
  void initState() {
    super.initState();
    _refresh();
    categories = service.fetchCategories();
  }

  void _refresh() {
    catalog = service.fetchBooks();
    bestsellers = service.fetchBestsellers();
    arrivals = service.fetchNewArrivals();
    setStateIfMounted();
  }

  void setStateIfMounted() {
    if (mounted) setState(() {});
  }

  Future<void> _search() async {
    final query = search.text.trim();
    setState(() => catalog = query.isEmpty ? service.fetchBooks() : service.searchBooks(query));
  }

  @override
  void dispose() { search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Bookstore Catalog')),
        body: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextField(controller: search, onSubmitted: (_) => _search(), decoration: InputDecoration(
              hintText: 'Search titles, authors, or ISBN', prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
              border: const OutlineInputBorder(),
            )),
            const SizedBox(height: 20),
            _futureSection('Bestsellers', bestsellers),
            _futureSection('New Arrivals', arrivals),
            const Text('Genres', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<BookCategory>>(future: categories, builder: (_, snapshot) => Wrap(spacing: 8, children: (snapshot.data ?? []).map((category) => ActionChip(
              label: Text(category.name), onPressed: () => setState(() => catalog = service.fetchBooksByCategory(category.name)),
            )).toList())),
            const SizedBox(height: 20),
            const Text('All Books', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            FutureBuilder<List<Book>>(future: catalog, builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
              if (snapshot.hasError) return Text('Unable to load books: ${snapshot.error}');
              return Column(children: (snapshot.data ?? []).map((book) => BookTile(book: book)).toList());
            }),
          ]),
        ),
      );

  Widget _futureSection(String title, Future<List<Book>> future) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 215, child: FutureBuilder<List<Book>>(future: future, builder: (_, snapshot) => ListView(
          scrollDirection: Axis.horizontal,
          children: (snapshot.data ?? []).map((book) => SizedBox(width: 150, child: BookCard(book: book))).toList(),
        ))),
        const SizedBox(height: 12),
      ]);
}

class BookCard extends StatelessWidget {
  final Book book;
  const BookCard({super.key, required this.book});
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(book: book))), child: Padding(
        padding: const EdgeInsets.only(right: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Image.network(book.imageUrl, width: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 80))),
          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(NumberFormat.currency(symbol: '\$').format(book.price)),
        ])));
}

class BookTile extends StatelessWidget {
  final Book book;
  const BookTile({super.key, required this.book});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Image.network(book.imageUrl, width: 50, errorBuilder: (_, __, ___) => const Icon(Icons.book)), title: Text(book.title), subtitle: Text(book.authorLabel), trailing: Text(NumberFormat.currency(symbol: '\$').format(book.price)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(book: book)))));
}

class DetailsPage extends StatelessWidget {
  final Book book;
  const DetailsPage({super.key, required this.book});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Book Details')), body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Image.network(book.imageUrl, height: 280, errorBuilder: (_, __, ___) => const Icon(Icons.book, size: 160))),
        Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
        Text(book.authorLabel, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12), Text(book.description),
        const SizedBox(height: 12), Text('Rating: ${book.rating.toStringAsFixed(1)} (${book.ratingsCount} ratings)'),
        Text('Publisher: ${book.publisher}'), Text('ISBN: ${book.isbn}'), Text('Pages: ${book.pageCount ?? '—'}'),
        Text('Published: ${book.publishedDate == null ? '—' : DateFormat.yMMMd().format(book.publishedDate!)}'),
      ]));
}
