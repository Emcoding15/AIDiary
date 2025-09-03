import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/search_service.dart';
import '../widgets/entry_card.dart';
import '../utils/snackbar_utils.dart';
import 'entry_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? userId;

  const SearchScreen({super.key, this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  
  List<JournalEntry> _searchResults = [];
  List<String> _suggestions = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  // Filter states
  DateTime? _startDate;
  DateTime? _endDate;
  bool _favoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadRecentSearches();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await _searchService.getSearchSuggestions(
      userId: widget.userId,
      limit: 10,
    );
    setState(() {
      _suggestions = suggestions;
    });
  }

  void _loadRecentSearches() {
    // TODO: Implement persistent storage for recent searches
    setState(() {
      _recentSearches = []; // Load from shared preferences
    });
  }

  Future<void> _performSearch([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();
    
    if (searchQuery.isEmpty && !_favoritesOnly && _startDate == null && _endDate == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<JournalEntry> results;
      
      if (_hasFilters() || searchQuery.isNotEmpty) {
        final filters = SearchFilters(
          query: searchQuery.isNotEmpty ? searchQuery : null,
          startDate: _startDate,
          endDate: _endDate,
          favoritesOnly: _favoritesOnly,
        );
        
        results = await _searchService.advancedSearch(
          filters,
          userId: widget.userId,
        );
      } else {
        results = [];
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

  // Do not add to recent searches here; only add on submit
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        SnackBarUtils.showError(context, 'Search failed: $e');
      }
    }
  }

  bool _hasFilters() {
    return _favoritesOnly || 
           _startDate != null || 
           _endDate != null;
  }

  void _addToRecentSearches(String query) {
    setState(() {
      _recentSearches.remove(query);
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.take(10).toList();
      }
    });
    // TODO: Save to shared preferences
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _startDate = null;
      _endDate = null;
      _favoritesOnly = false;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Entries'),
        actions: [
          if (_searchController.text.isNotEmpty || _hasFilters())
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
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
                hintText: 'Search your entries...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => _performSearch(),
              onSubmitted: (value) {
                _performSearch(value);
                if (value.trim().isNotEmpty) {
                  _addToRecentSearches(value.trim());
                }
              },
            ),
          ),

          // Filters Section
          if (_showFilters) _buildFiltersSection(),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Range Filter
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _startDate != null && _endDate != null
                        ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                        : 'Select Date Range',
                  ),
                ),
              ),
              if (_startDate != null && _endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    _performSearch();
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Favorites Filter
          CheckboxListTile(
            title: const Text('Favorites only'),
            value: _favoritesOnly,
            onChanged: (value) {
              setState(() {
                _favoritesOnly = value ?? false;
              });
              _performSearch();
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.isEmpty && !_hasFilters()) {
      return _buildSuggestionsAndRecents();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildSuggestionsAndRecents() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    _performSearch();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          if (_suggestions.isNotEmpty) ...[
            Text(
              'Suggestions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _suggestions.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () {
                    _searchController.text = suggestion;
                    _performSearch();
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No entries found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final entry = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EntryCard(
            entry: entry,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntryDetailsScreen(entry: entry),
                ),
              );
            },
            searchQuery: _searchController.text,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
