import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/network/api_service.dart';
import '../../core/widgets/navbar.dart';
import '../../core/widgets/footer.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;
  Map<String, dynamic>? _stats;
  List<TransactionModel> _adminTransactions = [];
  bool _isLoading = true;
  String _filterStatus = 'ALL';
  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAdminData();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _apiService.getProfile();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {}
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final dashboardData = await _apiService.getAdminDashboard();
      final txList = await _apiService.getAdminTransactions();
      setState(() {
        _stats = dashboardData['stats'];
        _adminTransactions = txList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _apiService.updateTransactionStatus(id, newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status transaksi diubah ke $newStatus'), backgroundColor: AppColors.accentGreen),
      );
      _loadAdminData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.accentRed),
      );
    }
  }

  List<TransactionModel> get _filteredTx {
    if (_filterStatus == 'ALL') return _adminTransactions;
    return _adminTransactions.where((t) => t.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      appBar: Navbar(
        user: _currentUser,
        onLogout: () async {
          await _apiService.setToken(null);
          if (mounted) setState(() => _currentUser = null);
        },
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 1100),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16,
                vertical: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: AppColors.accentGold),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Admin Control Panel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Overview Cards
                  if (_isLoading)
                    const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                  else ...[
                    _buildStatsGrid(isDesktop),
                    const SizedBox(height: 34),

                    // Filter & Transactions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kelola Transaksi Terbaru',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        DropdownButton<String>(
                          value: _filterStatus,
                          dropdownColor: AppColors.cardBg,
                          style: const TextStyle(color: AppColors.textPrimary),
                          items: ['ALL', 'PENDING', 'COMPLETED', 'FAILED'].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) => setState(() => _filterStatus = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transactions Table / List
                    _filteredTx.isEmpty
                        ? const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('Tidak ada transaksi', style: TextStyle(color: AppColors.textMuted))))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredTx.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _buildAdminTxCard(_filteredTx[index], isDesktop);
                            },
                          ),
                  ],
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isDesktop) {
    final revenue = _stats?['totalRevenue'] ?? 0;
    final totalTx = _stats?['totalTransactions'] ?? 0;
    final completedTx = _stats?['completedTransactions'] ?? 0;
    final totalUsers = _stats?['totalUsers'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isDesktop ? 1.8 : 1.5,
      children: [
        _statCard('Total Pendapatan', currencyFormat.format(revenue), Icons.monetization_on, AppColors.accentGreen),
        _statCard('Total Transaksi', '$totalTx Order', Icons.shopping_bag, AppColors.primary),
        _statCard('Sukses Terkirim', '$completedTx Selesai', Icons.task_alt, AppColors.secondary),
        _statCard('Pengguna Terdaftar', '$totalUsers User', Icons.people, AppColors.accentGold),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTxCard(TransactionModel tx, bool isDesktop) {
    Color statusColor;
    if (tx.isCompleted) {
      statusColor = AppColors.accentGreen;
    } else if (tx.isFailed) {
      statusColor = AppColors.accentRed;
    } else {
      statusColor = AppColors.accentGold;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tx.invoiceId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.gameName ?? "Game"} - ${tx.productName ?? "Item"}',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text('User ID: ${tx.gameUserId} ${tx.gameServerId ?? ""}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(tx.amount),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 8),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Ubah Status: ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _updateStatus(tx.id, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('SELESAI', style: TextStyle(fontSize: 11, color: Colors.black)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _updateStatus(tx.id, 'failed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('GAGAL', style: TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
