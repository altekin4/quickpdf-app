import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/mock_auth_provider.dart';
import 'admin_users_screen.dart';
import 'admin_templates_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  
  final List<AdminTab> _tabs = [
    AdminTab(
      title: 'Dashboard',
      icon: Icons.dashboard,
      screen: const AdminDashboardContent(),
    ),
    AdminTab(
      title: 'Kullanıcılar',
      icon: Icons.people,
      screen: const AdminUsersScreen(),
    ),
    AdminTab(
      title: 'Şablonlar',
      icon: Icons.description,
      screen: const AdminTemplatesScreen(),
    ),
    AdminTab(
      title: 'Ödemeler',
      icon: Icons.payment,
      screen: const AdminPaymentsScreen(),
    ),
    AdminTab(
      title: 'Analitik',
      icon: Icons.analytics,
      screen: const AdminAnalyticsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.blue.shade900,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'QuickPDF Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white24),
                
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isSelected = _selectedIndex == index;
                      
                      return ListTile(
                        leading: Icon(
                          tab.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                        title: Text(
                          tab.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.white.withValues(alpha: 0.1),
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                
                const Divider(color: Colors.white24),
                
                // User Info & Logout
                Consumer<MockAuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.currentUser;
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (user != null) ...[
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Text(
                                user.fullName[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              user.email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await authProvider.logout();
                                if (context.mounted) {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                }
                              },
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Çıkış'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _tabs[_selectedIndex].screen,
          ),
        ],
      ),
    );
  }
}

class AdminDashboardContent extends StatelessWidget {
  const AdminDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final stats = adminProvider.dashboardStats;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => adminProvider.refreshData(),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Message
                Text(
                  'Admin Dashboard\'a Hoş Geldiniz',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'QuickPDF platformunuzun genel durumunu buradan takip edebilirsiniz.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Stats Cards
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      'Toplam Kullanıcı',
                      stats['totalUsers']?.toString() ?? '0',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Aktif Kullanıcı',
                      stats['activeUsers']?.toString() ?? '0',
                      Icons.person_outline,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Toplam Şablon',
                      stats['totalTemplates']?.toString() ?? '0',
                      Icons.description,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Aktif Şablon',
                      stats['activeTemplates']?.toString() ?? '0',
                      Icons.check_circle,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Toplam Gelir',
                      '₺${stats['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.attach_money,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      'Aylık Gelir',
                      '₺${stats['monthlyRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.trending_up,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      'Toplam İndirme',
                      stats['totalDownloads']?.toString() ?? '0',
                      Icons.download,
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Aylık İndirme',
                      stats['monthlyDownloads']?.toString() ?? '0',
                      Icons.file_download,
                      Colors.pink,
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Activity
                Row(
                  children: [
                    Expanded(
                      child: _buildRecentActivity(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActions(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Yeni kullanıcı kaydı',
              'john.doe@example.com',
              '2 saat önce',
              Icons.person_add,
              Colors.green,
            ),
            _buildActivityItem(
              'Şablon onaylandı',
              'Fatura Şablonu',
              '4 saat önce',
              Icons.check_circle,
              Colors.blue,
            ),
            _buildActivityItem(
              'Ödeme tamamlandı',
              '₺29.99 - CV Şablonu',
              '6 saat önce',
              Icons.payment,
              Colors.orange,
            ),
            _buildActivityItem(
              'Yeni şablon başvurusu',
              'Sözleşme Şablonu',
              '1 gün önce',
              Icons.description,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı İşlemler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              'Yeni Kullanıcı Ekle',
              Icons.person_add,
              Colors.blue,
              () {},
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              'Şablon Onayla',
              Icons.check_circle,
              Colors.green,
              () {},
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              'Ödeme Durumu',
              Icons.payment,
              Colors.orange,
              () {},
            ),
            const SizedBox(height: 8),
            _buildQuickActionButton(
              'Rapor Oluştur',
              Icons.assessment,
              Colors.purple,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class AdminTab {
  final String title;
  final IconData icon;
  final Widget screen;

  AdminTab({
    required this.title,
    required this.icon,
    required this.screen,
  });
}