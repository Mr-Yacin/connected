# Contributing to Social Connect App

Thank you for your interest in contributing to Social Connect App! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

## 🤝 Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect differing viewpoints and experiences
- Accept responsibility for mistakes

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)
- Git
- Firebase account
- Code editor (VS Code or Android Studio recommended)

### Setup Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/connected.git
   cd connected
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
   - Set up your own Firebase project for testing

4. **Run the App**
   ```bash
   flutter run
   ```

5. **Verify Setup**
   ```bash
   flutter analyze
   flutter test
   ```

## 🔄 Development Workflow

### Branch Naming

Use descriptive branch names:
- `feature/add-group-chat` - New features
- `fix/chat-notification-bug` - Bug fixes
- `refactor/auth-service` - Code refactoring
- `docs/update-readme` - Documentation updates
- `test/chat-integration` - Test additions

### Development Process

1. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**
   - Write clean, documented code
   - Follow coding standards
   - Add tests for new features

3. **Test Your Changes**
   ```bash
   flutter analyze
   flutter test
   flutter test integration_test/
   ```

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: add group chat feature"
   ```

5. **Push to Your Fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Go to GitHub and create a PR
   - Fill out the PR template
   - Link related issues

## 📝 Coding Standards

### Dart Style Guide

Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// Good
class UserProfile {
  final String id;
  final String name;
  
  UserProfile({required this.id, required this.name});
}

// Bad
class userProfile {
  String id;
  String name;
}
```

### Code Formatting

Use `dart format`:
```bash
dart format lib/
```

### Linting

Follow the rules in `analysis_options.yaml`:
```bash
flutter analyze
```

### Architecture

Follow **Feature-First** with **Clean Architecture**:

```
features/
└── feature_name/
    ├── data/
    │   ├── models/
    │   ├── repositories/
    │   └── datasources/
    ├── domain/
    │   ├── entities/
    │   └── usecases/
    └── presentation/
        ├── providers/
        ├── screens/
        └── widgets/
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables**: `camelCase`
- **Constants**: `camelCase` or `SCREAMING_SNAKE_CASE`
- **Private**: `_leadingUnderscore`

```dart
// Files
user_profile.dart
chat_repository.dart

// Classes
class UserProfile {}
class ChatRepository {}

// Variables
final userName = 'John';
final isActive = true;

// Constants
const maxFileSize = 5 * 1024 * 1024;
const API_KEY = 'your-api-key';

// Private
class _UserProfileState {}
final _repository = UserRepository();
```

### State Management

Use **Riverpod** with code generation:

```dart
@riverpod
class UserProfile extends _$UserProfile {
  @override
  Future<UserProfileModel?> build(String userId) async {
    return await ref.read(userRepositoryProvider).getProfile(userId);
  }
  
  Future<void> updateProfile(UserProfileModel profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).updateProfile(profile);
      return profile;
    });
  }
}
```

### Error Handling

Always handle errors gracefully:

```dart
try {
  final result = await repository.getData();
  return result;
} on FirebaseException catch (e) {
  logger.error('Firebase error: ${e.code}', e);
  throw AppException('Failed to fetch data: ${e.message}');
} catch (e) {
  logger.error('Unexpected error', e);
  throw AppException('An unexpected error occurred');
}
```

### Comments and Documentation

- Add doc comments for public APIs
- Explain complex logic with inline comments
- Keep comments up-to-date

```dart
/// Fetches a user profile by ID.
///
/// Returns `null` if the profile doesn't exist.
/// Throws [FirebaseException] if there's a network error.
Future<UserProfile?> getProfile(String userId) async {
  // Implementation
}
```

## 📝 Commit Guidelines

### Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```bash
feat(chat): add voice message support

- Add audio recording functionality
- Add audio playback widget
- Update message model to support audio

Closes #123
```

```bash
fix(auth): resolve OTP verification timeout

The OTP verification was timing out due to incorrect
timeout configuration. Increased timeout to 60 seconds.

Fixes #456
```

## 🔍 Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] No linting errors
- [ ] Documentation updated
- [ ] Commits follow guidelines
- [ ] Branch is up-to-date with main

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How has this been tested?

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. Automated checks must pass
2. At least one approval required
3. Address review comments
4. Squash commits if requested
5. Maintainer will merge

## 🧪 Testing Guidelines

### Unit Tests

Test individual components:

```dart
void main() {
  group('UserProfile', () {
    test('should create profile from JSON', () {
      final json = {
        'id': '123',
        'name': 'John Doe',
        // ...
      };
      
      final profile = UserProfile.fromJson(json);
      
      expect(profile.id, '123');
      expect(profile.name, 'John Doe');
    });
  });
}
```

### Widget Tests

Test UI components:

```dart
void main() {
  testWidgets('ProfileCard displays user info', (tester) async {
    final profile = UserProfile(id: '123', name: 'John');
    
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileCard(profile: profile),
      ),
    );
    
    expect(find.text('John'), findsOneWidget);
  });
}
```

### Integration Tests

Test complete flows:

```dart
void main() {
  testWidgets('Complete login flow', (tester) async {
    await tester.pumpWidget(MyApp());
    
    // Enter phone number
    await tester.enterText(find.byType(TextField), '+1234567890');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();
    
    // Enter OTP
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    
    // Verify navigation to home
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```

### Test Coverage

Aim for:
- **Unit Tests**: 80%+ coverage
- **Widget Tests**: Critical UI components
- **Integration Tests**: Main user flows

Run coverage:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📚 Documentation

### Code Documentation

- Add doc comments to public APIs
- Document complex algorithms
- Include usage examples

### README Updates

Update README.md when:
- Adding new features
- Changing setup process
- Adding dependencies

### API Documentation

Update API.md when:
- Adding new data models
- Changing Firebase structure
- Adding new endpoints

## 🐛 Reporting Bugs

### Bug Report Template

```markdown
**Description**
Clear description of the bug

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Screenshots**
If applicable

**Environment**
- Device: [e.g. iPhone 12]
- OS: [e.g. iOS 15.0]
- App Version: [e.g. 1.0.0]

**Additional Context**
Any other relevant information
```

## 💡 Feature Requests

### Feature Request Template

```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches you've thought about

**Additional Context**
Mockups, examples, etc.
```

## 🎯 Priority Labels

- `priority: critical` - Security issues, data loss
- `priority: high` - Major bugs, important features
- `priority: medium` - Minor bugs, nice-to-have features
- `priority: low` - Cosmetic issues, future enhancements

## 📞 Getting Help

- Check existing documentation
- Search existing issues
- Ask in discussions
- Contact maintainers

## 🙏 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

---

**Thank you for contributing to Social Connect App! 🎉**
