# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KnitAndCalc is a SwiftUI iOS app for knitting calculations, available in Norwegian. The app provides three calculators:

1. **Garnkalkulator (Yarn Calculator)**: Calculate required skeins when substituting yarn with different yardage
2. **Strikkekalkulator (Stitch Calculator)**: Generate even distribution instructions for increases/decreases across a row
3. **Linjal (Ruler)**: On-screen ruler supporting centimeters and inches

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project KnitAndCalc.xcodeproj -scheme KnitAndCalc -configuration Debug build

# Run tests
xcodebuild test -project KnitAndCalc.xcodeproj -scheme KnitAndCalc -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build folder
xcodebuild clean -project KnitAndCalc.xcodeproj -scheme KnitAndCalc
```

### Opening in Xcode
```bash
open KnitAndCalc.xcodeproj
```

## Architecture

### Core Views
- **ContentView.swift**: Main navigation view with list of three calculators
- **YarnCalculatorView.swift**: Yarn substitution calculator with unit selection (meters/yards)
- **StitchCalculatorView.swift**: Increase/decrease distribution calculator with checkbox tracking
- **RulerView.swift**: Custom UIScrollView-based ruler with fixed axis marks and unit switching

### Key Technical Patterns

**StitchCalculatorView** implements a Bresenham-like distribution algorithm (originally from `strikke-logic.js`) for evenly distributing stitch changes across a row. The algorithm:
- Divides stitches into segments (changes + 1 for flat knitting, changes for circular)
- Uses error accumulation to distribute remainder stitches as evenly as possible
- Groups identical segments in the instruction output for readability

**RulerView** uses a custom `OffsetTrackingScrollView` (UIViewRepresentable) wrapping UIScrollView to:
- Track scroll offset for synchronized ruler marks on fixed axes
- Render marks only for visible range (performance optimization)
- Handle unit conversion between cm (64px/unit, 10 divisions) and inches (163px/unit, 16 divisions)
- Show/hide reset button based on scroll distance threshold

### Legacy Web Calculators
The `calculators/` directory contains legacy HTML/JavaScript implementations:
- `strikke_kalkulator/`: Original stitch calculator logic
- `garn_kalkulator/`: Original yarn calculator logic

These are reference implementations; the Swift views in `KnitAndCalc/` are the active codebase.

## Language and Localization

All UI text and calculations are in Norwegian. Key terms:
- "Øke" = increase, "Felle" = decrease
- "Masker" = stitches, "Pinnen" = needle
- "Nøster" = skeins, "Løpelengde" = yardage
- "Beregn" = calculate

## Testing Structure

- **KnitAndCalcTests/**: Unit tests
- **KnitAndCalcUITests/**: UI tests with launch tests

## Project Configuration

- **Target**: KnitAndCalc
- **Build Configurations**: Debug, Release
- **Platform**: iOS (SwiftUI)
- **Entitlements**: KnitAndCalc.entitlements