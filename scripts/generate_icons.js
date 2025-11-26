#!/usr/bin/env node

/**
 * Icon Generator for Social Connect App
 * 
 * This script generates app icons in all required sizes for both iOS and Android
 * from a source 1024x1024 icon image.
 * 
 * Prerequisites:
 * - Node.js
 * - sharp package (npm install sharp)
 * - Source icon: assets/branding/app_icon_source.png (1024x1024)
 * 
 * Usage:
 *   node generate_icons.js
 */

const fs = require('fs');
const path = require('path');

// Check if sharp is available
let sharp;
try {
    sharp = require('sharp');
} catch (error) {
    console.error('❌ Error: sharp is not installed.');
    console.error('Please run: npm install sharp');
    process.exit(1);
}

// Paths
const ROOT_DIR = path.join(__dirname, '..');
const ASSETS_DIR = path.join(ROOT_DIR, 'assets', 'branding');
const SOURCE_ICON = path.join(ASSETS_DIR, 'app_icon_source.png');

const IOS_DIR = path.join(ROOT_DIR, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
const ANDROID_RES_DIR = path.join(ROOT_DIR, 'android', 'app', 'src', 'main', 'res');

// iOS icon sizes (in pixels)
const IOS_SIZES = [
    { size: 20, scale: 1, filename: 'Icon-App-20x20@1x.png' },
    { size: 20, scale: 2, filename: 'Icon-App-20x20@2x.png' },
    { size: 20, scale: 3, filename: 'Icon-App-20x20@3x.png' },
    { size: 29, scale: 1, filename: 'Icon-App-29x29@1x.png' },
    { size: 29, scale: 2, filename: 'Icon-App-29x29@2x.png' },
    { size: 29, scale: 3, filename: 'Icon-App-29x29@3x.png' },
    { size: 40, scale: 1, filename: 'Icon-App-40x40@1x.png' },
    { size: 40, scale: 2, filename: 'Icon-App-40x40@2x.png' },
    { size: 40, scale: 3, filename: 'Icon-App-40x40@3x.png' },
    { size: 60, scale: 2, filename: 'Icon-App-60x60@2x.png' },
    { size: 60, scale: 3, filename: 'Icon-App-60x60@3x.png' },
    { size: 76, scale: 1, filename: 'Icon-App-76x76@1x.png' },
    { size: 76, scale: 2, filename: 'Icon-App-76x76@2x.png' },
    { size: 83.5, scale: 2, filename: 'Icon-App-83.5x83.5@2x.png' },
    { size: 1024, scale: 1, filename: 'Icon-App-1024x1024@1x.png' },
];

// Android icon sizes
const ANDROID_SIZES = [
    { density: 'mipmap-mdpi', size: 48 },
    { density: 'mipmap-hdpi', size: 72 },
    { density: 'mipmap-xhdpi', size: 96 },
    { density: 'mipmap-xxhdpi', size: 144 },
    { density: 'mipmap-xxxhdpi', size: 192 },
];

// Ensure directory exists
function ensureDir(dir) {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
}

// Generate iOS icons
async function generateiOSIcons() {
    console.log('📱 Generating iOS icons...\n');

    ensureDir(IOS_DIR);

    for (const { size, scale, filename } of IOS_SIZES) {
        const actualSize = Math.round(size * scale);
        const outputPath = path.join(IOS_DIR, filename);

        try {
            await sharp(SOURCE_ICON)
                .resize(actualSize, actualSize, {
                    fit: 'contain',
                    background: { r: 0, g: 0, b: 0, alpha: 0 }
                })
                .png()
                .toFile(outputPath);

            console.log(`  ✅ ${filename} (${actualSize}x${actualSize})`);
        } catch (error) {
            console.error(`  ❌ Failed to generate ${filename}:`, error.message);
        }
    }

    console.log('\n✨ iOS icons generated!\n');
}

// Generate Android icons
async function generateAndroidIcons() {
    console.log('🤖 Generating Android icons...\n');

    for (const { density, size } of ANDROID_SIZES) {
        const dir = path.join(ANDROID_RES_DIR, density);
        ensureDir(dir);

        const outputPath = path.join(dir, 'ic_launcher.png');

        try {
            await sharp(SOURCE_ICON)
                .resize(size, size, {
                    fit: 'contain',
                    background: { r: 0, g: 0, b: 0, alpha: 0 }
                })
                .png()
                .toFile(outputPath);

            console.log(`  ✅ ${density}/ic_launcher.png (${size}x${size})`);
        } catch (error) {
            console.error(`  ❌ Failed to generate ${density}:`, error.message);
        }
    }

    console.log('\n✨ Android icons generated!\n');
}

// Generate Play Store icon
async function generatePlayStoreIcon() {
    console.log('🎮 Generating Play Store icon...\n');

    const outputPath = path.join(ASSETS_DIR, 'play_store_icon.png');

    try {
        await sharp(SOURCE_ICON)
            .resize(512, 512, {
                fit: 'contain',
                background: { r: 0, g: 0, b: 0, alpha: 0 }
            })
            .png()
            .toFile(outputPath);

        console.log(`  ✅ play_store_icon.png (512x512)`);
    } catch (error) {
        console.error(`  ❌ Failed to generate Play Store icon:`, error.message);
    }

    console.log('\n✨ Play Store icon generated!\n');
}

// Main function
async function main() {
    console.log('🎨 Social Connect - Icon Generator\n');
    console.log('═══════════════════════════════════════\n');

    // Check if source icon exists
    if (!fs.existsSync(SOURCE_ICON)) {
        console.error('❌ Error: Source icon not found!');
        console.error(`Expected location: ${SOURCE_ICON}`);
        console.error('\nPlease place your 1024x1024 app icon at:');
        console.error('  assets/branding/app_icon_source.png\n');
        process.exit(1);
    }

    try {
        // Ensure assets directory exists
        ensureDir(ASSETS_DIR);

        // Generate all icons
        await generateiOSIcons();
        await generateAndroidIcons();
        await generatePlayStoreIcon();

        console.log('═══════════════════════════════════════\n');
        console.log('✅ All icons generated successfully!\n');
        console.log('Next steps:');
        console.log('  1. Review the generated icons');
        console.log('  2. Run flutter clean && flutter pub get');
        console.log('  3. Rebuild your app to see the new icons\n');

    } catch (error) {
        console.error('\n❌ An error occurred:', error.message);
        process.exit(1);
    }
}

// Run the script
main();
