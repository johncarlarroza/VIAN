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

  List<CategoryModel> _categories = const [];
  String _selectedCategoryId = 'all_menu';
  String _searchText = '';

  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleScale;
  late final Animation<Offset> _bubbleSlide;

  double _vivianTop = 110;
  double _vivianLeft = 8;
  bool _vivianPositionReady = false;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bubbleScale = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutBack,
    );

    _bubbleSlide = Tween<Offset>(
      begin: const Offset(-0.12, -0.12),
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

  Stream<List<ProductModel>> get _visibleProductsStream {
    if (_searchText.trim().isNotEmpty) {
      return MenuRepository.searchProducts(_searchText);
    }
    return MenuRepository.watchProductsByCategory(_selectedCategoryId);
  }

  String get _sectionTitle {
    if (_searchText.trim().isNotEmpty) return 'Search Results';
    if (_selectedCategoryId == 'all_menu') return 'All Menu';
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

  void _initVivianPosition(BoxConstraints constraints) {
    if (_vivianPositionReady) return;

    _vivianLeft = 7;
    _vivianTop = constraints.maxHeight > 220 ? 140 : 80;
    _vivianPositionReady = true;
  }

  Future<void> _showCustomerInfoDialog() async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F5EC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF1F6D44),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF213229),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Customer name is optional before payment.',
                            style: TextStyle(
                              color: Color(0xFF7C8B84),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Customer Name (optional)',
                    hintText: 'Leave blank for Walk-in Customer',
                    filled: true,
                    fillColor: const Color(0xFFF6F8F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF1F6D44),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'If left empty, the transaction will be saved as Walk-in Customer.',
                  style: TextStyle(
                    color: Color(0xFF8A9690),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E7EB)),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final customerName = nameController.text.trim().isEmpty
                              ? 'Walk-in Customer'
                              : nameController.text.trim();

                          Navigator.pop(dialogContext);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                orderType: widget.orderType,
                                customerName: customerName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: const Color(0xFF1F6D44),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
  }

  void _showVivianChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VivianChatSheet(orderType: widget.orderType),
    );
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
    return StreamBuilder<List<CategoryModel>>(
      stream: MenuRepository.watchCategories(),
      builder: (context, categorySnapshot) {
        if (!categorySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        _categories = categorySnapshot.data!;

        if (_categories.isNotEmpty &&
            !_categories.any((e) => e.id == _selectedCategoryId)) {
          _selectedCategoryId = _categories.first.id;
        }

        return StreamBuilder<List<ProductModel>>(
          stream: _visibleProductsStream,
          builder: (context, productSnapshot) {
            if (!productSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final products = productSnapshot.data!;
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
                                            // childAspectRatio: 0.96,
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
                                      // childAspectRatio: isTablet ? 0.90 : 0.74,
                                      paddingBottom:
                                          cart.itemList.isNotEmpty ? 120 : 24,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      if (cart.itemList.isNotEmpty) _buildMobileCartBar(cart),
                    ],
                  );
          },
        );
      },
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
                          children: const [
                            Text(
                              'Vivian',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                                height: 1.0,
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                if (_showSearch)
                  SizedBox(width: 340, child: _buildSearchField())
                else
                  _buildSearchToggleButton(),
                if (_showSearch) ...[
                  const SizedBox(width: 10),
                  _buildSearchToggleButton(),
                ],
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
                    const SizedBox(width: 8),
                    _buildSearchToggleButton(),
                  ],
                ),
                if (_showSearch) ...[
                  const SizedBox(height: 12),
                  _buildSearchField(),
                ],
              ],
            ),
    );
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
                            child: Icon(
                              _categoryIcon(category.id),
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF1F6D44),
                              size: 19,
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
                  Icon(
                    _categoryIcon(category.id),
                    color: selected ? Colors.white : const Color(0xFF1F6D44),
                    size: 18,
                  ),
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
          Icon(
            _categoryIcon(_selectedCategoryId),
            color: const Color(0xFF1F6D44),
            size: 22,
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
  required double paddingBottom,
}) {
  return GridView.builder(
    padding: EdgeInsets.fromLTRB(18, 8, 18, paddingBottom),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      mainAxisExtent: 245, // adjust to 195-215 if needed
    ),
    itemCount: products.length,
    itemBuilder: (context, index) {
      final product = products[index];
      return _ProductGridCard(
        product: product,
        onAdd: () => _showVariantSheet(product),
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
                        _CartItemThumb(product: item.product),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
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
              onPressed:
                  cart.itemList.isEmpty ? null : () => _showCustomerInfoDialog(),
              child: const Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartBar(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EBEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cart.totalItems} item${cart.totalItems == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Color(0xFF7A857F),
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 3),
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
          const SizedBox(width: 12),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => _showCustomerInfoDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6D44),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyMiniButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: const Color(0xFF486056)),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7A857F),
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF223128),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Future<void> _showVariantSheet(ProductModel product) async {
    final variants = product.availableVariants.isNotEmpty
        ? product.availableVariants
        : product.prices.keys.toList();

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product has no available variant.')),
      );
      return;
    }

    if (!product.hasVariants || variants.length == 1) {
      final selectedVariant = variants.first;
      context.read<CartProvider>().addItem(
            product: product,
            variant: selectedVariant,
            quantity: 1,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} added to cart.')),
      );
      return;
    }

    String selectedVariant = variants.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.32),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.78,
              minChildSize: 0.52,
              maxChildSize: 0.94,
              expand: false,
              builder: (_, controller) {
                return ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.92),
                            const Color(0xFFF6FBF8).withOpacity(0.88),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.65),
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: EdgeInsets.fromLTRB(
                          18,
                          14,
                          18,
                          MediaQuery.of(context).padding.bottom + 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 52,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB9C6BF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.42),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _BottomSheetProductPreview(product: product),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF223128),
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          product.description,
                                          style: const TextStyle(
                                            color: Color(0xFF697871),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.2,
                                            height: 1.45,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAF6EF),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: const Color(0xFFD6ECDC),
                                            ),
                                          ),
                                          child: Text(
                                            'Choose your preferred variant',
                                            style: TextStyle(
                                              color: const Color(0xFF1F6D44)
                                                  .withOpacity(0.95),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Select Variant',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF223128),
                                fontSize: 16.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...variants.map((variant) {
                              final price =
                                  product.prices[variant] ?? product.basePrice;
                              final selected = selectedVariant == variant;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedVariant = variant;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFFEAF6EF)
                                              .withOpacity(0.92)
                                          : Colors.white.withOpacity(0.48),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF1F6D44)
                                            : const Color(0xFFDCE5DF),
                                        width: selected ? 1.5 : 1,
                                      ),
                                      boxShadow: selected
                                          ? const [
                                              BoxShadow(
                                                color: Color(0x14000000),
                                                blurRadius: 12,
                                                offset: Offset(0, 5),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? const Color(0xFF1F6D44)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: selected
                                                  ? const Color(0xFF1F6D44)
                                                  : const Color(0xFFB8C5BE),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: selected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _prettyVariant(variant),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? const Color(0xFF1F6D44)
                                                  : const Color(0xFF2E3A34),
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₱${price.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: selected
                                                ? const Color(0xFF1F6D44)
                                                : const Color(0xFF2E3A34),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  context.read<CartProvider>().addItem(
                                        product: product,
                                        variant: selectedVariant,
                                        quantity: 1,
                                      );

                                  Navigator.pop(sheetContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content:
                                          Text('${product.name} added to cart.'),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xFF1F6D44),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Add to Cart',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _categoryIcon(String id) {
    switch (id) {
      case 'all_menu':
        return Icons.restaurant_menu_rounded;
      case 'best_sellers':
        return Icons.star_rounded;
      case 'drinks':
        return Icons.local_cafe_rounded;
      case 'meals':
        return Icons.restaurant_rounded;
      case 'snacks':
        return Icons.bakery_dining_rounded;
      case 'desserts':
        return Icons.cake_rounded;
      default:
        return Icons.fastfood_rounded;
    }
  }

  static String _prettyVariant(String value) {
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
      case 'regular':
        return 'Regular';
      case 'large':
        return 'Large';
      case 'slice':
        return 'Slice';
      case 'whole':
        return 'Whole';
      case 'default':
        return 'Default';
      case 'bbq':
        return 'BBQ';
      case 'cheese':
        return 'Cheese';
      case 'sourCream':
        return 'Sour Cream';
      case 'plain':
        return 'Plain';
      default:
        return value;
    }
  }
}

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAdd;

  const _ProductGridCard({
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final minPrice = product.prices.isEmpty
        ? product.basePrice
        : product.prices.values.reduce((a, b) => a < b ? a : b);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.75),
          width: 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 142,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _ProductThumb(product: product),
                ),
                if (product.isBestSeller)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F6D44),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Best Seller',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF213229),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7A857F),
                    fontWeight: FontWeight.w600,
                    fontSize: 10.8,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'From ₱${minPrice.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1F6D44),
                          fontWeight: FontWeight.w900,
                          fontSize: 13.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: product.stockQty <= 0 ? null : onAdd,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF1F6D44),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 14),
                        label: const Text(
                          'Add',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
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
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final ProductModel product;
  final bool compact;

  const _ProductThumb({
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 16.0 : 22.0;
    final iconSize = compact ? 24.0 : 42.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(
        child: Container(
          color: const Color(0xFFF3F6F7),
          child: product.imageUrl.trim().isNotEmpty
              ? Image.asset(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _fallback(iconSize),
                )
              : _fallback(iconSize),
        ),
      ),
    );
  }

  Widget _fallback(double iconSize) {
    return Center(
      child: Icon(
        _fallbackIcon(product),
        size: iconSize,
        color: const Color(0xFF6D7A73),
      ),
    );
  }

  IconData _fallbackIcon(ProductModel product) {
    switch (product.categoryId) {
      case 'drinks':
        return Icons.local_cafe_rounded;
      case 'meals':
        return Icons.restaurant_rounded;
      case 'snacks':
        return Icons.fastfood_rounded;
      case 'desserts':
        return Icons.cake_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}

class _CartItemThumb extends StatelessWidget {
  final ProductModel product;

  const _CartItemThumb({required this.product});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: const Color(0xFFF0F3F5),
          child: product.imageUrl.trim().isNotEmpty
              ? Image.asset(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    IconData icon;
    switch (product.categoryId) {
      case 'drinks':
        icon = Icons.local_cafe_rounded;
        break;
      case 'meals':
        icon = Icons.restaurant_rounded;
        break;
      case 'snacks':
        icon = Icons.fastfood_rounded;
        break;
      case 'desserts':
        icon = Icons.cake_rounded;
        break;
      default:
        icon = Icons.restaurant_menu_rounded;
    }

    return Center(
      child: Icon(
        icon,
        color: const Color(0xFF6D7A73),
        size: 22,
      ),
    );
  }
}

class _BottomSheetProductPreview extends StatelessWidget {
  final ProductModel product;

  const _BottomSheetProductPreview({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.55),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
      ),
      child: product.imageUrl.trim().isNotEmpty
          ? Image.asset(
              product.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    IconData icon;
    switch (product.categoryId) {
      case 'drinks':
        icon = Icons.local_cafe_rounded;
        break;
      case 'meals':
        icon = Icons.restaurant_rounded;
        break;
      case 'snacks':
        icon = Icons.fastfood_rounded;
        break;
      case 'desserts':
        icon = Icons.cake_rounded;
        break;
      default:
        icon = Icons.restaurant_menu_rounded;
    }

    return Center(
      child: Icon(
        icon,
        size: 34,
        color: const Color(0xFF6D7A73),
      ),
    );
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
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _opacity = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

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
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}