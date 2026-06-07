// ignore_for_file: use_build_context_synchronously, file_names
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── STANDALONE ENTRY POINT ─────────────────────────────────────────────────
const bool kMockMode = false; // ← hitting the real database
const String kRestaurantName = 'ZAYTOUNA PARK';
const String kTagline = 'THE COLLECTION';
const String _img = 'https://images.unsplash.com/';

// Reads from .env. Tries a few common key names so it matches your file.
String _env(List<String> keys) {
  for (final k in keys) {
    final v = dotenv.maybeGet(k);
    if (v != null && v.trim().isNotEmpty) return v.trim();
  }
  return '';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kMockMode) {
    await dotenv.load(fileName: '.env');

    final url = _env(['SUPABASE_URL', 'SUPABASE_PROJECT_URL']);
    final anonKey = _env(['SUPABASE_ANON_KEY', 'SUPABASE_KEY', 'ANON_KEY']);

    assert(
      url.isNotEmpty && anonKey.isNotEmpty,
      'Supabase credentials missing from .env. Expected SUPABASE_URL and '
      'SUPABASE_ANON_KEY (or matching keys). Found url="$url".',
    );

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Menu()));
}

// ─── MOCK DATA (fallback for offline testing when kMockMode = true) ─────────
const List<_Category> _mockCategories = [
  _Category(id: 1, name: 'Starters'),
  _Category(id: 2, name: 'Mains'),
  _Category(id: 3, name: 'Desserts'),
  _Category(id: 4, name: 'Drinks'),
];

const List<_MenuItem> _mockItems = [
  _MenuItem(
    id: 1,
    name: 'Burrata & Heirloom Tomato',
    description: 'Creamy burrata, basil oil, aged balsamic, sea salt',
    price: 12.0,
    categoryId: 1,
    categoryName: 'Starters',
    isAvailable: true,
    imageUrl: '${_img}photo-1608897013039-887f21d8c804?w=800&q=70',
  ),
  _MenuItem(
    id: 2,
    name: 'Grilled Halloumi',
    description: 'Charred halloumi, honey, crushed pistachio, mint',
    price: 9.5,
    categoryId: 1,
    categoryName: 'Starters',
    isAvailable: false,
    imageUrl: '${_img}photo-1541529086526-db283c563270?w=800&q=70',
  ),
  _MenuItem(
    id: 3,
    name: 'Signature Burger',
    description: 'Dry-aged beef, aged cheddar, truffle aioli, brioche',
    price: 18.0,
    categoryId: 2,
    categoryName: 'Mains',
    isAvailable: true,
    imageUrl: '${_img}photo-1568901346375-23c9450c58cd?w=800&q=70',
  ),
  _MenuItem(
    id: 4,
    name: 'Saffron Lamb Tagine',
    description: 'Slow-braised lamb, apricot, almond, herbed couscous',
    price: 24.0,
    categoryId: 2,
    categoryName: 'Mains',
    isAvailable: true,
    isSignature: true,
    imageUrl: '${_img}photo-1547928576-b822bc410bdf?w=800&q=70',
  ),
  _MenuItem(
    id: 5,
    name: 'Pistachio Baklava',
    description: 'Layered filo, orange blossom honey, clotted cream',
    price: 8.0,
    categoryId: 3,
    categoryName: 'Desserts',
    isAvailable: true,
    imageUrl: '${_img}photo-1519676867240-f03562e64548?w=800&q=70',
  ),
  _MenuItem(
    id: 6,
    name: 'Fresh Mint Lemonade',
    description: 'Hand-pressed lemon, mint, sparkling water',
    price: 5.0,
    categoryId: 4,
    categoryName: 'Drinks',
    isAvailable: true,
    imageUrl: '${_img}photo-1621263764928-df1444c5e859?w=800&q=70',
  ),
];

// ─── DESIGN TOKENS (Cinematic dark · coral accent) ──────────────────────────
class _T {
  _T._();
  static const bg = Color(0xFF0A0A0B);
  static const bg2 = Color(0xFF141416);
  static const accent = Color(0xFFFF6B35);
  static const accent2 = Color(0xFFFFA94D);
  static const cream = Color(0xFFF7F4EF);
  static const muted = Color(0xFFB5B2AC);
  static const muted2 = Color(0xFF6E6B66);
  static const danger = Color(0xFFFF5252);
}

// ─── MODELS ─────────────────────────────────────────────────────────────────
class _Category {
  final int id;
  final String name;
  const _Category({required this.id, required this.name});
}

class _MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final int? categoryId;
  final String categoryName;
  final bool isAvailable;
  final bool isSignature;
  final String imageUrl;
  const _MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.isAvailable,
    this.isSignature = false,
    this.imageUrl = '',
  });
}

// ─── DECODE WIDTH: cap bitmap size so low-end GPUs decode less ──────────────
int _decodeWidth(BuildContext c) {
  final mq = MediaQuery.of(c);
  final dpr = mq.devicePixelRatio.clamp(1.0, 2.0); // ignore 3x+ on phones
  return (mq.size.width * dpr).round();
}

// ─── SMOOTH PAGE PHYSICS (gentler, well-damped snap) ────────────────────────
class _SmoothPagePhysics extends PageScrollPhysics {
  const _SmoothPagePhysics({super.parent});

  @override
  _SmoothPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SmoothPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.5, stiffness: 110, damping: 18);
}

// ─── PAGE ───────────────────────────────────────────────────────────────────
class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  SupabaseClient get _sb => Supabase.instance.client;

  final PageController _pageController = PageController();

  final ValueNotifier<double> _scrollPage = ValueNotifier<double>(0);

  List<_MenuItem> _items = [];
  List<_Category> _categories = [];
  List<String> _filters = ['All'];
  String _categoryFilter = 'All';
  String _query = '';
  bool _loading = true;
  bool _searching = false;
  String? _error;
  int _page = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPage);
    _loadAll();
  }

  void _onPage() {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return;
    }
    final raw = _pageController.page ?? 0;
    _scrollPage.value = raw; // drives parallax, no setState
    final p = raw.round();
    if (p != _page) setState(() => _page = p);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPage);
    _pageController.dispose();
    _scrollPage.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (kMockMode) {
      await Future.delayed(const Duration(milliseconds: 700));
      _categories = List.of(_mockCategories);
      _items = List.of(_mockItems);
      _filters = ['All', ..._categories.map((c) => c.name)];
      setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        // menu_items: NOTE there is no is_signature column in your schema.
        _sb
            .from('menu_items')
            .select(
              'id, name, description, price, is_available, image_url, '
              'category_id, categories(name)',
            )
            .order('name'),
        // categories: only active ones, ordered by sort_order then name.
        _sb
            .from('categories')
            .select('id, name, sort_order, is_active')
            .eq('is_active', true)
            .order('sort_order', ascending: true, nullsFirst: false)
            .order('name'),
      ]);

      final iRows = results[0] as List;
      final cRows = results[1] as List;

      _items = iRows.map((r) {
        final cat = r['categories'];
        final catName = cat is Map
            ? (cat['name'] as String? ?? 'Uncategorized')
            : (cat is List && cat.isNotEmpty
                  ? (cat.first['name'] as String? ?? 'Uncategorized')
                  : 'Uncategorized');
        return _MenuItem(
          id: (r['id'] as num).toInt(),
          name: r['name'] as String? ?? 'Unnamed',
          description: r['description'] as String? ?? '',
          price: _toDouble(r['price']),
          categoryId: (r['category_id'] as num?)?.toInt(),
          categoryName: catName,
          isAvailable: (r['is_available'] as bool?) ?? true,
          isSignature: false, // no column; signature is derived (priciest)
          imageUrl: r['image_url'] as String? ?? '',
        );
      }).toList();

      _categories = cRows
          .map(
            (r) => _Category(
              id: (r['id'] as num).toInt(),
              name: r['name'] as String? ?? 'Unnamed',
            ),
          )
          .toList();

      _filters = ['All', ..._categories.map((c) => c.name)];
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Postgres `numeric` can arrive as a num OR a string — parse defensively.
  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  void _precacheImages() {
    if (_precached) return;
    _precached = true;
    final w = _decodeWidth(context);
    for (final i in _items) {
      if (i.imageUrl.isNotEmpty) {
        precacheImage(ResizeImage(NetworkImage(i.imageUrl), width: w), context);
      }
    }
  }

  // ─── DERIVED ──────────────────────────────────────────────────────────────
  List<_MenuItem> get _visible {
    final q = _query.toLowerCase().trim();
    final order = _categories.map((c) => c.name).toList();
    final list = _items.where((i) {
      final matchCat =
          _categoryFilter == 'All' || i.categoryName == _categoryFilter;
      final matchQuery =
          q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();
    list.sort((a, b) {
      final ci = order.indexOf(a.categoryName);
      final cj = order.indexOf(b.categoryName);
      if (ci != cj) return ci.compareTo(cj);
      return a.name.compareTo(b.name);
    });
    return list;
  }

  void _selectCategory(String c) {
    setState(() {
      _categoryFilter = c;
      _page = 0;
    });
    _scrollPage.value = 0;
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_loading && _error == null && _items.isNotEmpty && !_precached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _precacheImages();
      });
    }

    return Scaffold(
      backgroundColor: _T.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _loading
            ? _loadingState()
            : (_error != null ? _errorState() : _stage()),
      ),
    );
  }

  Widget _stage() {
    final items = _visible;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final decodeW = _decodeWidth(context);

    return Stack(
      key: const ValueKey('stage'),
      fit: StackFit.expand,
      children: [
        if (items.isEmpty)
          _emptyState()
        else
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const _SmoothPagePhysics(parent: BouncingScrollPhysics()),
            allowImplicitScrolling: true,
            itemCount: items.length,
            itemBuilder: (context, index) => _DishSlide(
              item: items[index],
              index: index,
              page: _scrollPage,
              fmt: _fmt,
              decodeWidth: decodeW,
              reduceMotion: reduceMotion,
            ),
          ),
        _topBar(),
        if (items.isNotEmpty) _pageRail(items.length),
        if (items.isNotEmpty) _swipeHint(),
      ],
    );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _topBar() {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPad + 14, bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _T.bg.withValues(alpha: 0.85),
              _T.bg.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: _searching
                        ? _searchField()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kRestaurantName,
                                style: GoogleFonts.oswald(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: _T.cream,
                                  letterSpacing: 4,
                                ),
                              ),
                              Text(
                                kTagline,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _T.accent,
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 12),
                  _circleBtn(
                    _searching ? Icons.close_rounded : Icons.search_rounded,
                    () => setState(() {
                      _searching = !_searching;
                      if (!_searching) {
                        _query = '';
                        _page = 0;
                        _scrollPage.value = 0;
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(0);
                        }
                      }
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                children: _filters.map((t) {
                  final sel = _categoryFilter == t;
                  return GestureDetector(
                    onTap: () => _selectCategory(t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel
                            ? _T.accent
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? _T.accent
                              : Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        t.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: sel ? Colors.white : _T.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() => SizedBox(
    height: 42,
    child: TextField(
      autofocus: true,
      onChanged: (s) {
        setState(() {
          _query = s;
          _page = 0;
        });
        _scrollPage.value = 0;
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      },
      style: GoogleFonts.inter(color: _T.cream, fontSize: 14),
      cursorColor: _T.accent,
      decoration: InputDecoration(
        hintText: 'Search dishes…',
        hintStyle: GoogleFonts.inter(color: _T.muted2),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: _T.cream, size: 20),
    ),
  );

  // ─── RIGHT-EDGE PAGE RAIL ────────────────────────────────────────────────────
  Widget _pageRail(int count) => Positioned(
    right: 14,
    top: 0,
    bottom: 0,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final active = i == _page;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 4,
            height: active ? 26 : 8,
            decoration: BoxDecoration(
              color: active ? _T.accent : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    ),
  );

  Widget _swipeHint() => Positioned(
    bottom: MediaQuery.of(context).padding.bottom + 18,
    left: 0,
    right: 0,
    child: IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: _page == 0 ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SWIPE UP',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _T.cream.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: _T.cream.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ─── STATES ───────────────────────────────────────────────────────────────
  Widget _loadingState() => Container(
    key: const ValueKey('loading'),
    color: _T.bg,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kRestaurantName,
            style: GoogleFonts.oswald(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: _T.cream,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_T.accent),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _errorState() => Container(
    key: const ValueKey('error'),
    color: _T.bg,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _T.danger, size: 52),
            const SizedBox(height: 14),
            Text(
              'Could not load the menu',
              style: GoogleFonts.oswald(
                fontSize: 20,
                color: _T.cream,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_error',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _T.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _T.accent),
              onPressed: _loadAll,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _emptyState() => Container(
    color: _T.bg,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu_rounded, size: 50, color: _T.muted2),
          const SizedBox(height: 14),
          Text(
            _query.isNotEmpty || _categoryFilter != 'All'
                ? 'No dishes match your search'
                : 'The menu is being prepared',
            style: GoogleFonts.inter(color: _T.muted, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  String _fmt(double v) =>
      v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

// ─── FULL-SCREEN DISH SLIDE ─────────────────────────────────────────────────
class _DishSlide extends StatelessWidget {
  final _MenuItem item;
  final int index;
  final ValueListenable<double> page;
  final String Function(double) fmt;
  final int decodeWidth;
  final bool reduceMotion;
  const _DishSlide({
    required this.item,
    required this.index,
    required this.page,
    required this.fmt,
    required this.decodeWidth,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

    final bg = RepaintBoundary(child: _bg());
    final scrim = _scrim();
    final ribbon = item.isSignature ? _ribbon() : null;
    final content = _content();

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: page,
            builder: (context, p, child) {
              final delta = (index - p).clamp(-1.0, 1.0);
              if (reduceMotion) return child!;
              return Transform.translate(
                offset: Offset(0, delta * -70),
                child: Transform.scale(
                  scale: 1.12,
                  filterQuality: FilterQuality.low,
                  child: child,
                ),
              );
            },
            child: bg,
          ),
          scrim,
          if (ribbon != null)
            Positioned(
              top: topPad + 120,
              left: 0,
              child: reduceMotion
                  ? ribbon
                  : ValueListenableBuilder<double>(
                      valueListenable: page,
                      builder: (context, p, child) {
                        final delta = (index - p).clamp(-1.0, 1.0);
                        return Transform.translate(
                          offset: Offset(delta * 40, 0),
                          child: child,
                        );
                      },
                      child: ribbon,
                    ),
            ),
          Positioned(
            left: 26,
            right: 50,
            bottom: bottomPad + 64,
            child: reduceMotion
                ? content
                : ValueListenableBuilder<double>(
                    valueListenable: page,
                    builder: (context, p, child) {
                      final delta = (index - p).clamp(-1.0, 1.0);
                      final op = (1 - delta.abs() * 1.1).clamp(0.0, 1.0);
                      return Opacity(
                        opacity: op,
                        child: Transform.translate(
                          offset: Offset(0, delta * 40),
                          child: child,
                        ),
                      );
                    },
                    child: content,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _scrim() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x730A0A0B),
          Color(0x0D0A0A0B),
          Color(0x8C0A0A0B),
          Color(0xF50A0A0B),
        ],
        stops: [0.0, 0.32, 0.62, 1.0],
      ),
    ),
  );

  Widget _ribbon() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    decoration: const BoxDecoration(
      color: _T.accent,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          "CHEF'S SIGNATURE",
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        item.categoryName.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
          color: _T.accent2,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        item.name,
        style: GoogleFonts.oswald(
          fontSize: 44,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: _T.cream,
        ),
      ),
      const SizedBox(height: 14),
      if (item.description.isNotEmpty)
        Text(
          item.description,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            height: 1.5,
            color: _T.muted,
          ),
        ),
      const SizedBox(height: 22),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _T.accent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '\$${fmt(item.price)}',
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (!item.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _T.danger.withValues(alpha: 0.6)),
              ),
              child: Text(
                'SOLD OUT',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _T.danger,
                ),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _bg() {
    if (item.imageUrl.isEmpty) return _fallback();
    return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: decodeWidth,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      loadingBuilder: (c, child, p) => p == null ? child : _fallback(),
      errorBuilder: (c, e, s) => _fallback(),
    );
  }

  Widget _fallback() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_T.bg2, _T.bg],
      ),
    ),
    child: Center(
      child: Icon(Icons.restaurant_rounded, color: _T.muted2, size: 54),
    ),
  );
}
