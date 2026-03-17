import 'dart:async';

import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';

class AlgoliaUserHit {
  final String uid;
  final String username;
  final String displayName;
  final bool isCreator;
  final String avatarUrl;

  AlgoliaUserHit({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.isCreator,
    required this.avatarUrl,
  });

  factory AlgoliaUserHit.fromMap(Map<String, dynamic> data) {
    return AlgoliaUserHit(
      uid: (data['uid'] ?? data['objectID'] ?? '') as String,
      username: (data['username'] ?? '') as String,
      displayName: (data['displayName'] ?? '') as String,
      isCreator: (data['isCreator'] ?? false) as bool,
      avatarUrl: (data['avatarUrl'] ?? '') as String,
    );
  }
}

class AlgoliaSearchService {
  static const String _appId = String.fromEnvironment('ALGOLIA_APP_ID');
  static const String _searchKey = String.fromEnvironment(
    'ALGOLIA_SEARCH_API_KEY',
  );
  static const String _usersIndex = String.fromEnvironment(
    'ALGOLIA_USERS_INDEX',
    defaultValue: 'users',
  );

  AlgoliaSearchService() {
    if (_appId.isEmpty || _searchKey.isEmpty) {
      throw StateError(
        'Missing Algolia config. Pass --dart-define=ALGOLIA_APP_ID and '
        '--dart-define=ALGOLIA_SEARCH_API_KEY.',
      );
    }
  }

  Future<List<AlgoliaUserHit>> searchUsers({
    required String query,
    String? ageMin,
    String? ageMax,
    String? location,
    List<String> interests = const [],
    bool creatorsOnly = false,
    int page = 0,
    int hitsPerPage = 20,
  }) async {
    final facetFilters = <String>[];
    final numericFilters = <String>[];

    if (creatorsOnly) {
      facetFilters.add('isCreator:true');
    }

    if (location != null && location.trim().isNotEmpty) {
      facetFilters.add('location:${location.trim()}');
    }

    for (final interest in interests) {
      final value = interest.trim();
      if (value.isNotEmpty) {
        facetFilters.add('interests:$value');
      }
    }

    if (ageMin != null && ageMin.trim().isNotEmpty) {
      numericFilters.add('age >= ${ageMin.trim()}');
    }

    if (ageMax != null && ageMax.trim().isNotEmpty) {
      numericFilters.add('age <= ${ageMax.trim()}');
    }

    final searcher = HitsSearcher(
      applicationID: _appId,
      apiKey: _searchKey,
      indexName: _usersIndex,
      debounce: Duration.zero,
    );

    final completer = Completer<SearchResponse>();
    late final StreamSubscription<SearchResponse> sub;

    sub = searcher.responses.listen((response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });

    searcher.applyState(
      (state) => state.copyWith(
        query: query,
        page: page,
        hitsPerPage: hitsPerPage,
        facetFilters: facetFilters.isEmpty ? null : facetFilters,
        numericFilters: numericFilters.isEmpty ? null : numericFilters,
      ),
    );

    final response = await completer.future.timeout(
      const Duration(seconds: 10),
    );
    await sub.cancel();
    searcher.dispose();

    return response.hits
        .map((hit) => AlgoliaUserHit.fromMap(Map<String, dynamic>.from(hit)))
        .toList();
  }
}
