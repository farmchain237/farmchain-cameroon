name: iOS TestFlight Deploy

on:
  push:
    branches: [main]
    paths:
      - "mobile/**"
      - ".github/workflows/ios-testflight.yml"

jobs:
  build-and-deploy:
    runs-on: macos-14
    defaults:
      run:
        working-directory: mobile

    steps:
      - uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.24.0"
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run analyzer
        run: flutter analyze --no-fatal-infos

      - name: Set up Ruby (for Fastlane)
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true
          working-directory: mobile/ios

      - name: Install CocoaPods
        run: |
          cd ios
          pod install --repo-update

      # Certificates/profiles pulled via Fastlane match + App Store Connect API key.
      # Secrets must be added under Settings > Secrets and variables > Actions.
      - name: Decode App Store Connect API key
        env:
          ASC_API_KEY_BASE64: ${{ secrets.ASC_API_KEY_BASE64 }}
        run: |
          mkdir -p ios/fastlane
          echo "$ASC_API_KEY_BASE64" | base64 --decode > ios/fastlane/AuthKey.p8

      - name: Build Flutter iOS release (no codesign, Fastlane signs)
        run: flutter build ios --release --no-codesign

      - name: Fastlane build + upload to TestFlight
        env:
          APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          MATCH_GIT_URL: ${{ secrets.MATCH_GIT_URL }}
        run: |
          cd ios
          bundle exec fastlane beta

      - name: Clean up signing key
        if: always()
        run: rm -f mobile/ios/fastlane/AuthKey.p8
