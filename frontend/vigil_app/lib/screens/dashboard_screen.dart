import 'package:flutter/material.dart';
import '../theme/vigil_theme.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _pocketModeActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: VigilTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildPocketModeCard(),
                const SizedBox(height: 20),
                _buildStatusGrid(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildRecentAlerts(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Guardian',
              style: TextStyle(
                fontSize: 14,
                color: VigilTheme.textGrey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'VIGIL Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: VigilTheme.textWhite,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: VigilTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: VigilTheme.cyan.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: VigilTheme.deepNavy, size: 24),
        ),
      ],
    );
  }

  Widget _buildPocketModeCard() {
    return GlassCard(
      glowColor: _pocketModeActive ? VigilTheme.emerald : VigilTheme.textGrey,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_pocketModeActive ? VigilTheme.emerald : VigilTheme.textGrey)
                  .withOpacity(0.15),
            ),
            child: Icon(
              _pocketModeActive ? Icons.shield_rounded : Icons.shield_outlined,
              color: _pocketModeActive ? VigilTheme.emerald : VigilTheme.textGrey,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pocket Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: VigilTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _pocketModeActive ? 'Protection Active' : 'Tap to Enable',
                  style: TextStyle(
                    fontSize: 13,
                    color: _pocketModeActive
                        ? VigilTheme.emerald
                        : VigilTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _pocketModeActive,
            onChanged: (value) => setState(() => _pocketModeActive = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Alerts', '0', Icons.warning_amber_rounded, VigilTheme.warningOrange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Contacts', '3', Icons.people_outline, VigilTheme.cyan)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Days Safe', '14', Icons.verified_user_outlined, VigilTheme.emerald)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: color,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: VigilTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VigilTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                'Pocket Mode',
                Icons.security_rounded,
                VigilTheme.cyan,
                () => Navigator.pushNamed(context, '/pocket-mode'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                'Contacts',
                Icons.contacts_rounded,
                VigilTheme.teal,
                () => Navigator.pushNamed(context, '/emergency-contacts'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                'Alert History',
                Icons.history_rounded,
                VigilTheme.warningOrange,
                () => Navigator.pushNamed(context, '/alert-history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionTile(
                'Settings',
                Icons.settings_rounded,
                VigilTheme.purple,
                () => Navigator.pushNamed(context, '/settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      glowColor: color,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: VigilTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: VigilTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: VigilTheme.emerald.withOpacity(0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All Clear',
                    style: TextStyle(
                      color: VigilTheme.textGrey.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No recent alerts',
                    style: TextStyle(
                      color: VigilTheme.textGrey.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: VigilTheme.darkNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/pocket-mode');
              break;
            case 2:
              Navigator.pushNamed(context, '/alert-history');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: 'Protect'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
