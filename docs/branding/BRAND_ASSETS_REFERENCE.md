# Social Connect - Brand Assets Quick Reference

## 🎨 Primary Brand Colors

```
Electric Blue:  #4F46E5  RGB(79, 70, 229)
Purple:         #9333EA  RGB(147, 51, 234)
Pink:           #EC4899  RGB(236, 72, 153)
```

## 📐 Icon Specifications

### Source Requirements
- **Format**: PNG
- **Size**: 1024x1024 pixels
- **Location**: `assets/branding/app_icon_source.png`
- **Safe Zone**: Keep important elements within center 80%

### Generated Outputs

#### iOS (15 files)
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png      (20px)
├── Icon-App-20x20@2x.png      (40px)
├── Icon-App-20x20@3x.png      (60px)
├── Icon-App-29x29@1x.png      (29px)
├── Icon-App-29x29@2x.png      (58px)
├── Icon-App-29x29@3x.png      (87px)
├── Icon-App-40x40@1x.png      (40px)
├── Icon-App-40x40@2x.png      (80px)
├── Icon-App-40x40@3x.png      (120px)
├── Icon-App-60x60@2x.png      (120px)
├── Icon-App-60x60@3x.png      (180px)
├── Icon-App-76x76@1x.png      (76px)
├── Icon-App-76x76@2x.png      (152px)
├── Icon-App-83.5x83.5@2x.png  (167px)
└── Icon-App-1024x1024@1x.png  (1024px)
```

#### Android (5 densities)
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      (48px)
├── mipmap-hdpi/ic_launcher.png      (72px)
├── mipmap-xhdpi/ic_launcher.png     (96px)
├── mipmap-xxhdpi/ic_launcher.png    (144px)
└── mipmap-xxxhdpi/ic_launcher.png   (192px)
```

#### Store Icons
```
assets/branding/
└── play_store_icon.png (512x512)

ios/Runner/Assets.xcassets/AppIcon.appiconset/
└── Icon-App-1024x1024@1x.png (App Store)
```

## 🚀 Quick Commands

### Generate Icons
```bash
cd scripts
npm install        # First time only
npm run generate-icons
```

### Clean Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 App Names

### Current Name
```
social_connect_app
```

### Display Name (Recommended)
```
Social Connect
```

### Update Locations
- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/Info.plist`
- **Flutter**: `pubspec.yaml` (name field)

## 🎯 Design Principles

### Style Keywords
- Minimalist
- Modern
- Vibrant
- Premium
- Friendly

### Visual Elements
- Gradient backgrounds
- Rounded corners (8-16px)
- Subtle shadows
- Clean typography
- Bold colors

## 📦 File Structure

```
connected/
├── assets/
│   └── branding/
│       ├── app_icon_source.png     (Your 1024x1024 source)
│       └── play_store_icon.png     (Generated 512x512)
├── scripts/
│   ├── generate_icons.js
│   ├── package.json
│   └── README.md
├── ios/Runner/Assets.xcassets/AppIcon.appiconset/
│   ├── Contents.json
│   └── Icon-App-*.png              (15 files)
├── android/app/src/main/res/
│   ├── mipmap-mdpi/
│   ├── mipmap-hdpi/
│   ├── mipmap-xhdpi/
│   ├── mipmap-xxhdpi/
│   └── mipmap-xxxhdpi/
├── BRAND_GUIDE.md                  (Full guidelines)
├── BRANDING_SETUP.md               (Implementation guide)
└── BRAND_ASSETS_REFERENCE.md       (This file)
```

## ✅ Implementation Checklist

- [ ] Choose/download preferred icon design from artifacts
- [ ] Save as `assets/branding/app_icon_source.png` (1024x1024)
- [ ] Run `cd scripts && npm install`
- [ ] Run `npm run generate-icons`
- [ ] Verify all icons generated correctly
- [ ] Update app display name (optional)
- [ ] Run `flutter clean && flutter pub get`
- [ ] Test on Android device
- [ ] Test on iOS device (if available)
- [ ] Take app screenshots for store
- [ ] Create feature graphics
- [ ] Update README with new branding

## 🔗 Documentation Links

- **Full Brand Guide**: [BRAND_GUIDE.md](BRAND_GUIDE.md)
- **Setup Instructions**: [BRANDING_SETUP.md](BRANDING_SETUP.md)
- **Icon Scripts**: [scripts/README.md](scripts/README.md)

---

**Quick Start**: Download icon → Save to `assets/branding/app_icon_source.png` → Run `scripts/npm run generate-icons` → Rebuild app ✨
