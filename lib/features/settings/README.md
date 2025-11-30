# Settings Feature

## Architecture Decision

This feature is **presentation-only** (no data or domain layers).

## Rationale

The settings feature primarily:
- Displays UI for app configuration
- Delegates data operations to shared services (`PreferencesService`, `UserDataService`)
- Contains minimal business logic (mostly UI state)
- Uses shared infrastructure services rather than feature-specific repositories

## Structure

```
settings/
└── presentation/
    ├── providers/
    │   └── settings_provider.dart  # Uses PreferencesService & UserDataService
    └── screens/
        ├── settings_screen.dart
        ├── privacy_policy_screen.dart
        └── terms_of_service_screen.dart
```

## Current Dependencies

- **`services/storage/preferences_service.dart`** - Theme, language preferences
- **`services/external/user_data_service.dart`** - User account operations

## When to Add Data/Domain Layers

Consider refactoring if:
- Settings require complex business rules
- Need feature-specific data validation
- Require custom data persistence beyond SharedPreferences
- Business logic grows beyond simple state management

## Alternative Architecture

If settings complexity increases, consider:
```
settings/
├── data/
│   └── repositories/
│       └── settings_repository.dart  # Wraps PreferencesService
├── domain/
│   ├── repositories/
│   │   └── settings_repository.dart  # Interface
│   └── usecases/
│       ├── update_theme.dart
│       └── update_language.dart
└── presentation/
    └── ...existing...
```

For now, the presentation-only approach is clean and appropriate.
