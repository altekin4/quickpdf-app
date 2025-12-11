import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/document.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../pdf/pdf_generation_screen.dart';

class DocumentHistoryScreen extends StatefulWidget {
  const DocumentHistoryScreen({super.key});

  @override
  State<DocumentHistoryScreen> createState() => _DocumentHistoryScreenState();
}

class _DocumentHistoryScreenState extends State<DocumentHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDocuments() {
    final authProvider = context.read<AuthProvider>();
    final documentProvider = context.read<DocumentProvider>();
    
    if (authProvider.currentUser != null) {
      documentProvider.loadDocuments(authProvider.currentUser!.id);
    }
  }

  void _onSearchChanged(String query) {
    final authProvider = context.read<AuthProvider>();
    final documentProvider = context.read<DocumentProvider>();
    
    if (authProvider.currentUser != null) {
      documentProvider.searchDocuments(authProvider.currentUser!.id, query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<DocumentProvider>().clearSearch();
  }

  Future<void> _shareDocument(Document document) async {
    // Show sharing options dialog
    final shareType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paylaşım Seçenekleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Dosya Olarak Paylaş'),
              subtitle: const Text('PDF dosyasını paylaş'),
              onTap: () => Navigator.of(context).pop('file'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('E-posta Gönder'),
              subtitle: const Text('E-posta ile gönder'),
              onTap: () => Navigator.of(context).pop('email'),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Metin Olarak'),
              subtitle: const Text('İçeriği metin olarak paylaş'),
              onTap: () => Navigator.of(context).pop('text'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );

    if (shareType == null || !mounted) return;

    try {
      final documentProvider = context.read<DocumentProvider>();
      
      switch (shareType) {
        case 'file':
          final file = await documentProvider.getDocumentFile(document.id);
          if (file != null && mounted) {
            await Share.shareXFiles(
              [XFile(file.path)],
              text: 'PDF Belgesi: ${document.filename}',
            );
          } else if (mounted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belge dosyası bulunamadı')),
              );
            }
          }
          break;
          
        case 'email':
          final file = await documentProvider.getDocumentFile(document.id);
          if (file != null) {
            await Share.shareXFiles(
              [XFile(file.path)],
              text: 'PDF belgesi ekte bulunmaktadır.\n\nOluşturulma tarihi: ${_dateFormat.format(document.createdAt)}',
              subject: document.filename,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Belge dosyası bulunamadı')),
              );
            }
          }
          break;
          
        case 'text':
          String shareText = 'Belge: ${document.filename}\n\n';
          shareText += 'İçerik:\n${document.content}\n\n';
          shareText += 'Oluşturulma tarihi: ${_dateFormat.format(document.createdAt)}';
          
          await Share.share(shareText, subject: document.filename);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım hatası: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text('${document.filename} belgesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final documentProvider = context.read<DocumentProvider>();
      
      if (authProvider.currentUser != null) {
        await documentProvider.deleteDocument(document.id, authProvider.currentUser!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Belge silindi')),
          );
        }
      }
    }
  }

  void _reopenDocument(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PdfGenerationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Belge Geçmişi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Belge ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Document List
          Expanded(
            child: Consumer<DocumentProvider>(
              builder: (context, documentProvider, child) {
                if (documentProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (documentProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          documentProvider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDocuments,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final documents = documentProvider.documents;

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          documentProvider.searchQuery.isNotEmpty
                              ? 'Arama sonucu bulunamadı'
                              : 'Henüz belge oluşturmadınız',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (documentProvider.searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearSearch,
                            child: const Text('Aramayı Temizle'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadDocuments(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      return _DocumentCard(
                        document: document,
                        dateFormat: _dateFormat,
                        onShare: () => _shareDocument(document),
                        onDelete: () => _deleteDocument(document),
                        onReopen: () => _reopenDocument(document),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Document document;
  final DateFormat dateFormat;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onReopen;

  const _DocumentCard({
    required this.document,
    required this.dateFormat,
    required this.onShare,
    required this.onDelete,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onReopen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    document.isFromTemplate 
                        ? Icons.description 
                        : Icons.text_snippet,
                    color: document.isFromTemplate 
                        ? Colors.blue 
                        : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.filename,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(document.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          onShare();
                          break;
                        case 'reopen':
                          onReopen();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'reopen',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Düzenle'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Paylaş'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sil', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (document.isFromTemplate) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Şablondan oluşturuldu',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Düzenlemek için dokunun',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}