# HCPP Demo - Makefile
# Two Rendering Worlds, One Screen: HC vs HCPP composition modes
#
# Usage:
#   make run-hcpp      # Run with Hybrid Composition++ enabled (default)
#   make run-hc        # Run with classic Hybrid Composition
#   make run-hcpp-profile  # Profile mode with HCPP
#   make run-hc-profile    # Profile mode with HC
#   make build         # Build debug APK (HCPP mode)
#   make clean         # Clean build artifacts

.PHONY: all run-hcpp run-hc run-hcpp-profile run-hc-profile build clean analyze help

# Default target
all: help

# Run with HCPP enabled (default)
run-hcpp:
	@echo "🚀 Running with HCPP (Hybrid Composition++) enabled..."
	@echo "   Check logcat for: 'Using HCPP platform view rendering strategy'"
	flutter run --dart-define=COMPOSITION_MODE=HCPP -PenableHcpp=true

# Run with classic Hybrid Composition
run-hc:
	@echo "🚀 Running with classic Hybrid Composition..."
	@echo "   HCPP is disabled - using traditional platform view composition"
	flutter run --dart-define=COMPOSITION_MODE=HC -PenableHcpp=false

# Profile mode with HCPP
run-hcpp-profile:
	@echo "📊 Running PROFILE mode with HCPP enabled..."
	@echo "   Use Flutter DevTools to analyze performance"
	flutter run --profile --dart-define=COMPOSITION_MODE=HCPP -PenableHcpp=true

# Profile mode with classic HC
run-hc-profile:
	@echo "📊 Running PROFILE mode with classic HC..."
	@echo "   Use Flutter DevTools to analyze performance"
	flutter run --profile --dart-define=COMPOSITION_MODE=HC -PenableHcpp=false

# Build debug APK (defaults to HCPP mode)
build:
	@echo "🔨 Building debug APK with HCPP enabled..."
	flutter build apk --debug -PenableHcpp=true

# Build APK in both modes
build-both:
	@echo "🔨 Building debug APKs in both modes..."
	@mkdir -p build/outputs
	flutter build apk --debug -PenableHcpp=true
	@mv build/app/outputs/flutter-apk/app-debug.apk build/outputs/app-hcpp-debug.apk 2>/dev/null || true
	flutter build apk --debug -PenableHcpp=false
	@mv build/app/outputs/flutter-apk/app-debug.apk build/outputs/app-hc-debug.apk 2>/dev/null || true
	@echo "✅ APKs built:"
	@echo "   - build/outputs/app-hcpp-debug.apk"
	@echo "   - build/outputs/app-hc-debug.apk"

# Run static analysis
analyze:
	flutter analyze

# Clean build artifacts
clean:
	flutter clean
	rm -rf build/outputs

# Get dependencies
deps:
	flutter pub get

# Help
help:
	@echo ""
	@echo "HCPP Demo - FlutterCon Talk Demo App"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make run-hcpp         Run with HCPP enabled (recommended)"
	@echo "  make run-hc           Run with classic Hybrid Composition"
	@echo "  make run-hcpp-profile Profile mode with HCPP"
	@echo "  make run-hc-profile   Profile mode with classic HC"
	@echo "  make build            Build debug APK (HCPP mode)"
	@echo "  make build-both       Build APKs in both modes"
	@echo "  make analyze          Run flutter analyze"
	@echo "  make clean            Clean build artifacts"
	@echo "  make deps             Get dependencies"
	@echo ""
	@echo "Requirements:"
	@echo "  - Flutter 3.29+ (stable) or 3.49+ (beta/master)"
	@echo "  - Android API 34+ device with Vulkan support"
	@echo ""
	@echo "To verify HCPP is active, check logcat for:"
	@echo "  'Using HCPP platform view rendering strategy'"
	@echo ""
