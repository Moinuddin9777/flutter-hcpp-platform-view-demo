import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const HcppDemoApp());
}

class HcppDemoApp extends StatelessWidget {
  const HcppDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HCPP Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE94560),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const FoodOrderingPage(),
    );
  }
}

class CartItem {
  final String name;
  final double price;

  CartItem({required this.name, required this.price});
}

class FoodOrderingPage extends StatefulWidget {
  const FoodOrderingPage({super.key});

  @override
  State<FoodOrderingPage> createState() => _FoodOrderingPageState();
}

class _FoodOrderingPageState extends State<FoodOrderingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final WebViewController _webViewController;

  final List<CartItem> _cartItems = [];
  bool _showRegionLabels = false;
  String? _compositionMode;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initWebView();
    _detectCompositionMode();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CartChannel',
        onMessageReceived: (message) {
          final data = jsonDecode(message.message) as Map<String, dynamic>;
          _addToCart(data['name'] as String, (data['price'] as num).toDouble());
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _webViewReady = true);
            _updateWebViewLabels();
          },
        ),
      );

    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final html = await rootBundle.loadString('assets/menu.html');
    await _webViewController.loadHtmlString(html);
  }

  Future<void> _detectCompositionMode() async {
    // Detection via checking if HCPP is active
    // Note: Actual detection requires checking logcat for
    // "Using HCPP platform view rendering strategy"
    // We display what mode was requested via manifest/flags
    setState(() {
      _compositionMode = 'Check logcat';
    });
  }

  void _addToCart(String name, double price) {
    setState(() {
      _cartItems.add(CartItem(name: name, price: price));
    });
    HapticFeedback.mediumImpact();
  }

  double get _cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + item.price);

  void _toggleRegionLabels() {
    setState(() {
      _showRegionLabels = !_showRegionLabels;
    });
    _updateWebViewLabels();
  }

  Future<void> _updateWebViewLabels() async {
    if (_webViewReady) {
      await _webViewController.runJavaScript(
        'setLabelVisible($_showRegionLabels)',
      );
    }
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildWebViewArea()),
              _buildCartSummary(),
            ],
          ),
          _buildFloatingAnimation(),
          _buildFloatingCartButton(),
          if (_compositionMode != null) _buildModeBadge(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: _showRegionLabels
            ? Border.all(color: Colors.green, width: 3)
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Bella Cucina',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_showRegionLabels) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'FLUTTER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Italian Fine Dining',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _toggleRegionLabels,
                icon: Icon(
                  _showRegionLabels ? Icons.layers : Icons.layers_outlined,
                  color: _showRegionLabels ? Colors.green : null,
                ),
                tooltip: 'Toggle region labels',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebViewArea() {
    return Container(
      decoration: _showRegionLabels
          ? BoxDecoration(border: Border.all(color: Colors.red, width: 3))
          : null,
      child: WebViewWidget(controller: _webViewController),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: _showRegionLabels
            ? Border.all(color: Colors.green, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 80, 12),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_cartItems.length} items',
                style: const TextStyle(fontSize: 14),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '\$${_cartTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (_cartItems.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Clear cart',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAnimation() {
    return Positioned(
      left: 16,
      bottom: 100,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final value = _animationController.value;
          final bounceValue = (value < 0.5 ? value * 2 : 2 - value * 2);
          return Transform.translate(
            offset: Offset(0, -bounceValue * 60),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    HSLColor.fromAHSL(1, value * 360, 0.8, 0.5).toColor(),
                    HSLColor.fromAHSL(1, (value * 360 + 60) % 360, 0.8, 0.5)
                        .toColor(),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: HSLColor.fromAHSL(0.4, value * 360, 0.8, 0.5)
                        .toColor(),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: _showRegionLabels
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
              ),
              child: const Icon(Icons.local_fire_department, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingCartButton() {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Container(
        decoration: BoxDecoration(
          border: _showRegionLabels
              ? Border.all(color: Colors.green, width: 3)
              : null,
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton.large(
          onPressed: () => _showCartSheet(context),
          backgroundColor: const Color(0xFFE94560),
          child: Badge(
            label: Text('${_cartItems.length}'),
            isLabelVisible: _cartItems.isNotEmpty,
            child: const Icon(Icons.shopping_cart, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBadge() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 56,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _compositionMode ?? '...',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your Cart',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_cartItems.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _clearCart();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cartItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Your cart is empty.\nTap items in the menu to add them!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cartItems.length,
                  itemBuilder: (context, index) {
                    final item = _cartItems[index];
                    return ListTile(
                      title: Text(item.name),
                      trailing: Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${_cartTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _cartItems.isEmpty ? null : () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order placed! (Demo)'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _clearCart();
                },
                child: const Text('Place Order'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
