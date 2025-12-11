import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/template_provider.dart';
import '../../providers/tag_provider.dart';
import '../../../domain/entities/template.dart';
import 'template_detail_screen.dart';
import 'template_list_screen.dart';
import '../../widgets/offline_template_manager.dart';
import '../../widgets/tag_widgets.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TemplateProvider>().loadTemplates();
      context.read<TemplateProvider>().loadCategories();
      context.read<TagProvider>().loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şablon Marketi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemplateListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!mounted) return;
          final templateProvider = context.read<TemplateProvider>();
          await templateProvider.loadTemplates();
          if (!mounted) return;
          await templateProvider.loadCategories();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline template manager
              const OfflineTemplateManager(),
              
              const SizedBox(height: 16),

              // Search bar
              _buildSearchBar(),
              
              const SizedBox(height: 24),

              // Categories
              _buildCategoriesSection(),

              const SizedBox(height: 24),

              // Popular tags
              _buildPopularTagsSection(),

              const SizedBox(height: 24),

              // Featured templates
              _buildFeaturedSection(),

              const SizedBox(height: 24),

              // Popular templates
              _buildPopularSection(),

              const SizedBox(height: 24),

              // Recent templates
              _buildRecentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TemplateListScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              'Şablon ara...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kategoriler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateListScreen(),
                  ),
                );
              },
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<TemplateProvider>(
          builder: (context, provider, child) {
            if (provider.categories.isEmpty) {
              return const Center(
                child: Text('Kategoriler yükleniyor...'),
              );
            }

            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  return _buildCategoryCard(category);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TemplateListScreen(),
              ),
            );
            // Set category filter
            context.read<TemplateProvider>().searchTemplates(category: category.id);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(category.icon),
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${category.templateCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Öne Çıkan Şablonlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateListScreen(),
                  ),
                );
                context.read<TemplateProvider>().loadTemplates(); // Load all templates
              },
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<TemplateProvider>(
          builder: (context, provider, child) {
            final featuredTemplates = provider.templates
                .where((template) => template.isFeatured)
                .take(5)
                .toList();

            if (featuredTemplates.isEmpty) {
              return const Center(
                child: Text('Öne çıkan şablon bulunamadı'),
              );
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredTemplates.length,
                itemBuilder: (context, index) {
                  final template = featuredTemplates[index];
                  return _buildTemplateCard(template);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopularSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popüler Şablonlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateListScreen(),
                  ),
                );
                context.read<TemplateProvider>().searchTemplates(sortBy: 'popularity');
              },
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<TemplateProvider>(
          builder: (context, provider, child) {
            final popularTemplates = provider.templates
                .where((template) => template.downloadCount > 100)
                .take(5)
                .toList();

            if (popularTemplates.isEmpty) {
              return const Center(
                child: Text('Popüler şablon bulunamadı'),
              );
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: popularTemplates.length,
                itemBuilder: (context, index) {
                  final template = popularTemplates[index];
                  return _buildTemplateCard(template);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yeni Eklenen Şablonlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplateListScreen(),
                  ),
                );
                context.read<TemplateProvider>().searchTemplates(sortBy: 'date');
              },
              child: const Text('Tümünü Gör'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<TemplateProvider>(
          builder: (context, provider, child) {
            final recentTemplates = provider.templates.take(3).toList();

            if (recentTemplates.isEmpty) {
              return const Center(
                child: Text('Yeni şablon bulunamadı'),
              );
            }

            return Column(
              children: recentTemplates.map((template) {
                return _buildTemplateListItem(template);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTemplateCard(Template template) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateDetailScreen(templateId: template.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template preview
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: template.previewImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: Image.network(
                          template.previewImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.description, size: 40);
                          },
                        ),
                      )
                    : const Icon(Icons.description, size: 40),
              ),

              // Template info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber[600]),
                          const SizedBox(width: 2),
                          Text(
                            template.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        template.isFree ? 'ÜCRETSİZ' : '${template.price.toStringAsFixed(0)} TL',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: template.isFree ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateListItem(Template template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: template.previewImageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    template.previewImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.description, size: 24);
                    },
                  ),
                )
              : const Icon(Icons.description, size: 24),
        ),
        title: Text(
          template.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber[600]),
                const SizedBox(width: 2),
                Text(
                  template.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                Icon(Icons.download, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Text(
                  '${template.downloadCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              template.isFree ? 'ÜCRETSİZ' : '${template.price.toStringAsFixed(0)} TL',
              style: TextStyle(
                color: template.isFree ? Colors.green : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (template.isFeatured)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ÖNE ÇIKAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TemplateDetailScreen(templateId: template.id),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'gavel':
        return Icons.gavel;
      case 'business':
        return Icons.business;
      case 'school':
        return Icons.school;
      case 'description':
        return Icons.description;
      case 'assignment':
        return Icons.assignment;
      case 'people':
        return Icons.people;
      case 'account_balance':
        return Icons.account_balance;
      case 'folder_open':
        return Icons.folder_open;
      default:
        return Icons.folder;
    }
  }
}
  Widget _buildPopularTagsSection() {
    return Consumer<TagProvider>(
      builder: (context, tagProvider, child) {
        if (tagProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tagProvider.popularTags.isEmpty) {
          return const SizedBox.shrink();
        }

        return PopularTagsWidget(
          tags: tagProvider.popularTags,
          onTagTap: (tag) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateListScreen(
                  initialTag: tag.name,
                ),
              ),
            );
          },
        );
      },
    );
  }