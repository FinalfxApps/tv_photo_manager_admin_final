import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

class FxMasterDb {
  static final db = FirebaseFirestore.instance;
  static final categories = db.collection('menu_categories');
  static final menu = db.collection('menu_items');
  static final offers = db.collection('offers');
  static final templates = db.collection('display_templates');
  static final groups = db.collection('tv_groups');
  static final devices = db.collection('tv_devices');
  static final commands = db.collection('tv_commands');
  static final roles = db.collection('admin_roles');
  static final audits = db.collection('audit_logs');
  static final emergency = db.doc('emergency/current');
  static final qr = db.doc('qr_config/menu');
}

class FxMasterC {
  static const bg = Color(0xFF07090E);
  static const card = Color(0xFF11141B);
  static const card2 = Color(0xFF151923);
  static const border = Color(0x18FFFFFF);
  static const primary = Color(0xFF7656F8);
  static const red = Color(0xFFE05252);
  static const green = Color(0xFF36C98A);
  static const gold = Color(0xFFD8B45A);
}

const fxNameStyles = <String>[
  '3D Glow',
  '3D Shadow',
  'Outline',
  'Gradient',
  'Minimal',
];

const fxNameColors = <String>['White', 'Gold', 'Purple', 'Cyan', 'Red'];

const fxDisplayModes = <String>[
  'Fullscreen Slideshow',
  'Menu Display',
  'Mixed Mode',
];

const fxCategoryColors = <String>['Purple', 'Gold', 'Cyan', 'Red', 'White'];

const fxAllergens = <String>[
  'Milk',
  'Egg',
  'Wheat / Gluten',
  'Soy',
  'Fish',
  'Shellfish',
  'Peanuts',
  'Tree Nuts',
  'Sesame',
];

const fxBadges = <String>['Best Seller', 'New', 'Spicy', 'Recommended'];

String fxMasterId() => DateTime.now().microsecondsSinceEpoch.toString();

Future<void> fxMasterAudit(String action, String target, String summary) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    await FxMasterDb.audits.add({
      'action': action,
      'target': target,
      'summary': summary,
      'uid': user?.uid ?? '',
      'email': user?.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {}
}

Future<String?> fxMasterTranslateArabic(String input) async {
  final q = input.trim();
  if (q.isEmpty) return null;

  const dictionary = <String, String>{
    'broast': 'بروست',
    'broasted': 'بروستد',
    'burger': 'برجر',
    'burgers': 'برجر',
    'chicken': 'دجاج',
    'fries': 'بطاطس مقلية',
    'pizza': 'بيتزا',
    'shawarma': 'شاورما',
    'sandwich': 'ساندويتش',
    'sandwiches': 'ساندويتشات',
    'nuggets': 'ناجتس',
    'wings': 'أجنحة دجاج',
    'rice': 'أرز',
    'salad': 'سلطة',
    'dessert': 'حلويات',
    'desserts': 'حلويات',
    'drinks': 'مشروبات',
    'beverages': 'مشروبات',
    'meals': 'وجبات',
    'appetizers': 'مقبلات',
    'breakfast': 'فطور',
    'seafood': 'مأكولات بحرية',
    'sauce': 'صلصة',
    'sauces': 'صلصات',
    'kids': 'أطفال',
    'family meal': 'وجبة عائلية',
    'family meals': 'وجبات عائلية',
    'hot drinks': 'مشروبات ساخنة',
    'cold drinks': 'مشروبات باردة',
  };

  final exact = dictionary[q.toLowerCase()];
  if (exact != null) return exact;

  try {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': 'en',
      'tl': 'ar',
      'dt': 't',
      'q': q,
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty || data[0] is! List) return null;

    final parts = <String>[];
    for (final row in data[0] as List) {
      if (row is List && row.isNotEmpty && row[0] != null) {
        final value = row[0].toString().trim();
        if (value.isNotEmpty) parts.add(value);
      }
    }
    final result = parts.join();
    return result.isEmpty ? null : result;
  } catch (_) {
    return null;
  }
}

Future<String?> fxMasterUpload(PlatformFile file, String folder) async {
  try {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;

    final safeName = file.name.replaceAll(RegExp(r'[/\\]'), '_');
    final reference = FirebaseStorage.instance
        .ref()
        .child(folder)
        .child('${DateTime.now().microsecondsSinceEpoch}_$safeName');

    await reference.putData(
      bytes,
      SettableMetadata(contentType: _fxMime(file.extension)),
    );
    return await reference.getDownloadURL();
  } catch (_) {
    return null;
  }
}

String _fxMime(String? extension) {
  switch ((extension ?? '').toLowerCase()) {
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
    case 'm4v':
      return 'video/mp4';
    default:
      return 'application/octet-stream';
  }
}

class FxMasterCategory {
  FxMasterCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.order,
    required this.active,
    required this.highlight,
    required this.color,
  });

  final String id;
  String nameEn;
  String nameAr;
  int order;
  bool active;
  bool highlight;
  String color;

  factory FxMasterCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FxMasterCategory(
      id: doc.id,
      nameEn: data['nameEn']?.toString() ?? '',
      nameAr: data['nameAr']?.toString() ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      active: data['active'] != false,
      highlight: data['highlight'] == true,
      color: data['highlightColor']?.toString() ?? 'Purple',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'nameEn': nameEn,
    'nameAr': nameAr,
    'order': order,
    'active': active,
    'highlight': highlight,
    'highlightColor': color,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class FxMasterMenuItem {
  FxMasterMenuItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.price,
    required this.calories,
    required this.categoryId,
    required this.categoryName,
    required this.allergens,
    required this.badges,
    required this.photoUrl,
    required this.videoUrl,
    required this.active,
    required this.displayMode,
    required this.nameStyle,
    required this.nameColor,
  });

  final String id;
  String nameEn;
  String nameAr;
  String categoryId;
  String categoryName;
  String photoUrl;
  String videoUrl;
  String displayMode;
  String nameStyle;
  String nameColor;
  double price;
  int calories;
  List<String> allergens;
  List<String> badges;
  bool active;

  factory FxMasterMenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawAllergens = data['allergens'];
    final rawBadges = data['badges'];

    return FxMasterMenuItem(
      id: doc.id,
      nameEn: data['nameEn']?.toString() ?? '',
      nameAr: data['nameAr']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      categoryId: data['categoryId']?.toString() ?? '',
      categoryName:
          data['categoryName']?.toString() ??
          data['category']?.toString() ??
          '',
      allergens: rawAllergens is List
          ? rawAllergens.map((e) => e.toString()).toList()
          : <String>[],
      badges: rawBadges is List
          ? rawBadges.map((e) => e.toString()).toList()
          : <String>[],
      photoUrl: data['photoUrl']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      active: data['active'] != false,
      displayMode: data['displayMode']?.toString() ?? 'Menu Display',
      nameStyle: data['nameStyle']?.toString() ?? '3D Glow',
      nameColor: data['nameColor']?.toString() ?? 'White',
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'nameEn': nameEn,
    'nameAr': nameAr,
    'price': price,
    'calories': calories,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'category': categoryName,
    'allergens': allergens,
    'badges': badges,
    'photoUrl': photoUrl,
    'videoUrl': videoUrl,
    'active': active,
    'displayMode': displayMode,
    'nameStyle': nameStyle,
    'nameColor': nameColor,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class FxMasterOffer {
  FxMasterOffer({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.oldPrice,
    required this.offerPrice,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.active,
  });

  final String id;
  String nameEn;
  String nameAr;
  String imageUrl;
  double oldPrice;
  double offerPrice;
  DateTime startDate;
  DateTime endDate;
  bool active;

  factory FxMasterOffer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime readDate(String key, DateTime fallback) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      return fallback;
    }

    final now = DateTime.now();
    return FxMasterOffer(
      id: doc.id,
      nameEn: data['nameEn']?.toString() ?? '',
      nameAr: data['nameAr']?.toString() ?? '',
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      offerPrice: (data['offerPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl']?.toString() ?? '',
      startDate: readDate('startDate', now),
      endDate: readDate('endDate', now.add(const Duration(days: 7))),
      active: data['active'] != false,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'nameEn': nameEn,
    'nameAr': nameAr,
    'oldPrice': oldPrice,
    'offerPrice': offerPrice,
    'imageUrl': imageUrl,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'active': active,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

class FxRestaurantStudioScreen extends StatefulWidget {
  const FxRestaurantStudioScreen({super.key});

  @override
  State<FxRestaurantStudioScreen> createState() =>
      _FxRestaurantStudioScreenState();
}

class _FxRestaurantStudioScreenState extends State<FxRestaurantStudioScreen>
    with TickerProviderStateMixin {
  static const labels = <String>[
    'Overview',
    'Categories',
    'Menu',
    'Offers',
    'Templates',
    'TV Groups',
    'Remote',
    'QR Menu',
    'Roles',
    'Audit',
  ];

  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: labels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.dashboard_rounded,
      Icons.category_rounded,
      Icons.restaurant_menu_rounded,
      Icons.local_offer_rounded,
      Icons.dashboard_customize_rounded,
      Icons.groups_rounded,
      Icons.settings_remote_rounded,
      Icons.qr_code_2_rounded,
      Icons.admin_panel_settings_rounded,
      Icons.history_rounded,
    ];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 800;

    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FxMasterC.bg,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          brightness: Brightness.dark,
          primary: FxMasterC.primary,
          surface: FxMasterC.card,
        ),
        textTheme: Theme.of(context).textTheme
            .apply(bodyColor: Colors.white, displayColor: Colors.white),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FxMasterC.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FxMasterC.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FxMasterC.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: FxMasterC.primary, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: FxMasterC.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: FxMasterC.border),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: FxMasterC.bg,
        body: SafeArea(
          child: Row(
            children: <Widget>[
              Container(
                width: compact ? 74 : 238,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B0E14),
                  border: Border(right: BorderSide(color: FxMasterC.border)),
                ),
                child: AnimatedBuilder(
                  animation: _tabs,
                  builder: (context, _) {
                    final selected = _tabs.index;
                    return Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 16, 20),
                          child: Row(
                            mainAxisAlignment: compact
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(13),
                                  gradient: const LinearGradient(
                                    colors: <Color>[
                                      FxMasterC.primary,
                                      Color(0xFF9B7CFF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.restaurant_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(width: 11),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'FINAL FX',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'TV Manager',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!compact)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: FxMasterC.green.withOpacity(.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: FxMasterC.green.withOpacity(.18),
                                ),
                              ),
                              child: const Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: FxMasterC.green,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'SYSTEM ONLINE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: labels.length,
                            itemBuilder: (context, index) {
                              final active = selected == index;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Material(
                                  color: active
                                      ? FxMasterC.primary.withOpacity(.14)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(11),
                                    onTap: () => _tabs.animateTo(index),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        border: Border.all(
                                          color: active
                                              ? FxMasterC.primary.withOpacity(
                                                  .25,
                                                )
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Icon(
                                            icons[index],
                                            size: 18,
                                            color: active
                                                ? Colors.white
                                                : Colors.white54,
                                          ),
                                          if (!compact)
                                            const SizedBox(width: 12),
                                          if (!compact)
                                            Expanded(
                                              child: Text(
                                                labels[index],
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: active
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: active
                                                      ? Colors.white
                                                      : Colors.white60,
                                                ),
                                              ),
                                            ),
                                          if (active)
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: FxMasterC.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!compact)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            child: Text(
                              'FINAL FX • Restaurant & TV Control',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(.32),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 72,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 16 : 26,
                      ),
                      decoration: const BoxDecoration(
                        color: FxMasterC.card2,
                        border: Border(
                          bottom: BorderSide(color: FxMasterC.border),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _tabs,
                              builder: (context, _) => Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    labels[_tabs.index],
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (!compact) const SizedBox(height: 2),
                                  if (!compact)
                                    Text(
                                      'Manage your restaurant display workspace',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(.42),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (!compact)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: FxMasterC.green.withOpacity(.09),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: FxMasterC.green.withOpacity(.22),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: FxMasterC.green,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: FxMasterC.bg,
                        child: TabBarView(
                          controller: _tabs,
                          children: const <Widget>[
                            _FxOverview(),
                            _FxCategories(),
                            _FxMenu(),
                            _FxOffers(),
                            _FxTemplates(),
                            _FxGroups(),
                            _FxRemote(),
                            _FxQr(),
                            _FxRoles(),
                            _FxAudit(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FxOverview extends StatelessWidget {
  const _FxOverview();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FxMasterDb.menu.snapshots(),
      builder: (context, menuSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FxMasterDb.devices.snapshots(),
          builder: (context, tvSnapshot) {
            final cards = <Widget>[
              _statCard(
                'Menu Items',
                menuSnapshot.data?.docs.length ?? 0,
                Icons.restaurant_menu_rounded,
              ),
              _statCard(
                'TV Devices',
                tvSnapshot.data?.docs.length ?? 0,
                Icons.tv_rounded,
              ),
              _statCard(
                'Online TVs',
                tvSnapshot.data?.docs
                        .where((doc) => doc.data()['status'] == 'online')
                        .length ??
                    0,
                Icons.wifi_rounded,
              ),
            ];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Restaurant Studio',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Menu, offers, TV control and signage workspace.',
                    style: TextStyle(color: Colors.white.withOpacity(.55)),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900 ? 3 : 1;
                      final ratio = constraints.maxWidth < 600 ? 2.0 : 2.8;
                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: ratio,
                        children: cards,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _panel(
                    'Architecture',
                    const Text(
                      'The existing Photos & Videos workflow remains separate. '
                      'This studio adds reusable categories, menu items, offers, '
                      'TV groups, remote commands, QR configuration and audit data.',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Widget _statCard(String title, int value, IconData icon) {
  return _panel(
    title,
    Row(
      children: <Widget>[
        Icon(icon, size: 28, color: FxMasterC.primary),
        const SizedBox(width: 12),
        Text(
          '$value',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _FxCategories extends StatefulWidget {
  const _FxCategories();

  @override
  State<_FxCategories> createState() => _FxCategoriesState();
}

class _FxCategoriesState extends State<_FxCategories> {
  final list = <FxMasterCategory>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await FxMasterDb.categories.orderBy('order').get();
      list
        ..clear()
        ..addAll(snapshot.docs.map(FxMasterCategory.fromDoc));
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit([FxMasterCategory? existing]) async {
    final en = TextEditingController(text: existing?.nameEn ?? '');
    final ar = TextEditingController(text: existing?.nameAr ?? '');
    final order = TextEditingController(
      text: '${existing?.order ?? list.length + 1}',
    );
    var active = existing?.active ?? true;
    var highlight = existing?.highlight ?? true;
    var color = existing?.color ?? 'Purple';
    Timer? translateTimer;
    var lastArabic = existing?.nameAr ?? '';

    Future<void> translateArabic() async {
      final value = await fxMasterTranslateArabic(en.text);
      if (!mounted || value == null) return;
      if (ar.text.trim().isEmpty || ar.text.trim() == lastArabic) {
        ar.text = value;
        lastArabic = value;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              backgroundColor: FxMasterC.card2,
              title: Text(existing == null ? 'Add Category' : 'Edit Category'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: en,
                        decoration: const InputDecoration(
                          labelText: 'Category Name – English',
                        ),
                        onChanged: (_) {
                          translateTimer?.cancel();
                          translateTimer = Timer(
                            const Duration(milliseconds: 650),
                            () async {
                              await translateArabic();
                              if (dialogContext.mounted) setDialog(() {});
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ar,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'اسم الفئة – Arabic',
                          helperText: 'Automatic Arabic; editable.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: order,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Display Order',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: color,
                        decoration: const InputDecoration(
                          labelText: 'TV Highlight Color',
                        ),
                        items: fxCategoryColors
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialog(() => color = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: highlight,
                        title: const Text('Highlight on TV'),
                        onChanged: (value) {
                          setDialog(() => highlight = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        title: const Text('Active'),
                        onChanged: (value) {
                          setDialog(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final nameEn = en.text.trim();
                    final nameAr = ar.text.trim();
                    if (nameEn.isEmpty || nameAr.isEmpty) return;

                    final item = FxMasterCategory(
                      id: existing?.id ?? fxMasterId(),
                      nameEn: nameEn,
                      nameAr: nameAr,
                      order: int.tryParse(order.text.trim()) ?? list.length + 1,
                      active: active,
                      highlight: highlight,
                      color: color,
                    );

                    await FxMasterDb.categories
                        .doc(item.id)
                        .set(item.toMap(), SetOptions(merge: true));
                    await fxMasterAudit(
                      existing == null ? 'create' : 'update',
                      'category',
                      item.nameEn,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save Category'),
                ),
              ],
            );
          },
        );
      },
    );

    translateTimer?.cancel();
    en.dispose();
    ar.dispose();
    order.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return _fxMasterListPage(
      'Categories',
      'Create once and reuse on every menu item.',
      FilledButton.icon(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = list[index];
                return _fxDataCard(
                  item.nameEn,
                  item.nameAr,
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      if (item.highlight) _fxPill('TV ${item.color}'),
                      _fxPill(item.active ? 'Active' : 'Hidden'),
                      IconButton(
                        onPressed: () => _edit(item),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        onPressed: () async {
                          await FxMasterDb.categories.doc(item.id).delete();
                          await _load();
                        },
                        color: FxMasterC.red,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _FxMenu extends StatefulWidget {
  const _FxMenu();

  @override
  State<_FxMenu> createState() => _FxMenuState();
}

class _FxMenuState extends State<_FxMenu> {
  final list = <FxMasterMenuItem>[];
  final categories = <FxMasterCategory>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>(
        <Future<QuerySnapshot<Map<String, dynamic>>>>[
          FxMasterDb.menu.orderBy('nameEn').get(),
          FxMasterDb.categories.orderBy('order').get(),
        ],
      );
      list
        ..clear()
        ..addAll(results[0].docs.map(FxMasterMenuItem.fromDoc));
      categories
        ..clear()
        ..addAll(results[1].docs.map(FxMasterCategory.fromDoc));
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit([FxMasterMenuItem? existing]) async {
    final en = TextEditingController(text: existing?.nameEn ?? '');
    final ar = TextEditingController(text: existing?.nameAr ?? '');
    final price = TextEditingController(
      text: existing == null ? '' : existing.price.toString(),
    );
    final kcal = TextEditingController(
      text: existing == null ? '' : '${existing.calories}',
    );

    var categoryId = existing?.categoryId ?? '';
    var allergens = List<String>.from(existing?.allergens ?? const <String>[]);
    var badges = List<String>.from(existing?.badges ?? const <String>[]);
    var active = existing?.active ?? true;
    var mode = existing?.displayMode ?? 'Menu Display';
    var style = existing?.nameStyle ?? '3D Glow';
    var color = existing?.nameColor ?? 'White';
    var photo = existing?.photoUrl ?? '';
    var video = existing?.videoUrl ?? '';
    Timer? translateTimer;
    var lastArabic = existing?.nameAr ?? '';

    Future<void> translateArabic() async {
      final value = await fxMasterTranslateArabic(en.text);
      if (!mounted || value == null) return;
      if (ar.text.trim().isEmpty || ar.text.trim() == lastArabic) {
        ar.text = value;
        lastArabic = value;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            final activeCategories = categories
                .where((category) => category.active)
                .toList();

            return AlertDialog(
              backgroundColor: FxMasterC.card2,
              title: Text(
                existing == null ? 'Add Menu Item' : 'Edit Menu Item',
              ),
              content: SizedBox(
                width: 720,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: en,
                        decoration: const InputDecoration(
                          labelText: 'Item Name – English',
                        ),
                        onChanged: (_) {
                          translateTimer?.cancel();
                          translateTimer = Timer(
                            const Duration(milliseconds: 650),
                            () async {
                              await translateArabic();
                              if (dialogContext.mounted) setDialog(() {});
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ar,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'اسم الصنف – Arabic',
                          helperText: 'Automatic Arabic; editable.',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: price,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Final Price (SAR)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: kcal,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Calories (kcal)',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: categoryId.isEmpty ? null : categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: activeCategories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category.id,
                                child: Row(
                                  children: <Widget>[
                                    Expanded(child: Text(category.nameEn)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          category.nameAr,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialog(() => categoryId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Allergens',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: fxAllergens
                            .map(
                              (item) => FilterChip(
                                label: Text(item),
                                selected: allergens.contains(item),
                                onSelected: (value) {
                                  setDialog(() {
                                    if (value && !allergens.contains(item)) {
                                      allergens.add(item);
                                    }
                                    if (!value) allergens.remove(item);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Badges',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: fxBadges
                            .map(
                              (item) => FilterChip(
                                label: Text(item),
                                selected: badges.contains(item),
                                onSelected: (value) {
                                  setDialog(() {
                                    if (value && !badges.contains(item)) {
                                      badges.add(item);
                                    }
                                    if (!value) badges.remove(item);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: mode,
                        decoration: const InputDecoration(
                          labelText: 'TV Display Mode',
                        ),
                        items: fxDisplayModes
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialog(() => mode = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: style,
                        decoration: const InputDecoration(
                          labelText: 'Name Style',
                        ),
                        items: fxNameStyles
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialog(() => style = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: color,
                        decoration: const InputDecoration(
                          labelText: 'Name Color',
                        ),
                        items: fxNameColors
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setDialog(() => color = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () async {
                              final file = await FilePicker.pickFile(
                                type: FileType.image,
                              );
                              if (file == null) {
                                return;
                              }
                              final url = await fxMasterUpload(
                                file,
                                'restaurant/menu/photos',
                              );
                              if (url != null) {
                                setDialog(() => photo = url);
                              }
                            },
                            icon: const Icon(Icons.image_rounded),
                            label: Text(
                              photo.isEmpty ? 'Add Photo' : 'Photo Selected',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final file = await FilePicker.pickFile(
                                type: FileType.video,
                              );
                              if (file == null) {
                                return;
                              }
                              final url = await fxMasterUpload(
                                file,
                                'restaurant/menu/videos',
                              );
                              if (url != null) {
                                setDialog(() => video = url);
                              }
                            },
                            icon: const Icon(Icons.video_file_rounded),
                            label: Text(
                              video.isEmpty ? 'Add Video' : 'Video Selected',
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        title: const Text('Available'),
                        onChanged: (value) {
                          setDialog(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final parsedPrice = double.tryParse(price.text.trim());
                    final parsedCalories = int.tryParse(kcal.text.trim()) ?? 0;
                    if (en.text.trim().isEmpty ||
                        ar.text.trim().isEmpty ||
                        parsedPrice == null ||
                        categoryId.isEmpty) {
                      return;
                    }

                    final category = activeCategories.firstWhere(
                      (item) => item.id == categoryId,
                      orElse: () => categories.firstWhere(
                        (item) => item.id == categoryId,
                      ),
                    );

                    final item = FxMasterMenuItem(
                      id: existing?.id ?? fxMasterId(),
                      nameEn: en.text.trim(),
                      nameAr: ar.text.trim(),
                      price: parsedPrice,
                      calories: parsedCalories,
                      categoryId: category.id,
                      categoryName: category.nameEn,
                      allergens: allergens,
                      badges: badges,
                      photoUrl: photo,
                      videoUrl: video,
                      active: active,
                      displayMode: mode,
                      nameStyle: style,
                      nameColor: color,
                    );

                    await FxMasterDb.menu
                        .doc(item.id)
                        .set(item.toMap(), SetOptions(merge: true));
                    await fxMasterAudit(
                      existing == null ? 'create' : 'update',
                      'menu_item',
                      item.nameEn,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save Item'),
                ),
              ],
            );
          },
        );
      },
    );

    translateTimer?.cancel();
    en.dispose();
    ar.dispose();
    price.dispose();
    kcal.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return _fxMasterListPage(
      'Menu Items',
      'Final SAR price + reusable category + premium TV styling.',
      FilledButton.icon(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Menu Item'),
      ),
      loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = list[index];
                return _fxDataCard(
                  item.nameEn,
                  '${item.nameAr} • ${item.categoryName} • '
                  'SAR ${item.price.toStringAsFixed(2)} • ${item.calories} kcal',
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      _fxPill(item.active ? 'Available' : 'Hidden'),
                      IconButton(
                        onPressed: () => _edit(item),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        onPressed: () async {
                          await FxMasterDb.menu.doc(item.id).delete();
                          await _load();
                        },
                        color: FxMasterC.red,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _FxOffers extends StatefulWidget {
  const _FxOffers();

  @override
  State<_FxOffers> createState() => _FxOffersState();
}

class _FxOffersState extends State<_FxOffers> {
  final list = <FxMasterOffer>[];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await FxMasterDb.offers.orderBy('startDate').get();
      list
        ..clear()
        ..addAll(snapshot.docs.map(FxMasterOffer.fromDoc));
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit([FxMasterOffer? existing]) async {
    final en = TextEditingController(text: existing?.nameEn ?? '');
    final ar = TextEditingController(text: existing?.nameAr ?? '');
    final oldPrice = TextEditingController(
      text: existing == null ? '' : existing.oldPrice.toString(),
    );
    final offerPrice = TextEditingController(
      text: existing == null ? '' : existing.offerPrice.toString(),
    );

    var startDate = existing?.startDate ?? DateTime.now();
    var endDate =
        existing?.endDate ?? DateTime.now().add(const Duration(days: 7));
    var active = existing?.active ?? true;
    var imageUrl = existing?.imageUrl ?? '';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              backgroundColor: FxMasterC.card2,
              title: Text(existing == null ? 'Add Offer' : 'Edit Offer'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      TextField(
                        controller: en,
                        decoration: const InputDecoration(
                          labelText: 'Offer Name – English',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ar,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'اسم العرض – Arabic',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: oldPrice,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Old Price',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: offerPrice,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Offer Price',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start Date'),
                        trailing: Text(_date(startDate)),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: startDate,
                          );
                          if (selected != null) {
                            setDialog(() => startDate = selected);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End Date'),
                        trailing: Text(_date(endDate)),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: dialogContext,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            initialDate: endDate,
                          );
                          if (selected != null) {
                            setDialog(() => endDate = selected);
                          }
                        },
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final file = await FilePicker.pickFile(
                            type: FileType.image,
                          );
                          if (file == null) return;
                          final url = await fxMasterUpload(
                            file,
                            'restaurant/offers',
                          );
                          if (url != null) {
                            setDialog(() => imageUrl = url);
                          }
                        },
                        icon: const Icon(Icons.image_rounded),
                        label: Text(
                          imageUrl.isEmpty
                              ? 'Add Offer Image'
                              : 'Image Selected',
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active,
                        title: const Text('Active'),
                        onChanged: (value) {
                          setDialog(() => active = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final oldValue = double.tryParse(oldPrice.text.trim());
                    final offerValue = double.tryParse(offerPrice.text.trim());

                    if (en.text.trim().isEmpty ||
                        ar.text.trim().isEmpty ||
                        oldValue == null ||
                        offerValue == null) {
                      return;
                    }

                    final item = FxMasterOffer(
                      id: existing?.id ?? fxMasterId(),
                      nameEn: en.text.trim(),
                      nameAr: ar.text.trim(),
                      oldPrice: oldValue,
                      offerPrice: offerValue,
                      imageUrl: imageUrl,
                      startDate: startDate,
                      endDate: endDate,
                      active: active,
                    );

                    await FxMasterDb.offers
                        .doc(item.id)
                        .set(item.toMap(), SetOptions(merge: true));
                    await fxMasterAudit(
                      existing == null ? 'create' : 'update',
                      'offer',
                      item.nameEn,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save Offer'),
                ),
              ],
            );
          },
        );
      },
    );

    en.dispose();
    ar.dispose();
    oldPrice.dispose();
    offerPrice.dispose();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return _fxMasterListPage(
      'Offers',
      'Date-based promotions with start and expiry dates.',
      FilledButton.icon(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Offer'),
      ),
      loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = list[index];
                return _fxDataCard(
                  item.nameEn,
                  '${item.nameAr} • SAR '
                  '${item.oldPrice.toStringAsFixed(2)} → '
                  'SAR ${item.offerPrice.toStringAsFixed(2)} • '
                  '${_date(item.startDate)} - ${_date(item.endDate)}',
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      _fxPill(item.active ? 'Active' : 'Hidden'),
                      IconButton(
                        onPressed: () => _edit(item),
                        icon: const Icon(Icons.edit_rounded),
                      ),
                      IconButton(
                        onPressed: () async {
                          await FxMasterDb.offers.doc(item.id).delete();
                          await _load();
                        },
                        color: FxMasterC.red,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _FxTemplates extends StatelessWidget {
  const _FxTemplates();

  static const _presets = <String>[
    'Classic Hero',
    'Food Grid',
    'Special Offer',
    'Combo Deals',
    'Category Showcase',
    'New Arrival',
    'Breakfast',
    'Dessert',
    'Drinks',
    'Good Food • Good Mood',
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FxMasterDb.templates.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        return _fxMasterListPage(
          'TV Templates',
          'Choose a layout and preview how it can look on your restaurant TV.',
          FilledButton.icon(
            onPressed: () => _showScaffoldInfo(
              context,
              'TV Templates',
              _presets,
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
          snapshot.hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Templates could not be loaded. Check the Firebase connection and try again.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                )
              : snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : docs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.dashboard_customize_rounded,
                                  size: 44,
                                  color: FxMasterC.primary,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No templates found yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Template cards will appear here when they are added to the shared collection.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1000 ? 2 : 1;
                            final cellWidth = (constraints.maxWidth -
                                    (columns - 1) * 16) /
                                columns;
                            // 16:9 artwork plus room for title, category and action.
                            final tileHeight = cellWidth * 9 / 16 + 130;
                            final aspectRatio = cellWidth / tileHeight;

                            return GridView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                              itemCount: docs.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data();
                                final rawName = (data['name'] ??
                                        data['title'] ??
                                        doc.id)
                                    .toString()
                                    .trim();
                                final name = rawName.isEmpty ? doc.id : rawName;
                                final layout = (data['layout'] ??
                                        data['category'] ??
                                        data['type'] ??
                                        'template')
                                    .toString();
                                final imageValue = data['previewUrl'] ??
                                    data['thumbnailUrl'] ??
                                    data['imageUrl'] ??
                                    data['photoUrl'];
                                final imageUrl = imageValue?.toString().trim();

                                return _FxTemplateCard(
                                  name: name,
                                  layout: layout,
                                  imageUrl: imageUrl == null || imageUrl.isEmpty
                                      ? null
                                      : imageUrl,
                                  onPreview: () => _showFxTemplatePreview(
                                    context,
                                    name: name,
                                    layout: layout,
                                    imageUrl: imageUrl == null || imageUrl.isEmpty
                                        ? null
                                        : imageUrl,
                                  ),
                                );
                              },
                            );
                          },
                        ),
        );
      },
    );
  }
}

class _FxTemplateCard extends StatelessWidget {
  const _FxTemplateCard({
    required this.name,
    required this.layout,
    required this.imageUrl,
    required this.onPreview,
  });

  final String name;
  final String layout;
  final String? imageUrl;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FxMasterC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FxMasterC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _FxTemplateArtwork(
              name: name,
              layout: layout,
              imageUrl: imageUrl,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _fxPill(layout.isEmpty ? 'template' : layout),
            ],
          ),
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_rounded, size: 17),
              label: const Text('Preview template'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: FxMasterC.primary.withOpacity(.55)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showFxTemplatePreview(
  BuildContext context, {
  required String name,
  required String layout,
  required String? imageUrl,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: FxMasterC.card2,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TV template preview • $layout',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 400,
                child: _FxTemplateArtwork(
                  name: name,
                  layout: layout,
                  imageUrl: imageUrl,
                  expanded: true,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.tv_rounded,
                    color: FxMasterC.primary,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Illustrative layout preview. Connect menu photos and content to create a live menu preview.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FxTemplateArtwork extends StatelessWidget {
  const _FxTemplateArtwork({
    required this.name,
    required this.layout,
    required this.imageUrl,
    this.expanded = false,
  });

  final String name;
  final String layout;
  final String? imageUrl;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final key = '$name $layout'.toLowerCase();
    final accent = key.contains('offer')
        ? FxMasterC.red
        : key.contains('drink')
            ? const Color(0xFF34C7E8)
            : key.contains('dessert') || key.contains('breakfast')
                ? FxMasterC.gold
                : FxMasterC.primary;
    final isOffer = key.contains('offer');
    final isGrid = key.contains('grid') || key.contains('combo');
    final isCategories = key.contains('categor');
    final isDrinks = key.contains('drink');
    final isDessert = key.contains('dessert');
    final isBreakfast = key.contains('breakfast');
    final isBrand = key.contains('brand') || key.contains('mood');

    final items = isDrinks
        ? const <(String, String, String)>[
            ('🥤', 'COLD DRINKS', 'SAR 8'),
            ('☕', 'HOT COFFEE', 'SAR 10'),
            ('🧋', 'SPECIAL', 'SAR 14'),
          ]
        : isDessert
            ? const <(String, String, String)>[
                ('🍰', 'CHEESECAKE', 'SAR 18'),
                ('🍩', 'DONUTS', 'SAR 9'),
                ('🍮', 'PUDDING', 'SAR 12'),
              ]
            : isBreakfast
                ? const <(String, String, String)>[
                    ('🍳', 'EGGS MEAL', 'SAR 16'),
                    ('🥞', 'PANCAKES', 'SAR 19'),
                    ('🥐', 'BAKERY', 'SAR 8'),
                  ]
                : isCategories
                    ? const <(String, String, String)>[
                        ('🍔', 'BURGERS', 'EXPLORE'),
                        ('🍕', 'PIZZA', 'EXPLORE'),
                        ('🍗', 'CHICKEN', 'EXPLORE'),
                      ]
                    : const <(String, String, String)>[
                        ('🍔', 'CLASSIC BURGER', 'SAR 24'),
                        ('🍕', 'FAMILY PIZZA', 'SAR 39'),
                        ('🍗', 'CRISPY CHICKEN', 'SAR 29'),
                      ];

    final heroEmoji = isDrinks
        ? '🥤'
        : isDessert
            ? '🍰'
            : isBreakfast
                ? '🥞'
                : isBrand
                    ? '🍽️'
                    : '🍗';
    final headline = isDrinks
        ? 'FRESH & COOL'
        : isDessert
            ? 'SWEET MOMENTS'
            : isBreakfast
                ? 'GOOD MORNING'
                : isBrand
                    ? 'GOOD FOOD.\nGOOD MOOD.'
                    : 'SIGNATURE\nFLAVOUR';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF24203B), Color(0xFF090B12)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    const Color(0xFF07090E).withOpacity(.94),
                    const Color(0xFF10131B).withOpacity(.72),
                    accent.withOpacity(.26),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(expanded ? 28 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.restaurant_rounded,
                        size: expanded ? 23 : 15,
                        color: accent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'FINAL FX',
                        style: TextStyle(
                          fontSize: expanded ? 15 : 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: expanded ? 12 : 7,
                          vertical: expanded ? 7 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.18),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: accent.withOpacity(.45)),
                        ),
                        child: Text(
                          layout.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: expanded ? 12 : 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: expanded ? 22 : 10),
                  Expanded(
                    child: isOffer
                        ? Row(
                            children: <Widget>[
                              Container(
                                width: expanded ? 150 : 75,
                                height: expanded ? 150 : 75,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: accent.withOpacity(.28),
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '30%\nOFF',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: expanded ? 30 : 17,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: expanded ? 26 : 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'LIMITED TIME',
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: expanded ? 14 : 9,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: expanded ? 9 : 4),
                                    Text(
                                      'SPECIAL OFFER',
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: expanded ? 30 : 17,
                                        height: 1.0,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: expanded ? 10 : 4),
                                    Text(
                                      'Big flavour. Better value.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: expanded ? 15 : 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (expanded)
                                const Text('🍔', style: TextStyle(fontSize: 74)),
                            ],
                          )
                        : isGrid || isCategories || isDrinks || isDessert || isBreakfast
                            ? Row(
                                children: <Widget>[
                                  for (final item in items)
                                    Expanded(
                                      child: _FxTemplateMiniItem(
                                        emoji: item.$1,
                                        title: item.$2,
                                        subtitle: item.$3,
                                        accent: accent,
                                        expanded: expanded,
                                      ),
                                    ),
                                ],
                              )
                            : Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: expanded ? 12 : 7,
                                            vertical: expanded ? 7 : 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withOpacity(.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isBrand ? 'OUR PROMISE' : 'CHEF’S PICK',
                                            style: TextStyle(
                                              color: accent,
                                              fontSize: expanded ? 12 : 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: expanded ? 14 : 7),
                                        Text(
                                          headline,
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: expanded ? 39 : 20,
                                            height: .98,
                                            letterSpacing: -.4,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: expanded ? 12 : 6),
                                        Text(
                                          'Made fresh. Served with love.',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: expanded ? 16 : 9,
                                          ),
                                        ),
                                        SizedBox(height: expanded ? 14 : 7),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: expanded ? 14 : 8,
                                            vertical: expanded ? 9 : 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent,
                                            borderRadius: BorderRadius.circular(7),
                                          ),
                                          child: Text(
                                            'ORDER NOW  →',
                                            style: TextStyle(
                                              fontSize: expanded ? 12 : 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: expanded ? 18 : 8),
                                  Container(
                                    width: expanded ? 230 : 105,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withOpacity(.13),
                                      border: Border.all(
                                        color: accent.withOpacity(.35),
                                        width: expanded ? 3 : 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        heroEmoji,
                                        style: TextStyle(
                                          fontSize: expanded ? 116 : 55,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FxTemplateMiniItem extends StatelessWidget {
  const _FxTemplateMiniItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.expanded,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: expanded ? 7 : 3),
      padding: EdgeInsets.all(expanded ? 14 : 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E15).withOpacity(.72),
        borderRadius: BorderRadius.circular(expanded ? 14 : 8),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                emoji,
                style: TextStyle(fontSize: expanded ? 62 : 30),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: expanded ? 13 : 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: expanded ? 12 : 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FxGroups extends StatelessWidget {
  const _FxGroups();

  @override
  Widget build(BuildContext context) {
    return _simpleCollection(
      'TV Groups',
      FxMasterDb.groups,
      Icons.groups_rounded,
      const <String>['Active', 'Hidden'],
    );
  }
}

class _FxRemote extends StatefulWidget {
  const _FxRemote();

  @override
  State<_FxRemote> createState() => _FxRemoteState();
}

class _FxRemoteState extends State<_FxRemote> {
  bool groupMode = true;
  String target = '';
  String note = '';
  final groups = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final tvs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>(
        <Future<QuerySnapshot<Map<String, dynamic>>>>[
          FxMasterDb.groups.orderBy('name').get(),
          FxMasterDb.devices.orderBy('name').get(),
        ],
      );
      groups
        ..clear()
        ..addAll(results[0].docs);
      tvs
        ..clear()
        ..addAll(results[1].docs);

      if (target.isEmpty) {
        if (groupMode && groups.isNotEmpty) {
          target = groups.first.id;
        } else if (!groupMode && tvs.isNotEmpty) {
          target = tvs.first.id;
        }
      }
    } catch (_) {}

    if (mounted) setState(() {});
  }

  Future<void> _send(String command) async {
    if (target.isEmpty) return;

    await FxMasterDb.commands.add(<String, dynamic>{
      'targetId': target,
      'targetType': groupMode ? 'group' : 'device',
      'command': command,
      'note': note.trim(),
      'processed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'sourceUid': FirebaseAuth.instance.currentUser?.uid ?? '',
    });

    await fxMasterAudit(
      'remote',
      groupMode ? 'tv_group' : 'tv_device',
      '$command → $target',
    );

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Command sent: $command')));
    }
  }

  Future<void> _emergency(bool enabled) async {
    await FxMasterDb.emergency.set(<String, dynamic>{
      'enabled': enabled,
      'title': enabled ? 'EMERGENCY' : '',
      'message': enabled ? 'Please follow staff instructions.' : '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await fxMasterAudit(
      enabled ? 'emergency_on' : 'emergency_off',
      'emergency',
      enabled ? 'Emergency display enabled' : 'Emergency display disabled',
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = groupMode ? groups : tvs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'TV Remote',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('Group')),
              ButtonSegment<bool>(value: false, label: Text('TV')),
            ],
            selected: <bool>{groupMode},
            onSelectionChanged: (selection) {
              groupMode = selection.first;
              target = '';
              _load();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: target.isEmpty ? null : target,
            items: list
                .map(
                  (doc) => DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(doc.data()['name']?.toString() ?? doc.id),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => target = value ?? '');
            },
            decoration: const InputDecoration(labelText: 'Target'),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Command note'),
            onChanged: (value) => note = value,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                <String>[
                      'Play',
                      'Pause',
                      'Previous',
                      'Next',
                      'Refresh',
                      'Mute',
                      'Unmute',
                      'Restart',
                    ]
                    .map(
                      (command) => FilledButton.tonal(
                        onPressed: () => _send(command),
                        child: Text(command),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),
          _panel(
            'Emergency Display',
            Wrap(
              spacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: () => _emergency(true),
                  child: const Text('Emergency ON'),
                ),
                OutlinedButton(
                  onPressed: () => _emergency(false),
                  child: const Text('Emergency OFF'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FxQr extends StatefulWidget {
  const _FxQr();

  @override
  State<_FxQr> createState() => _FxQrState();
}

class _FxQrState extends State<_FxQr> {
  final urlController = TextEditingController();
  bool enabled = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await FxMasterDb.qr.get();
      final data = snapshot.data() ?? <String, dynamic>{};
      urlController.text = data['url']?.toString() ?? '';
      enabled = data['enabled'] != false;
    } catch (_) {}

    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    await FxMasterDb.qr.set(<String, dynamic>{
      'url': urlController.text.trim(),
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('QR settings saved.')));
    }
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = urlController.text.trim().isEmpty
        ? 'https://example.com/menu'
        : urlController.text.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'QR Menu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: urlController,
            decoration: const InputDecoration(labelText: 'Public Menu URL'),
            onChanged: (_) => setState(() {}),
          ),
          SwitchListTile(
            value: enabled,
            title: const Text('QR Enabled'),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => enabled = value),
          ),
          FilledButton(onPressed: _save, child: const Text('Save QR')),
          const SizedBox(height: 20),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(18),
              child: QrImageView(data: data, size: 240),
            ),
          ),
        ],
      ),
    );
  }
}

class _FxRoles extends StatelessWidget {
  const _FxRoles();

  @override
  Widget build(BuildContext context) {
    return _simpleCollection(
      'Roles',
      FxMasterDb.roles,
      Icons.person_rounded,
      const <String>['owner', 'manager', 'content', 'viewer'],
    );
  }
}

class _FxAudit extends StatelessWidget {
  const _FxAudit();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FxMasterDb.audits
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return _fxDataCard(
              '${data['action'] ?? ''} • ${data['target'] ?? ''}',
              '${data['summary'] ?? ''} • ${data['email'] ?? ''}',
              const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}

Widget _simpleCollection(
  String title,
  CollectionReference<Map<String, dynamic>> collection,
  IconData icon,
  List<String> choices,
) {
  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: collection.snapshots(),
    builder: (context, snapshot) {
      final docs =
          snapshot.data?.docs ??
          const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

      return _fxMasterListPage(
        title,
        'Shared management collection.',
        FilledButton.icon(
          onPressed: () => _showScaffoldInfo(context, title, choices),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add'),
        ),
        ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name = data['name']?.toString().trim();
            final subtitle =
                data['layout']?.toString() ??
                data['role']?.toString() ??
                data['status']?.toString() ??
                '';

            return _fxDataCard(
              name == null || name.isEmpty ? docs[index].id : name,
              subtitle,
              Icon(icon),
            );
          },
        ),
      );
    },
  );
}

Future<void> _showScaffoldInfo(
  BuildContext context,
  String title,
  List<String> choices,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: FxMasterC.card2,
        title: Text('Add $title'),
        content: Text(
          'This section is prepared as the shared data structure. '
          'Available presets: ${choices.join(', ')}.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Widget _fxMasterListPage(
  String title,
  String subtitle,
  Widget action,
  Widget child,
) {
  return Column(
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(.55)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            action,
          ],
        ),
      ),
      Expanded(child: child),
    ],
  );
}

Widget _fxDataCard(String title, String subtitle, Widget trailing) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: FxMasterC.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: FxMasterC.border),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    ),
  );
}

Widget _fxPill(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: FxMasterC.primary.withOpacity(.14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

Widget _panel(String title, Widget child) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: FxMasterC.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: FxMasterC.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

String _date(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
