import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class SearchFilters {
  final String? query;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? favoritesOnly;

  SearchFilters({
    this.query,
    this.startDate,
    this.endDate,
    this.favoritesOnly,
  });
}

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'journal_entries';

  /// Search entries by text query across title, transcription, summary, and notes
  Future<List<JournalEntry>> searchEntries(String query, {String? userId}) async {
    if (query.trim().isEmpty) return [];

    try {
      final lowercaseQuery = query.toLowerCase();
      
      // Get all entries first (Firestore doesn't support full-text search natively)
      Query baseQuery = _firestore.collection(_collection);
      
      if (userId != null) {
        baseQuery = baseQuery.where('userId', isEqualTo: userId);
      }
      
      final querySnapshot = await baseQuery.get();
      
      final entries = querySnapshot.docs
          .map((doc) => JournalEntry.fromMap(doc.data() as Map<String, dynamic>))
          .where((entry) => _matchesQuery(entry, lowercaseQuery))
          .toList();

      // Sort by relevance (title matches first, then date)
      entries.sort((a, b) {
        final aRelevance = _calculateRelevance(a, lowercaseQuery);
        final bRelevance = _calculateRelevance(b, lowercaseQuery);
        
        if (aRelevance != bRelevance) {
          return bRelevance.compareTo(aRelevance);
        }
        
        return b.date.compareTo(a.date);
      });

      return entries;
    } catch (e) {
      print('Error searching entries: $e');
      return [];
    }
  }

  /// Filter entries by date range
  Future<List<JournalEntry>> filterByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      query = query
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true);

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => JournalEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error filtering by date range: $e');
      return [];
    }
  }

  /// Get favorite entries
  Future<List<JournalEntry>> getFavoriteEntries({String? userId}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      query = query
          .where('isFavorite', isEqualTo: true)
          .orderBy('date', descending: true);

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => JournalEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting favorite entries: $e');
      return [];
    }
  }

  /// Advanced search with multiple filters
  Future<List<JournalEntry>> advancedSearch(
    SearchFilters filters, {
    String? userId,
  }) async {
    try {
      List<JournalEntry> results = [];

      // Start with all entries or filtered by date range
      if (filters.startDate != null && filters.endDate != null) {
        results = await filterByDateRange(
          filters.startDate!,
          filters.endDate!,
          userId: userId,
        );
      } else {
        Query query = _firestore.collection(_collection);
        
        if (userId != null) {
          query = query.where('userId', isEqualTo: userId);
        }
        
        query = query.orderBy('date', descending: true);
        
        final querySnapshot = await query.get();
        results = querySnapshot.docs
            .map((doc) => JournalEntry.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      }

      // Apply text search filter
      if (filters.query != null && filters.query!.trim().isNotEmpty) {
        final lowercaseQuery = filters.query!.toLowerCase();
        results = results
            .where((entry) => _matchesQuery(entry, lowercaseQuery))
            .toList();
      }

      // Apply favorites filter
      if (filters.favoritesOnly == true) {
        results = results.where((entry) => entry.isFavorite).toList();
      }

      // Sort by relevance if there's a query, otherwise by date
      if (filters.query != null && filters.query!.trim().isNotEmpty) {
        final lowercaseQuery = filters.query!.toLowerCase();
        results.sort((a, b) {
          final aRelevance = _calculateRelevance(a, lowercaseQuery);
          final bRelevance = _calculateRelevance(b, lowercaseQuery);
          
          if (aRelevance != bRelevance) {
            return bRelevance.compareTo(aRelevance);
          }
          
          return b.date.compareTo(a.date);
        });
      }

      return results;
    } catch (e) {
      print('Error in advanced search: $e');
      return [];
    }
  }

  /// Get search suggestions based on existing entries
  Future<List<String>> getSearchSuggestions({String? userId, int limit = 10}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      
      query = query.orderBy('date', descending: true).limit(100);
      
      final querySnapshot = await query.get();
      final entries = querySnapshot.docs
          .map((doc) => JournalEntry.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Extract keywords from titles and tags
      final suggestions = <String>{};
      
      for (final entry in entries) {
        // Add title words
        suggestions.addAll(_extractKeywords(entry.title));
        
        // Add words from summaries
        if (entry.summary?.isNotEmpty == true) {
          suggestions.addAll(_extractKeywords(entry.summary!));
        }
      }

      return suggestions.take(limit).toList();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }

  /// Check if entry matches the search query
  bool _matchesQuery(JournalEntry entry, String lowercaseQuery) {
    final searchableText = [
      entry.title,
      entry.transcription ?? '',
      entry.summary ?? '',
      entry.notes ?? '',
    ].join(' ').toLowerCase();

    return searchableText.contains(lowercaseQuery);
  }

  /// Calculate relevance score for search ranking
  int _calculateRelevance(JournalEntry entry, String lowercaseQuery) {
    int score = 0;
    
    // Title matches get highest score
    if (entry.title.toLowerCase().contains(lowercaseQuery)) {
      score += 10;
    }
    
    // Summary matches get medium score
    if (entry.summary?.toLowerCase().contains(lowercaseQuery) == true) {
      score += 6;
    }
    
    // Transcription matches get lower score
    if (entry.transcription?.toLowerCase().contains(lowercaseQuery) == true) {
      score += 4;
    }
    
    // Notes matches get lowest score
    if (entry.notes?.toLowerCase().contains(lowercaseQuery) == true) {
      score += 2;
    }
    
    return score;
  }

  /// Extract keywords from text
  List<String> _extractKeywords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^\w]+'))
        .where((word) => word.length > 2)
        .toSet()
        .toList();
  }
}
