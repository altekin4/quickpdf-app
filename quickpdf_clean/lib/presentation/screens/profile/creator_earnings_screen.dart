import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';

class CreatorEarningsScreen extends StatefulWidget {
  const CreatorEarningsScreen({super.key});

  @override
  State<CreatorEarningsScreen> createState() => _CreatorEarningsScreenState();
}

class _CreatorEarningsScreenState extends State<CreatorEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _payoutAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPayouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kazançlarım'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Genel Bakış'),
            Tab(text: 'Ödeme Geçmişi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPayoutHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) {
          return const Center(child: Text('Kullanıcı bilgileri yüklenemedi'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, 
                               color: Colors.green[600], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Mevcut Bakiye',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${user.balance.toStringAsFixed(2)} TL',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: user.balance >= 100 ? () => _showPayoutDialog() : null,
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Ödeme Talep Et'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showEarningsDetails(),
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: const Text('Detaylar'),
                            ),
                          ),
                        ],
                      ),
                      if (user.balance < 100) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, 
                                   color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Minimum ödeme tutarı 100 TL\'dir',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Total Earnings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, 
                               color: Colors.blue[600], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Toplam Kazanç',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${user.totalEarnings.toStringAsFixed(2)} TL',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tüm zamanlar boyunca elde ettiğiniz toplam kazanç',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Earnings Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kazanç Bilgileri',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.percent,
                        'Komisyon Oranı',
                        'Her satıştan %80 kazanırsınız',
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.account_balance,
                        'Minimum Ödeme',
                        '100 TL ve üzeri tutarlar ödenebilir',
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.schedule,
                        'Ödeme Süresi',
                        'Ödeme talepleri 1-3 iş günü içinde işlenir',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutHistoryTab() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        if (paymentProvider.payouts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz ödeme talebiniz yok',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kazancınız 100 TL\'ye ulaştığında ödeme talep edebilirsiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => paymentProvider.loadPayouts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paymentProvider.payouts.length,
            itemBuilder: (context, index) {
              final payout = paymentProvider.payouts[index];
              return _buildPayoutCard(payout);
            },
          ),
        );
      },
    );
  }

  Widget _buildPayoutCard(Payout payout) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${payout.amount.toStringAsFixed(2)} ${payout.currency}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildPayoutStatusChip(payout.status),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Talep: ${_formatDate(payout.requestedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            if (payout.processedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'İşlem: ${_formatDate(payout.processedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            if (payout.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.done_all, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Tamamlandı: ${_formatDate(payout.completedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        displayText = 'Tamamlandı';
        break;
      case 'processing':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        displayText = 'İşleniyor';
        break;
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        displayText = 'Beklemede';
        break;
      case 'failed':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        displayText = 'Başarısız';
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPayoutDialog() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Talep Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mevcut Bakiye: ${user.balance.toStringAsFixed(2)} TL'),
            const SizedBox(height: 16),
            TextField(
              controller: _payoutAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ödeme Tutarı (TL)',
                hintText: '100.00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ödeme Bilgileri',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Minimum ödeme tutarı: 100 TL\n'
                    '• İşlem süresi: 1-3 iş günü\n'
                    '• Ödeme banka hesabınıza yapılacaktır',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _payoutAmountController.clear();
              Navigator.pop(context);
            },
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => _requestPayout(),
            child: const Text('Talep Et'),
          ),
        ],
      ),
    );
  }

  void _showEarningsDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kazanç Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kazanç Sistemi Nasıl Çalışır?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Şablonlarınız satıldığında satış fiyatının %80\'ini kazanırsınız\n'
              '2. Kazançlarınız hesabınızda birikir\n'
              '3. 100 TL ve üzeri tutarları ödeme olarak talep edebilirsiniz\n'
              '4. Ödeme talepleri 1-3 iş günü içinde işlenir\n'
              '5. Ödemeler banka hesabınıza yapılır',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Örnek Hesaplama',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Şablon Fiyatı: 50 TL\n'
                    'Sizin Kazancınız: 40 TL (%80)\n'
                    'Platform Komisyonu: 10 TL (%20)',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPayout() async {
    final amountText = _payoutAmountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ödeme tutarını girin')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum ödeme tutarı 100 TL\'dir')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null || amount > user.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetersiz bakiye')),
      );
      return;
    }

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final success = await paymentProvider.requestPayout(amount);

      if (!mounted) return;
      
      if (success) {
        Navigator.pop(context);
        _payoutAmountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme talebiniz başarıyla oluşturuldu'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh user data to update balance
        context.read<AuthProvider>().refreshUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.error ?? 'Ödeme talebi oluşturulamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _payoutAmountController.dispose();
    super.dispose();
  }
}