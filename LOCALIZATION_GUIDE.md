# KnitAndCalc Localization Guide

## ✅ What Has Been Done

I've set up bilingual support (Norwegian/English) for your app with the following:

### 1. Created Localization Files

**Created:**
- `KnitAndCalc/en.lproj/Localizable.strings` - English translations
- `KnitAndCalc/nb.lproj/Localizable.strings` - Norwegian (Bokmål) translations

### 2. Updated Files

**Already Updated:**
- ✅ `ContentView.swift` - "Avansert" and "Garnlager telling"
- ✅ `YarnStockCounterView.swift` - "Start telling" button

## 🔧 Xcode Configuration Required

To enable language switching in your app, you need to configure Xcode:

### Step 1: Add Localizations to Project
1. Open `KnitAndCalc.xcodeproj` in Xcode
2. Select the project in the navigator (top blue icon)
3. Select the `KnitAndCalc` target
4. Go to the "Info" tab
5. Under "Localizations" click the "+" button
6. Add "Norwegian Bokmål (nb)"
7. Add "English (en)" if not already there
8. When prompted, select the `Localizable.strings` files to localize

### Step 2: Add Localization Files to Project
1. In Xcode, right-click on the `KnitAndCalc` folder
2. Select "Add Files to KnitAndCalc..."
3. Navigate to and select both folders:
   - `en.lproj`
   - `nb.lproj`
4. Make sure "Copy items if needed" is checked
5. Click "Add"

### Step 3: Configure File Localizations
1. Select `Localizable.strings` in the Project Navigator
2. In the File Inspector (right panel), check the localizations:
   - ✅ English
   - ✅ Norwegian Bokmål

## 📱 Testing Localizations

### Change Language in Simulator
1. Open Settings app in simulator
2. Go to General → Language & Region
3. Add or change "iPhone Language" to:
   - "English" for English
   - "Norsk Bokmål" for Norwegian

### Change Language in Xcode Scheme
1. Product menu → Scheme → Edit Scheme
2. Select "Run" in left panel
3. Go to "Options" tab
4. Under "App Language" select:
   - "Norwegian (nb)" for Norwegian
   - "English (en)" for English

## 🔤 Translation Keys Reference

All Norwegian terms you requested have been translated:

| Norwegian | English | Key |
|-----------|---------|-----|
| Garnlager telling | Yarn Stock Count | `menu.yarn_stock_count` |
| Avansert | Advanced | `menu.advanced` |
| Start telling | Start Count | `yarn_stock.start_count` |
| Alle | All | `yarn_stock.all` |
| garn | yarn | `yarn_stock.yarn` |
| total vekt | total weight | `yarn_stock.total_weight` |
| Administrer lokasjoner | Manage Locations | `yarn_stock.manage_locations` |
| Vis ikke sjekket garn | Show Unchecked Yarn | `yarn_stock.show_unchecked` |
| Lokasjoner | Locations | `location.locations` |
| Ny lokasjon | New Location | `location.new_location` |
| Velg lokasjon for telling | Select location for count | `location.select_for_count` |

## 📝 How to Use Localized Strings in Code

Replace hardcoded Norwegian strings with:

```swift
// Before
Text("Avansert")

// After
Text(NSLocalizedString("menu.advanced", comment: ""))
```

## ✏️ Files That Still Need Updating

The following files contain hardcoded Norwegian strings that should be updated to use `NSLocalizedString`:

1. **YarnStockCounterView.swift** - Remaining strings
2. **YarnCountingSessionView.swift** - All counting session strings
3. **LocationManagementView.swift** - All location management strings

Search for these patterns and replace:
- `Text("Alle")` → `Text(NSLocalizedString("yarn_stock.all", comment: ""))`
- `"Uten lokasjon"` → `NSLocalizedString("yarn_stock.no_location", comment: "")`
- etc.

## 🌍 App Behavior

Once configured:
- App will automatically use device language
- Supported: Norwegian (Bokmål) and English
- Falls back to Norwegian if language not supported
- Users can change language in device settings

## 📊 Build Status

After adding files to Xcode project, rebuild:
```bash
xcodebuild -project KnitAndCalc.xcodeproj -scheme KnitAndCalc clean build
```

---

**Generated:** 2025-10-20
**Status:** Localization files created, Xcode configuration required
