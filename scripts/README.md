# Icon Generation Scripts

This directory contains scripts to generate app icons for Social Connect.

## Prerequisites

- Node.js (v14 or higher)
- npm

## Setup

```bash
cd scripts
npm install
```

## Usage

### Generate All Icons

This will generate all required icons for iOS and Android from your source icon:

```bash
npm run generate-icons
```

### Source Icon Requirements

- **Location**: `assets/branding/app_icon_source.png`
- **Size**: 1024x1024 pixels
- **Format**: PNG with transparency (if needed)
- **Design**: Ensure important content is in the center 80% (safe zone for adaptive icons)

## What Gets Generated

### iOS Icons
All icon sizes will be generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
- 20x20 (@1x, @2x, @3x)
- 29x29 (@1x, @2x, @3x)
- 40x40 (@1x, @2x, @3x)
- 60x60 (@2x, @3x)
- 76x76 (@1x, @2x)
- 83.5x83.5 (@2x)
- 1024x1024 (App Store)

### Android Icons
Icons will be generated for all densities in `android/app/src/main/res/`:
- mipmap-mdpi: 48x48
- mipmap-hdpi: 72x72
- mipmap-xhdpi: 96x96
- mipmap-xxhdpi: 144x144
- mipmap-xxxhdpi: 192x192

### Play Store Icon
A 512x512 icon will be generated in `assets/branding/play_store_icon.png`

## After Generating Icons

1. Review the generated icons to ensure they look good at all sizes
2. Run `flutter clean && flutter pub get`
3. Rebuild your app: `flutter run`
4. Test on both Android and iOS devices

## Troubleshooting

### Error: sharp is not installed
```bash
cd scripts
npm install sharp
```

### Error: Source icon not found
1. Create the directory: `mkdir -p ../assets/branding`
2. Place your 1024x1024 icon at `../assets/branding/app_icon_source.png`
3. Run the script again

### Icons not showing up
- Clean and rebuild: `flutter clean && flutter pub get && flutter run`
- Restart your IDE
- For Android: Uninstall and reinstall the app

## Design Tips

- Keep the design simple and recognizable at small sizes
- Use high contrast colors
- Avoid fine details that won't be visible at 20x20
- Test at the smallest size (20x20) to ensure clarity
- For Android adaptive icons, keep important content in the center 80%

## Files

- `generate_icons.js` - Main icon generation script
- `package.json` - Node.js dependencies
- `README.md` - This file
