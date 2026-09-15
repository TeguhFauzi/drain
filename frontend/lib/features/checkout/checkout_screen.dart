import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/network/api_service.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/footer.dart';
import '../../core/widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  final TransactionModel transaction;

  const CheckoutScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late TransactionModel _tx;
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;
  bool _isAuthLoading = false;
  bool _isRefreshing = false;
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction;
    _currentUser = _apiService.currentUser;
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (_currentUser == null && _apiService.token != null) {
      if (mounted) setState(() => _isAuthLoading = true);
    }
    try {
      final user = await _apiService.getProfile();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _refreshStatus() async {
    setState(() => _isRefreshing = true);
    try {
      final updated = await _apiService.getTransactionDetail(_tx.id);
      setState(() => _tx = updated);
    } catch (e) {
      // Keep current state
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _openPaymentUrl() async {
    if (_tx.paymentUrl != null && _tx.paymentUrl!.isNotEmpty) {
      final uri = Uri.parse(_tx.paymentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
          await _apiService.logout();
          if (mounted) setState(() => _currentUser = null);
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16,
                vertical: 40,
              ),
              child: Column(
                children: [
                  // Status Header Icon
                  _buildStatusHeader(),
                  const SizedBox(height: 24),

                  // Invoice Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoice ID & Copy Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NO. INVOICE', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                SelectableText(
                                  _tx.invoiceId,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _tx.invoiceId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No. Invoice berhasil disalin!')),
                                );
                              },
                              icon: const Icon(Icons.copy, color: AppColors.primary, size: 20),
                              tooltip: 'Salin Invoice',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.cardBorder),
                        const SizedBox(height: 16),

                        // Order Items
                        _detailRow('Game', _tx.gameName ?? 'Game Top-Up'),
                        _detailRow('Item', _tx.productName ?? 'Produk Top-Up'),
                        _detailRow('ID User / Server', '${_tx.gameUserId} ${_tx.gameServerId != null ? "(${_tx.gameServerId})" : ""}'),
                        _detailRow('Metode Pembayaran', _tx.paymentMethod ?? 'QRIS'),
                        _detailRow('Waktu Transaksi', _tx.createdAt.replaceAll('T', ' ').substring(0, 16)),

                        const SizedBox(height: 16),
                        const Divider(color: AppColors.cardBorder),
                        const SizedBox(height: 16),

                        // Total Amount
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15)),
                            Text(
                              currencyFormat.format(_tx.amount),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QRIS / Payment Actions
                  if (_tx.isPending) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SCAN QRIS ATAU BAYAR VIA MIDTRANS',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          // Mock QR Code Icon Box
                          Container(
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.qr_code_2, size: 150, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'BAYAR SEKARANG VIA MIDTRANS',
                            icon: Icons.open_in_new,
                            onPressed: _openPaymentUrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Refresh Status Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRefreshing ? null : _refreshStatus,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _isRefreshing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                              : const Icon(Icons.refresh, color: AppColors.primary),
                          label: const Text('Cek Status Pembayaran', style: TextStyle(color: AppColors.textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cardBorder),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Ke Beranda', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color bg;
    IconData icon;
    String statusTitle;
    String statusDesc;

    if (_tx.isCompleted) {
      bg = AppColors.accentGreen;
      icon = Icons.check_circle;
      statusTitle = 'PEMBAYARAN BERHASIL!';
      statusDesc = 'Diamond / Item telah berhasil dikirim ke akun Anda.';
    } else if (_tx.isFailed) {
      bg = AppColors.accentRed;
      icon = Icons.cancel;
      statusTitle = 'PEMBAYARAN GAGAL';
      statusDesc = 'Waktu pembayaran telah habis atau dibatalkan.';
    } else {
      bg = AppColors.accentGold;
      icon = Icons.timer;
      statusTitle = 'MENUNGGU PEMBAYARAN';
      statusDesc = 'Selesaikan pembayaran sebelum batas waktu berakhir.';
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: bg, width: 2),
          ),
          child: Icon(icon, color: bg, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          statusTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: bg,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusDesc,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
