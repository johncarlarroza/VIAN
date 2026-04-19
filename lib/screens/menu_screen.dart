import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vian_kopi/widgets/vivian_chat_sheet.dart';

import '../data/menu_repository.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import 'payment_screen.dart';

class MenuScreen extends StatefulWidget {
  final String orderType;

  const MenuScreen({super.key, required this.orderType});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late List<CategoryModel> _categories;
  String _selectedCategoryId = 'best_sellers';
  String _searchText = '';

  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleScale;
  late final Animation<Offset> _bubbleSlide;

  double _vivianTop = 120;
  double _vivianLeft = 0;
  bool _vivianPositionReady = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _categories = MenuRepository.getCategories();
    if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    }

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bubbleScale = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutBack,
    );

    _bubbleSlide =
        Tween<Offset>(
          begin: const Offset(0.12, -0.12),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _bubbleController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bubbleController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  List<ProductModel> get _visibleProducts {
    if (_searchText.trim().isNotEmpty) {
      return MenuRepository.searchProducts(_searchText);
    }
    return MenuRepository.getProductsByCategory(_selectedCategoryId);
  }

  String get _sectionTitle {
    if (_searchText.trim().isNotEmpty) return 'Search Results';
    if (_selectedCategoryId == 'best_sellers') return 'Best Sellers';

    final match = _categories.where((e) => e.id == _selectedCategoryId);
    if (match.isNotEmpty) return match.first.name;

    return 'Menu';
  }

  bool _isDesktop(double width) => width >= 1150;
  bool _isTablet(double width) => width >= 700 && width < 1150;

  double _bubbleWidth(double screenWidth) {
    return screenWidth < 700 ? 158 : 185;
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;

      if (!_showSearch) {
        _searchController.clear();
        _searchText = '';
      }
    });
  }

  Widget _buildSearchToggleButton() {
    return InkWell(
      onTap: _toggleSearch,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          _showSearch ? Icons.close_rounded : Icons.search_rounded,
          color: const Color(0xFF1E2C24),
          size: 20,
        ),
      ),
    );
  }

  void _initVivianPosition(BoxConstraints constraints) {
    if (_vivianPositionReady) return;

    final bubbleWidth = _bubbleWidth(constraints.maxWidth);
    _vivianLeft = constraints.maxWidth - bubbleWidth - 12;
    _vivianTop = constraints.maxHeight > 220 ? 110 : 80;
    _vivianPositionReady = true;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _initVivianPosition(constraints);

            final bubbleWidth = _bubbleWidth(constraints.maxWidth);
            final bubbleHeight = constraints.maxWidth < 700 ? 58.0 : 62.0;

            return Stack(
              children: [
                _buildMainContent(cart),

                Positioned(
                  left: _vivianLeft,
                  top: _vivianTop,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _vivianLeft += details.delta.dx;
                        _vivianTop += details.delta.dy;

                        _vivianLeft = _vivianLeft.clamp(
                          8.0,
                          constraints.maxWidth - bubbleWidth - 8,
                        );

                        _vivianTop = _vivianTop.clamp(
                          8.0,
                          constraints.maxHeight - bubbleHeight - 8,
                        );
                      });
                    },
                    onPanEnd: (_) {
                      final screenMid = constraints.maxWidth / 2;

                      setState(() {
                        if (_vivianLeft + (bubbleWidth / 2) < screenMid) {
                          _vivianLeft = 8;
                        } else {
                          _vivianLeft = constraints.maxWidth - bubbleWidth - 8;
                        }
                      });
                    },
                    child: _buildFloatingVivianBubble(
                      isDesktop: _isDesktop(constraints.maxWidth),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(CartProvider cart) {
    final products = _visibleProducts;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = _isDesktop(width);
    final isTablet = _isTablet(width);

    return isDesktop
        ? Column(
            children: [
              _buildTopBar(isDesktop: true),
              Expanded(
                child: Row(
                  children: [
                    _buildCategorySidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildSectionHeader(products.length),
                          Expanded(
                            child: products.isEmpty
                                ? _buildEmptyState()
                                : _buildProductsGrid(
                                    products,
                                    crossAxisCount: 4,
                                    childAspectRatio: 0.76,
                                    paddingBottom: 18,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    _buildCartPanel(cart),
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              _buildTopBar(isDesktop: false),
              _buildMobileCategoryStrip(),
              Expanded(
                child: Column(
                  children: [
                    _buildSectionHeader(products.length),
                    Expanded(
                      child: products.isEmpty
                          ? _buildEmptyState()
                          : _buildProductsGrid(
                              products,
                              crossAxisCount: isTablet ? 3 : 2,
                              childAspectRatio: isTablet ? 0.78 : 0.72,
                              paddingBottom: cart.itemList.isNotEmpty
                                  ? 120
                                  : 24,
                            ),
                    ),
                  ],
                ),
              ),
              if (cart.itemList.isNotEmpty) _buildMobileCartBar(cart),
            ],
          );
  }

  Widget _buildFloatingVivianBubble({required bool isDesktop}) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 700;

    return SlideTransition(
      position: _bubbleSlide,
      child: ScaleTransition(
        scale: _bubbleScale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showVivianChat,
            borderRadius: BorderRadius.circular(999),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 14,
                    vertical: isSmallScreen ? 10 : 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1F6D44).withOpacity(0.92),
                        const Color(0xFF245E46).withOpacity(0.84),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildVivianGifIcon(size: isSmallScreen ? 34 : 38),
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7CFFAA),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      if (!isSmallScreen) ...[
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vivian',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                _TypingDot(delay: 0),
                                SizedBox(width: 3),
                                _TypingDot(delay: 180),
                                SizedBox(width: 3),
                                _TypingDot(delay: 360),
                                SizedBox(width: 6),
                                Text(
                                  'Ask me anything',
                                  style: TextStyle(
                                    color: Color(0xFFE8F8EE),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.2,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVivianGifIcon({double size = 28}) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          color: Colors.white.withOpacity(0.12),
          child: Image.asset(
            'assets/vivian_logo.gif',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return const Center(
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required bool isDesktop}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 18,
        vertical: isSmall ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EBEE))),
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _backButton(),
                const SizedBox(width: 12),
                _buildLogo(),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTitleSection(),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(width: 340, child: _buildSearchField()),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _backButton(),
                    const SizedBox(width: 10),
                    _buildLogo(size: isSmall ? 44 : 48),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTitleSection(compact: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSearchField(),
              ],
            ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1E2C24),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildLogo({double size = 52}) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAED)),
      ),
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.storefront),
      ),
    );
  }

  Widget _buildTitleSection({bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VIAN CAFÉ',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF183126),
            fontSize: compact ? 17 : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 13,
              color: Color(0xFF77837C),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                widget.orderType == 'dine_in'
                    ? 'DINE-IN ORDER'
                    : 'TAKEOUT ORDER',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF77837C),
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(
          color: Color(0xFF25332B),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search menu...',
          hintStyle: const TextStyle(
            color: Color(0xFF96A0A8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF8E98A1),
          ),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF8E98A1),
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 220,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE7EBEE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2F26),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Browse menu items',
            style: TextStyle(
              color: Color(0xFF8B9690),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected =
                    category.id == _selectedCategoryId &&
                    _searchText.trim().isEmpty;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                      _searchText = '';
                      _searchController.clear();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1F6D44)
                          : const Color(0xFFF6F8F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1F6D44)
                            : const Color(0xFFE5EAEE),
                      ),
                      boxShadow: selected
                          ? const [
                              BoxShadow(
                                color: Color(0x19000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.16)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _chipEmoji(category.id),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF334239),
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCategoryStrip() {
    return Container(
      height: 78,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EBEE))),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected =
              category.id == _selectedCategoryId && _searchText.trim().isEmpty;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _selectedCategoryId = category.id;
                _searchText = '';
                _searchController.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF1F6D44)
                    : const Color(0xFFF6F8F9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1F6D44)
                      : const Color(0xFFE5EAEE),
                ),
              ),
              child: Row(
                children: [
                  Text(_chipEmoji(category.id)),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334239),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(
        children: [
          Text(
            _selectedCategoryId == 'best_sellers' && _searchText.trim().isEmpty
                ? '⭐'
                : '🍽',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _sectionTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF213229),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E9ED)),
            ),
            child: Text(
              '$count item${count == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Color(0xFF6D7A73),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No products found.',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xFF7A7A7A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductsGrid(
    List<ProductModel> products, {
    required int crossAxisCount,
    required double childAspectRatio,
    required double paddingBottom,
  }) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(18, 8, 18, paddingBottom),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductGridCard(
          product: product,
          onAdd: () => _showVariantSheet(product),
          emoji: _productEmoji(product.categoryId),
        );
      },
    );
  }

  Widget _buildCartPanel(CartProvider cart) {
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE7EBEE))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE7EBEE))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Current Order',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF223128),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.totalItems}',
                    style: const TextStyle(
                      color: Color(0xFF1F6D44),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildCartItems(cart)),
          _buildCartFooter(cart),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    return cart.itemList.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No items in cart.\nSelect products from the menu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8A9690),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            itemCount: cart.itemList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = cart.itemList[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7ECF0)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _productEmoji(item.product.categoryId),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: Color(0xFF324238),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _prettyVariant(item.variant),
                                style: const TextStyle(
                                  color: Color(0xFF88948D),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₱${item.unitPrice.toStringAsFixed(0)} each',
                                style: const TextStyle(
                                  color: Color(0xFF6D7A73),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            context.read<CartProvider>().removeItem(
                              item.cartKey,
                            );
                          },
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: Color(0xFF8E8E8E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE3E8EC)),
                          ),
                          child: Row(
                            children: [
                              _qtyMiniButton(
                                icon: Icons.remove,
                                onTap: () {
                                  context.read<CartProvider>().decreaseQty(
                                    item.cartKey,
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF324238),
                                  ),
                                ),
                              ),
                              _qtyMiniButton(
                                icon: Icons.add,
                                onTap: () {
                                  context.read<CartProvider>().increaseQty(
                                    item.cartKey,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₱${item.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F6D44),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildCartFooter(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EBEE))),
      ),
      child: Column(
        children: [
          _summaryRow('Items', '${cart.totalItems}'),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', '₱${cart.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF223128),
                ),
              ),
              const Spacer(),
              Text(
                '₱${cart.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F6D44),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6D44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: cart.itemList.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PaymentScreen(orderType: widget.orderType),
                        ),
                      );
                    },
              child: const Text(
                'Proceed to Payment',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: cart.itemList.isEmpty
                ? null
                : () {
                    context.read<CartProvider>().clearCart();
                  },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFF8A9890),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EBEE))),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cart.totalItems} item${cart.totalItems == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF6E7A74),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${cart.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF1F6D44),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F6D44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _showCartBottomSheet,
                  child: const Text(
                    'View Cart',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartBottomSheet() {
    final cart = context.read<CartProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 64,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DDE1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Current Order',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF223128),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F6F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Color(0xFF1F6D44),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildCartItems(cart)),
                _buildCartFooter(cart),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E7A74),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2F3D35),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _qtyMiniButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: const Color(0xFF46634F)),
      ),
    );
  }

  void _showVariantSheet(ProductModel product) {
    String selectedVariant = product.availableVariants.isNotEmpty
        ? product.availableVariants.first
        : 'regular';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final price = product.prices[selectedVariant] ?? product.basePrice;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7DDE1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF223128),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: const TextStyle(
                          color: Color(0xFF7A7F7C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose variant',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF223128),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: product.availableVariants.map((variant) {
                          final selected = variant == selectedVariant;
                          final variantPrice =
                              product.prices[variant] ?? product.basePrice;

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setModal(() {
                                selectedVariant = variant;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF1F6D44)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1F6D44)
                                      : const Color(0xFFE3E8EC),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _prettyVariant(variant),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF314933),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₱${variantPrice.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFFE9F5EC)
                                          : const Color(0xFF1F6D44),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F6D44),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            context.read<CartProvider>().addItem(
                              product: product,
                              variant: selectedVariant,
                            );
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Add to Order • ₱${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVivianChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VivianChatSheet(orderType: widget.orderType),
    );
  }

  String _prettyVariant(String value) {
    switch (value) {
      case 'hot':
        return 'Hot';
      case 'iced12':
        return 'Iced 12oz';
      case 'iced16':
        return 'Iced 16oz';
      case 'withDrink':
        return 'With Drink';
      case 'withoutDrink':
        return 'Without Drink';
      case 'slice':
        return 'Slice';
      case 'whole':
        return 'Whole';
      case 'regular':
        return 'Regular';
      case 'large':
        return 'Large';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String _chipEmoji(String id) {
    switch (id) {
      case 'best_sellers':
        return '⭐';
      case 'drinks':
        return '☕';
      case 'meals':
        return '🍛';
      case 'snacks':
        return '🍟';
      case 'desserts':
        return '🍰';
      default:
        return '🍽';
    }
  }

  String _productEmoji(String categoryId) {
    switch (categoryId) {
      case 'drinks':
        return '☕';
      case 'meals':
        return '🍛';
      case 'snacks':
        return '🍟';
      case 'desserts':
        return '🍰';
      default:
        return '🍽';
    }
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(
      begin: 0.7,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;
  final String emoji;

  const _ProductGridCard({
    required this.product,
    required this.onAdd,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = product.prices.values.isEmpty
        ? 0.0
        : product.prices.values.reduce((a, b) => a < b ? a : b);

    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: product.imageUrl.trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Image.asset(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 44),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 44),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isBestSeller) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2CC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'BESTSELLER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB57A00),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E3D35),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.2,
                      height: 1.3,
                      color: Color(0xFF86918B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₱${minPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF1F6D44),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F6D44),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: onAdd,
                          child: const Text(
                            'Add',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
