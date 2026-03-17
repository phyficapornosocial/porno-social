## Algolia Runtime Config

Pass these defines when running or building:

- `--dart-define=ALGOLIA_APP_ID=...`
- `--dart-define=ALGOLIA_SEARCH_API_KEY=...`
- Optional: `--dart-define=ALGOLIA_USERS_INDEX=users`

Examples:

```bash
flutter run \
  --dart-define=ALGOLIA_APP_ID=YOUR_APP_ID \
  --dart-define=ALGOLIA_SEARCH_API_KEY=YOUR_SEARCH_ONLY_KEY \
  --dart-define=ALGOLIA_USERS_INDEX=users
```

```bash
flutter build apk \
  --dart-define=ALGOLIA_APP_ID=YOUR_APP_ID \
  --dart-define=ALGOLIA_SEARCH_API_KEY=YOUR_SEARCH_ONLY_KEY \
  --dart-define=ALGOLIA_USERS_INDEX=users
```

If `ALGOLIA_APP_ID` or `ALGOLIA_SEARCH_API_KEY` is missing, the search screen shows a clear configuration error instead of silently falling back.

## Required Index Fields

To match the current filters in search:

- `uid` (or `objectID`)
- `username`
- `displayName`
- `isCreator` (boolean facet)
- `interests` (facet/array)
- `location` (facet)
- `age` (numeric)

## Notes

- Use a Search-Only API key on client apps.
- Ensure `interests`, `location`, and `isCreator` are configured as filterable attributes/facets in Algolia.
- Ensure `age` is stored as a numeric attribute for numeric filtering.
