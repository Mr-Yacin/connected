# 🛠️ Scripts & Tools Guide

This guide explains the difference between `/scripts` and `/tool` folders and their proper usage.

## 📁 Folder Overview

### `/scripts` - Build & Development Scripts ✅ **Committed to Git**

**Purpose**: Build-time automation scripts that are **safe to share** and version control.

**Contents**:
- Icon generation scripts
- Build automation
- Asset processing
- CI/CD scripts

**Git Status**: ✅ **Committed** (part of the codebase)

```
scripts/
├── generate_icons.js      # Icon generation automation
├── package.json          # Script dependencies
├── package-lock.json     # Dependency lock file
└── README.md             # Usage documentation
```

---

### `/tool` - Admin & Development Tools 🔒 **Gitignored**

**Purpose**: Admin tools and utilities that contain or require **sensitive credentials**.

**Contents**:
- Firebase admin tools
- Data migration scripts
- Mock data uploaders
- Service account keys (sensitive!)

**Git Status**: 🔒 **Gitignored** (contains sensitive data)

```
tool/
├── .gitignore                        # Tool-specific gitignore
├── README.md                         # Tool documentation
├── serviceAccountKey.json            # 🔒 SENSITIVE - Firebase credentials
├── upload-mock-data.js              # Mock data uploader
├── mock_data_uploader.dart          # Dart mock data tool
├── migrate_chat_unread_counts.js    # Database migration
├── deploy_indexes.sh/.bat           # Firestore index deployment
├── deploy_security_rules.sh/.bat    # Security rules deployment
├── package.json                     # Tool dependencies
└── package-lock.json                # Dependency lock file
```

## 🎯 Key Differences

| Aspect | `/scripts` | `/tool` |
|--------|------------|---------|
| **Purpose** | Build automation | Admin & development utilities |
| **Git Status** | ✅ Committed | 🔒 Gitignored |
| **Sensitive Data** | ❌ No | ✅ Yes (service account keys) |
| **Used When** | Build time | Development/maintenance |
| **Team Access** | All developers | Admin/DevOps only |
| **Examples** | Icon generation, asset processing | Data migration, mock data upload |

## 📖 Detailed Breakdown

### 🔧 Scripts Folder - Build Automation

#### Purpose
Scripts that are part of the development workflow and can be safely committed to version control.

#### Characteristics
- ✅ No sensitive data
- ✅ Safe to share publicly
- ✅ Part of standard build process
- ✅ Version controlled
- ✅ Documented for team use

#### Current Scripts

**1. Icon Generation** (`generate_icons.js`)
```bash
cd scripts
npm install
npm run generate-icons
```

**Purpose**: Generates app icons for iOS and Android from a source image.

**Use Case**: 
- Updating app icons
- Creating platform-specific icon sizes
- Automated icon generation in CI/CD

**Safe to commit**: ✅ Yes (no sensitive data)

---

### 🔒 Tool Folder - Admin Utilities

#### Purpose
Administrative and development tools that require sensitive credentials or are used for special operations.

#### Characteristics
- 🔒 Contains sensitive data (service account keys)
- 🔒 Gitignored for security
- 🔒 Admin/DevOps access only
- 🔒 Not for regular development
- 🔒 Requires Firebase admin permissions

#### Current Tools

**1. Mock Data Uploader** (`upload-mock-data.js`)
```bash
cd tool
npm install
node upload-mock-data.js
```

**Purpose**: Upload test user profiles to Firestore for development.

**Requires**: 
- serviceAccountKey.json
- Firebase Admin SDK permissions

**Use Case**: Development testing, demo data

---

**2. Chat Migration** (`migrate_chat_unread_counts.js`)
```bash
cd tool
npm install firebase-admin
node migrate_chat_unread_counts.js
```

**Purpose**: Migrate existing chat documents to include unread counts.

**Requires**: 
- serviceAccountKey.json
- Production database access (USE WITH CAUTION)

**Use Case**: Database schema updates

---

**3. Firestore Index Deployment** (`deploy_indexes.sh/.bat`)
```bash
cd tool
./deploy_indexes.sh    # Linux/Mac
# or
deploy_indexes.bat     # Windows
```

**Purpose**: Deploy Firestore composite indexes.

**Requires**: Firebase CLI authentication

**Use Case**: Index deployment automation

---

**4. Security Rules Deployment** (`deploy_security_rules.sh/.bat`)
```bash
cd tool
./deploy_security_rules.sh    # Linux/Mac
# or
deploy_security_rules.bat     # Windows
```

**Purpose**: Deploy Firestore and Storage security rules.

**Requires**: Firebase CLI authentication

**Use Case**: Security rules deployment automation

---

**5. Dart Mock Data Uploader** (`mock_data_uploader.dart`)
```bash
cd tool
dart run mock_data_uploader.dart
```

**Purpose**: Alternative mock data uploader in Dart.

**Requires**: Firebase configuration

**Use Case**: Development testing (Dart version)

## 🔐 Security Best Practices

### For `/tool` Folder

1. **Never Commit Service Account Keys**
   - ✅ Already gitignored in `/tool/.gitignore`
   - ✅ Also ignored in root `.gitignore`
   - ⚠️ Double-check before committing

2. **Rotate Keys Regularly**
   - Generate new service account keys quarterly
   - Delete old keys from Firebase Console
   - Update local `serviceAccountKey.json`

3. **Limit Access**
   - Only admin/DevOps should have access
   - Use least-privilege principle
   - Document who has access

4. **Audit Usage**
   - Log all admin tool usage
   - Review Firebase Admin SDK usage
   - Monitor for unauthorized access

### For `/scripts` Folder

1. **No Sensitive Data**
   - Never add API keys or secrets
   - Use environment variables if needed
   - Document any external dependencies

2. **Version Control**
   - Commit all scripts to git
   - Document changes in git commits
   - Keep README.md updated

## 📋 When to Use Each Folder

### Use `/scripts` when:
- ✅ Building assets (icons, images)
- ✅ Automating build processes
- ✅ Running pre-commit checks
- ✅ Generating code
- ✅ Processing assets for deployment
- ✅ CI/CD pipeline tasks

### Use `/tool` when:
- 🔒 Uploading data to Firebase
- 🔒 Migrating database schemas
- 🔒 Running admin operations
- 🔒 Deploying infrastructure
- 🔒 Testing with mock data
- 🔒 Database maintenance

## 🚀 Adding New Scripts/Tools

### Adding to `/scripts`

1. **Create the script**
   ```bash
   cd scripts
   touch new_script.js
   ```

2. **Add to package.json**
   ```json
   {
     "scripts": {
       "new-script": "node new_script.js"
     }
   }
   ```

3. **Document in README**
   Update `scripts/README.md` with usage instructions

4. **Commit to git**
   ```bash
   git add scripts/
   git commit -m "feat: add new build script"
   ```

### Adding to `/tool`

1. **Create the tool**
   ```bash
   cd tool
   touch new_tool.js
   ```

2. **Add to package.json** (if needed)
   ```json
   {
     "scripts": {
       "new-tool": "node new_tool.js"
     }
   }
   ```

3. **Document in README**
   Update `tool/README.md` with:
   - Purpose
   - Requirements
   - Security considerations
   - Usage instructions

4. **DO NOT commit sensitive files**
   ```bash
   # Only commit the script, not credentials
   git add tool/new_tool.js tool/README.md
   git commit -m "feat: add new admin tool"
   ```

## 📝 Documentation Requirements

### Scripts (`/scripts/README.md`)
- ✅ Purpose of each script
- ✅ Prerequisites
- ✅ Installation steps
- ✅ Usage examples
- ✅ Troubleshooting

### Tools (`/tool/README.md`)
- ✅ Purpose of each tool
- ✅ Security requirements
- ✅ Service account setup
- ✅ Permissions needed
- ✅ Rollback procedures
- ✅ Monitoring/logging

## 🔍 Current Status

### `/scripts` Folder
```
✅ Status: Clean & Organized
✅ Git: Committed
✅ Dependencies: Documented
✅ README: Up to date
✅ Security: Safe
```

### `/tool` Folder
```
✅ Status: Functional
🔒 Git: Properly gitignored
⚠️ Security: Contains sensitive keys
✅ README: Documented
⚠️ Access: Admin only
```

## ⚠️ Important Warnings

### For `/tool` Folder

1. **🚨 NEVER COMMIT serviceAccountKey.json**
   - This file grants full admin access to Firebase
   - Already gitignored, but double-check!

2. **⚠️ USE MIGRATION SCRIPTS WITH CAUTION**
   - Always backup production data first
   - Test on staging environment
   - Schedule during low-traffic periods

3. **🔐 ROTATE CREDENTIALS REGULARLY**
   - Service account keys should be rotated quarterly
   - Delete old keys from Firebase Console

4. **📊 MONITOR USAGE**
   - Log all admin tool executions
   - Review Firebase Admin SDK usage in console

## 🎓 Best Practices Summary

### `/scripts` - Build Scripts
- ✅ Commit to version control
- ✅ Document thoroughly
- ✅ No sensitive data
- ✅ Part of CI/CD pipeline
- ✅ Accessible to all developers

### `/tool` - Admin Tools
- 🔒 Never commit sensitive files
- 🔒 Require explicit permissions
- 🔒 Document security requirements
- 🔒 Audit usage regularly
- 🔒 Admin/DevOps access only

## 📞 Support

### For Scripts Issues
- Check `scripts/README.md`
- Review script comments
- Ensure dependencies installed (`npm install`)

### For Tool Issues
- Check `tool/README.md`
- Verify service account key is present
- Confirm Firebase permissions
- Contact admin/DevOps team

---

**Summary**: 
- **`/scripts`** = Safe build automation ✅ (committed)
- **`/tool`** = Sensitive admin utilities 🔒 (gitignored)

**Remember**: If it needs credentials, it goes in `/tool`. If it's build automation, it goes in `/scripts`.
