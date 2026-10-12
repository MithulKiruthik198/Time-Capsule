import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_capsule/core/constants/app_strings.dart';
import 'package:time_capsule/core/services/subscription_service.dart';
import 'package:time_capsule/features/capture/add_memory_modal.dart';
import 'package:time_capsule/features/capture/capture_view.dart';
import 'package:time_capsule/features/documentary/cinematic_reel_view.dart';
import 'package:time_capsule/features/documentary/hardcover_album_view.dart';
import 'package:time_capsule/features/home/home_view.dart';
import 'package:time_capsule/models/capsule.dart';
import 'package:time_capsule/models/day_group.dart';
import 'package:time_capsule/models/memory.dart';
import 'package:time_capsule/repositories/app_repository_manager.dart';
import 'package:time_capsule/widgets/journey_timeline_tile.dart';
import 'package:time_capsule/widgets/pro_upgrade_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SubscriptionService Tests', () {
    test('Initial free tier limits enforced', () async {
      final sub = SubscriptionService();
      await sub.init();
      // Ensure starting as free
      await sub.setPro(false);

      expect(sub.isPro, isFalse);
      expect(sub.canCreateCapsule(0), isTrue);
      expect(sub.canCreateCapsule(1), isFalse); // Max 1 capsule on free tier
      expect(sub.canUseAudio, isFalse);
      expect(sub.canUseVideo, isFalse);
    });

    test('Daily media limit tracks quota on free tier', () async {
      final sub = SubscriptionService();
      await sub.init();
      await sub.setPro(false);

      final today = DateTime.now();
      expect(await sub.canAddMediaToday(date: today), isTrue);
      expect(await sub.getRemainingFreeMediaToday(date: today), equals(2));

      await sub.recordMediaAddedToday(date: today);
      expect(await sub.getMediaCountToday(date: today), equals(1));
      expect(await sub.getRemainingFreeMediaToday(date: today), equals(1));
      expect(await sub.canAddMediaToday(date: today), isTrue);

      await sub.recordMediaAddedToday(date: today);
      expect(await sub.getMediaCountToday(date: today), equals(2));
      expect(await sub.getRemainingFreeMediaToday(date: today), equals(0));
      expect(await sub.canAddMediaToday(date: today), isFalse); // Reached daily limit of 2
    });

    test('Upgrading to Pro unlocks unlimited access', () async {
      final sub = SubscriptionService();
      await sub.init();
      await sub.setPro(true);

      expect(sub.isPro, isTrue);
      expect(sub.canCreateCapsule(10), isTrue); // Unlimited capsules
      expect(await sub.canAddMediaToday(), isTrue);
      expect(sub.canUseAudio, isTrue);
      expect(sub.canUseVideo, isTrue);
      expect(sub.canUseCinematicReel, isTrue);
    });
  });

  group('Mystery Shielding in JourneyTimelineTile Tests', () {
    final testMemory = Memory(
      id: 'mem-1',
      capsuleId: 'cap-1',
      userId: 'user-1',
      title: 'Secret Proposal Moment',
      content: 'This was the most magical evening of my entire life.',
      imageUrl: 'https://images.unsplash.com/photo-example.jpg',
      isImportant: true,
      capturedAt: DateTime.utc(2026, 9, 9, 19, 48),
      createdAt: DateTime.utc(2026, 9, 9, 19, 48),
    );

    final dayGroup = DayGroup(
      date: DateTime(2026, 9, 9),
      memories: [testMemory],
    );

    testWidgets('Locked Capsule strictly conceals photos and secret notes behind mystery seal',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyTimelineTile(
              dayGroup: dayGroup,
              isCapsuleLocked: true, // Sealed in vault!
            ),
          ),
        ),
      );
      await tester.pump();

      // Mystery seal title is shown
      expect(find.text(AppStrings.mysteryKeyMomentTitle), findsOneWidget);
      expect(find.text('Photo sealed in time'), findsOneWidget);

      // Secret note content and title MUST NOT be rendered! Zero leak!
      expect(find.text('Secret Proposal Moment'), findsNothing);
      expect(find.text('This was the most magical evening of my entire life.'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Unlocked Capsule reveals memories for documentary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyTimelineTile(
              dayGroup: dayGroup,
              isCapsuleLocked: false, // Unlocked
            ),
          ),
        ),
      );
      await tester.pump();

      // Content is now revealed for unboxed documentary
      expect(find.text('Secret Proposal Moment'), findsOneWidget);
      expect(find.text('This was the most magical evening of my entire life.'), findsOneWidget);
    });
  });

  group('Option A & Option B Documentary Views Tests', () {
    final capsule = Capsule(
      id: 'cap-100',
      userId: 'user-1',
      title: 'Year of Reflection',
      createdAt: DateTime.utc(2025, 1, 1),
      unlockAt: DateTime.utc(2026, 1, 1),
      status: CapsuleStatus.opened,
    );

    final memories = [
      Memory(
        id: 'm1',
        capsuleId: 'cap-100',
        userId: 'user-1',
        title: 'Morning Flight',
        content: 'Leaving for the adventure.',
        capturedAt: DateTime.utc(2025, 5, 10, 8, 30),
        createdAt: DateTime.utc(2025, 5, 10, 8, 30),
      ),
      Memory(
        id: 'm2',
        capsuleId: 'cap-100',
        userId: 'user-1',
        title: 'Mountain Top',
        content: 'Looking at the golden clouds.',
        capturedAt: DateTime.utc(2025, 7, 15, 18, 0),
        createdAt: DateTime.utc(2025, 7, 15, 18, 0),
      ),
    ];

    testWidgets('CinematicReelView renders slides and progress indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CinematicReelView(capsule: capsule, memories: memories),
        ),
      );
      await tester.pump();

      expect(find.text('${AppStrings.appName} REEL'), findsOneWidget);
      expect(find.text('Morning Flight'), findsOneWidget);
      expect(find.text('“Leaving for the adventure.”'), findsOneWidget);
    });

    testWidgets('HardcoverAlbumView renders album cover and navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HardcoverAlbumView(capsule: capsule, memories: memories),
        ),
      );
      await tester.pump();

      expect(find.text('ARCHIVAL ALBUM'), findsOneWidget);
      expect(find.text('OFFICIAL ARCHIVAL EDITION'), findsOneWidget);
      expect(find.text('OPEN FIRST PAGE'), findsOneWidget);
    });

    testWidgets('ProUpgradeModal displays luxury paywall options', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProUpgradeModal(reasonMessage: 'Test Upgrade Gating'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.proModalTitle), findsOneWidget);
      expect(find.text('Test Upgrade Gating'), findsOneWidget);
      expect(find.text('Unlimited Time Capsules'), findsOneWidget);
      expect(find.text('Daily Media Memories'), findsOneWidget);
    });
  });

  group('HomeView & CaptureView Redesign Tests', () {
    testWidgets('HomeView renders Active Vault Tab without leaking raw photo tiles', (tester) async {
      final repo = AppRepositoryManager().capsuleRepository;
      final capsule = await repo.createCapsule(
        title: 'Future Vault 2027',
        unlockAtUtc: DateTime.now().toUtc().add(const Duration(days: 365)),
      );
      await repo.addMemory(
        capsuleId: capsule.id,
        title: 'Secret Proposal',
        content: 'Unforgettable night under stars',
        imageUrl: 'https://example.com/proposal.jpg',
        isImportant: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeView(onNavigateToCapture: () {}),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // App Title is rendered without overflow
      expect(find.text(AppStrings.appName), findsOneWidget);

      // Verify Active Time Vault Card is shown
      expect(find.text('ACTIVE TIME VAULT'), findsOneWidget);
      expect(find.text('🔒 Confidential: Tap to view countdown to open capsule'), findsOneWidget);

      // Verify ZERO raw photo or memory detail cards leak on home screen
      expect(find.text('Secret Proposal'), findsNothing);
      expect(find.text('Unforgettable night under stars'), findsNothing);
      expect(find.byType(JourneyTimelineTile), findsNothing);
    });

    testWidgets('CaptureView renders vertical tactile option cards when active capsule exists', (tester) async {
      final repo = AppRepositoryManager().capsuleRepository;
      await repo.createCapsule(
        title: 'Vault 2027',
        unlockAtUtc: DateTime.now().toUtc().add(const Duration(days: 365)),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CaptureView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Check vertical cards exist
      expect(find.text('Photo Memory'), findsOneWidget);
      expect(find.text('Voice Transmission'), findsOneWidget);
      expect(find.text('Video Moment'), findsOneWidget);
      expect(find.text('Key Moment'), findsOneWidget);
      expect(find.text('Inspire My Reflection'), findsOneWidget);
    });

    testWidgets('AddMemoryModal renders vertical tactile option cards', (tester) async {
      final capsule = Capsule(
        id: 'test-cap-1',
        userId: 'user-1',
        title: 'Year of Wonder',
        createdAt: DateTime.now().toUtc(),
        unlockAt: DateTime.now().toUtc().add(const Duration(days: 365)),
        status: CapsuleStatus.locked,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddMemoryModal(capsule: capsule),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Add Photo Memory'), findsOneWidget);
      expect(find.text('Voice Transmission'), findsOneWidget);
      expect(find.text('Video Moment'), findsOneWidget);
      expect(find.text('Key Moment'), findsOneWidget);
      expect(find.text('Inspire My Reflection'), findsOneWidget);
    });
  });
}
