import 'package:flutter/material.dart';
import '../services/knowledge_hub_service.dart';
import 'package:intl/intl.dart';

class KnowledgeHubPanel extends StatefulWidget {
  final Function(KnowledgeItem) onItemSelected;

  const KnowledgeHubPanel({Key? key, required this.onItemSelected})
    : super(key: key);

  @override
  _KnowledgeHubPanelState createState() => _KnowledgeHubPanelState();
}

class _KnowledgeHubPanelState extends State<KnowledgeHubPanel> {
  final KnowledgeHubService _service = KnowledgeHubService();
  List<String> _categories = [];
  List<KnowledgeItem> _knowledgeItems = [];
  String _selectedCategory = '';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final categories = await _service.getKnowledgeCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty && _selectedCategory.isEmpty) {
          _selectedCategory = categories.first;
          _loadKnowledgeItems(_selectedCategory);
        } else {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadKnowledgeItems(String category) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _selectedCategory = category;
    });

    try {
      final items = await _service.getKnowledgeByCategory(category);
      setState(() {
        _knowledgeItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _searchKnowledge() async {
    if (_searchQuery.isEmpty) {
      _loadKnowledgeItems(_selectedCategory);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _isSearching = true;
    });

    try {
      final items = await _service.searchKnowledge(_searchQuery);
      setState(() {
        _knowledgeItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Knowledge Hub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _searchQuery = '';
                        _loadKnowledgeItems(_selectedCategory);
                      }
                    });
                  },
                  tooltip: _isSearching ? 'Close Search' : 'Search',
                ),
              ],
            ),
          ),

          // Search bar
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search knowledge base...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  _searchQuery = value;
                },
                onSubmitted: (_) => _searchKnowledge(),
              ),
            ),

          // Category tabs
          if (!_isSearching)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () => _loadKnowledgeItems(category),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green.shade100
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green.shade600
                                : Colors.grey.shade300,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          Divider(height: 1),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade300,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Error loading knowledge content',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    TextButton(
                      onPressed: () => _isSearching
                          ? _searchKnowledge()
                          : _loadKnowledgeItems(_selectedCategory),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_knowledgeItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _isSearching
                          ? 'No items match your search'
                          : 'No knowledge items available',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _knowledgeItems.length,
                padding: EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _knowledgeItems[index];
                  return _buildKnowledgeItem(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeItem(KnowledgeItem item) {
    return InkWell(
      onTap: () => widget.onItemSelected(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(item.category),
                  color: Colors.green.shade700,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                if (item.lastUpdated != null)
                  Text(
                    'Updated ${DateFormat('MMM d').format(item.lastUpdated!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              _truncateContent(item.content),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags
                  .map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _truncateContent(String content) {
    if (content.length <= 120) return content;
    return content.substring(0, 120) + '...';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'panchakarma basics':
        return Icons.info_outline;
      case 'procedures':
        return Icons.medical_services_outlined;
      case 'patient care':
        return Icons.healing;
      case 'best practices':
        return Icons.lightbulb_outline;
      default:
        return Icons.article_outlined;
    }
  }
}
