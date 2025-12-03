# Repository Pattern Quick Reference

## TL;DR

✅ **All Firestore repositories MUST extend `BaseFirestoreRepository`**  
✅ **All repositories MUST have abstract interfaces**  
✅ **Providers MUST use interface types, not concrete types**  
✅ **Domain layer MUST NOT import Firebase dependencies** (except AuthRepository)

## Quick Checklist

When creating a new repository:

- [ ] Create interface in `lib/features/{feature}/domain/repositories/{feature}_repository.dart`
- [ ] Create implementation in `lib/features/{feature}/data/repositories/firestore_{feature}_repository.dart`
- [ ] Implementation extends `BaseFirestoreRepository`
- [ ] Implementation implements the interface
- [ ] Use `handleFirestoreOperation` for operations that return values
- [ ] Use `handleFirestoreVoidOperation` for void operations
- [ ] Provider uses interface type: `Provider<FeatureRepository>`
- [ ] Run verification: `dart tool/verify_repository_patterns.dart`

## Template

### Interface (`domain/repositories/feature_repository.dart`)

```dart
/// Repository interface for {feature} operations
abstract class FeatureRepository {
  /// Description of method
  Future<ReturnType> methodName(String param);
}
```

### Implementation (`data/repositories/firestore_feature_repository.dart`)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/base_firestore_repository.dart';
import '../../domain/repositories/feature_repository.dart';

/// Firestore implementation of FeatureRepository
class FirestoreFeatureRepository extends BaseFirestoreRepository 
    implements FeatureRepository {
  
  final FirebaseFirestore _firestore;
  
  FirestoreFeatureRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<ReturnType> methodName(String param) async {
    return handleFirestoreOperation(
      operation: () async {
        // Your implementation here
      },
      operationName: 'methodName',
      screen: 'ScreenName',
      arabicErrorMessage: 'رسالة الخطأ بالعربية',
      collection: 'collectionName',
      documentId: param,
    );
  }
}
```

### Provider (`presentation/providers/feature_providers.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_feature_repository.dart';
import '../../domain/repositories/feature_repository.dart';

final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  return FirestoreFeatureRepository();
});
```

## Error Handling

### For operations that return a value:

```dart
return handleFirestoreOperation<ReturnType>(
  operation: () async {
    // Your code here
    return result;
  },
  operationName: 'operationName',
  screen: 'ScreenName',
  arabicErrorMessage: 'رسالة الخطأ',
  collection: 'collectionName',
  documentId: 'docId', // optional
);
```

### For void operations:

```dart
return handleFirestoreVoidOperation(
  operation: () async {
    // Your code here
  },
  operationName: 'operationName',
  screen: 'ScreenName',
  arabicErrorMessage: 'رسالة الخطأ',
  collection: 'collectionName',
  documentId: 'docId', // optional
);
```

## Common Arabic Error Messages

```dart
// Create operations
arabicErrorMessage: 'فشل في إنشاء {item}'

// Read operations
arabicErrorMessage: 'فشل في جلب {item}'

// Update operations
arabicErrorMessage: 'فشل في تحديث {item}'

// Delete operations
arabicErrorMessage: 'فشل في حذف {item}'

// Send operations
arabicErrorMessage: 'فشل في إرسال {item}'

// Examples:
'فشل في إنشاء القصة'  // Failed to create story
'فشل في جلب الرسائل'  // Failed to fetch messages
'فشل في تحديث الملف الشخصي'  // Failed to update profile
'فشل في حذف المحادثة'  // Failed to delete chat
'فشل في إرسال الرسالة'  // Failed to send message
```

## Verification

Run the automated compliance check:

```bash
dart tool/verify_repository_patterns.dart
```

Expected output when compliant:
```
✅ All Firestore repositories extend BaseFirestoreRepository
✅ All repositories have corresponding interfaces
✅ All repositories follow proper structure
```

## Testing

### Unit Test with Mock

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FeatureRepository])
import 'feature_test.mocks.dart';

void main() {
  test('should call repository method', () async {
    final mockRepo = MockFeatureRepository();
    when(mockRepo.methodName(any)).thenAnswer((_) async => result);
    
    final result = await mockRepo.methodName('param');
    
    verify(mockRepo.methodName('param')).called(1);
  });
}
```

## Common Mistakes

❌ **Don't use concrete type in provider:**
```dart
final provider = Provider<FirestoreFeatureRepository>((ref) => ...);
```

✅ **Use interface type:**
```dart
final provider = Provider<FeatureRepository>((ref) => ...);
```

---

❌ **Don't handle errors manually:**
```dart
try {
  await _firestore.collection('items').doc(id).set(data);
} catch (e) {
  print('Error: $e');
}
```

✅ **Use handleFirestoreVoidOperation:**
```dart
return handleFirestoreVoidOperation(
  operation: () async {
    await _firestore.collection('items').doc(id).set(data);
  },
  operationName: 'createItem',
  screen: 'ItemScreen',
  arabicErrorMessage: 'فشل في إنشاء العنصر',
  collection: 'items',
);
```

---

❌ **Don't forget to extend BaseFirestoreRepository:**
```dart
class FirestoreFeatureRepository implements FeatureRepository {
  // Missing: extends BaseFirestoreRepository
}
```

✅ **Always extend BaseFirestoreRepository:**
```dart
class FirestoreFeatureRepository extends BaseFirestoreRepository 
    implements FeatureRepository {
  // Correct!
}
```

## Resources

- **Full Guide**: [Repository Pattern Guide](../guides/REPOSITORY_PATTERN_GUIDE.md)
- **Architecture**: [Architecture Guidelines](../architecture_guidelines.md)
- **Base Class**: `lib/core/data/base_firestore_repository.dart`
- **Examples**: Check existing repositories in `lib/features/*/data/repositories/`

---

**Last Updated**: December 2025
