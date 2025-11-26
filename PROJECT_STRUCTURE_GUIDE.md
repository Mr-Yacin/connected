# 📁 Project Structure Guide

This document provides a comprehensive overview of the Social Connect App project structure after reorganization.

## 🗂️ Root Directory Structure

```
connected/
├── .dart_tool/              # Dart build cache (gitignored)
├── .kiro/                   # Kiro IDE configurations
├── android/                 # Android platform code
├── assets/                  # App assets (images, icons, etc.)
├── docs/                    # 📚 All documentation (organized by category)
├── functions/               # Firebase Cloud Functions
├── integration_test/        # Integration tests
├── ios/                     # iOS platform code
├── lib/                     # 💙 Flutter application code
├── linux/                   # Linux platform code
├── macos/                   # macOS platform code
├── scripts/                 # Build and utility scripts
├── test/                    # Unit tests
├── tool/                    # Development tools (gitignored)
├── web/                     # Web platform code
├── windows/                 # Windows platform code
├── .gitignore              # Git ignore patterns
├── analysis_options.yaml    # Dart analysis configuration
├── CONTRIBUTING.md          # Contribution guidelines
├── firebase.json           # Firebase configuration
├── firestore.indexes.json  # Firestore index definitions
├── firestore.rules         # Firestore security rules
├── pubspec.yaml            # Flutter dependencies
├── README.md               # Main project README
└── storage.rules           # Firebase Storage rules
```

## 📚 Documentation Structure (`/docs`)

All project documentation is organized in the `docs/` folder by category:

### 🎨 `/docs/branding/`
Brand identity, design guidelines, and assets
- BRAND_GUIDE.md
- ICON_DESIGN_GUIDE.md
- BRAND_ASSETS_REFERENCE.md
- ARABIC_BRAND_PROPOSAL.md
- NABD_BRAND_IMPLEMENTATION.md
- COMPLETE_BRANDING_SUMMARY.md
- BRANDING_SETUP.md
- README.md

### 📝 `/docs/changelog/`
Version history and milestone tracking
- CHANGELOG.md
- WEEK3_COMPLETE.md
- README.md

### 🚀 `/docs/deployment/`
Deployment guides and production setup
- DEPLOYMENT_INSTRUCTIONS.md
- DEPLOYMENT_READY.md
- DEPLOYMENT_SUCCESS.md
- DEPLOYMENT_GUIDE_WEEK3.md
- IMPLEMENTATION_COMPLETE.md
- IMPLEMENTATION_SUMMARY.md
- QUICK_START_WEEK3.md
- WEEK3_IMPLEMENTATION.md

### 🔧 `/docs/fixes/`
Historical bug fixes and improvements
- WEEK1_FIXES_COMPLETE.md
- Week-1-Critical-Fixes-Implementation-Plan.md
- FIX2_*.md (Fix 2 documentation)
- FIX3_*.md (Fix 3 documentation)
- FIX4_*.md (Fix 4 documentation)

### 📖 `/docs/guides/`
Setup, configuration, and how-to guides
- FIREBASE_SETUP.md
- SETUP_COMPLETE.md
- PHONE_AUTH_TROUBLESHOOTING.md
- MIGRATION_CHECKLIST.md
- CHAT_OPTIMIZATION_GUIDE.md
- COMPOSITE_INDEXES_GUIDE.md
- FCM_COMPLETE_GUIDE.md
- FCM_QUICK_ANSWER.md

### 📊 `/docs/project-management/`
Project planning and organization
- PROJECT_SUMMARY.md
- PROJECT_ORGANIZATION.md
- IMPLEMENTATION_CHECKLIST.md
- SCALING_ROADMAP.md
- README.md

### 📋 `/docs/references/`
Technical references and API documentation
- API.md
- PROJECT_STRUCTURE.md
- PERFORMANCE_COMPARISON.md
- SECURITY_RULES_OPTIMIZATION.md
- INDEX_VERIFICATION.md
- PAGINATION_FEATURES.md
- Analysis-o- Your-Social-Connect-App.md
- QUICK_REFERENCE.md

## 💙 Application Code Structure (`/lib`)

```
lib/
├── core/                    # Shared components
│   ├── constants/          # App-wide constants
│   ├── theme/              # Theme and styling
│   ├── utils/              # Utility functions
│   └── widgets/            # Reusable widgets
├── features/                # Feature modules (feature-first architecture)
│   ├── auth/               # Authentication feature
│   ├── profile/            # User profile feature
│   ├── chat/               # Messaging feature
│   ├── discovery/          # User discovery feature
│   ├── stories/            # Stories feature
│   ├── settings/           # Settings feature
│   └── moderation/         # Content moderation feature
└── services/                # Shared services
    ├── firebase_service.dart
    └── ...
```

### Feature-First Architecture

Each feature folder follows Clean Architecture principles:

```
feature/
├── data/                   # Data layer
│   ├── models/            # Data models
│   ├── repositories/      # Repository implementations
│   └── data_sources/      # API/local data sources
├── domain/                 # Domain layer
│   ├── entities/          # Business entities
│   └── usecases/          # Business logic
└── presentation/           # Presentation layer
    ├── screens/           # UI screens
    ├── widgets/           # Feature-specific widgets
    └── providers/         # State management (Riverpod)
```

## 🔥 Firebase Structure

### Cloud Functions (`/functions`)
- index.js - Cloud Functions entry point
- package.json - Node.js dependencies

### Security Rules
- `firestore.rules` - Firestore database security
- `storage.rules` - Cloud Storage security

### Indexes
- `firestore.indexes.json` - Database composite indexes

## 🧪 Testing Structure

### Unit Tests (`/test`)
Mirror the lib/ structure for unit tests

### Integration Tests (`/integration_test`)
End-to-end integration tests

## 🛠️ Development Tools & Scripts

### `/scripts` - Build Automation ✅ (Committed)
**Purpose**: Build-time scripts safe to version control
- Icon generation (`generate_icons.js`)
- Build automation scripts
- Asset processing utilities
- CI/CD pipeline scripts

**Status**: ✅ Committed to git (no sensitive data)

### `/tool` - Admin Tools 🔒 (Gitignored)
**Purpose**: Administrative utilities with sensitive credentials
- Mock data uploaders (`upload-mock-data.js`)
- Database migration scripts (`migrate_chat_unread_counts.js`)
- Deployment scripts (`deploy_indexes.sh/bat`, `deploy_security_rules.sh/bat`)
- Service account keys (🔒 SENSITIVE - never commit)

**Status**: 🔒 Gitignored (contains serviceAccountKey.json)

**⚠️ Key Difference**: 
- `scripts/` = Build tools (safe) ✅
- `tool/` = Admin tools (sensitive) 🔒

See [SCRIPTS_AND_TOOLS_GUIDE.md](SCRIPTS_AND_TOOLS_GUIDE.md) for detailed usage.

## 📦 Assets (`/assets`)

```
assets/
├── images/                 # App images
├── icons/                  # App icons
└── ...
```

## 🔒 Security & Gitignore

### Ignored Files/Folders
- Build artifacts (`/build`, `.dart_tool`)
- IDE configs (`.idea`, `.vscode/settings.json`)
- Sensitive configs (`google-services.json`, `GoogleService-Info.plist`)
- Firebase local data (`.firebase/`, emulator exports)
- Development tools (`/tool`)
- Large/temporary files (`project_structure.txt`, `*.tmp`)
- Dependencies (`node_modules/`, iOS Pods)

See `.gitignore` for complete list.

## 📋 Key Configuration Files

| File | Purpose |
|------|---------|
| `pubspec.yaml` | Flutter dependencies and assets |
| `firebase.json` | Firebase project configuration |
| `analysis_options.yaml` | Dart linter rules |
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Database indexes |

## 🚀 Quick Navigation

### For New Developers
1. Start with `/README.md`
2. Read `/docs/project-management/PROJECT_SUMMARY.md`
3. Follow `/docs/guides/FIREBASE_SETUP.md`
4. Review `/docs/guides/SETUP_COMPLETE.md`

### For Designers
1. Check `/docs/branding/README.md`
2. Review `/docs/branding/BRAND_GUIDE.md`
3. Reference `/assets` folder for brand assets

### For DevOps
1. Review `/docs/deployment/DEPLOYMENT_INSTRUCTIONS.md`
2. Check `/firebase.json`, `firestore.rules`, `storage.rules`
3. Verify `/firestore.indexes.json`

### For Project Managers
1. Check `/docs/project-management/PROJECT_SUMMARY.md`
2. Review `/docs/changelog/CHANGELOG.md`
3. Monitor `/docs/project-management/IMPLEMENTATION_CHECKLIST.md`

## 🔄 Maintenance

### Regular Updates
- Update CHANGELOG.md with every release
- Keep implementation checklist current
- Update documentation when adding features
- Review and update security rules periodically

### Documentation Organization
- Place new docs in appropriate `/docs` subfolder
- Update category README.md files
- Update main `/docs/README.md` index
- Follow naming convention: `UPPERCASE_WITH_UNDERSCORES.md`

---

**Last Updated**: 2025-11-26  
**Version**: 1.0.0 (Post-Reorganization)
