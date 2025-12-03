# Code Review Checklist

## Performance
- [ ] No N+1 queries (use batch queries or denormalization)
- [ ] Proper disposal of controllers, timers, and subscriptions
- [ ] No memory leaks (caches have size limits)
- [ ] Images are properly cached and compressed
- [ ] Pagination is used for large lists

## Code Quality
- [ ] No print statements (use AppLogger or ErrorLoggingService)
- [ ] No code duplication (extract to shared utilities)
- [ ] Proper error handling with try-catch
- [ ] User-friendly Arabic error messages
- [ ] Repositories extend BaseFirestoreRepository (run `dart tool/verify_repository_patterns.dart`)
- [ ] All repositories have interfaces (verified by automated script)

## Architecture
- [ ] Follows clean architecture (domain/data/presentation)
- [ ] Uses Riverpod for state management
- [ ] Services are properly abstracted
- [ ] Dependencies are injected via providers
- [ ] Feature-specific code is in feature folders

## Testing
- [ ] Unit tests for business logic
- [ ] Property-based tests for universal properties
- [ ] Integration tests for critical flows
- [ ] Tests use mocks/fakes, not real Firebase

## Documentation
- [ ] Public APIs have doc comments
- [ ] Complex logic has inline comments
- [ ] README updated if architecture changes
- [ ] Breaking changes are documented

## Security
- [ ] No hardcoded secrets or API keys
- [ ] Firestore rules are properly configured
- [ ] User input is validated
- [ ] PII is handled securely

## Accessibility
- [ ] Semantic labels for screen readers
- [ ] Sufficient color contrast
- [ ] Touch targets are at least 44x44
- [ ] Supports RTL layout (Arabic)

## Automated Checks

Before submitting for review, run these automated verification scripts:

### Repository Pattern Compliance
```bash
dart tool/verify_repository_patterns.dart
```
Verifies that all repositories follow architectural patterns. See [Repository Pattern Guide](../docs/guides/REPOSITORY_PATTERN_GUIDE.md) for details.

### Print Statement Detection
```bash
flutter test test/print_statement_static_analysis_test.dart
```
Ensures no print statements exist in production code.

### All Tests
```bash
flutter test
```
Runs all unit tests, property-based tests, and integration tests.
