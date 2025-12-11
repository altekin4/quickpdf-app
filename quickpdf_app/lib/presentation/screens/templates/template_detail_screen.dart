import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../../domain/entities/template.dart';
import 'template_form_screen.dart';
import '../../widgets/purchase_dialog.dart';
import '../../widgets/pdf_preview_widget.dart';

class TemplateDetailScreen extends StatefulWidget {
  final String templateId;

  const TemplateDetailScreen({super.key, required this.templateId});

  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Template? _template;
  bool _isLoading = true;
  String? _error;
  bool _hasPurchased = false;
  bool _checkingPurchase = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = context.read<TemplateProvider>();
      final template = await provider.getTemplateById(widget.templateId);
      
      setState(() {
        _template = template;
        _isLoading = false;
      });

      // Check if user has purchased this template
      await _checkPurchaseStatus();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPurchaseStatus() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || _template == null || _template!.isFree) {
      return;
    }

    setState(() {
      _checkingPurchase = true;
    });

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final hasPurchased = await paymentProvider.hasUserPurchased(_template!.id);
      
      setState(() {
        _hasPurchased = hasPurchased;
        _checkingPurchase = false;
      });
    } catch (e) {
      setState(() {
        _checkingPurchase = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Şablon Detayı')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Şablon Detayı')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Hata: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTemplate,
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Şablon Detayı')),
        body: const Center(child: Text('Şablon bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_template!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTemplate(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Template header
          _buildTemplateHeader(),
          
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Detaylar'),
              Tab(text: 'Önizleme'),
              Tab(text: 'Değerlendirmeler'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildPreviewTab(),
                _buildRatingsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildTemplateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template preview image
          Container(
            width: 100,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _template!.previewImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _template!.previewImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.description, size: 50);
                      },
                    ),
                  )
                : const Icon(Icons.description, size: 50),
          ),

          const SizedBox(width: 16),

          // Template info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _template!.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_template!.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ÖNE ÇIKAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  _template!.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 12),

                // Rating and stats
                Row(
                  children: [
                    Icon(Icons.star, size: 20, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      _template!.rating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      ' (${_template!.totalRatings} değerlendirme)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.download, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${_template!.downloadCount} indirme',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_template!.isVerified) ...[
                      Icon(Icons.verified, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Doğrulanmış',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Price
                Text(
                  _template!.isFree ? 'ÜCRETSİZ' : '${_template!.price.toStringAsFixed(0)} TL',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _template!.isFree ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Açıklama',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _template!.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 24),

          Text(
            'Şablon Alanları',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Placeholder fields
          ...(_template!.placeholders.entries.toList()
                ..sort((a, b) => a.value.order.compareTo(b.value.order)))
              .map((entry) {
            final config = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_getFieldIcon(config.type)),
                title: Text(config.label),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tür: ${config.type.displayName}'),
                    if (!config.required)
                      const Text('İsteğe bağlı', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                trailing: config.required
                    ? const Icon(Icons.star, color: Colors.red, size: 16)
                    : null,
              ),
            );
          }),

          const SizedBox(height: 24),

          Text(
            'Şablon Bilgileri',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _buildInfoRow('Versiyon', _template!.version),
          _buildInfoRow('Oluşturulma', _formatDate(_template!.createdAt)),
          _buildInfoRow('Güncellenme', _formatDate(_template!.updatedAt)),
          _buildInfoRow('Durum', _template!.status.displayName),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PDF Önizleme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Şablonun örnek verilerle nasıl görüneceğini inceleyin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          
          // PDF Preview Widget
          PdfPreviewWidget(
            templateId: _template?.id,
            previewData: _generateSampleData(),
          ),
          
          const SizedBox(height: 24),
          
          // Sample data info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Örnek Veriler',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bu önizleme örnek veriler kullanılarak oluşturulmuştur. '
                    'Gerçek PDF\'iniz girdiğiniz verilere göre farklı görünecektir.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Show sample data
                  if (_template != null) ...[
                    Text(
                      'Kullanılan Örnek Veriler:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._generateSampleData().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    return Consumer<TemplateProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: Future.value({
            'ratings': [
              {
                'id': '1',
                'userName': 'Ahmet Y.',
                'rating': 5,
                'comment': 'Çok kullanışlı bir şablon, teşekkürler!',
                'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
              },
            ],
            'summary': {
              'averageRating': 4.5,
              'totalRatings': 1,
              'ratingDistribution': {'5': 1, '4': 0, '3': 0, '2': 0, '1': 0},
            },
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Değerlendirmeler yüklenemedi: ${snapshot.error}'),
              );
            }

            final ratingsData = snapshot.data;
            if (ratingsData == null) {
              return const Center(child: Text('Değerlendirme bulunamadı'));
            }

            final ratings = ratingsData['ratings'] as List;
            final summary = ratingsData['summary'] as Map<String, dynamic>;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating summary
                  _buildRatingSummary(summary),
                  
                  const SizedBox(height: 24),

                  // Individual ratings
                  Text(
                    'Kullanıcı Değerlendirmeleri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (ratings.isEmpty)
                    const Center(
                      child: Text('Henüz değerlendirme yapılmamış'),
                    )
                  else
                    ...ratings.map((rating) => _buildRatingCard(rating)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRatingSummary(Map<String, dynamic> summary) {
    final averageRating = (summary['averageRating'] as num).toDouble();
    final totalRatings = summary['totalRatings'] as int;
    final distribution = summary['ratingDistribution'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating ? Icons.star : Icons.star_border,
                          color: Colors.amber[600],
                          size: 20,
                        );
                      }),
                    ),
                    Text('$totalRatings değerlendirme'),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final starCount = 5 - index;
                      final count = distribution[starCount.toString()] ?? 0;
                      final percentage = totalRatings > 0 ? (count / totalRatings) : 0.0;
                      
                      return Row(
                        children: [
                          Text('$starCount'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation(Colors.amber[600]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$count'),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  rating['userName'] ?? 'Anonim',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating['rating'] ? Icons.star : Icons.star_border,
                      color: Colors.amber[600],
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            if (rating['comment'] != null && rating['comment'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rating['comment']),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(DateTime.parse(rating['createdAt'])),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (!authProvider.isAuthenticated) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToLogin(),
                child: const Text('Giriş Yapın'),
              ),
            );
          }

          // Free template or already purchased
          if (_template!.isFree || _hasPurchased) {
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _useTemplate(),
                    icon: const Icon(Icons.edit),
                    label: const Text('Şablonu Kullan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (_hasPurchased)
                  OutlinedButton.icon(
                    onPressed: () => _showRatingDialog(),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Değerlendir'),
                  ),
              ],
            );
          }

          // Paid template not purchased yet
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPreview(),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Önizleme'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _checkingPurchase ? null : () => _showPurchaseDialog(),
                  icon: _checkingPurchase 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart),
                  label: Text('${_template!.price.toStringAsFixed(0)} TL - Satın Al'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFieldIcon(PlaceholderType type) {
    switch (type) {
      case PlaceholderType.string:
        return Icons.text_fields;
      case PlaceholderType.text:
      case PlaceholderType.textarea:
        return Icons.notes;
      case PlaceholderType.date:
        return Icons.calendar_today;
      case PlaceholderType.number:
        return Icons.numbers;
      case PlaceholderType.phone:
        return Icons.phone;
      case PlaceholderType.email:
        return Icons.email;
      case PlaceholderType.select:
        return Icons.arrow_drop_down_circle;
      case PlaceholderType.checkbox:
        return Icons.check_box;
      case PlaceholderType.radio:
        return Icons.radio_button_checked;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Map<String, dynamic> _generateSampleData() {
    if (_template == null) return {};
    
    final sampleData = <String, dynamic>{};
    
    _template!.placeholders.forEach((key, config) {
      switch (config.type) {
        case PlaceholderType.string:
          sampleData[key] = _getSampleString(config.label);
          break;
        case PlaceholderType.text:
        case PlaceholderType.textarea:
          sampleData[key] = _getSampleText(config.label);
          break;
        case PlaceholderType.date:
          sampleData[key] = _formatDate(DateTime.now());
          break;
        case PlaceholderType.number:
          sampleData[key] = '1000';
          break;
        case PlaceholderType.phone:
          sampleData[key] = '+90 555 123 45 67';
          break;
        case PlaceholderType.email:
          sampleData[key] = 'ornek@email.com';
          break;
        case PlaceholderType.select:
          sampleData[key] = 'Seçenek 1';
          break;
        case PlaceholderType.checkbox:
          sampleData[key] = 'Evet';
          break;
        case PlaceholderType.radio:
          sampleData[key] = 'Seçenek A';
          break;
      }
    });
    
    return sampleData;
  }

  String _getSampleString(String label) {
    final samples = {
      'ad': 'Ahmet',
      'soyad': 'Yılmaz',
      'şirket': 'ABC Şirketi',
      'unvan': 'Yazılım Geliştirici',
      'şehir': 'İstanbul',
      'adres': 'Örnek Mahallesi, Örnek Sokak No:1',
    };
    
    final lowerLabel = label.toLowerCase();
    for (final key in samples.keys) {
      if (lowerLabel.contains(key)) {
        return samples[key]!;
      }
    }
    
    return 'Örnek Metin';
  }

  String _getSampleText(String label) {
    final samples = {
      'açıklama': 'Bu bir örnek açıklama metnidir. Gerçek kullanımda buraya ilgili bilgiler yazılacaktır.',
      'içerik': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      'mesaj': 'Sayın yetkili, bu örnek bir mesaj içeriğidir.',
      'not': 'Önemli: Bu örnek bir not içeriğidir.',
    };
    
    final lowerLabel = label.toLowerCase();
    for (final key in samples.keys) {
      if (lowerLabel.contains(key)) {
        return samples[key]!;
      }
    }
    
    return 'Bu bir örnek metin içeriğidir. Gerçek kullanımda buraya ilgili bilgiler yazılacaktır.';
  }

  void _useTemplate() {
    if (_template!.isFree || _hasPurchased) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateFormScreen(template: _template!),
        ),
      );
    } else {
      _showPurchaseDialog();
    }
  }

  void _shareTemplate() {
    // TODO: Implement template sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paylaşım özelliği yakında gelecek')),
    );
  }

  void _showRatingDialog() {
    if (!_hasPurchased && !_template!.isFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Değerlendirme yapabilmek için önce şablonu satın almalısınız'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        templateId: _template!.id,
        onRatingSubmitted: () {
          // Refresh ratings
          setState(() {});
        },
      ),
    );
  }

  void _showPurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => PurchaseDialog(
        template: _template!,
        onPurchaseCompleted: () {
          // Refresh purchase status
          _checkPurchaseStatus();
        },
      ),
    );
  }

  void _showPreview() {
    _tabController.animateTo(1); // Navigate to preview tab
  }

  void _navigateToLogin() {
    // TODO: Navigate to login screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Giriş ekranına yönlendirme yakında gelecek')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _RatingDialog extends StatefulWidget {
  final String templateId;
  final VoidCallback onRatingSubmitted;

  const _RatingDialog({
    required this.templateId,
    required this.onRatingSubmitted,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Şablonu Değerlendir'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Puanınız:'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber[600],
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text('Yorumunuz (isteğe bağlı):'),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Şablon hakkındaki düşüncelerinizi paylaşın...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _rating == 0 ? null : _submitRating,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }

  Future<void> _submitRating() async {
    if (_rating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Call API to submit rating
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Değerlendirmeniz başarıyla gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRatingSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}