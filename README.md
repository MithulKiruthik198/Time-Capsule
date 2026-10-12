# ⏳ Time Capsule — A Personal Time Machine for Your Life

> **“I am sending a message through time.”**  
> Capture today. Lock it in time. Meet yourself later.

---

## 🌟 Product Philosophy

Time Capsule is built around a singular, emotionally resonant loop:
1. **Capture**: Capture a memory containing a photo, a personal reflection, and a title.
2. **Lock**: Choose when this moment should return (Tomorrow, 1 Month, 6 Months, 1 Year, 5 Years, or Custom Date).
3. **Wait**: The memory is sealed in a time vault with strict zero-preview shielding.
4. **Notification**: The time machine signals you when the moment arrives.
5. **Revisit**: A cinematic 9-stage unboxing experience takes you back to your past self.
6. **Emotion**: Reflect on personal growth and generate an archival keepsake card.

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.44+ & Dart 3.12+
- Chrome, Edge, or an Android/iOS device/emulator

### Running the App
```bash
# Run on Chrome
flutter run -d chrome

# Or run on Microsoft Edge
flutter run -d edge

# Or run on a connected Android/iOS device
flutter run
```

### Running the Automated Test Suite
```bash
flutter test
```
All unit tests covering leap-year calendar calculations, month clamping, UTC normalization, domain models, and repository lifecycle operations are fully verified.

---

## 🏛️ Architecture & Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_strings.dart       # Emotional microcopy & product statements
│   │   └── app_colors.dart        # Midnight Black (#08090D), Cosmic Violet (#8B7CFF)
│   ├── services/
│   │   ├── supabase_service.dart  # Supabase Client & authentication
│   │   ├── notification_service.dart # Local scheduled notifications
│   │   ├── storage_service.dart   # Image compression & storage handling
│   │   └── analytics_service.dart # Privacy-first event tracker
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart         # Premium dark-first theme
│   └── utils/
│       └── date_utils.dart        # Leap-year calculations, UTC conversions, countdowns
├── features/
│   ├── auth/                      # Email/password authentication + Local Vault entry
│   ├── capture/                   # Sub-30s capture form & "Memory Locked" transition
│   ├── home/                      # Hero Orbital Portal centerpiece & timeline sections
│   ├── memory/                    # Locked security screen, 9-stage reveal & Keepsake Card
│   ├── onboarding/                # 3-step minimal cinematic onboarding
│   ├── settings/                  # Supabase credentials modal, notification test
│   └── timeline/                  # Chronological timeline with Waiting/Ready/Opened filters
├── models/
│   └── memory.dart                # Strongly typed domain model with status evaluation
└── repositories/
    ├── memory_repository.dart     # Repository contract
    ├── supabase_memory_repository.dart # Cloud implementation with Row Level Security
    ├── local_memory_repository.dart    # Offline persistent vault using SharedPreferences
    └── app_repository_manager.dart     # Seamless switcher between Local and Cloud
```

---

## 🔒 Security & Supabase Cloud Integration

Time Capsule is built with strict privacy guarantees. User memories can never be viewed by other users.

### Supabase Schema Setup
1. Create a project in [Supabase](https://supabase.com).
2. Go to the **SQL Editor** and execute the provided [`supabase_schema.sql`](./supabase_schema.sql).
3. This creates:
   - The `memories` table with status constraints.
   - Row Level Security (RLS) policies ensuring users can only read, write, update, and delete their own memories.
   - The private storage bucket `memory-images` with folder-scoped user policies.
4. In Time Capsule, open **Settings** → tap **Connect Supabase Cloud** → enter your Project URL and Anon Public Key.

### Resilient Hybrid Dual-Vault
- If Supabase credentials are not entered, the app defaults to the **Local Private Vault**, providing 100% functionality offline on-device with zero friction.

---

## 🎨 Key Features

### 1. Hero Orbital Time Portal
Displays the exact days or countdown to your next memory with an ambient glowing orbital ring.

### 2. Rapid Capture Flow (< 30 seconds)
- Add a photo from Camera or Gallery.
- Write a personal reflection to your future self.
- Select preset time horizons (Tomorrow, 1 Month, 6 Months, 1 Year, 5 Years) or custom future date & time.
- Tap **Lock Memory** to initiate the capsule sealing animation.

### 3. Strict Zero-Preview Vault
Tapping a locked memory displays:
- Large glowing lock glyph.
- *"Not yet. You asked me to keep this moment safe."*
- Countdown to unlock date.
- Content and photos remain strictly sealed.

### 4. 9-Stage Cinematic Reveal
When the unlock date arrives:
1. Deep cosmic dark background.
2. Glowing time indicator.
3. *"You asked me to remember this."*
4. Creation date and *"One year ago…"*.
5. Capsule unlock burst.
6. Smooth photo fade & scale.
7. Memory title.
8. Full narrative reflection.
9. Interactive keepsake actions.

### 5. Archival Keepsake Share Card
Generates a card formatted like an archival artifact:
- Relative origin header (*"ONE YEAR AGO"*).
- Original capture timestamp.
- User reflection excerpt.
- Attribution: *"— Future Me"*.
- App branding: *"TIME CAPSULE • Your life. Replayed."*
- Image capture & share via system share sheet.

### 6. "On This Day"
Highlights past unlocked memories captured on today's calendar date in previous years.
