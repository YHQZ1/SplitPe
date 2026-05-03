# SplitPe

A lightweight Flutter application for splitting bills and generating UPI payment links instantly. Built for the Indian market where UPI is the default payment method.

---

## Overview

SplitPe removes the friction from splitting bills among friends. Instead of manually calculating who owes what and then reminding people to pay, SplitPe calculates each person's share and generates a ready-to-tap UPI deep link for every participant. One tap opens their UPI app with the amount pre-filled.

No backend. No account required. No payment processing. Just math and links.

---

## Features

- Equal and unequal bill splitting
- Instant UPI deep link generation compatible with GPay, PhonePe, and Paytm
- Share payment links directly via WhatsApp or any messaging app
- Works completely offline
- Supports both Android and iOS

---

## How It Works

1. Enter the total bill amount and your UPI ID
2. Add the names of people splitting the bill
3. Choose equal split or assign custom amounts per person
4. SplitPe generates a UPI payment link for each person
5. Share the links via WhatsApp or copy them individually

The generated links follow the standard UPI deep link format:

```
upi://pay?pa=yourname@okaxis&pn=YourName&am=300.00&cu=INR
```

When a recipient taps the link, their default UPI app opens with your UPI ID and the amount already filled in.

---

## Tech Stack

- Flutter
- Dart
- No external dependencies for V1

---

## Getting Started

### Prerequisites

- Flutter SDK 3.0 or above
- Xcode 14+ (for iOS builds)
- Android Studio or VS Code with Flutter extension

### Installation

```bash
git clone https://github.com/yourname/splitpe.git
cd splitpe
flutter pub get
flutter run
```

### Running on iOS (TestFlight)

```bash
flutter build ios
```

Open `ios/Runner.xcworkspace` in Xcode, select your target device, and archive for TestFlight distribution.

### Running on Android

```bash
flutter build apk
```

---

## Project Structure

```
lib/
├── main.dart               # App entry point
├── screens/
│   ├── home_screen.dart    # Bill amount + UPI ID input
│   ├── split_screen.dart   # Add people + assign amounts
│   └── result_screen.dart  # Generated payment links
├── models/
│   └── participant.dart    # Participant data model
└── utils/
    └── upi_helper.dart     # UPI deep link generator
```

---

## Roadmap

- V1: Core split + UPI link generation
- V2: Split history saved locally
- V3: Payment reminders via WhatsApp
- V4: Scan bill photo with OCR to auto-detect amount

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
