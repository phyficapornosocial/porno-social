import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:porno_social/services/algolia_search_service.dart';

class SearchFilters {
  String? ageMin;
  String? ageMax;
  String? location;
  List<String> interests;
  bool creatorsOnly;

  SearchFilters({
    this.ageMin,
    this.ageMax,
    this.location,
    this.interests = const [],
    this.creatorsOnly = false,
  });

  String toAlgoliaFilter() {
    final parts = <String>[];

    if (creatorsOnly) {
      parts.add('isCreator:true');
    }

    if (ageMin != null && ageMin!.isNotEmpty) {
      parts.add('age >= ${ageMin!.trim()}');
    }

    if (ageMax != null && ageMax!.isNotEmpty) {
      parts.add('age <= ${ageMax!.trim()}');
    }

    if (location != null && location!.trim().isNotEmpty) {
      final escaped = location!.trim().replaceAll("'", "\\'");
      parts.add("location:'$escaped'");
    }

    if (interests.isNotEmpty) {
      parts.add('(${interests.map((i) => 'interests:$i').join(' OR ')})');
    }

    return parts.join(' AND ');
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  final _interestController = TextEditingController();
  final _ageMinController = TextEditingController();
  final _ageMaxController = TextEditingController();
  final _locationController = TextEditingController();

  AlgoliaSearchService? _algoliaSearchService;
  Timer? _debounce;

  String _query = '';
  SearchFilters _filters = SearchFilters();
  bool _isLoading = false;
  String? _error;
  List<AlgoliaUserHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    try {
      _algoliaSearchService = AlgoliaSearchService();
    } catch (e) {
      _error = e.toString();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    _interestController.dispose();
    _ageMinController.dispose();
    _ageMaxController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    if (_algoliaSearchService == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _algoliaSearchService!.searchUsers(
        query: _query,
        ageMin: _filters.ageMin,
        ageMax: _filters.ageMax,
        location: _filters.location,
        interests: _filters.interests,
        creatorsOnly: _filters.creatorsOnly,
      );

      if (!mounted) return;
      setState(() {
        _hits = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hits = const [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  onChanged: (value) {
                    setState(() => _query = value.trim());
                    _scheduleSearch();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Name, username, interests...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _interestController,
                        decoration: const InputDecoration(
                          labelText: 'Add interest filter',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final value = _interestController.text.trim();
                        if (value.isEmpty) return;
                        setState(() {
                          _filters = SearchFilters(
                            ageMin: _filters.ageMin,
                            ageMax: _filters.ageMax,
                            location: _filters.location,
                            creatorsOnly: _filters.creatorsOnly,
                            interests: [..._filters.interests, value],
                          );
                        });
                        _interestController.clear();
                        _scheduleSearch();
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageMinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age min',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          setState(
                            () => _filters = _filters..ageMin = v.trim(),
                          );
                          _scheduleSearch();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ageMaxController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age max',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          setState(
                            () => _filters = _filters..ageMax = v.trim(),
                          );
                          _scheduleSearch();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setState(() => _filters = _filters..location = v.trim());
                    _scheduleSearch();
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Creators only'),
                  value: _filters.creatorsOnly,
                  onChanged: (value) {
                    setState(() {
                      _filters = SearchFilters(
                        ageMin: _filters.ageMin,
                        ageMax: _filters.ageMax,
                        location: _filters.location,
                        interests: _filters.interests,
                        creatorsOnly: value,
                      );
                    });
                    _scheduleSearch();
                  },
                ),
                if (_filters.interests.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: _filters.interests
                        .map(
                          (interest) => Chip(
                            label: Text(interest),
                            onDeleted: () {
                              setState(() {
                                _filters = SearchFilters(
                                  ageMin: _filters.ageMin,
                                  ageMax: _filters.ageMax,
                                  location: _filters.location,
                                  creatorsOnly: _filters.creatorsOnly,
                                  interests: _filters.interests
                                      .where((i) => i != interest)
                                      .toList(),
                                );
                              });
                              _scheduleSearch();
                            },
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Algolia filter: ${_filters.toAlgoliaFilter()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_algoliaSearchService == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error ?? 'Algolia is not configured.'),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $_error'),
        ),
      );
    }

    if (_hits.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.builder(
      itemCount: _hits.length,
      itemBuilder: (context, index) {
        final hit = _hits[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: hit.avatarUrl.isNotEmpty
                ? NetworkImage(hit.avatarUrl)
                : null,
            child: hit.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(hit.displayName.isEmpty ? hit.username : hit.displayName),
          subtitle: Text('@${hit.username}'),
          trailing: hit.isCreator ? const Icon(Icons.verified, size: 18) : null,
          onTap: () => context.push('/profile/${hit.uid}'),
        );
      },
    );
  }
}
