import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/template.dart';
import '../providers/payment_provider.dart';

class PurchaseDialog extends StatefulWidget {
  final Template template;
  final VoidCallback? onPurchaseCompleted;

  const PurchaseDialog({
    super.key,
    required this.template,
    this.onPurchaseCompleted,
  });

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şablon Satın Al'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template info
          Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: widget.template.previewImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.template.previewImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.description, size: 30);
                          },
                        ),
                      )
                    : const Icon(Icons.description, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.template.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.template.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Price info
          Container(
            width: double.infinity,
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
                  'Ödeme Detayları',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Şablon Fiyatı:'),
                    Text(
                      '${widget.template.price.toStringAsFixed(0)} TL',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toplam:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.template.price.toStringAsFixed(0)} TL',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Payment info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Güvenli Ödeme',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Stripe güvenli ödeme sistemi\n'
                  '• 3D Secure destekli\n'
                  '• Kredi kartı bilgileriniz saklanmaz\n'
                  '• Satın aldıktan sonra anında erişim',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPurchase,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Satın Al'),
        ),
      ],
    );
  }

  Future<void> _processPurchase() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final paymentProvider = context.read<PaymentProvider>();
      
      // Create payment intent
      final paymentIntent = await paymentProvider.createPaymentIntent(widget.template.id);
      
      if (paymentIntent == null) {
        setState(() {
          _error = paymentProvider.error ?? 'Ödeme başlatılamadı';
          _isProcessing = false;
        });
        return;
      }

      // In a real app, you would integrate with Stripe SDK here
      // For now, we'll simulate a successful payment
      await Future.delayed(const Duration(seconds: 2));
      
      // Confirm payment
      final success = await paymentProvider.confirmPayment(paymentIntent.id);
      
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Satın alma işlemi başarıyla tamamlandı!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPurchaseCompleted?.call();
        }
      } else {
        setState(() {
          _error = paymentProvider.error ?? 'Ödeme tamamlanamadı';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Beklenmeyen bir hata oluştu: $e';
        _isProcessing = false;
      });
    }
  }
}

// Simulated Stripe payment widget for demo purposes
class _StripePaymentWidget extends StatefulWidget {
  final PaymentIntent paymentIntent;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const _StripePaymentWidget({
    required this.paymentIntent,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_StripePaymentWidget> createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<_StripePaymentWidget> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Kart Bilgileri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Kart Numarası',
            hintText: '1234 5678 9012 3456',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryController,
                decoration: const InputDecoration(
                  labelText: 'Son Kullanma',
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cvcController,
                decoration: const InputDecoration(
                  labelText: 'CVC',
                  hintText: '123',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            child: _isProcessing
                ? const CircularProgressIndicator()
                : Text('${widget.paymentIntent.amount.toStringAsFixed(0)} TL Öde'),
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment() async {
    // Validate inputs
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvcController.text.isEmpty) {
      widget.onError('Lütfen tüm alanları doldurun');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate success (in real app, this would be handled by Stripe SDK)
      widget.onSuccess();
    } catch (e) {
      widget.onError('Ödeme işlemi başarısız: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }
}