import 'package:flutter/material.dart';
import 'menu_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color bg = Colors.white;
  static const Color darkGreen = Color(0xFF234B37);
  static const Color midGreen = Color(0xFF4D7A62);
  static const Color softText = Color(0xFF8A8F89);
  static const Color lineColor = Color(0xFFE5E5E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ✅ YOUR LOGO
                  Image.asset(
                    'assets/vianlogo.png',
                    height: 270,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 3),

                  // Divider + tagline
                  Row(
                    children: const [
                      Expanded(child: _Line()),
                      SizedBox(width: 12),
                      Text(
                        'Indulge in Every Sip and Slice',
                        style: TextStyle(
                          color: softText,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: _Line()),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'How would you like to order?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B2B2B),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose your preferred café experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: _orderTypeCard(
                          context,
                          icon: Icons.restaurant_outlined,
                          title: 'Dine-In',
                          subtitle: 'Eat inside the café',
                          orderType: 'dine_in',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _orderTypeCard(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          title: 'Takeout',
                          subtitle: 'Grab and go',
                          orderType: 'takeout',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Freshly prepared. Simply better.',
                    style: TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String orderType,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuScreen(orderType: orderType)),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: midGreen.withOpacity(0.08),
                ),
                child: Icon(icon, size: 26, color: darkGreen),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Select',
                    style: TextStyle(
                      color: midGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: midGreen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: const Color(0xFFE5E5E5), // ✅ FIXED HERE
    );
  }
}
