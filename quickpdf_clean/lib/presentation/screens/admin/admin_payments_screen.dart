import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Ödeme Yönetimi'),
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
          body: Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Ödeme ara...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) => adminProvider.searchPayments(value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Status Filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Durum Filtresi',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Tüm Durumlar'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'completed',
                            child: Text('Tamamlandı'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'pending',
                            child: Text('Beklemede'),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'failed',
                            child: Text('Başarısız'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                          adminProvider.filterPaymentsByStatus(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Payments List
              Expanded(
                child: adminProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : adminProvider.payments.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Ödeme bulunamadı',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: adminProvider.payments.length,
                            itemBuilder: (context, index) {
                              final payment = adminProvider.payments[index];
                              return _buildPaymentCard(context, payment, adminProvider);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> payment, AdminProvider adminProvider) {
    final status = payment['status'] as String;
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Payment Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPaymentMethodIcon(payment['paymentMethod']),
                size: 24,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Payment Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment['templateTitle'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusDisplayName(status),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kullanıcı: ${payment['userName']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₺${payment['amount'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _getPaymentMethodDisplayName(payment['paymentMethod']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tarih: ${_formatDate(payment['createdAt'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Actions
            Column(
              children: [
                if (status == 'pending') ...[
                  ElevatedButton(
                    onPressed: () {
                      adminProvider.updatePaymentStatus(payment['id'], 'completed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Onayla', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () {
                      adminProvider.updatePaymentStatus(payment['id'], 'failed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Reddet', style: TextStyle(fontSize: 12)),
                  ),
                ] else if (status == 'failed') ...[
                  ElevatedButton(
                    onPressed: () {
                      adminProvider.updatePaymentStatus(payment['id'], 'pending');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Yeniden İncele', style: TextStyle(fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _showPaymentDetailsDialog(context, payment);
                        break;
                      case 'refund':
                        _showRefundDialog(context, payment);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Detayları Görüntüle'),
                        ],
                      ),
                    ),
                    if (status == 'completed')
                      const PopupMenuItem(
                        value: 'refund',
                        child: Row(
                          children: [
                            Icon(Icons.undo, size: 16, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('İade Et', style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                      ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'failed':
        return 'Başarısız';
      default:
        return 'Bilinmiyor';
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'credit_card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'credit_card':
        return 'Kredi Kartı';
      case 'paypal':
        return 'PayPal';
      case 'bank_transfer':
        return 'Banka Havalesi';
      default:
        return 'Bilinmiyor';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPaymentDetailsDialog(BuildContext context, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme Detayları'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Ödeme ID', payment['id']),
              _buildDetailRow('Kullanıcı', payment['userName']),
              _buildDetailRow('Şablon', payment['templateTitle']),
              _buildDetailRow('Tutar', '₺${payment['amount'].toStringAsFixed(2)}'),
              _buildDetailRow('Para Birimi', payment['currency']),
              _buildDetailRow('Ödeme Yöntemi', _getPaymentMethodDisplayName(payment['paymentMethod'])),
              _buildDetailRow('Durum', _getStatusDisplayName(payment['status'])),
              _buildDetailRow('Tarih', _formatDate(payment['createdAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(BuildContext context, Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ödeme İadesi'),
        content: Text('${payment['templateTitle']} için ₺${payment['amount'].toStringAsFixed(2)} tutarında iade işlemi başlatılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // İade işlemi burada yapılacak
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('İade işlemi başlatıldı'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('İade Et'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}