import 'fx_master_restaurant_studio.dart';

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (_) {}
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FxWorkspaceSwitcher(),
    ),
  );
  unawaited(AppStatsService.ensureInitialized());
  unawaited(SyncService.start());
}


/// Top-level switcher keeps the Restaurant Studio and the original TV Photo
/// Manager available from one app. The two existing workspaces remain intact.
class FxWorkspaceSwitcher extends StatefulWidget {
  const FxWorkspaceSwitcher({super.key});

  @override
  State<FxWorkspaceSwitcher> createState() => _FxWorkspaceSwitcherState();
}

class _FxWorkspaceSwitcherState extends State<FxWorkspaceSwitcher> {
  bool _showTvPhotoManager = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Scaffold(
          backgroundColor: C.bg,
          body: Column(
            children: <Widget>[
              Container(
                height: 56,
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
                decoration: const BoxDecoration(
                  color: C.card2,
                  border: Border(bottom: BorderSide(color: C.border)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.grid_view_rounded, color: C.light, size: 19),
                    SizedBox(width: compact ? 6 : 9),
                    Text(
                      compact ? 'FINAL FX' : 'FINAL FX WORKSPACES',
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: compact ? .5 : 1.1,
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    _workspaceButton(
                      label: compact ? 'Studio' : 'Restaurant Studio',
                      icon: Icons.storefront_rounded,
                      tvManager: false,
                      compact: compact,
                    ),
                    SizedBox(width: compact ? 5 : 8),
                    _workspaceButton(
                      label: compact ? 'TV Photos' : 'TV Photo Manager',
                      icon: Icons.photo_library_rounded,
                      tvManager: true,
                      compact: compact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _showTvPhotoManager
                    ? const TVPhotoManagerApp()
                    : const FxRestaurantStudioScreen(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _workspaceButton({
    required String label,
    required IconData icon,
    required bool tvManager,
    required bool compact,
  }) {
    final selected = _showTvPhotoManager == tvManager;
    return Material(
      color: selected ? C.primary.withValues(alpha: .18) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _showTvPhotoManager = tvManager),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? C.primary.withValues(alpha: .48) : C.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: compact ? 13 : 15,
                  color: selected ? C.light : Colors.white60),
              SizedBox(width: compact ? 4 : 7),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: compact ? 9 : 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class C {
  static const bg = Color(0xFF07090E);
  static const side = Color(0xFF0C0F15);
  static const card = Color(0xFF11141B);
  static const card2 = Color(0xFF151923);
  static const border = Color(0x12FFFFFF);
  static const primary = Color(0xFF7656F8);
  static const light = Color(0xFFA996FF);
  static const green = Color(0xFF3DDB8B);
  static const red = Color(0xFFE05252);
  static const amber = Color(0xFFFFB84D);
  static const cyan = Color(0xFF39BDF8);
}

class Paths {
  static final db = FirebaseFirestore.instance;
  static final media = db.collection('tv_media');
  static final playlists = db.collection('playlists');
  static final devices = db.collection('tv_devices');
  static final schedules = db.collection('schedules');
  static final stats = db.doc('app_stats/current');
  static final sync = db.doc('tv_sync/current');
  static final settings = db.doc('system/config');
  static final storage = FirebaseStorage.instance.ref().child('photos');
}

enum MediaType { image, video }

class MediaItem {
  MediaItem({
    required this.id,
    required this.name,
    required this.url,
    required this.path,
    required this.type,
    required this.version,
    required this.order,
    required this.duration,
  });
  final String id;
  String name;
  final String url;
  final String path;
  final MediaType type;
  int version;
  int order;
  int duration;
  bool get video => type == MediaType.video;

  factory MediaItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return MediaItem(
      id: d.id,
      name: x['name']?.toString() ?? d.id,
      url: x['downloadUrl']?.toString() ?? '',
      path: x['storagePath']?.toString() ?? '',
      type: x['type']?.toString() == 'video'
          ? MediaType.video
          : MediaType.image,
      version: (x['version'] as num?)?.toInt() ?? 1,
      order: (x['order'] as num?)?.toInt() ?? 0,
      duration: (x['durationSeconds'] as num?)?.toInt() ?? 5,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'downloadUrl': url,
    'storagePath': path,
    'type': video ? 'video' : 'image',
    'version': version,
    'order': order,
    'durationSeconds': duration,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class PlaylistItem {
  PlaylistItem({
    required this.id,
    required this.name,
    required this.mediaIds,
    required this.deviceIds,
    required this.enabled,
  });
  final String id;
  String name;
  List<String> mediaIds;
  List<String> deviceIds;
  bool enabled;

  factory PlaylistItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return PlaylistItem(
      id: d.id,
      name: x['name']?.toString() ?? d.id,
      mediaIds: List<String>.from(x['mediaIds'] ?? const []),
      deviceIds: List<String>.from(x['deviceIds'] ?? const []),
      enabled: x['enabled'] != false,
    );
  }
}

class DeviceItem {
  DeviceItem({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    required this.playlistId,
    this.lastSeen,
  });
  final String id;
  String name;
  String code;
  String status;
  String playlistId;
  DateTime? lastSeen;

  factory DeviceItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return DeviceItem(
      id: d.id,
      name: x['name']?.toString() ?? d.id,
      code: x['pairingCode']?.toString() ?? '',
      status: x['status']?.toString() ?? 'offline',
      playlistId: x['playlistId']?.toString() ?? '',
      lastSeen: x['lastSeen'] is Timestamp
          ? (x['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }
}

class ScheduleItem {
  ScheduleItem({
    required this.id,
    required this.name,
    required this.playlistId,
    required this.deviceIds,
    required this.startDate,
    required this.endDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.weekdays,
    required this.enabled,
  });
  final String id;
  String name;
  String playlistId;
  List<String> deviceIds;
  DateTime startDate;
  DateTime endDate;
  int startMinutes;
  int endMinutes;
  List<int> weekdays;
  bool enabled;

  factory ScheduleItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final x = d.data() ?? {};
    return ScheduleItem(
      id: d.id,
      name: x['name']?.toString() ?? d.id,
      playlistId: x['playlistId']?.toString() ?? '',
      deviceIds: List<String>.from(x['deviceIds'] ?? const []),
      startDate: x['startDate'] is Timestamp
          ? (x['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: x['endDate'] is Timestamp
          ? (x['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      startMinutes: (x['startMinutes'] as num?)?.toInt() ?? 540,
      endMinutes: (x['endMinutes'] as num?)?.toInt() ?? 1320,
      weekdays: List<int>.from(x['weekdays'] ?? const []),
      enabled: x['enabled'] != false,
    );
  }
}

class AppStatsService {
  static final media = ValueNotifier<int>(0);
  static final images = ValueNotifier<int>(0);
  static final videos = ValueNotifier<int>(0);
  static final playlists = ValueNotifier<int>(0);
  static final tvs = ValueNotifier<int>(0);
  static final schedules = ValueNotifier<int>(0);
  static final revision = ValueNotifier<int>(0);

  static void apply(Map<String, dynamic> x) {
    media.value = (x['mediaCount'] as num?)?.toInt() ?? 0;
    images.value = (x['imageCount'] as num?)?.toInt() ?? 0;
    videos.value = (x['videoCount'] as num?)?.toInt() ?? 0;
    playlists.value = (x['playlistCount'] as num?)?.toInt() ?? 0;
    tvs.value = (x['tvCount'] as num?)?.toInt() ?? 0;
    schedules.value = (x['scheduleCount'] as num?)?.toInt() ?? 0;
  }

  static Future<void> ensureInitialized() async {
    try {
      final s = await Paths.stats.get();
      if (s.exists) {
        apply(s.data() ?? {});
        await SyncService.load();
        return;
      }
      final r = await Future.wait([
        Paths.media.count().get(),
        Paths.media.where('type', isEqualTo: 'image').count().get(),
        Paths.media.where('type', isEqualTo: 'video').count().get(),
        Paths.playlists.count().get(),
        Paths.devices.count().get(),
        Paths.schedules.count().get(),
      ]);
      final x = {
        'mediaCount': r[0].count ?? 0,
        'imageCount': r[1].count ?? 0,
        'videoCount': r[2].count ?? 0,
        'playlistCount': r[3].count ?? 0,
        'tvCount': r[4].count ?? 0,
        'scheduleCount': r[5].count ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await Paths.stats.set(x, SetOptions(merge: true));
      apply(x);
      await SyncService.load();
    } catch (_) {}
  }

  static Future<void> change({
    int mediaDelta = 0,
    int imageDelta = 0,
    int videoDelta = 0,
    int playlistDelta = 0,
    int tvDelta = 0,
    int scheduleDelta = 0,
  }) async {
    await Paths.stats.set({
      'mediaCount': FieldValue.increment(mediaDelta),
      'imageCount': FieldValue.increment(imageDelta),
      'videoCount': FieldValue.increment(videoDelta),
      'playlistCount': FieldValue.increment(playlistDelta),
      'tvCount': FieldValue.increment(tvDelta),
      'scheduleCount': FieldValue.increment(scheduleDelta),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    media.value = max(0, media.value + mediaDelta);
    images.value = max(0, images.value + imageDelta);
    videos.value = max(0, videos.value + videoDelta);
    playlists.value = max(0, playlists.value + playlistDelta);
    tvs.value = max(0, tvs.value + tvDelta);
    schedules.value = max(0, schedules.value + scheduleDelta);
  }
}

class SyncService {
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;

  static Future<void> start() async {
    await sub?.cancel();
    sub = Paths.sync.snapshots().listen((s) {
      revisionValue(s.data());
    }, onError: (_) {});
  }

  static void revisionValue(Map<String, dynamic>? x) {
    AppStatsService.revision.value = (x?['revision'] as num?)?.toInt() ?? 0;
  }

  static Future<void> load() async {
    try {
      final s = await Paths.sync.get();
      revisionValue(s.data());
    } catch (_) {}
  }

  static Future<void> bump(String reason) async {
    final next = AppStatsService.revision.value + 1;
    AppStatsService.revision.value = next;
    await Paths.sync.set({
      'revision': FieldValue.increment(1),
      'reason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

String id() => DateTime.now().microsecondsSinceEpoch.toString();

String pairCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random();
  return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
}

MediaType typeFor(String ext) =>
    const {'mp4', 'webm', 'mov', 'm4v'}.contains(ext.toLowerCase())
    ? MediaType.video
    : MediaType.image;

String mime(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'mp4':
      return 'video/mp4';
    case 'webm':
      return 'video/webm';
    case 'mov':
      return 'video/quicktime';
    case 'm4v':
      return 'video/x-m4v';
    default:
      return 'application/octet-stream';
  }
}

String dur(int s) {
  if (s <= 0) return '--:--';
  final m = s ~/ 60;
  final sec = s % 60;
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String dateText(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String timeText(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  final ap = h >= 12 ? 'PM' : 'AM';
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh:${m.toString().padLeft(2, '0')} $ap';
}

Future<bool> confirmBox(
  BuildContext context, {
  required String title,
  required String text,
  required String action,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: C.card2,
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

// ============================================================================
// APP
// ============================================================================

class TVPhotoManagerApp extends StatelessWidget {
  const TVPhotoManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TV Photo Manager',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.primary,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: C.card2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.primary),
          ),
        ),
      ),
      home: const AdminShell(),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  late final PageController pageController;

  final pages = const [
    DashboardScreen(),
    MediaScreen(),
    PlaylistsScreen(),
    DevicesScreen(),
    ScheduleScreen(),
    SettingsScreen(),
  ];
  final labels = const [
    'Dashboard',
    'Photos & Videos',
    'Playlists',
    'TV Devices',
    'Schedule',
    'Settings',
  ];
  final icons = const [
    Icons.space_dashboard_rounded,
    Icons.perm_media_rounded,
    Icons.playlist_play_rounded,
    Icons.tv_rounded,
    Icons.calendar_month_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _selectPage(int page) {
    setState(() => index = page);
    if (pageController.hasClients) {
      pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (viewportWidth < 760) {
      return _buildMobileShell(viewportWidth);
    }

    return Scaffold(
      backgroundColor: C.bg,
      body: Row(
        children: [
          Container(
            width: 250,
            color: C.side,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8E72FF), Color(0xFF5C3DF5)],
                            ),
                          ),
                          child: const Icon(Icons.tv_rounded),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'TV PHOTO\nMANAGER',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WORKSPACE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: .30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(labels.length, (i) => _desktopNavItem(i)),
                  const Spacer(),
                  _revisionFooter(compact: false),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (value) {
                if (mounted) setState(() => index = value);
              },
              children: pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileShell(double viewportWidth) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.card2,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'TV Photo Manager',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        leading: Builder(
          builder: (buttonContext) => IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(buttonContext).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        width: min(320.0, viewportWidth * .86),
        backgroundColor: C.side,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E72FF), Color(0xFF5C3DF5)],
                        ),
                      ),
                      child: const Icon(Icons.tv_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'TV PHOTO MANAGER',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: .40),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: labels.length,
                  itemBuilder: (drawerContext, i) => _mobileNavItem(drawerContext, i),
                ),
              ),
              _revisionFooter(compact: true),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: PageView(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (value) {
            if (mounted) setState(() => index = value);
          },
          children: pages,
        ),
      ),
    );
  }

  Widget _desktopNavItem(int i) {
    final selected = i == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? C.primary.withValues(alpha: .18) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectPage(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(color: C.light.withValues(alpha: .20))
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Icon(icons[i], size: 20,
                    color: selected ? C.light : Colors.white.withValues(alpha: .44)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white.withValues(alpha: .58),
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(color: C.light, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileNavItem(BuildContext drawerContext, int i) {
    final selected = i == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? C.primary.withValues(alpha: .20) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(drawerContext).pop();
            _selectPage(i);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? C.primary.withValues(alpha: .55) : Colors.transparent,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(icons[i], size: 20,
                    color: selected ? C.light : Colors.white.withValues(alpha: .62)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white.withValues(alpha: .78),
                    ),
                  ),
                ),
                if (selected) const Icon(Icons.check_rounded, color: C.light, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _revisionFooter({required bool compact}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: ValueListenableBuilder<int>(
        valueListenable: AppStatsService.revision,
        builder: (_, value, __) => Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: C.border),
          ),
          child: Row(
            children: <Widget>[
              const _Dot(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SYSTEM ONLINE\nRevision $value',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: .60),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: C.green),
  );
}

Widget header(String title, String subtitle, Widget? trailing) {
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: .45),
              ),
            ),
          ],
        ),
      ),
      if (trailing != null) trailing,
    ],
  );
}

Widget cardPanel({
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: C.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: .34),
            ),
          ),
        ],
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

ButtonStyle outline({bool danger = false}) => OutlinedButton.styleFrom(
  foregroundColor: danger ? const Color(0xFFFF8D8D) : Colors.white70,
  side: BorderSide(
    color: danger
        ? C.red.withValues(alpha: .45)
        : Colors.white.withValues(alpha: .12),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

// ============================================================================
// DASHBOARD
// ============================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool refreshing = false;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 760) {
      return _buildMobileDashboard();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 34, 42, 34),
      child: Column(
        children: [
          header(
            'Dashboard',
            'Control your digital screens from one workspace.',
            OutlinedButton.icon(
              onPressed: refreshing ? null : _refresh,
              style: outline(),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _stat(
                'TOTAL MEDIA',
                AppStatsService.media,
                Icons.perm_media_outlined,
                C.light,
              ),
              const SizedBox(width: 16),
              _stat(
                'PLAYLISTS',
                AppStatsService.playlists,
                Icons.playlist_play_rounded,
                C.cyan,
              ),
              const SizedBox(width: 16),
              _stat(
                'TV DEVICES',
                AppStatsService.tvs,
                Icons.tv_outlined,
                C.green,
              ),
              const SizedBox(width: 16),
              _stat(
                'SCHEDULED',
                AppStatsService.schedules,
                Icons.schedule_rounded,
                C.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: cardPanel(
                    title: 'Content overview',
                    subtitle: 'Real-time counters from the Admin data model.',
                    child: SizedBox(
                      height: 235,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 46,
                              color: C.light,
                            ),
                            const SizedBox(height: 15),
                            ValueListenableBuilder<int>(
                              valueListenable: AppStatsService.media,
                              builder: (_, total, __) => Text(
                                '$total media files ready',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<int>(
                              valueListenable: AppStatsService.images,
                              builder: (_, images, __) =>
                                  ValueListenableBuilder<int>(
                                    valueListenable: AppStatsService.videos,
                                    builder: (_, videos, __) => Text(
                                      '$images images • $videos videos',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: .40,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: cardPanel(
                    title: 'System status',
                    subtitle: 'Current backend state.',
                    child: Column(
                      children: [
                        _status('Firebase', 'Connected'),
                        _status('Storage', 'Online'),
                        ValueListenableBuilder<int>(
                          valueListenable: AppStatsService.revision,
                          builder: (_, value, __) =>
                              _status('Sync revision', '$value'),
                        ),
                        _status('Playback', 'Local cache ready'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          cardPanel(
            title: 'Cost & performance protection',
            subtitle:
                'Unchanged media is not re-downloaded by the TV architecture.',
            child: Row(
              children: const [
                _Feature(
                  Icons.flash_on_rounded,
                  'FAST UPLOAD',
                  'Parallel media uploads',
                ),
                _Feature(
                  Icons.cached_rounded,
                  'CACHE FIRST',
                  'Local metadata cache',
                ),
                _Feature(
                  Icons.sync_rounded,
                  'CHANGE ONLY',
                  'Revision-driven sync',
                ),
                _Feature(
                  Icons.movie_filter_outlined,
                  'LAZY VIDEO',
                  'Preview on demand',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          header(
            'Dashboard',
            'Control your digital screens from one workspace.',
            IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: refreshing ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: <Widget>[
              _mobileStat('TOTAL MEDIA', AppStatsService.media, Icons.perm_media_outlined, C.light),
              _mobileStat('PLAYLISTS', AppStatsService.playlists, Icons.playlist_play_rounded, C.cyan),
              _mobileStat('TV DEVICES', AppStatsService.tvs, Icons.tv_outlined, C.green),
              _mobileStat('SCHEDULED', AppStatsService.schedules, Icons.schedule_rounded, C.amber),
            ],
          ),
          const SizedBox(height: 16),
          cardPanel(
            title: 'Content overview',
            subtitle: 'Real-time counters from the Admin data model.',
            child: SizedBox(
              height: 142,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(Icons.auto_awesome_rounded, size: 38, color: C.light),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<int>(
                      valueListenable: AppStatsService.media,
                      builder: (_, total, __) => Text(
                        '$total media files ready',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ValueListenableBuilder<int>(
                      valueListenable: AppStatsService.images,
                      builder: (_, images, __) => ValueListenableBuilder<int>(
                        valueListenable: AppStatsService.videos,
                        builder: (_, videos, __) => Text(
                          '$images images • $videos videos',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .55)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          cardPanel(
            title: 'System status',
            subtitle: 'Current backend state.',
            child: Column(
              children: <Widget>[
                _status('Firebase', 'Connected'),
                _status('Storage', 'Online'),
                ValueListenableBuilder<int>(
                  valueListenable: AppStatsService.revision,
                  builder: (_, value, __) => _status('Sync revision', '$value'),
                ),
                _status('Playback', 'Local cache ready'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          cardPanel(
            title: 'Cost & performance protection',
            subtitle: 'Cache-first playback reduces repeat downloads.',
            child: Column(
              children: <Widget>[
                _mobileFeature(Icons.flash_on_rounded, 'FAST UPLOAD', 'Parallel media uploads'),
                const Divider(height: 20, color: C.border),
                _mobileFeature(Icons.cached_rounded, 'CACHE FIRST', 'Local metadata cache'),
                const Divider(height: 20, color: C.border),
                _mobileFeature(Icons.sync_rounded, 'CHANGE ONLY', 'Revision-driven sync'),
                const Divider(height: 20, color: C.border),
                _mobileFeature(Icons.movie_filter_outlined, 'LAZY VIDEO', 'Preview on demand'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileStat(String title, ValueNotifier<int> notifier, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (_, value, __) => Text(
              '$value',
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, letterSpacing: .6, fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: .58)),
          ),
        ],
      ),
    );
  }

  Widget _mobileFeature(IconData icon, String title, String subtitle) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: C.primary.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, size: 18, color: C.light),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .55))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String title, ValueNotifier<int> n, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 18),
            ValueListenableBuilder<int>(
              valueListenable: n,
              builder: (_, v, __) => Text(
                '$v',
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: .34),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _status(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const _Dot(),
        const SizedBox(width: 12),
        Expanded(child: Text(a)),
        Text(
          b,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: .40),
          ),
        ),
      ],
    ),
  );

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    await AppStatsService.ensureInitialized();
    if (mounted) setState(() => refreshing = false);
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: C.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: C.light),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: .35),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ============================================================================
// MEDIA
// ============================================================================

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});
  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final items = <MediaItem>[];
  bool loading = true;
  bool uploading = false;
  bool deletingAll = false;
  double progress = 0;
  String filter = 'All';
  String search = '';

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    setState(() => loading = true);

    // Cache-first: render local Firestore metadata immediately when available.
    try {
      final cached = await Paths.media
          .orderBy('order')
          .get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) apply(cached.docs);
    } catch (_) {}

    if (mounted) setState(() => loading = items.isEmpty);

    // One normal server refresh per explicit open/refresh.
    try {
      final snap = await Paths.media.orderBy('order').get();
      apply(snap.docs);
    } catch (e) {
      if (items.isEmpty && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unable to load media: $e')));
      }
    }

    if (mounted) setState(() => loading = false);
  }

  void apply(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final list = docs.map(MediaItem.fromDoc).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    items
      ..clear()
      ..addAll(list);
    AppStatsService.media.value = list.length;
    AppStatsService.images.value = list
        .where((e) => e.type == MediaType.image)
        .length;
    AppStatsService.videos.value = list
        .where((e) => e.type == MediaType.video)
        .length;
    if (mounted) setState(() {});
  }

  List<MediaItem> get visible {
    final q = search.trim().toLowerCase();
    return items.where((item) {
      final f =
          filter == 'All' ||
          (filter == 'Images' && !item.video) ||
          (filter == 'Videos' && item.video);
      final s = q.isEmpty || item.name.toLowerCase().contains(q);
      return f && s;
    }).toList();
  }

  Future<void> upload() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'mp4',
        'webm',
        'mov',
        'm4v',
      ],
    );
    if (files.isEmpty) return;

    setState(() {
      uploading = true;
      progress = 0;
    });

    try {
      // Limited concurrency: fast without opening too many huge browser jobs.
      final queue = List<PlatformFile>.from(files);
      final results = <_UploadResult>[];
      int completed = 0;

      Future<void> worker() async {
        while (queue.isNotEmpty) {
          final file = queue.removeAt(0);
          final result = await uploadOne(file);
          results.add(result);
          completed++;
          if (mounted) {
            setState(() => progress = completed / files.length);
          }
        }
      }

      await Future.wait(List.generate(min(3, files.length), (_) => worker()));

      final newItems = <MediaItem>[];
      int nextOrder = items.length;
      final ops = <void Function(WriteBatch)>[];

      for (final r in results) {
        final item = MediaItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: r.name,
          url: r.url,
          path: r.path,
          type: r.type,
          version: 1,
          order: nextOrder++,
          duration: 0,
        );
        newItems.add(item);
        ops.add((batch) {
          batch.set(Paths.media.doc(item.id), item.toMap());
        });
      }

      await commitBatches(ops);

      // One revision bump for the complete multi-file operation.
      await Paths.sync.set({
        'revision': FieldValue.increment(1),
        'reason': 'media-upload',
        'totalMedia': items.length + newItems.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AppStatsService.change(
        mediaDelta: newItems.length,
        imageDelta: newItems.where((e) => e.type == MediaType.image).length,
        videoDelta: newItems.where((e) => e.type == MediaType.video).length,
      );

      items.addAll(newItems);
      if (mounted) setState(() {});

      // Duration lookup is deliberately deferred and never blocks upload UI.
      for (final item in newItems.where((e) => e.video)) {
        unawaited(resolveVideoDuration(item));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newItems.length} media file(s) uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
          progress = 0;
        });
      }
    }
  }

  Future<_UploadResult> uploadOne(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    final ext = file.extension?.toLowerCase() ?? '';
    final safeName = file.name.replaceAll(RegExp(r'[/\\]'), '_');
    final storageName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final ref = Paths.storage.child(storageName);

    await ref.putData(bytes, SettableMetadata(contentType: mime(ext)));
    final url = await ref.getDownloadURL();

    return _UploadResult(
      name: file.name,
      url: url,
      path: ref.fullPath,
      type: typeFor(ext),
    );
  }

  Future<void> resolveVideoDuration(MediaItem item) async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(item.url));
      await c.initialize();
      final seconds = c.value.duration.inSeconds;
      await c.dispose();
      if (seconds <= 0) return;
      item.duration = seconds;
      await Paths.media.doc(item.id).update({'durationSeconds': seconds});
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> deleteOne(MediaItem item) async {
    final yes = await confirmBox(
      context,
      title: 'Delete media?',
      text: item.name,
      action: 'Delete',
    );
    if (!yes) return;

    try {
      await FirebaseStorage.instance.ref(item.path).delete();
    } catch (_) {}
    await Paths.media.doc(item.id).delete();
    items.removeWhere((e) => e.id == item.id);
    for (int i = 0; i < items.length; i++) {
      items[i].order = i;
    }
    final reorderOps = <void Function(WriteBatch)>[];
    for (final current in items) {
      reorderOps.add((batch) {
        batch.update(Paths.media.doc(current.id), {'order': current.order});
      });
    }
    await commitBatches(reorderOps);
    await Paths.sync.set({
      'revision': FieldValue.increment(1),
      'reason': 'media-delete',
      'totalMedia': items.length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AppStatsService.change(
      mediaDelta: -1,
      imageDelta: item.video ? 0 : -1,
      videoDelta: item.video ? -1 : 0,
    );
    if (mounted) setState(() {});
  }

  Future<void> deleteAll() async {
    if (items.isEmpty) return;
    final yes = await confirmBox(
      context,
      title: 'Delete all media?',
      text: 'This will remove all ${items.length} photos/videos.',
      action: 'Delete All',
    );
    if (!yes) return;

    setState(() => deletingAll = true);
    final queue = List<MediaItem>.from(items);
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final item = queue.removeAt(0);
        try {
          await FirebaseStorage.instance.ref(item.path).delete();
        } catch (_) {}
      }
    }

    try {
      await Future.wait(List.generate(min(8, items.length), (_) => worker()));
      final count = items.length;
      final imageCount = items.where((e) => !e.video).length;
      final videoCount = items.where((e) => e.video).length;
      await commitBatches(
        items
            .map(
              (item) => (WriteBatch b) {
                b.delete(Paths.media.doc(item.id));
              },
            )
            .toList(),
      );
      await Paths.sync.set({
        'revision': FieldValue.increment(1),
        'reason': 'media-delete-all',
        'totalMedia': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await AppStatsService.change(
        mediaDelta: -count,
        imageDelta: -imageCount,
        videoDelta: -videoCount,
      );
      items.clear();
    } finally {
      if (mounted) setState(() => deletingAll = false);
    }
  }

  Future<void> edit(MediaItem item) async {
    final name = TextEditingController(text: item.name);
    int seconds = item.duration > 0 ? item.duration : 5;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: C.card2,
          title: const Text('Edit media'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  value: seconds,
                  decoration: const InputDecoration(
                    labelText: 'Image duration',
                  ),
                  items: const [3, 5, 10, 15, 20, 30]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e seconds'),
                        ),
                      )
                      .toList(),
                  onChanged: item.video
                      ? null
                      : (v) {
                          if (v != null) {
                            setDialogState(() => seconds = v);
                          }
                        },
                ),
                if (item.video) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Video duration: ${dur(item.duration)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .45),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final newName = name.text.trim();
    if (newName.isEmpty) return;
    item.name = newName;
    final data = <String, dynamic>{
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!item.video) {
      item.duration = seconds;
      data['durationSeconds'] = seconds;
    }
    await Paths.media.doc(item.id).update(data);
    await SyncService.bump('media-metadata-change');
    if (mounted) setState(() {});
  }

  Future<void> preview(MediaItem item) async {
    if (!item.video) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.name)),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1000,
                    maxHeight: 700,
                  ),
                  child: Image.network(item.url, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => VideoPreview(item: item),
    );
  }

  Future<void> reorder(MediaItem dragged, MediaItem target) async {
    if (dragged.id == target.id) return;
    final oldIndex = items.indexWhere((e) => e.id == dragged.id);
    final newIndex = items.indexWhere((e) => e.id == target.id);
    if (oldIndex < 0 || newIndex < 0) return;

    setState(() {
      final moved = items.removeAt(oldIndex);
      items.insert(newIndex, moved);
      for (int i = 0; i < items.length; i++) {
        items[i].order = i;
      }
    });

    final ops = <void Function(WriteBatch)>[];
    for (final item in items) {
      ops.add((batch) {
        batch.update(Paths.media.doc(item.id), {'order': item.order});
      });
    }
    await commitBatches(ops);
    await SyncService.bump('media-order-change');
  }

  @override
  Widget build(BuildContext context) {
    final list = visible;
    final compact = MediaQuery.sizeOf(context).width < 760;
    final actionButtons = <Widget>[
      OutlinedButton.icon(
        onPressed: load,
        style: outline(),
        icon: const Icon(Icons.refresh_rounded, size: 17),
        label: const Text('Refresh'),
      ),
      OutlinedButton.icon(
        onPressed: items.isEmpty || deletingAll ? null : deleteAll,
        style: outline(danger: true),
        icon: const Icon(Icons.delete_sweep_rounded, size: 17),
        label: Text(deletingAll ? 'Deleting...' : 'Delete All'),
      ),
      FilledButton.icon(
        onPressed: uploading ? null : upload,
        style: FilledButton.styleFrom(backgroundColor: C.primary),
        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
        label: Text(uploading ? 'Uploading...' : 'Upload Media'),
      ),
    ];
    final searchField = SizedBox(
      width: compact ? double.infinity : 250,
      height: 40,
      child: TextField(
        onChanged: (v) => setState(() => search = v),
        style: const TextStyle(fontSize: 12),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, size: 18),
          hintText: 'Search media...',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 42, compact ? 18 : 34,
          compact ? 16 : 42, compact ? 18 : 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (compact) ...<Widget>[
            header('Photos & Videos', 'Manage every file displayed on your TVs.', null),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
          ] else
            header(
              'Photos & Videos',
              'Manage every file displayed on your TVs.',
              Row(children: <Widget>[
                actionButtons[0],
                const SizedBox(width: 9),
                actionButtons[1],
                const SizedBox(width: 9),
                actionButtons[2],
              ]),
            ),
          SizedBox(height: compact ? 16 : 24),
          if (compact) ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _filter('All'),
                _filter('Images'),
                _filter('Videos'),
                ValueListenableBuilder<int>(
                  valueListenable: AppStatsService.images,
                  builder: (_, v, __) => _tiny('Images $v'),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: AppStatsService.videos,
                  builder: (_, v, __) => _tiny('Videos $v'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            searchField,
          ] else
            Row(children: <Widget>[
              _filter('All'),
              const SizedBox(width: 8),
              _filter('Images'),
              const SizedBox(width: 8),
              _filter('Videos'),
              const SizedBox(width: 16),
              ValueListenableBuilder<int>(
                valueListenable: AppStatsService.images,
                builder: (_, v, __) => _tiny('Images $v'),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: AppStatsService.videos,
                builder: (_, v, __) => _tiny('Videos $v'),
              ),
              const Spacer(),
              searchField,
            ]),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Text('All Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              ValueListenableBuilder<int>(
                valueListenable: AppStatsService.media,
                builder: (_, v, __) => countBadge(v),
              ),
              if (!compact) ...<Widget>[
                const Spacer(),
                Text(
                  'Drag cards to change playback order',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .45)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (uploading) ...[
            LinearProgressIndicator(
              value: progress == 0 ? null : progress,
              minHeight: 5,
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: loading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? const Center(child: Text('No matching media'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int columns = 4;
                      if (constraints.maxWidth < 1200) columns = 3;
                      if (constraints.maxWidth < 820) columns = 2;
                      if (constraints.maxWidth < 560) columns = 1;
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 16 / 10,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return DragTarget<MediaItem>(
                            onAcceptWithDetails: (details) =>
                                unawaited(reorder(details.data, item)),
                            builder: (context, candidate, rejected) {
                              return LongPressDraggable<MediaItem>(
                                data: item,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: 300,
                                    height: 188,
                                    child: mediaCard(item, index + 1),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: .18,
                                  child: mediaCard(item, index + 1),
                                ),
                                child: mediaCard(
                                  item,
                                  index + 1,
                                  highlight: candidate.isNotEmpty,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filter(String text) {
    final selected = filter == text;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => filter = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? C.primary.withValues(alpha: .18)
              : Colors.white.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? C.light.withValues(alpha: .35)
                : Colors.white.withValues(alpha: .06),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _tiny(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      color: Colors.white.withValues(alpha: .035),
    ),
    child: Text(text, style: const TextStyle(fontSize: 10)),
  );

  Widget mediaCard(MediaItem item, int number, {bool highlight = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? C.light : C.border,
          width: highlight ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: item.video
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF181D28), Color(0xFF080B10)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        size: 60,
                        color: Colors.white12,
                      ),
                    ),
                  )
                : Image.network(
                    item.url,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .10),
                      Colors.transparent,
                      Colors.black.withValues(alpha: .86),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(left: 12, top: 12, child: _badge('$number')),
          Positioned(
            right: 12,
            top: 12,
            child: PopupMenuButton<String>(
              color: C.card2,
              onSelected: (value) {
                if (value == 'preview') unawaited(preview(item));
                if (value == 'edit') unawaited(edit(item));
                if (value == 'delete') unawaited(deleteOne(item));
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'preview', child: Text('Preview')),
                PopupMenuItem(value: 'edit', child: Text('Edit details')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              child: _circle(Icons.more_horiz),
            ),
          ),
          if (item.video)
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(60),
                onTap: () => unawaited(preview(item)),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: C.primary.withValues(alpha: .94),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .24),
                    ),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 42),
                ),
              ),
            ),
          Positioned(
            left: 12,
            right: 56,
            bottom: 46,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: Colors.black.withValues(alpha: .72),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.video
                        ? Icons.play_circle_outline_rounded
                        : Icons.timer_outlined,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.video
                        ? (item.duration > 0 ? dur(item.duration) : 'VIDEO')
                        : '${item.duration}s',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: const Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11)),
  );

  Widget _circle(IconData icon) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.black.withValues(alpha: .68),
    ),
    child: Icon(icon, size: 18),
  );
}

// ============================================================================
// PLAYLISTS
// ============================================================================

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});
  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final list = <PlaylistItem>[];
  final media = <MediaItem>[];
  final devices = <DeviceItem>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final r = await Future.wait([
        Paths.playlists.orderBy('name').get(),
        Paths.media.orderBy('order').get(),
        Paths.devices.orderBy('name').get(),
      ]);
      list
        ..clear()
        ..addAll(
          (r[0] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            PlaylistItem.fromDoc,
          ),
        );
      media
        ..clear()
        ..addAll(
          (r[1] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            MediaItem.fromDoc,
          ),
        );
      devices
        ..clear()
        ..addAll(
          (r[2] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            DeviceItem.fromDoc,
          ),
        );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Playlist load failed: $e')));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([PlaylistItem? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final selected = List<String>.from(existing?.mediaIds ?? const []);
    final tvSelected = Set<String>.from(existing?.deviceIds ?? const []);
    bool enabled = existing?.enabled ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            backgroundColor: C.card2,
            title: Text(existing == null ? 'Create playlist' : 'Edit playlist'),
            content: SizedBox(
              width: 820,
              height: 560,
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Playlist name',
                    ),
                  ),
                  SwitchListTile(
                    value: enabled,
                    title: const Text('Enabled'),
                    onChanged: (v) => setDialog(() => enabled = v),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _pickList(
                            title: 'Media • ${selected.length}',
                            children: media.map((item) {
                              final checked = selected.contains(item.id);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(item.video ? 'Video' : 'Image'),
                                onChanged: (v) {
                                  setDialog(() {
                                    if (v == true) {
                                      if (!selected.contains(item.id)) {
                                        selected.add(item.id);
                                      }
                                    } else {
                                      selected.remove(item.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _pickList(
                            title: 'TV Devices • ${tvSelected.length}',
                            children: devices.map((device) {
                              final checked = tvSelected.contains(device.id);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                title: Text(device.name),
                                subtitle: Text(device.status),
                                onChanged: (v) {
                                  setDialog(() {
                                    if (v == true) {
                                      tvSelected.add(device.id);
                                    } else {
                                      tvSelected.remove(device.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save Playlist'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    final title = name.text.trim();
    if (title.isEmpty) return;

    final pid = existing?.id ?? id();
    await Paths.playlists.doc(pid).set({
      'name': title,
      'mediaIds': selected,
      'deviceIds': tvSelected.toList(),
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await SyncService.bump('playlist-change');

    if (existing == null) {
      list.add(
        PlaylistItem(
          id: pid,
          name: title,
          mediaIds: selected,
          deviceIds: tvSelected.toList(),
          enabled: enabled,
        ),
      );
      await AppStatsService.change(playlistDelta: 1);
    } else {
      existing.name = title;
      existing.mediaIds = selected;
      existing.deviceIds = tvSelected.toList();
      existing.enabled = enabled;
    }
    if (mounted) setState(() {});
  }

  Widget _pickList({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: children.isEmpty
                ? const Center(child: Text('None available'))
                : ListView(children: children),
          ),
        ],
      ),
    );
  }

  Future<void> remove(PlaylistItem item) async {
    final ok = await confirmBox(
      context,
      title: 'Delete playlist?',
      text: item.name,
      action: 'Delete',
    );
    if (!ok) return;
    await Paths.playlists.doc(item.id).delete();
    await SyncService.bump('playlist-delete');
    await AppStatsService.change(playlistDelta: -1);
    list.remove(item);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final refreshButton = OutlinedButton.icon(
      onPressed: load,
      style: outline(),
      icon: const Icon(Icons.refresh_rounded, size: 17),
      label: const Text('Refresh'),
    );
    final addButton = FilledButton.icon(
      onPressed: () => unawaited(edit()),
      style: FilledButton.styleFrom(backgroundColor: C.primary),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Playlist'),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 42, compact ? 20 : 34,
          compact ? 16 : 42, compact ? 16 : 34),
      child: Column(
        children: <Widget>[
          if (compact) ...<Widget>[
            header('Playlists', 'Build content sequences and assign them to TVs.', null),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: <Widget>[refreshButton, addButton]),
            ),
          ] else
            header(
              'Playlists',
              'Build content sequences and assign them to TVs.',
              Row(children: <Widget>[refreshButton, const SizedBox(width: 10), addButton]),
            ),
          SizedBox(height: compact ? 16 : 24),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? Center(
                    child: cardPanel(
                      title: 'No playlists yet',
                      subtitle: 'Create a playlist and select media/TVs.',
                      child: const SizedBox(
                        height: 240,
                        child: Center(child: Text('Create Playlist to begin.')),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: C.primary.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.playlist_play_rounded,
                                color: C.light,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${item.mediaIds.length} media • ${item.deviceIds.length} TVs',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: .40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: item.enabled,
                              onChanged: (value) async {
                                item.enabled = value;
                                await Paths.playlists.doc(item.id).update({
                                  'enabled': value,
                                });
                                await SyncService.bump('playlist-enable');
                                if (mounted) setState(() {});
                              },
                            ),
                            IconButton(
                              onPressed: () => unawaited(edit(item)),
                              icon: const Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              onPressed: () => unawaited(remove(item)),
                              color: C.red,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TV DEVICES
// ============================================================================

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final list = <DeviceItem>[];
  final playlists = <PlaylistItem>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final r = await Future.wait([
        Paths.devices.orderBy('name').get(),
        Paths.playlists.orderBy('name').get(),
      ]);
      list
        ..clear()
        ..addAll(
          (r[0] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            DeviceItem.fromDoc,
          ),
        );
      playlists
        ..clear()
        ..addAll(
          (r[1] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            PlaylistItem.fromDoc,
          ),
        );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('TV device load failed: $e')));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([DeviceItem? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    String status = existing?.status ?? 'offline';
    String playlistId = existing?.playlistId ?? '';
    String code = existing?.code.isNotEmpty == true
        ? existing!.code
        : pairCode();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: C.card2,
          title: Text(existing == null ? 'Add TV device' : 'Edit TV device'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Device name',
                    hintText: 'Lobby TV 01',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: playlistId.isEmpty ? null : playlistId,
                  decoration: const InputDecoration(labelText: 'Playlist'),
                  items: playlists
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setDialog(() => playlistId = v ?? ''),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                    DropdownMenuItem(value: 'offline', child: Text('Offline')),
                  ],
                  onChanged: (v) => setDialog(() => status = v ?? 'offline'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pairing code: $code',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setDialog(() => code = pairCode()),
                      child: const Text('Regenerate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Device'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final title = name.text.trim();
    if (title.isEmpty) return;

    final did = existing?.id ?? id();
    await Paths.devices.doc(did).set({
      'name': title,
      'pairingCode': code,
      'status': status,
      'playlistId': playlistId,
      'lastSeen': existing?.lastSeen == null
          ? null
          : Timestamp.fromDate(existing!.lastSeen!),
      'updatedAt': FieldValue.serverTimestamp(),
      if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await SyncService.bump('tv-device-change');

    if (existing == null) {
      list.add(
        DeviceItem(
          id: did,
          name: title,
          code: code,
          status: status,
          playlistId: playlistId,
        ),
      );
      await AppStatsService.change(tvDelta: 1);
    } else {
      existing.name = title;
      existing.code = code;
      existing.status = status;
      existing.playlistId = playlistId;
    }
    if (mounted) setState(() {});
  }

  Future<void> remove(DeviceItem item) async {
    final ok = await confirmBox(
      context,
      title: 'Remove TV device?',
      text: item.name,
      action: 'Remove',
    );
    if (!ok) return;
    await Paths.devices.doc(item.id).delete();
    await SyncService.bump('tv-device-delete');
    await AppStatsService.change(tvDelta: -1);
    list.remove(item);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final refreshButton = OutlinedButton.icon(
      onPressed: load,
      style: outline(),
      icon: const Icon(Icons.refresh_rounded, size: 17),
      label: const Text('Refresh'),
    );
    final addButton = FilledButton.icon(
      onPressed: () => unawaited(edit()),
      style: FilledButton.styleFrom(backgroundColor: C.primary),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add TV'),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 42, compact ? 20 : 34,
          compact ? 16 : 42, compact ? 16 : 34),
      child: Column(
        children: <Widget>[
          if (compact) ...<Widget>[
            header('TV Devices', 'Pair screens, assign playlists and manage device state.', null),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: <Widget>[refreshButton, addButton]),
            ),
          ] else
            header(
              'TV Devices',
              'Pair screens, assign playlists and manage device state.',
              Row(children: <Widget>[refreshButton, const SizedBox(width: 10), addButton]),
            ),
          SizedBox(height: compact ? 16 : 24),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? Center(
                    child: cardPanel(
                      title: 'No TV devices yet',
                      subtitle: 'Add a display to create its pairing code.',
                      child: const SizedBox(
                        height: 240,
                        child: Center(child: Text('Add TV to begin.')),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final playlist = firstWhereOrNull(
                        playlists
                            .where((p) => p.id == item.playlistId)
                            .map((p) => p.name),
                      );
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: C.cyan.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.tv_rounded,
                                color: C.cyan,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Code ${item.code} • ${playlist ?? 'No playlist'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: .40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _pill(
                              item.status == 'online' ? 'Online' : 'Offline',
                              item.status == 'online',
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => unawaited(edit(item)),
                              icon: const Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              onPressed: () => unawaited(remove(item)),
                              color: C.red,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SCHEDULE
// ============================================================================

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final list = <ScheduleItem>[];
  final playlists = <PlaylistItem>[];
  final devices = <DeviceItem>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final r = await Future.wait([
        Paths.schedules.orderBy('startDate').get(),
        Paths.playlists.orderBy('name').get(),
        Paths.devices.orderBy('name').get(),
      ]);
      list
        ..clear()
        ..addAll(
          (r[0] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            ScheduleItem.fromDoc,
          ),
        );
      playlists
        ..clear()
        ..addAll(
          (r[1] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            PlaylistItem.fromDoc,
          ),
        );
      devices
        ..clear()
        ..addAll(
          (r[2] as QuerySnapshot<Map<String, dynamic>>).docs.map(
            DeviceItem.fromDoc,
          ),
        );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Schedule load failed: $e')));
      }
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([ScheduleItem? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    String playlistId = existing?.playlistId ?? '';
    DateTime start = existing?.startDate ?? DateTime.now();
    DateTime end = existing?.endDate ?? DateTime.now();
    int from = existing?.startMinutes ?? 9 * 60;
    int to = existing?.endMinutes ?? 22 * 60;
    bool enabled = existing?.enabled ?? true;
    final tvs = Set<String>.from(existing?.deviceIds ?? const []);
    final days = Set<int>.from(existing?.weekdays ?? const []);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          backgroundColor: C.card2,
          title: Text(existing == null ? 'Create schedule' : 'Edit schedule'),
          content: SizedBox(
            width: 760,
            height: 580,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Schedule name',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: playlistId.isEmpty ? null : playlistId,
                    decoration: const InputDecoration(labelText: 'Playlist'),
                    items: playlists
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialog(() => playlistId = v ?? ''),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final v = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                              initialDate: start,
                            );
                            if (v != null) setDialog(() => start = v);
                          },
                          icon: const Icon(Icons.event_rounded),
                          label: Text('Start ${dateText(start)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final v = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 3650),
                              ),
                              initialDate: end,
                            );
                            if (v != null) setDialog(() => end = v);
                          },
                          icon: const Icon(Icons.event_rounded),
                          label: Text('End ${dateText(end)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final v = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: (from ~/ 60) % 24,
                                minute: from % 60,
                              ),
                            );
                            if (v != null) {
                              setDialog(() => from = v.hour * 60 + v.minute);
                            }
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('From ${timeText(from)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final v = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay(
                                hour: (to ~/ 60) % 24,
                                minute: to % 60,
                              ),
                            );
                            if (v != null) {
                              setDialog(() => to = v.hour * 60 + v.minute);
                            }
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('Until ${timeText(to)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recurring weekdays',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: .75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: List.generate(7, (i) {
                      const labels = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      final day = i + 1;
                      return FilterChip(
                        label: Text(labels[i]),
                        selected: days.contains(day),
                        onSelected: (v) {
                          setDialog(() {
                            if (v) {
                              days.add(day);
                            } else {
                              days.remove(day);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TV devices',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: .75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.border),
                    ),
                    child: devices.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No TV devices available.'),
                          )
                        : Column(
                            children: devices.map((device) {
                              final selected = tvs.contains(device.id);
                              return CheckboxListTile(
                                dense: true,
                                value: selected,
                                title: Text(device.name),
                                subtitle: Text(device.status),
                                onChanged: (v) {
                                  setDialog(() {
                                    if (v == true) {
                                      tvs.add(device.id);
                                    } else {
                                      tvs.remove(device.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                  ),
                  SwitchListTile(
                    value: enabled,
                    title: const Text('Schedule enabled'),
                    onChanged: (v) => setDialog(() => enabled = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Schedule'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final title = name.text.trim();
    if (title.isEmpty || playlistId.isEmpty) return;

    final sid = existing?.id ?? id();
    await Paths.schedules.doc(sid).set({
      'name': title,
      'playlistId': playlistId,
      'deviceIds': tvs.toList(),
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end),
      'startMinutes': from,
      'endMinutes': to,
      'weekdays': days.toList()..sort(),
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
      if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await SyncService.bump('schedule-change');

    if (existing == null) {
      list.add(
        ScheduleItem(
          id: sid,
          name: title,
          playlistId: playlistId,
          deviceIds: tvs.toList(),
          startDate: start,
          endDate: end,
          startMinutes: from,
          endMinutes: to,
          weekdays: days.toList(),
          enabled: enabled,
        ),
      );
      await AppStatsService.change(scheduleDelta: 1);
    } else {
      existing.name = title;
      existing.playlistId = playlistId;
      existing.deviceIds = tvs.toList();
      existing.startDate = start;
      existing.endDate = end;
      existing.startMinutes = from;
      existing.endMinutes = to;
      existing.weekdays = days.toList();
      existing.enabled = enabled;
    }
    if (mounted) setState(() {});
  }

  Future<void> remove(ScheduleItem item) async {
    final ok = await confirmBox(
      context,
      title: 'Delete schedule?',
      text: item.name,
      action: 'Delete',
    );
    if (!ok) return;
    await Paths.schedules.doc(item.id).delete();
    await SyncService.bump('schedule-delete');
    await AppStatsService.change(scheduleDelta: -1);
    list.remove(item);
    if (mounted) setState(() {});
  }

  String playlistName(String pid) =>
      firstWhereOrNull(
        playlists.where((p) => p.id == pid).map((p) => p.name),
      ) ??
      'Unknown';

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    final refreshButton = OutlinedButton.icon(
      onPressed: load,
      style: outline(),
      icon: const Icon(Icons.refresh_rounded, size: 17),
      label: const Text('Refresh'),
    );
    final addButton = FilledButton.icon(
      onPressed: playlists.isEmpty ? null : () => unawaited(edit()),
      style: FilledButton.styleFrom(backgroundColor: C.primary),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create Schedule'),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 42, compact ? 20 : 34,
          compact ? 16 : 42, compact ? 16 : 34),
      child: Column(
        children: <Widget>[
          if (compact) ...<Widget>[
            header('Schedule', 'Automate which playlist appears on which TV and when.', null),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 8, children: <Widget>[refreshButton, addButton]),
            ),
          ] else
            header(
              'Schedule',
              'Automate which playlist appears on which TV and when.',
              Row(children: <Widget>[refreshButton, const SizedBox(width: 10), addButton]),
            ),
          SizedBox(height: compact ? 16 : 24),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? Center(
                    child: cardPanel(
                      title: 'No schedules yet',
                      subtitle: 'Create a playlist first, then schedule it.',
                      child: const SizedBox(
                        height: 240,
                        child: Center(child: Text('Create Schedule to begin.')),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = list[i];
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: C.amber.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: C.amber,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${playlistName(s.playlistId)} • ${timeText(s.startMinutes)} → ${timeText(s.endMinutes)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: .40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateText(s.startDate)} → ${dateText(s.endDate)} • ${s.deviceIds.length} TV(s)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: .30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _pill(
                              s.enabled ? 'Enabled' : 'Disabled',
                              s.enabled,
                            ),
                            IconButton(
                              onPressed: () => unawaited(edit(s)),
                              icon: const Icon(Icons.edit_rounded),
                            ),
                            IconButton(
                              onPressed: () => unawaited(remove(s)),
                              color: C.red,
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SETTINGS
// ============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final venue = TextEditingController();
  final logo = TextEditingController();
  int duration = 5;
  double volume = 1.0;
  String transition = 'Fade';
  String fit = 'Cover';
  String cache = 'Cache first';
  bool autoplay = true;
  bool clock = false;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      final s = await Paths.settings.get();
      final x = s.data() ?? {};
      venue.text = x['venueName']?.toString() ?? '';
      logo.text = x['logoUrl']?.toString() ?? '';
      duration = (x['defaultDuration'] as num?)?.toInt() ?? 5;
      volume = (x['volume'] as num?)?.toDouble() ?? 1.0;
      transition = x['transition']?.toString() ?? 'Fade';
      fit = x['fitMode']?.toString() ?? 'Cover';
      cache = x['cachePolicy']?.toString() ?? 'Cache first';
      autoplay = x['autoplay'] != false;
      clock = x['showClock'] == true;
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await Paths.settings.set({
        'venueName': venue.text.trim(),
        'logoUrl': logo.text.trim(),
        'defaultDuration': duration,
        'volume': volume,
        'transition': transition,
        'fitMode': fit,
        'cachePolicy': cache,
        'autoplay': autoplay,
        'showClock': clock,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await SyncService.bump('settings-change');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    venue.dispose();
    logo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    final compact = MediaQuery.sizeOf(context).width < 760;

    final saveButton = FilledButton.icon(
      onPressed: saving ? null : save,
      style: FilledButton.styleFrom(backgroundColor: C.primary),
      icon: const Icon(Icons.save_rounded),
      label: Text(saving ? 'Saving...' : 'Save Settings'),
    );

    final workspaceCard = cardPanel(
      title: 'Workspace',
      subtitle: 'Branding used across the system.',
      child: Column(
        children: <Widget>[
          TextField(controller: venue, decoration: const InputDecoration(labelText: 'Venue / Company name')),
          const SizedBox(height: 14),
          TextField(controller: logo, decoration: const InputDecoration(labelText: 'Logo URL (optional)')),
        ],
      ),
    );

    final playbackCard = cardPanel(
      title: 'Playback defaults',
      subtitle: 'Defaults the TV app can use.',
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<int>(
            value: duration,
            decoration: const InputDecoration(labelText: 'Default image duration'),
            items: const [3, 5, 10, 15, 20, 30]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v seconds')))
                .toList(),
            onChanged: (v) { if (v != null) setState(() => duration = v); },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: transition,
            decoration: const InputDecoration(labelText: 'Transition'),
            items: const ['Fade', 'None', 'Slide']
                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) { if (v != null) setState(() => transition = v); },
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: fit,
            decoration: const InputDecoration(labelText: 'Fit mode'),
            items: const ['Cover', 'Contain', 'Fill']
                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) { if (v != null) setState(() => fit = v); },
          ),
        ],
      ),
    );

    final audioCard = cardPanel(
      title: 'Audio & display',
      subtitle: 'Default TV playback behavior.',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('Default volume'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: volume, min: 0, max: 1, divisions: 10,
                  label: '${(volume * 100).round()}%',
                  onChanged: (v) => setState(() => volume = v),
                ),
              ),
              Text('${(volume * 100).round()}%'),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: autoplay,
            title: const Text('Autoplay videos'),
            onChanged: (v) => setState(() => autoplay = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: clock,
            title: const Text('Show clock overlay'),
            onChanged: (v) => setState(() => clock = v),
          ),
        ],
      ),
    );

    final syncCard = cardPanel(
      title: 'Sync & cache',
      subtitle: 'Cost-control policy for TV synchronization.',
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: cache,
            decoration: const InputDecoration(labelText: 'Cache policy'),
            items: const ['Cache first', 'Balanced', 'Always refresh']
                .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) { if (v != null) setState(() => cache = v); },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.green.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.green.withValues(alpha: .12)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.shield_outlined, color: C.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'TVs use revision-based synchronization and should keep unchanged media locally.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(compact ? 16 : 42, compact ? 20 : 34,
          compact ? 16 : 42, compact ? 24 : 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (compact) ...<Widget>[
            header('Settings', 'Manage workspace branding, playback defaults and cache behavior.', null),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: saveButton),
          ] else
            header('Settings', 'Manage workspace branding, playback defaults and cache behavior.', saveButton),
          const SizedBox(height: 20),
          if (compact) ...<Widget>[
            workspaceCard,
            const SizedBox(height: 16),
            playbackCard,
            const SizedBox(height: 16),
            audioCard,
            const SizedBox(height: 16),
            syncCard,
          ] else ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: workspaceCard),
                const SizedBox(width: 20),
                Expanded(child: playbackCard),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: audioCard),
                const SizedBox(width: 20),
                Expanded(child: syncCard),
              ],
            ),
          ],
          const SizedBox(height: 20),
          cardPanel(
            title: 'Data model',
            subtitle: 'Collections used by the Admin and TV apps.',
            child: Column(
              children: const <Widget>[
                _Info('Media', 'tv_media'),
                _Info('Playlists', 'playlists'),
                _Info('TV Devices', 'tv_devices'),
                _Info('Schedules', 'schedules'),
                _Info('Revision', 'tv_sync/current'),
                _Info('Admin Settings', 'system/config'),
                _Info('Dashboard Stats', 'app_stats/current'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.a, this.b);
  final String a;
  final String b;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(a)),
        Text(
          b,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: .38),
          ),
        ),
      ],
    ),
  );
}

Widget _pill(String text, bool green) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(
    color: green
        ? C.green.withValues(alpha: .10)
        : Colors.white.withValues(alpha: .05),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    text,
    style: TextStyle(fontSize: 11, color: green ? C.green : Colors.white54),
  ),
);

// ============================================================================
// MISSING SUPPORT TYPES / HELPERS
// These complete the single-file Admin build used by the screens above.
// ============================================================================

class _UploadResult {
  const _UploadResult({
    required this.name,
    required this.url,
    required this.path,
    required this.type,
  });

  final String name;
  final String url;
  final String path;
  final MediaType type;
}

Future<void> commitBatches(
  Iterable<void Function(WriteBatch)> operations,
) async {
  const maxOperationsPerBatch = 400;
  final list = operations.toList(growable: false);

  for (var start = 0; start < list.length; start += maxOperationsPerBatch) {
    final end = min(start + maxOperationsPerBatch, list.length);
    final batch = Paths.db.batch();

    for (var i = start; i < end; i++) {
      list[i](batch);
    }

    await batch.commit();
  }
}

T? firstWhereOrNull<T>(Iterable<T> values) {
  for (final value in values) {
    return value;
  }
  return null;
}

Widget countBadge(int value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text('$value', style: const TextStyle(fontSize: 11)),
  );
}

class VideoPreview extends StatefulWidget {
  const VideoPreview({required this.item, super.key});

  final MediaItem item;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? controller;
  bool loading = true;
  bool playing = false;
  bool muted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.item.url));

      await c.initialize();
      await c.setVolume(1);

      try {
        await c.play();
      } catch (_) {
        // Browser autoplay policies may block sound autoplay.
      }

      if (!mounted) {
        await c.dispose();
        return;
      }

      if (c.value.duration.inSeconds > 0 &&
          widget.item.duration != c.value.duration.inSeconds) {
        widget.item.duration = c.value.duration.inSeconds;
        unawaited(
          Paths.media.doc(widget.item.id).update({
            'durationSeconds': widget.item.duration,
          }),
        );
      }

      setState(() {
        controller = c;
        loading = false;
        playing = c.value.isPlaying;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _togglePlay() async {
    final c = controller;
    if (c == null) return;

    if (c.value.isPlaying) {
      await c.pause();
      if (mounted) setState(() => playing = false);
    } else {
      await c.play();
      if (mounted) setState(() => playing = true);
    }
  }

  Future<void> _toggleMute() async {
    final c = controller;
    if (c == null) return;

    muted = !muted;
    await c.setVolume(muted ? 0 : 1);

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: C.card2,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 820),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: controller?.value.isInitialized == true
                    ? controller!.value.aspectRatio
                    : 16 / 9,
                child: Container(
                  color: Colors.black,
                  clipBehavior: Clip.antiAlias,
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : controller == null
                      ? const Center(
                          child: Text('Unable to preview this video.'),
                        )
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                clipBehavior: Clip.hardEdge,
                                child: SizedBox(
                                  width: controller!.value.size.width,
                                  height: controller!.value.size.height,
                                  child: VideoPlayer(controller!),
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: C.primary.withValues(alpha: .94),
                                ),
                                child: IconButton(
                                  onPressed: _togglePlay,
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 14,
                              bottom: 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: .70),
                                ),
                                child: IconButton(
                                  onPressed: _toggleMute,
                                  icon: Icon(
                                    muted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  muted ? 'Audio muted' : 'Audio enabled',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: .40),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
