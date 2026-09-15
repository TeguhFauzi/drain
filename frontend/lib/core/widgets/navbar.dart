import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../../features/auth/login_screen.dart';
import '../../features/transaction/transaction_history_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel? user;
  final bool isLoadingAuth;
  final VoidCallback? onLogout;

  const Navbar({
    Key? key,
    this.user,
    this.isLoadingAuth = false,
    this.onLogout,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo
          InkWell(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.black, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'DRIANSTORE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    foreground: Paint()
                      ..shader = AppColors.primaryGradient.createShader(
                        const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                      ),
                  ),
                ),
              ],
            ),
          ),

          // Actions / Nav Links
          Row(
            children: [
              if (isLoadingAuth) ...[
                Container(
                  width: 110,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                ),
              ] else if (user != null) ...[
                // History Link
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, color: AppColors.textSecondary, size: 20),
                  label: isDesktop
                      ? Text(
                          'Riwayat',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),

                // Admin Dashboard Link if admin
                if (user!.isAdmin) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 10, vertical: 10),
                    ),
                    icon: const Icon(Icons.admin_panel_settings, size: 18),
                    label: isDesktop ? const Text('Admin Panel') : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                ],

                // User Profile Menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'logout' && onLogout != null) {
                      onLogout!();
                    }
                  },
                  color: AppColors.cardBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user!.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 8),
                          Text(
                            user!.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                        const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text(user!.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          const Divider(color: AppColors.cardBorder),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.accentRed, size: 18),
                          SizedBox(width: 8),
                          Text('Keluar', style: TextStyle(color: AppColors.accentRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12, vertical: 12),
                  ),
                  child: const Text('Masuk / Daftar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
