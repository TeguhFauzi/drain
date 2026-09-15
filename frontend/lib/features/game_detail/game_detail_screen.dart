import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/game_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/product_model.dart';
import '../../core/network/api_service.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/footer.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../checkout/checkout_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final String slug;

  const GameDetailScreen({Key? key, required this.slug}) : super(key: key);

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;
  GameModel? _game;
  bool _isLoading = true;
  ProductModel? _selectedProduct;
  String _selectedPayment = 'QRIS';

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _zoneIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentUser = _apiService.currentUser;
    _loadGame();
    _loadUser();
  }

  bool _isAuthLoading = false;

  Future<void> _loadUser() async {
    if (_currentUser == null && _apiService.token != null) {
      setState(() => _isAuthLoading = true);
    }
    try {
      final user = await _apiService.getProfile();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _loadGame() async {
    setState(() => _isLoading = true);
    try {
      final game = await _apiService.getGameBySlug(widget.slug);
      setState(() {
        _game = game;
        _isLoading = false;
        if (game.products.isNotEmpty) {
          _selectedProduct = game.products.first;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _isSubmitting = false;

  Future<void> _handleOrder() async {
    if (_game == null || _selectedProduct == null) return;
    if (_userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap masukkan ${_game!.inputLabel} terlebih dahulu!'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final transaction = await _apiService.createTransaction(
        productId: _selectedProduct!.id,
        gameUserId: _userIdController.text.trim(),
        gameServerId: _zoneIdController.text.trim().isNotEmpty ? _zoneIdController.text.trim() : null,
        paymentMethod: _selectedPayment,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CheckoutScreen(transaction: transaction),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat pesanan: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: Navbar(
        user: _currentUser,
        isLoadingAuth: _isAuthLoading,
        onLogout: () async {
          await _apiService.setToken(null);
          if (mounted) setState(() => _currentUser = null);
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _game == null
              ? const Center(child: Text('Game tidak ditemukan'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Banner
                      _buildHeaderBanner(isDesktop),

                      // Main Form Container
                      Container(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 40 : 16,
                          vertical: 30,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (isDesktop) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left side info card
                                  Expanded(flex: 1, child: _buildGameInfoCard()),
                                  const SizedBox(width: 30),
                                  // Right side form steps
                                  Expanded(flex: 2, child: _buildFormSteps()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildGameInfoCard(),
                                const SizedBox(height: 24),
                                _buildFormSteps(),
                              ],
                            );
                          },
                        ),
                      ),

                      // Footer
                      const Footer(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderBanner(bool isDesktop) {
    return Container(
      height: isDesktop ? 220 : 160,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(_game!.bannerUrl ?? _game!.imageUrl ?? ''),
          fit: BoxFit.cover,
          onError: (_, __) {},
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.8),
              AppColors.background.withOpacity(0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
      ),
    );
  }

  Widget _buildGameInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _game!.imageUrl ?? '',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: AppColors.surface,
                    child: const Icon(Icons.sports_esports, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _game!.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _game!.publisher ?? 'Official Store',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Text(
            _game!.description ?? 'Top up cepat dan mudah 24 jam.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          _featureRow(Icons.flash_on, 'Proses Otomatis Instan'),
          _featureRow(Icons.security, 'Layanan Aman & Terpercaya'),
          _featureRow(Icons.support_agent, 'Layanan Pelanggan 24 Jam'),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFormSteps() {
    return Column(
      children: [
        // STEP 1: Account Data
        _buildStepContainer(
          stepNumber: 1,
          title: 'Masukkan Data Akun',
          child: Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: _game!.inputLabel,
                  hint: _game!.inputPlaceholder,
                  controller: _userIdController,
                  prefixIcon: Icons.person_outline,
                ),
              ),
              if (_game!.inputLabel2 != null) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: _game!.inputLabel2!,
                    hint: _game!.inputPlaceholder2 ?? 'Server',
                    controller: _zoneIdController,
                    prefixIcon: Icons.dns_outlined,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // STEP 2: Product Selection
        _buildStepContainer(
          stepNumber: 2,
          title: 'Pilih Nominal Top Up',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.3,
            ),
            itemCount: _game!.products.length,
            itemBuilder: (context, index) {
              final product = _game!.products[index];
              final isSelected = _selectedProduct?.id == product.id;

              return InkWell(
                onTap: () => setState(() => _selectedProduct = product),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.cardBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(product.sellPrice),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // STEP 3: Payment Method
        _buildStepContainer(
          stepNumber: 3,
          title: 'Pilih Pembayaran',
          child: Column(
            children: [
              _paymentOptionTile('QRIS', 'QRIS (BCA, OVO, Dana, Gopay, LinkAja)', Icons.qr_code_scanner),
              const SizedBox(height: 10),
              _paymentOptionTile('TRANSFER_BANK', 'Transfer Bank (BCA / Mandiri / BNI)', Icons.account_balance),
              const SizedBox(height: 10),
              _paymentOptionTile('EWALLET', 'E-Wallet (Gopay, OVO, ShopeePay)', Icons.account_balance_wallet),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // STEP 4: WhatsApp Contact
        _buildStepContainer(
          stepNumber: 4,
          title: 'No. WhatsApp (Untuk Bukti Transaksi)',
          child: CustomTextField(
            label: 'Nomor WhatsApp',
            hint: '081234567890',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_android,
          ),
        ),
        const SizedBox(height: 30),

        // Summary & Submit Button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran:', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  Text(
                    _selectedProduct != null ? currencyFormat.format(_selectedProduct!.sellPrice) : 'Rp 0',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'BELI SEKARANG',
                icon: Icons.shopping_cart_checkout,
                isLoading: _isSubmitting,
                onPressed: _handleOrder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepContainer({required int stepNumber, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _paymentOptionTile(String value, String label, IconData icon) {
    final isSelected = _selectedPayment == value;

    return InkWell(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPayment,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _selectedPayment = val!),
            ),
          ],
        ),
      ),
    );
  }
}
