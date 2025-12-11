import 'package:flutter/material.dart';
import '../../domain/entities/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showUsageCount;

  const TagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.showUsageCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showUsageCount) ...[
              const SizedBox(width: 4),
              Text(
                '(${tag.usageCount})',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TagSelector extends StatefulWidget {
  final List<Tag> availableTags;
  final List<Tag> selectedTags;
  final Function(List<Tag>) onTagsChanged;
  final bool allowCreate;

  const TagSelector({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    this.allowCreate = true,
  });

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final _controller = TextEditingController();
  List<Tag> _filteredTags = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.availableTags;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterTags(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTags = widget.availableTags;
        _showSuggestions = false;
      } else {
        _filteredTags = widget.availableTags
            .where((tag) => 
                tag.name.toLowerCase().contains(query.toLowerCase()) &&
                !widget.selectedTags.any((selected) => selected.id == tag.id))
            .toList();
        _showSuggestions = true;
      }
    });
  }

  void _addTag(Tag tag) {
    final newTags = List<Tag>.from(widget.selectedTags)..add(tag);
    widget.onTagsChanged(newTags);
    _controller.clear();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _removeTag(Tag tag) {
    final newTags = widget.selectedTags.where((t) => t.id != tag.id).toList();
    widget.onTagsChanged(newTags);
  }

  void _createAndAddTag(String name) {
    if (name.trim().isEmpty) return;
    
    // Create a temporary tag (in real app, this would call API)
    final newTag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      slug: name.trim().toLowerCase().replaceAll(' ', '-'),
      usageCount: 0,
      createdAt: DateTime.now(),
    );
    
    _addTag(newTag);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.selectedTags.map((tag) => TagChip(
              tag: tag,
              isSelected: true,
              onDelete: () => _removeTag(tag),
            )).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Input field
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Etiket ekle...',
            prefixIcon: const Icon(Icons.tag),
            border: const OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty && widget.allowCreate
                ? IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _createAndAddTag(_controller.text),
                  )
                : null,
          ),
          onChanged: _filterTags,
          onSubmitted: widget.allowCreate ? _createAndAddTag : null,
        ),

        // Suggestions
        if (_showSuggestions && _filteredTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredTags.length,
              itemBuilder: (context, index) {
                final tag = _filteredTags[index];
                return ListTile(
                  dense: true,
                  title: Text(tag.name),
                  trailing: Text(
                    '${tag.usageCount} kullanım',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => _addTag(tag),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class PopularTagsWidget extends StatelessWidget {
  final List<Tag> tags;
  final Function(Tag) onTagTap;
  final String title;

  const PopularTagsWidget({
    super.key,
    required this.tags,
    required this.onTagTap,
    this.title = 'Popüler Etiketler',
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => TagChip(
            tag: tag,
            showUsageCount: true,
            onTap: () => onTagTap(tag),
          )).toList(),
        ),
      ],
    );
  }
}