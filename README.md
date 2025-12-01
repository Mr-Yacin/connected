# Social Connect App

A modern social networking Flutter application with real-time chat, story sharing, and profile discovery features. Built with Firebase backend and clean architecture principles.

## 🌟 Features

- **Phone Authentication**: Secure OTP-based authentication
- **User Profiles**: Rich user profiles with images, personal info, and anonymous sharing links
- **Real-time Chat**: One-on-one messaging with text and voice notes
- **Stories**: Share temporary stories (24-hour expiration) with your connections
- **Discovery**: Find and connect with users based on filters (country, age, gender)
- **Shuffle Mode**: Random profile discovery with swipe interactions
- **Moderation**: Report and block users, content moderation system
- **Multi-language**: Arabic (RTL) and English support
- **Dark Mode**: Beautiful dark theme enabled by default

## 🏗️ Architecture

This project follows **Feature-First Architecture** with **Clean Architecture** principles:

```
lib/
├── core/                    # Shared components
│   ├── constants/          # App constants
│   ├── theme/              # Themes and colors
│   ├── utils/              # Utility functions
│   └── widgets/            # Shared widgets
├── features/                # Feature modules
│   ├── auth/               # Authentication
│   ├── profile/            # User profiles
│   ├── chat/               # Messaging
│   ├── discovery/          # User discovery
│   ├── stories/            # Story sharing
│   ├── settings/           # App settings
│   └── moderation/         # Content moderation
└── services/                # Shared services
```

Each feature follows Clean Architecture layers:
- **Data**: Models, repositories, data sources
- **Domain**: Entities, use cases, business logic
- **Presentation**: Screens, widgets, state management (Riverpod)

## 📋 Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)
- Firebase account
- Android Studio / Xcode (for mobile development)
- Node.js (for development tools)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd connected
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

Follow the detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md):

1. Create a Firebase project
2. Enable Authentication (Phone), Firestore, and Storage
3. Run FlutterFire CLI configuration:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Deploy security rules:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only storage:rules
   ```

### 4. Run the App

```bash
flutter run
```

## 🛠️ Development Tools

### Build Scripts (`/scripts`)
Build-time automation scripts for icon generation and asset processing.

```bash
cd scripts
npm install
npm run generate-icons  # Generate app icons for all platforms
```

See [scripts/README.md](scripts/README.md) for details.

### Admin Tools (`/tool`)
⚠️ **Admin only** - Contains sensitive credentials (gitignored)

Development and admin utilities for database operations:
- Mock data uploaders
- Database migration scripts
- Deployment automation

See [SCRIPTS_AND_TOOLS_GUIDE.md](SCRIPTS_AND_TOOLS_GUIDE.md) for detailed information.

**Security Note**: The `/tool` folder is gitignored as it contains Firebase service account keys. Never commit these credentials.

## 📦 Key Dependencies

### Production
- `firebase_core`: ^3.8.1 - Firebase initialization
- `firebase_auth`: ^5.3.4 - Authentication
- `cloud_firestore`: ^5.5.2 - Database
- `firebase_storage`: ^12.3.8 - File storage
- `flutter_riverpod`: ^2.6.1 - State management
- `go_router`: ^14.6.2 - Navigation
- `cached_network_image`: ^3.3.1 - Image caching
- `image_picker`: ^1.0.7 - Image selection
- `record`: ^5.1.2 - Audio recording
- `audioplayers`: ^6.0.0 - Audio playback

### Development
- `faker`: ^2.2.0 - Mock data generation
- `mockito`: ^5.4.4 - Testing mocks
- `build_runner`: ^2.4.14 - Code generation
- `riverpod_generator`: ^2.6.3 - Riverpod code generation

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Code Analysis
```bash
flutter analyze
```

## 📱 Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Linux
- ✅ macOS
- ✅ Windows

## 🔒 Security

- Firebase Security Rules are enforced for Firestore and Storage
- User data is protected with authentication-based access control
- Anonymous profile links use UUID for secure sharing
- Content moderation system for reporting inappropriate content

## 🌍 Localization

The app supports:
- **Arabic** (ar) - RTL layout, default language
- **English** (en) - LTR layout

## 🎨 Theming

- **Dark Mode**: Enabled by default
- **Light Mode**: Available in settings
- **RTL Support**: Full right-to-left layout for Arabic
- **Material Design 3**: Modern UI components

## 📚 Documentation

### Core Documentation
- [Project Summary](docs/project-management/PROJECT_SUMMARY.md) - High-level project overview
- [Project Organization](docs/project-management/PROJECT_ORGANIZATION.md) - Project structure and workflow
- [Brand Guide](docs/branding/BRAND_GUIDE.md) - Complete brand identity guidelines
- [Changelog](docs/changelog/CHANGELOG.md) - Version history and release notes

### Setup & Configuration
- [Firebase Setup Guide](docs/guides/FIREBASE_SETUP.md) - Firebase configuration guide
- [Setup Complete Guide](docs/guides/SETUP_COMPLETE.md) - Initial setup checklist
- [Phone Auth Troubleshooting](docs/guides/PHONE_AUTH_TROUBLESHOOTING.md) - Phone auth debugging
- [Migration Checklist](docs/guides/MIGRATION_CHECKLIST.md) - Migration guide
- [Chat Optimization Guide](docs/guides/CHAT_OPTIMIZATION_GUIDE.md) - Chat performance optimization
- [Composite Indexes Guide](docs/guides/COMPOSITE_INDEXES_GUIDE.md) - Firestore indexes setup
- [FCM Complete Guide](docs/guides/FCM_COMPLETE_GUIDE.md) - Firebase Cloud Messaging guide

### Deployment & Operations
- [Deployment Instructions](docs/deployment/DEPLOYMENT_INSTRUCTIONS.md) - Production deployment guide
- [Deployment Ready](docs/deployment/DEPLOYMENT_READY.md) - Deployment checklist
- [Week 3 Deployment Guide](docs/deployment/DEPLOYMENT_GUIDE_WEEK3.md) - Week 3 deployment
- [Implementation Complete](docs/deployment/IMPLEMENTATION_COMPLETE.md) - Implementation summary

### Development History
- [Week 1 Fixes](docs/fixes/WEEK1_FIXES_COMPLETE.md) - Week 1 critical fixes
- [Fix 4 Complete](docs/fixes/FIX4_COMPLETE.md) - Fix 4 pagination implementation
- [Week 3 Complete](docs/changelog/WEEK3_COMPLETE.md) - Week 3 milestone

### Technical References
- [API Documentation](docs/references/API.md) - API reference
- [Project Structure](docs/references/PROJECT_STRUCTURE.md) - Detailed architecture
- [Performance Comparison](docs/references/PERFORMANCE_COMPARISON.md) - Performance metrics
- [Security Rules Optimization](docs/references/SECURITY_RULES_OPTIMIZATION.md) - Security guidelines
- [Pagination Features](docs/references/PAGINATION_FEATURES.md) - Pagination documentation

### Branding & Design
- [Brand Guide](docs/branding/BRAND_GUIDE.md) - Complete brand guidelines
- [Icon Design Guide](docs/branding/ICON_DESIGN_GUIDE.md) - App icon specifications
- [Brand Assets Reference](docs/branding/BRAND_ASSETS_REFERENCE.md) - Asset usage guide
- [Arabic Brand Proposal](docs/branding/ARABIC_BRAND_PROPOSAL.md) - Arabic branding

### Planning & Roadmap
- [Scaling Roadmap](docs/project-management/SCALING_ROADMAP.md) - Future scaling and growth
- [Implementation Checklist](docs/project-management/IMPLEMENTATION_CHECKLIST.md) - Task tracking

**📖 [Full Documentation Index](docs/README.md)** - Browse all documentation organized by category

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is private and not licensed for public use.

## 🐛 Troubleshooting

### Phone Authentication Issues
See [Phone Auth Troubleshooting Guide](docs/guides/PHONE_AUTH_TROUBLESHOOTING.md)

### Firebase Permission Errors
1. Check Firestore security rules in `firestore.rules`
2. Verify user is authenticated
3. Ensure user document exists in `users` collection

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

## 📞 Support

For issues and questions:
1. Check existing documentation
2. Review Firebase Console logs
3. Check Flutter and Firebase SDK versions
4. Create an issue with detailed error logs

## 🗺️ Roadmap

- [x] ~~Push notifications~~ ✅ Implemented
- [ ] Group chat support
- [ ] Video calls
- [ ] Advanced profile verification
- [ ] AI-powered content moderation
- [ ] Analytics dashboard

---

**Built with ❤️ using Flutter and Firebase**
