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
  static const primary = Color(0xFF0F766E);
  static const light = Color(0xFFA996FF);
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
        canvasColor: FxMasterC.card2,
        popupMenuTheme: PopupMenuThemeData(
          color: FxMasterC.card2,
          textStyle: const TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: FxMasterC.border),
          ),
        ),
        colorScheme: Theme.of(context).colorScheme.copyWith(
          brightness: Brightness.dark,
          primary: FxMasterC.primary,
          onPrimary: Colors.white,
          secondary: FxMasterC.gold,
          onSecondary: Colors.white,
          surface: FxMasterC.card,
          onSurface: const Color(0xFFE8EEF4),
        ),
        textTheme: Theme.of(context).textTheme
            .apply(bodyColor: Colors.white, displayColor: Colors.white)
            .copyWith(
              bodyMedium: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: .90),
                fontSize: 14,
              ),
              bodySmall: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
              labelLarge: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: FxMasterC.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF272333),
            disabledForegroundColor: Colors.white54,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white38,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            side: BorderSide(color: FxMasterC.primary.withValues(alpha: .55)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: FxMasterC.light,
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
                chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF18232E),
          selectedColor: const Color(0xFF0F766E),
          disabledColor: const Color(0xFF26313B),
          secondarySelectedColor: const Color(0xFF0F766E),
          labelStyle: const TextStyle(color: Color(0xFFE8EEF4), fontWeight: FontWeight.w600),
          secondaryLabelStyle: const TextStyle(color: Colors.white),
          side: const BorderSide(color: Color(0xFF536273)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
            borderSide: const BorderSide(color: Color(0xFF5EEAD4), width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          labelStyle: const TextStyle(
            color: Color(0xFFD4DCE5),
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF5EEAD4),
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(color: Color(0xFFB0BBC6)),
          helperStyle: const TextStyle(color: Color(0xFFB0BBC6), fontSize: 11),
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
                          padding: EdgeInsets.fromLTRB(compact ? 0 : 18, 18, compact ? 0 : 16, 20),
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
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                        activeTrackColor: const Color(0xFF0F766E),
                        activeThumbColor: Colors.white,
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              content: SizedBox(
                width: MediaQuery.sizeOf(context).width < 760
                    ? MediaQuery.sizeOf(context).width * .82
                    : 720,
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
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFF3F6F9)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: fxAllergens
                            .map(
                              (item) => FilterChip(
                                label: Text(
                                  item,
                                  style: TextStyle(
                                    color: allergens.contains(item) ? Colors.white : const Color(0xFFD4DCE5),
                                    fontWeight: allergens.contains(item) ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: allergens.contains(item),
                                showCheckmark: true,
                                checkmarkColor: Colors.white,
                                selectedColor: const Color(0xFF0F766E),
                                backgroundColor: const Color(0xFF1A2936),
                                side: BorderSide(
                                  color: allergens.contains(item) ? const Color(0xFF5EEAD4) : const Color(0xFF3A4B5B),
                                  width: allergens.contains(item) ? 1.3 : 1,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 3),
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFF3F6F9)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: fxBadges
                            .map(
                              (item) => FilterChip(
                                label: Text(
                                  item,
                                  style: TextStyle(
                                    color: badges.contains(item) ? Colors.white : const Color(0xFFD4DCE5),
                                    fontWeight: badges.contains(item) ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: badges.contains(item),
                                showCheckmark: true,
                                checkmarkColor: Colors.white,
                                selectedColor: const Color(0xFF0F766E),
                                backgroundColor: const Color(0xFF1A2936),
                                side: BorderSide(
                                  color: badges.contains(item) ? const Color(0xFF5EEAD4) : const Color(0xFF3A4B5B),
                                  width: badges.contains(item) ? 1.3 : 1,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                labelPadding: const EdgeInsets.symmetric(horizontal: 3),
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
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE8EEF4),
                              side: const BorderSide(color: Color(0xFF3A4B5B)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE8EEF4),
                              side: const BorderSide(color: Color(0xFF3A4B5B)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
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
                        title: const Text('Available', style: TextStyle(color: Color(0xFFE8EEF4), fontWeight: FontWeight.w600)),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(124, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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

String _fxFriendlyPhotoName(String rawName, int index, {required String fallbackPrefix}) {
  final value = rawName.trim();
  final looksLikeFilename = RegExp(
    r'\.(png|jpe?g|webp|gif|mp4|webm|mov|m4v)$',
    caseSensitive: false,
  ).hasMatch(value) ||
      value.toLowerCase().startsWith('chatgpt image') ||
      value.contains('/') ||
      value.contains(r'\');
  if (value.isEmpty || looksLikeFilename) {
    return '$fallbackPrefix ${index + 1}';
  }
  return value;
}

class _FxTemplateFood {
  const _FxTemplateFood({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.price,
  });

  final String name;
  final String category;
  final String imageUrl;
  final double price;
}

class _FxTemplates extends StatefulWidget {
  const _FxTemplates();

  @override
  State<_FxTemplates> createState() => _FxTemplatesState();
}

class _FxTemplatesState extends State<_FxTemplates> {
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

  static const _layoutByPreset = <String, String>{
    'Classic Hero': 'hero',
    'Food Grid': 'grid',
    'Special Offer': 'offer',
    'Combo Deals': 'combo',
    'Category Showcase': 'categories',
    'New Arrival': 'new',
    'Breakfast': 'breakfast',
    'Dessert': 'dessert',
    'Drinks': 'drinks',
    'Good Food • Good Mood': 'brand',
  };

  List<_FxTemplateFood> _foods = const <_FxTemplateFood>[];
  String? _offerImageUrl;
  bool _loadingPhotos = true;
  bool _savingSelection = false;
  bool _addingTemplate = false;
  String? _photoLoadMessage;
  String? _selectedTemplateId;
  String? _selectedTemplateName;

  @override
  void initState() {
    super.initState();
    _loadPreviewPhotos();
    _loadCurrentTemplate();
  }

  Future<void> _loadCurrentTemplate() async {
    try {
      final doc = await FxMasterDb.db
          .collection('display_config')
          .doc('current')
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _selectedTemplateId = data['selectedTemplateId']?.toString();
        _selectedTemplateName = data['selectedTemplateName']?.toString();
      });
    } catch (_) {
      // The Templates page remains usable if read access to the optional
      // active-template setting has not been granted yet.
    }
  }

  Future<bool> _chooseTemplate({
    required String templateId,
    required String name,
    required String layout,
  }) async {
    if (_savingSelection) return false;
    if (_selectedTemplateId == templateId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" is already the active default template.')),
        );
      }
      return true;
    }

    setState(() => _savingSelection = true);
    try {
      // Persist a single shared default selection. The TV player can consume
      // display_config/current to render this layout when player integration
      // is enabled in the TV client.
      await FxMasterDb.db.collection('display_config').doc('current').set(
        <String, dynamic>{
          'selectedTemplateId': templateId,
          'selectedTemplateName': name,
          'selectedTemplateLayout': layout,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      await fxMasterAudit('select', 'display_template', '$name ($layout)');
      if (!mounted) return false;
      setState(() {
        _selectedTemplateId = templateId;
        _selectedTemplateName = name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" saved as the active default template.')),
      );
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Template selection could not be saved. Check Firestore write permissions and try again.',
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _savingSelection = false);
    }
  }

  Future<void> _addTemplate() async {
    if (_addingTemplate) return;
    final nameController = TextEditingController();
    var selectedPreset = _presets.first;
    String? validationMessage;
    Map<String, String>? result;

    try {
      result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: FxMasterC.card2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add TV template'),
            content: SizedBox(
              width: 430,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Create a reusable layout preset. You can preview it and set it as the active default after saving.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Template name',
                      hintText: 'e.g. Weekend Family Combo',
                      prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                    ),
                    onChanged: (_) {
                      if (validationMessage != null) {
                        setDialogState(() => validationMessage = null);
                      }
                    },
                    onSubmitted: (_) {
                      final value = nameController.text.trim();
                      if (value.isEmpty) {
                        setDialogState(() => validationMessage = 'Enter a template name.');
                        return;
                      }
                      Navigator.pop(dialogContext, <String, String>{
                        'name': value,
                        'preset': selectedPreset,
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                    initialValue: selectedPreset,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Starting layout',
                      prefixIcon: Icon(Icons.dashboard_customize_rounded),
                    ),
                    items: _presets
                        .map((preset) => DropdownMenuItem<String>(
                              value: preset,
                              child: Text(preset, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedPreset = value);
                      }
                    },
                  ),
                  if (validationMessage != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      validationMessage!,
                      style: const TextStyle(color: FxMasterC.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final value = nameController.text.trim();
                  if (value.isEmpty) {
                    setDialogState(() => validationMessage = 'Enter a template name.');
                    return;
                  }
                  Navigator.pop(dialogContext, <String, String>{
                    'name': value,
                    'preset': selectedPreset,
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Create template'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
    }

    if (result == null) return;
    final name = (result['name'] ?? '').trim();
    final preset = result['preset'] ?? _presets.first;
    final layout = _layoutByPreset[preset] ?? 'hero';
    if (name.isEmpty) return;

    setState(() => _addingTemplate = true);
    try {
      await FxMasterDb.templates.add(<String, dynamic>{
        'name': name,
        'layout': layout,
        'category': layout,
        'type': layout,
        'previewUrl': '',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });
      await fxMasterAudit('create', 'display_template', '$name ($layout)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "$name" created. You can now preview or select it.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Template could not be created. Check Firestore write permissions and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingTemplate = false);
    }
  }

  // Load menu/offer images once on entering the Templates tab. We do not add
  // another permanent Firestore listener, keeping reads lower and previews
  // based on real images already uploaded by the restaurant.
  Future<void> _loadPreviewPhotos() async {
    if (mounted) {
      setState(() {
        _loadingPhotos = true;
        _photoLoadMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        FxMasterDb.menu.limit(60).get(),
        FxMasterDb.offers.limit(30).get(),
        FxMasterDb.categories.limit(100).get(),
      ]);
      final menuSnapshot = results[0];
      final offerSnapshot = results[1];
      final categorySnapshot = results[2];

      final categoryNamesById = <String, String>{};
      for (final categoryDoc in categorySnapshot.docs) {
        final categoryData = categoryDoc.data();
        final nameEn = (categoryData['nameEn'] ?? '').toString().trim();
        final nameAr = (categoryData['nameAr'] ?? '').toString().trim();
        final readableName = nameEn.isNotEmpty ? nameEn : nameAr;
        if (readableName.isNotEmpty) categoryNamesById[categoryDoc.id] = readableName;
      }

      final photos = <_FxTemplateFood>[];
      for (final doc in menuSnapshot.docs) {
        final data = doc.data();
        final imageUrl = (data['photoUrl'] ??
                data['imageUrl'] ??
                data['thumbnailUrl'] ??
                data['imageURL'] ??
                data['image'] ??
                data['pictureUrl'] ??
                '')
            .toString()
            .trim();
        if (imageUrl.isEmpty) continue;

        final categoryId = (data['categoryId'] ?? '').toString().trim();
        final rawCategory = (data['categoryName'] ?? data['category'] ?? '')
            .toString()
            .trim();
        final category = categoryNamesById[categoryId] ??
            categoryNamesById[rawCategory] ??
            rawCategory;
        final rawName = (data['nameEn'] ?? data['name'] ?? data['title'] ?? '')
            .toString();
        final priceValue = data['price'];
        final price = priceValue is num ? priceValue.toDouble() : 0.0;
        if (data['active'] == false) continue;

        photos.add(_FxTemplateFood(
          name: _fxFriendlyPhotoName(
            rawName,
            photos.length,
            fallbackPrefix: 'Menu item',
          ),
          category: category,
          imageUrl: imageUrl,
          price: price,
        ));
      }

      // Use the TV Photo Manager gallery as a fallback only for general
      // layouts. Category-specific layouts never receive these photos.
      if (photos.length < 3) {
        try {
          final mediaSnapshot = await FxMasterDb.db
              .collection('tv_media')
              .where('type', isEqualTo: 'image')
              .limit(40)
              .get();
          final seenUrls = photos.map((photo) => photo.imageUrl).toSet();
          for (final doc in mediaSnapshot.docs) {
            if (photos.length >= 12) break;
            final data = doc.data();
            final url = (data['downloadUrl'] ?? data['photoUrl'] ?? data['imageUrl'] ?? '')
                .toString()
                .trim();
            if (url.isEmpty || seenUrls.contains(url)) continue;
            final rawName = (data['name'] ?? data['title'] ?? doc.id).toString();
            photos.add(_FxTemplateFood(
              name: _fxFriendlyPhotoName(rawName, photos.length, fallbackPrefix: 'Restaurant photo'),
              category: 'Gallery',
              imageUrl: url,
              price: 0,
            ));
            seenUrls.add(url);
          }
        } catch (_) {}
      }

      String? offerPhoto;
      for (final doc in offerSnapshot.docs) {
        final data = doc.data();
        final url = (data['imageUrl'] ?? data['photoUrl'] ?? '').toString().trim();
        if (url.isNotEmpty && data['active'] != false) {
          offerPhoto = url;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _foods = photos;
        _offerImageUrl = offerPhoto;
        _loadingPhotos = false;
        _photoLoadMessage = photos.isEmpty
            ? 'No real photos were found in Menu or the TV photo gallery. Upload food photos, then press Refresh photos.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPhotos = false;
        _photoLoadMessage = 'Could not load menu photos. Check Firebase permissions/connection, then press Refresh photos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FxMasterDb.templates.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        return _fxMasterListPage(
          'TV Templates',
          'Preview a layout, then select it to save your active default template.',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _loadingPhotos ? null : _loadPreviewPhotos,
                icon: _loadingPhotos
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Refresh photos'),
              ),
              FilledButton.icon(
                onPressed: _addingTemplate ? null : _addTemplate,
                icon: _addingTemplate
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_rounded, size: 17),
                label: Text(_addingTemplate ? 'Adding...' : 'Add template'),
              ),
            ],
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
              : snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : docs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.dashboard_customize_rounded, size: 44, color: FxMasterC.primary),
                                const SizedBox(height: 12),
                                const Text('No templates found yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 5),
                                const Text('Use Add template to create your first layout preset.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
                                const SizedBox(height: 16),
                                FilledButton.icon(onPressed: _addTemplate, icon: const Icon(Icons.add_rounded), label: const Text('Add template')),
                              ],
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 1000 ? 2 : 1;
                            final cellWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
                            final tileHeight = cellWidth * 9 / 16 + 182;
                            final aspectRatio = cellWidth / tileHeight;

                            return Column(
                              children: <Widget>[
                                if (_photoLoadMessage != null)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: FxMasterC.gold.withValues(alpha: .08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: FxMasterC.gold.withValues(alpha: .25)),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(Icons.photo_library_outlined, color: FxMasterC.gold),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(_photoLoadMessage!, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                                      ],
                                    ),
                                  ),
                                if (_selectedTemplateId != null)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: FxMasterC.green.withValues(alpha: .08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: FxMasterC.green.withValues(alpha: .30)),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(Icons.check_circle_rounded, color: FxMasterC.green, size: 19),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'Active default: ${_selectedTemplateName?.isNotEmpty == true ? _selectedTemplateName : _selectedTemplateId}',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ),
                                        if (_savingSelection) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                      ],
                                    ),
                                  ),
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                                    itemCount: docs.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: aspectRatio,
                                    ),
                                    itemBuilder: (context, index) {
                                      final doc = docs[index];
                                      final data = doc.data();
                                      final rawName = (data['name'] ?? data['title'] ?? doc.id).toString().trim();
                                      final name = rawName.isEmpty ? doc.id : rawName;
                                      final layout = (data['layout'] ?? data['category'] ?? data['type'] ?? 'template').toString();
                                      final imageValue = data['previewUrl'] ?? data['thumbnailUrl'] ?? data['imageUrl'] ?? data['photoUrl'];
                                      final imageUrl = imageValue?.toString().trim();
                                      final templateImage = imageUrl == null || imageUrl.isEmpty ? null : imageUrl;
                                      final selected = _selectedTemplateId == doc.id;

                                      Future<bool> selectThis() => _chooseTemplate(
                                            templateId: doc.id,
                                            name: name,
                                            layout: layout,
                                          );

                                      return _FxTemplateCard(
                                        key: ValueKey<String>(doc.id),
                                        name: name,
                                        layout: layout,
                                        imageUrl: templateImage,
                                        foods: _foods,
                                        offerImageUrl: _offerImageUrl,
                                        selected: selected,
                                        selecting: _savingSelection,
                                        onSelect: selectThis,
                                        onPreview: () => _showFxTemplatePreview(
                                          context,
                                          name: name,
                                          layout: layout,
                                          imageUrl: templateImage,
                                          foods: _foods,
                                          offerImageUrl: _offerImageUrl,
                                          onSelect: selectThis,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
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
    super.key,
    required this.name,
    required this.layout,
    required this.imageUrl,
    required this.foods,
    required this.offerImageUrl,
    required this.selected,
    required this.selecting,
    required this.onSelect,
    required this.onPreview,
  });

  final String name;
  final String layout;
  final String? imageUrl;
  final List<_FxTemplateFood> foods;
  final String? offerImageUrl;
  final bool selected;
  final bool selecting;
  final Future<bool> Function() onSelect;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? FxMasterC.green : FxMasterC.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: FxMasterC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(color: FxMasterC.green.withValues(alpha: .08), blurRadius: 16),
              ]
            : const <BoxShadow>[],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: _FxTemplateArtwork(
              name: name,
              layout: layout,
              imageUrl: imageUrl,
              foods: foods,
              offerImageUrl: offerImageUrl,
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
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (selected) ...<Widget>[
                const SizedBox(width: 6),
                _fxStatusPill('ACTIVE', FxMasterC.green),
              ],
              const SizedBox(width: 7),
              _fxPill(layout.isEmpty ? 'template' : layout),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Preview'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: FxMasterC.primary.withValues(alpha: .65)),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: selecting
                      ? null
                      : () async {
                          await onSelect();
                        },
                  icon: selecting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(selected ? Icons.check_circle_rounded : Icons.done_all_rounded, size: 16),
                  label: Text(selected ? 'Selected' : 'Use template', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: FilledButton.styleFrom(
                    backgroundColor: selected ? FxMasterC.green : FxMasterC.primary,
                    foregroundColor: selected ? const Color(0xFF07120C) : Colors.white,
                    disabledBackgroundColor: selected ? FxMasterC.green.withValues(alpha: .35) : const Color(0xFF272333),
                    disabledForegroundColor: selected ? const Color(0xFF07120C) : Colors.white54,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _fxStatusPill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: .36)),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
    ),
  );
}

Future<void> _showFxTemplatePreview(
  BuildContext context, {
  required String name,
  required String layout,
  required String? imageUrl,
  required List<_FxTemplateFood> foods,
  required String? offerImageUrl,
  required Future<bool> Function() onSelect,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: FxMasterC.card2,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
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
                        Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('TV template preview • $layout',
                            style: const TextStyle(color: Colors.white60)),
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
                height: 420,
                child: _FxTemplateArtwork(
                  name: name,
                  layout: layout,
                  imageUrl: imageUrl,
                  foods: foods,
                  offerImageUrl: offerImageUrl,
                  expanded: true,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SizedBox(
                    width: 560,
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.tv_rounded, color: FxMasterC.primary, size: 19),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Category layouts show matching Menu items only. If a matching photo is missing, add it to Menu first.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final saved = await onSelect();
                      if (saved && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                    label: const Text('Use this template'),
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
    required this.foods,
    required this.offerImageUrl,
    this.expanded = false,
  });

  final String name;
  final String layout;
  final String? imageUrl;
  final List<_FxTemplateFood> foods;
  final String? offerImageUrl;
  final bool expanded;

  List<_FxTemplateFood> _photosForTemplate(String key) {
    if (foods.isEmpty) return const <_FxTemplateFood>[];
    final normalized = key.toLowerCase();

    // Category-specific templates must only show genuinely matching Menu
    // items. Generic TV gallery images are intentionally excluded so a
    // chicken image is not displayed in Dessert/Drinks, for example.
    Set<String>? categoryHints;
    if (normalized.contains('dessert')) {
      categoryHints = <String>{
        'dessert', 'sweet', 'cake', 'bakery', 'pastry', 'donut',
        'doughnut', 'ice cream', 'pudding', 'fruit', 'حلويات', 'كعك', 'حلو',
      };
    } else if (normalized.contains('breakfast')) {
      categoryHints = <String>{
        'breakfast', 'brunch', 'morning', 'egg', 'pancake', 'waffle',
        'bakery', 'فطور', 'إفطار',
      };
    } else if (normalized.contains('drink')) {
      categoryHints = <String>{
        'drink', 'beverage', 'juice', 'coffee', 'tea', 'water', 'soda',
        'smoothie', 'مشروبات', 'عصير', 'قهوة', 'شاي',
      };
    }

    if (categoryHints != null) {
      final matched = foods.where((food) {
        if (food.category.toLowerCase() == 'gallery') return false;
        final searchText = '${food.category} ${food.name}'.toLowerCase();
        return categoryHints!.any(searchText.contains);
      }).toList();
      return matched.take(3).toList();
    }

    // For general layouts, show actual menu items first. Use general TV
    // gallery photos only to fill the remaining preview positions.
    final menuPhotos = foods
        .where((food) => food.category.toLowerCase() != 'gallery')
        .toList();
    if (menuPhotos.length >= 3) return menuPhotos.take(3).toList();
    final result = <_FxTemplateFood>[...menuPhotos];
    for (final photo in foods.where((food) => food.category.toLowerCase() == 'gallery')) {
      if (result.length >= 3) break;
      if (!result.any((existing) => existing.imageUrl == photo.imageUrl)) {
        result.add(photo);
      }
    }
    return result;
  }

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
    final isGrid = key.contains('grid') || key.contains('combo') ||
        key.contains('categor') || key.contains('drink') ||
        key.contains('dessert') || key.contains('breakfast');
    final isBrand = key.contains('brand') || key.contains('mood');
    final photoFoods = _photosForTemplate(key);
    final heroPhoto = photoFoods.isNotEmpty ? photoFoods.first.imageUrl : null;
    // Do not reuse an unrelated menu/gallery picture as an offer banner.
    // The card will show its upload placeholder until an Offer image exists.
    final specialOfferPhoto =
        (offerImageUrl?.isNotEmpty == true) ? offerImageUrl : null;
    final fallbackNames = key.contains('drink')
        ? const <String>['Cold Drinks', 'Hot Coffee', 'Fresh Juice']
        : key.contains('dessert')
            ? const <String>['Cheesecake', 'Donuts', 'Dessert']
            : key.contains('breakfast')
                ? const <String>['Eggs Meal', 'Pancakes', 'Bakery']
                : const <String>['Menu Favourite', 'Chef Special', 'Best Seller'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              accent.withValues(alpha: .25),
              const Color(0xFF090B12),
              const Color(0xFF10131B),
            ],
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
                    const Color(0xFF07090E).withValues(alpha: .95),
                    const Color(0xFF10131B).withValues(alpha: .74),
                    accent.withValues(alpha: .32),
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
                      Icon(Icons.restaurant_rounded,
                          size: expanded ? 23 : 15, color: accent),
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
                          color: accent.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: accent.withValues(alpha: .45)),
                        ),
                        child: Text(
                          layout.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: expanded ? 12 : 9,
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
                                    BoxShadow(color: accent.withValues(alpha: .28), blurRadius: 22),
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
                              SizedBox(width: expanded ? 22 : 12),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text('LIMITED TIME', style: TextStyle(
                                      color: accent, fontSize: expanded ? 14 : 9,
                                      letterSpacing: 1.5, fontWeight: FontWeight.w900,
                                    )),
                                    SizedBox(height: expanded ? 9 : 4),
                                    Text('SPECIAL OFFER', maxLines: 2, style: TextStyle(
                                      fontSize: expanded ? 30 : 17, height: 1.0,
                                      fontWeight: FontWeight.w900,
                                    )),
                                    SizedBox(height: expanded ? 10 : 4),
                                    Text('Big flavour. Better value.', style: TextStyle(
                                      color: Colors.white70, fontSize: expanded ? 16 : 9,
                                    )),
                                  ],
                                ),
                              ),
                              SizedBox(width: expanded ? 12 : 6),
                              SizedBox(
                                width: expanded ? 190 : 92,
                                child: _FxTemplateFoodImage(
                                  url: specialOfferPhoto,
                                  accent: accent,
                                  label: 'Offer photo',
                                  expanded: expanded,
                                ),
                              ),
                            ],
                          )
                        : isGrid
                            ? Row(
                                children: <Widget>[
                                  for (var i = 0; i < 3; i++)
                                    Expanded(
                                      child: _FxTemplateMiniItem(
                                        imageUrl: i < photoFoods.length ? photoFoods[i].imageUrl : null,
                                        title: i < photoFoods.length && photoFoods[i].name.isNotEmpty
                                            ? photoFoods[i].name
                                            : fallbackNames[i],
                                        subtitle: i >= photoFoods.length
                                            ? 'ADD PHOTO IN MENU'
                                            : photoFoods[i].category.toLowerCase() == 'gallery'
                                                ? 'GALLERY PHOTO'
                                                : photoFoods[i].price > 0
                                                    ? 'SAR ${photoFoods[i].price.toStringAsFixed(0)}'
                                                    : 'ADD PRICE IN MENU',
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
                                            color: accent.withValues(alpha: .2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isBrand ? 'OUR PROMISE' : 'CHEF’S PICK',
                                            style: TextStyle(
                                              color: accent, fontSize: expanded ? 12 : 8,
                                              fontWeight: FontWeight.w900, letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: expanded ? 14 : 7),
                                        Text(
                                          isBrand ? 'GOOD FOOD.\nGOOD MOOD.' : 'SIGNATURE\nFLAVOUR',
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: expanded ? 39 : 20,
                                            height: .98,
                                            letterSpacing: -.4,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: expanded ? 12 : 6),
                                        Text('Made fresh. Served with love.',
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.white70,
                                                fontSize: expanded ? 16 : 9)),
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
                                          child: Text('ORDER NOW  →', style: TextStyle(
                                            fontSize: expanded ? 12 : 8,
                                            fontWeight: FontWeight.w900,
                                          )),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: expanded ? 22 : 8),
                                  SizedBox(
                                    width: expanded ? 220 : 112,
                                    child: AspectRatio(
                                      // Keep a real landscape menu image from
                                      // being squeezed into a narrow vertical strip.
                                      aspectRatio: 1,
                                      child: _FxTemplateFoodImage(
                                        url: heroPhoto,
                                        accent: accent,
                                        label: 'Menu food photo',
                                        expanded: expanded,
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
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.expanded,
  });

  final String? imageUrl;
  final String title;
  final String subtitle;
  final Color accent;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: expanded ? 7 : 3),
      padding: EdgeInsets.all(expanded ? 12 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E15).withValues(alpha: .78),
        borderRadius: BorderRadius.circular(expanded ? 14 : 8),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(expanded ? 10 : 6),
              child: _FxTemplateFoodImage(
                url: imageUrl,
                accent: accent,
                label: 'Upload photo',
                expanded: expanded,
              ),
            ),
          ),
          SizedBox(height: expanded ? 8 : 4),
          Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: expanded ? 13 : 10, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: expanded ? 11 : 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FxTemplateFoodImage extends StatelessWidget {
  const _FxTemplateFoodImage({
    required this.url,
    required this.accent,
    required this.label,
    required this.expanded,
  });

  final String? url;
  final Color accent;
  final String label;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    if (!hasUrl) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0D13),
          border: Border.all(color: accent.withValues(alpha: .25)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.add_photo_alternate_outlined,
                    color: accent.withValues(alpha: .8), size: expanded ? 34 : 20),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: expanded ? 10 : 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFF0A0D13),
          alignment: Alignment.center,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes == null
                  ? null
                  : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF0A0D13),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          'PHOTO UNAVAILABLE',
          textAlign: TextAlign.center,
          style: TextStyle(color: accent, fontSize: expanded ? 10 : 7,
              fontWeight: FontWeight.w800),
        ),
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
    final compact = MediaQuery.sizeOf(context).width < 600;

    Widget commandButton(String command, IconData icon, Color color) {
      return FilledButton.icon(
        onPressed: target.isEmpty ? null : () => _send(command),
        icon: Icon(icon, size: 19),
        label: Text(command),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: FxMasterC.card2,
          disabledForegroundColor: Colors.white38,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(compact ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'TV Remote',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose a group or one TV, then send a command.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          SegmentedButton<bool>(
            showSelectedIcon: true,
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.groups_rounded),
                label: Text('Group'),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.tv_rounded),
                label: Text('Single TV'),
              ),
            ],
            selected: <bool>{groupMode},
            onSelectionChanged: (selection) {
              setState(() {
                groupMode = selection.first;
                target = '';
              });
              _load();
            },
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : const Color(0xFFE2E8F0),
              ),
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (states) => states.contains(WidgetState.selected)
                    ? FxMasterC.primary
                    : const Color(0xFF1A202B),
              ),
              side: WidgetStateProperty.resolveWith<BorderSide>(
                (states) => BorderSide(
                  color: states.contains(WidgetState.selected)
                      ? const Color(0xFF9D8BFF)
                      : const Color(0xFF424B5B),
                  width: 1.1,
                ),
              ),
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A202B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF424B5B)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFFFC857), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      groupMode
                          ? 'No TV groups found. Add a group in TV Groups first.'
                          : 'No TV devices found. Pair a TV in TV Photo Manager → TV Devices first.',
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: target.isEmpty ? null : target,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A202B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Color(0xFFD6CCFF)),
              items: list
                  .map(
                    (doc) => DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        doc.data()['name']?.toString() ?? doc.id,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => target = value ?? ''),
              decoration: InputDecoration(
                labelText: groupMode ? 'Select TV group' : 'Select TV device',
                labelStyle: const TextStyle(color: Color(0xFFD6D9E2)),
                prefixIcon: Icon(
                  groupMode ? Icons.groups_rounded : Icons.tv_rounded,
                  color: const Color(0xFF9D8BFF),
                ),
                filled: true,
                fillColor: const Color(0xFF141923),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFF424B5B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF9D8BFF), width: 1.5,
                  ),
                ),
              ),
            ),
          if (list.isNotEmpty && target.isEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Row(
              children: <Widget>[
                Icon(Icons.touch_app_rounded,
                    size: 16, color: Color(0xFFFFC857)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Select a target to enable the command buttons.',
                    style: TextStyle(color: Color(0xFFFFD889), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (value) => note = value,
            decoration: InputDecoration(
              labelText: 'Command note (optional)',
              hintText: 'Example: Update the dinner menu',
              labelStyle: const TextStyle(color: Color(0xFFD6D9E2)),
              hintStyle: const TextStyle(color: Color(0xFF969FB0)),
              prefixIcon: const Icon(Icons.edit_note_rounded,
                  color: Color(0xFF9D8BFF)),
              filled: true,
              fillColor: const Color(0xFF141923),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFF424B5B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: Color(0xFF9D8BFF), width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            'Playback controls',
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: <Widget>[
                commandButton('Play', Icons.play_arrow_rounded,
                    const Color(0xFF16865F)),
                commandButton('Pause', Icons.pause_rounded,
                    const Color(0xFFB7791F)),
                commandButton('Previous', Icons.skip_previous_rounded,
                    const Color(0xFF2369A8)),
                commandButton('Next', Icons.skip_next_rounded,
                    const Color(0xFF2369A8)),
                commandButton('Refresh', Icons.refresh_rounded,
                    const Color(0xFF6546DE)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _panel(
            'Sound & device',
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: <Widget>[
                commandButton('Mute', Icons.volume_off_rounded,
                    const Color(0xFF56647A)),
                commandButton('Unmute', Icons.volume_up_rounded,
                    const Color(0xFF087F8C)),
                commandButton('Restart', Icons.restart_alt_rounded,
                    const Color(0xFFB93845)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _panel(
            'Emergency display',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Use only when you need to show an urgent message on the display.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .70),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => _emergency(true),
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text('Emergency ON'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB93845),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _emergency(false),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Emergency OFF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7EE7B5),
                        side: const BorderSide(
                          color: Color(0xFF36C98A), width: 1.2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
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

class _FxAudit extends StatefulWidget {
  const _FxAudit();

  @override
  State<_FxAudit> createState() => _FxAuditState();
}

class _FxAuditState extends State<_FxAudit> {
  final TextEditingController _searchController = TextEditingController();
  String _actionFilter = 'all';
  bool _clearingAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _prettyAction(String rawAction, String rawTarget) {
    final action = rawAction.trim().toLowerCase();
    final target = rawTarget.trim().toLowerCase();
    if (action == 'select' && target == 'display_template') return 'Template selected';
    if (action == 'use_template' && target == 'display_template') return 'Template applied';
    if (action == 'emergency_off') return 'Emergency display turned off';
    if (action == 'emergency_on') return 'Emergency display turned on';

    const labels = <String, String>{
      'create': 'Created',
      'update': 'Updated',
      'delete': 'Deleted',
      'select': 'Selected',
      'use_template': 'Applied template',
      'login': 'Signed in',
      'logout': 'Signed out',
    };
    if (labels.containsKey(action)) return labels[action]!;
    final readable = action.replaceAll('_', ' ').trim();
    if (readable.isEmpty) return 'Activity recorded';
    return readable[0].toUpperCase() + readable.substring(1);
  }

  String _prettyTarget(String rawTarget) {
    const labels = <String, String>{
      'display_template': 'Display template',
      'category': 'Menu category',
      'menu_item': 'Menu item',
      'offer': 'Special offer',
      'tv_group': 'TV group',
      'tv_device': 'TV device',
      'device': 'TV device',
      'remote': 'Remote control',
      'qr_config': 'QR menu settings',
      'role': 'Access role',
      'emergency': 'Emergency control',
    };
    final key = rawTarget.trim().toLowerCase();
    if (labels.containsKey(key)) return labels[key]!;
    final readable = key.replaceAll('_', ' ').trim();
    if (readable.isEmpty) return 'Workspace';
    return readable[0].toUpperCase() + readable.substring(1);
  }

  String _cleanSummary(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'No additional details';
    final match = RegExp(r'^(.*?)\s*\(([^()]*)\)$').firstMatch(value);
    if (match != null) {
      final base = (match.group(1) ?? '').trim();
      final suffix = (match.group(2) ?? '').trim().replaceAll('_', ' ');
      if (base.isNotEmpty && base.toLowerCase() == suffix.toLowerCase()) {
        return base;
      }
    }
    return value;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String _dateLabel(dynamic value) {
    final date = _readDate(value);
    if (date == null) return 'Date not recorded';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${date.year} • $hour:$minute $suffix';
  }

  IconData _actionIcon(String action) {
    switch (action.trim().toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline_rounded;
      case 'update':
        return Icons.edit_note_rounded;
      case 'delete':
        return Icons.delete_outline_rounded;
      case 'select':
      case 'use_template':
        return Icons.dashboard_customize_rounded;
      case 'emergency_off':
      case 'emergency_on':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  Color _actionColor(String action) {
    switch (action.trim().toLowerCase()) {
      case 'create':
        return const Color(0xFF36C98A);
      case 'update':
      case 'select':
      case 'use_template':
        return const Color(0xFF9B83FF);
      case 'delete':
      case 'emergency_off':
        return const Color(0xFFFF8585);
      default:
        return const Color(0xFF65C7F7);
    }
  }

  Future<void> _clearAllHistory() async {
    if (_clearingAll) return;

    final confirmation = TextEditingController();
    final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              backgroundColor: FxMasterC.card2,
              title: Row(
                children: <Widget>[
                  const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF8585)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Clear all audit history')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'This permanently deletes every audit history record stored in Firebase, '
                      'not just the records currently visible on this page.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Color(0xFFFF8585),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Type CLEAR to confirm.'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmation,
                      autofocus: false,
                      onChanged: (_) => setDialogState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type CLEAR',
                        filled: true,
                        fillColor: FxMasterC.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: FxMasterC.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB93845),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: confirmation.text.trim().toUpperCase() == 'CLEAR'
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('Delete all records'),
                ),
              ],
            ),
          ),
        ) ??
        false;

    confirmation.dispose();
    if (!confirmed || !mounted) return;

    setState(() => _clearingAll = true);
    var deletedCount = 0;

    try {
      // Delete in pages under Firestore's 500-write batch limit.
      // No orderBy is intentional: delete every document, including legacy
      // audit records that may not have a createdAt field.
      while (true) {
        final page = await FxMasterDb.audits.limit(400).get();
        if (page.docs.isEmpty) break;

        final batch = FxMasterDb.db.batch();
        for (final doc in page.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        deletedCount += page.docs.length;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audit history cleared. $deletedCount record(s) deleted.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deletedCount == 0
                  ? 'Could not clear audit history: $error'
                  : 'Partially cleared: $deletedCount record(s) deleted. Error: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _clearingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FxMasterDb.audits
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _auditMessage(
            icon: Icons.error_outline_rounded,
            title: 'Activity history is unavailable',
            message: 'Check the connection or audit-log permissions, then try again.',
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ??
            const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final query = _searchController.text.trim().toLowerCase();
        final filtered = docs.where((doc) {
          final data = doc.data();
          final action = data['action']?.toString() ?? '';
          final target = data['target']?.toString() ?? '';
          final summary = data['summary']?.toString() ?? '';
          final email = data['email']?.toString() ?? '';
          final matchesFilter = _actionFilter == 'all' ||
              action.trim().toLowerCase() == _actionFilter;
          final searchable = '$action $target $summary $email'.toLowerCase();
          return matchesFilter && (query.isEmpty || searchable.contains(query));
        }).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final horizontalPadding = compact ? 14.0 : 24.0;
            final search = TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search activity, user or item…',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                filled: true,
                fillColor: FxMasterC.card,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FxMasterC.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FxMasterC.border),
                ),
              ),
            );
            final filter = Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: FxMasterC.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FxMasterC.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _actionFilter,
                  isExpanded: true,
                  dropdownColor: FxMasterC.card2,
                  iconEnabledColor: Colors.white70,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'all', child: Text('All activities')),
                    DropdownMenuItem(value: 'create', child: Text('Created')),
                    DropdownMenuItem(value: 'update', child: Text('Updated')),
                    DropdownMenuItem(value: 'delete', child: Text('Deleted')),
                    DropdownMenuItem(value: 'select', child: Text('Template selected')),
                    DropdownMenuItem(value: 'use_template', child: Text('Template applied')),
                    DropdownMenuItem(value: 'emergency_off', child: Text('Emergency actions')),
                    DropdownMenuItem(value: 'emergency_on', child: Text('Emergency actions (on)')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _actionFilter = value);
                  },
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Activity history',
                                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'A clear record of changes in this workspace.',
                                      style: TextStyle(fontSize: 12, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: FxMasterC.primary.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: FxMasterC.primary.withValues(alpha: .26)),
                                ),
                                child: Text(
                                  '${filtered.length} records',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _clearingAll ? null : _clearAllHistory,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFF8585),
                                side: BorderSide(
                                  color: const Color(0xFFFF8585).withValues(alpha: .55),
                                ),
                                backgroundColor: const Color(0xFFFF8585).withValues(alpha: .06),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              ),
                              icon: _clearingAll
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.delete_sweep_outlined, size: 18),
                              label: Text(_clearingAll ? 'Clearing history…' : 'Clear all history'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (compact) ...<Widget>[
                        search,
                        const SizedBox(height: 10),
                        filter,
                      ] else
                        Row(
                          children: <Widget>[
                            Expanded(child: search),
                            const SizedBox(width: 12),
                            SizedBox(width: 210, child: filter),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _auditMessage(
                          icon: Icons.manage_search_rounded,
                          title: query.isEmpty && _actionFilter == 'all' ? 'No activity yet' : 'No matching activity',
                          message: query.isEmpty && _actionFilter == 'all'
                              ? 'Changes to templates, categories, menu items and settings will appear here.'
                              : 'Try another search term or choose All activities.',
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final data = filtered[index].data();
                            final action = data['action']?.toString() ?? '';
                            final target = data['target']?.toString() ?? '';
                            final summary = _cleanSummary(data['summary']?.toString() ?? '');
                            final email = data['email']?.toString().trim() ?? '';
                            final color = _actionColor(action);
                            return Container(
                              padding: EdgeInsets.all(compact ? 14 : 16),
                              decoration: BoxDecoration(
                                color: FxMasterC.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: FxMasterC.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: .13),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_actionIcon(action), color: color, size: 21),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          summary == 'No additional details' ? _prettyAction(action, target) : summary,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Wrap(
                                          spacing: 7,
                                          runSpacing: 5,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: <Widget>[
                                            Text(_prettyAction(action, target), style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                                            const Text('·', style: TextStyle(color: Colors.white38)),
                                            Text(_prettyTarget(target), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                          ],
                                        ),
                                        const SizedBox(height: 9),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 5,
                                          children: <Widget>[
                                            Text(
                                              email.isEmpty ? 'User not recorded' : email,
                                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                                            ),
                                            Text(_dateLabel(data['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.white54)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _auditMessage({required IconData icon, required String title, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 34, color: Colors.white38),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white60, height: 1.5)),
            ],
          ),
        ),
      ),
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
          onPressed: () => _addSimpleCollectionRecord(
            context,
            title: title,
            collection: collection,
            choices: choices,
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(title == 'Roles' ? 'Add role record' : 'Add group'),
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

Future<void> _addSimpleCollectionRecord(
  BuildContext context, {
  required String title,
  required CollectionReference<Map<String, dynamic>> collection,
  required List<String> choices,
}) async {
  final isRoles = title.toLowerCase() == 'roles';
  final nameController = TextEditingController();
  var selectedChoice = choices.first;
  String? validationMessage;
  Map<String, String>? result;

  try {
    result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: FxMasterC.card2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isRoles ? 'Add role record' : 'Create TV group'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  autofocus: true,
                  keyboardType: isRoles ? TextInputType.emailAddress : TextInputType.text,
                  textCapitalization: isRoles ? TextCapitalization.none : TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: isRoles ? 'Email or user identifier' : 'Group name',
                    hintText: isRoles ? 'staff@example.com' : 'e.g. Main Restaurant TVs',
                    prefixIcon: Icon(isRoles ? Icons.person_outline_rounded : Icons.groups_rounded),
                  ),
                  onChanged: (_) {
                    if (validationMessage != null) {
                      setDialogState(() => validationMessage = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  dropdownColor: FxMasterC.card2,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  initialValue: selectedChoice,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: isRoles ? 'Role label' : 'Initial group status',
                    prefixIcon: Icon(isRoles ? Icons.admin_panel_settings_outlined : Icons.toggle_on_outlined),
                  ),
                  items: choices
                      .map((choice) => DropdownMenuItem<String>(
                            value: choice,
                            child: Text(choice, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedChoice = value);
                  },
                ),
                if (isRoles) ...<Widget>[
                  const SizedBox(height: 10),
                  const Text(
                    'This creates a role record. Actual account permissions still depend on Firebase Authentication and Security Rules.',
                    style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                ],
                if (validationMessage != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(validationMessage!, style: const TextStyle(color: FxMasterC.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final value = nameController.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => validationMessage = isRoles
                      ? 'Enter an email or user identifier.'
                      : 'Enter a group name.');
                  return;
                }
                if (isRoles && value.contains(' ') ) {
                  setDialogState(() => validationMessage = 'Use an email or a single user identifier.');
                  return;
                }
                Navigator.pop(dialogContext, <String, String>{
                  'name': value,
                  'choice': selectedChoice,
                });
              },
              icon: const Icon(Icons.save_rounded, size: 17),
              label: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  } finally {
    nameController.dispose();
  }

  if (result == null) return;
  final name = (result['name'] ?? '').trim();
  final choice = result['choice'] ?? choices.first;
  if (name.isEmpty) return;

  try {
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'name': name,
      'createdAt': now,
      'updatedAt': now,
    };
    if (isRoles) {
      data.addAll(<String, dynamic>{
        'email': name,
        'role': choice,
        'active': true,
      });
    } else {
      final active = choice.toLowerCase() == 'active';
      data.addAll(<String, dynamic>{
        'status': choice.toLowerCase(),
        'active': active,
        'deviceIds': <String>[],
      });
    }
    await collection.add(data);
    await fxMasterAudit('create', isRoles ? 'admin_role' : 'tv_group', '$name • $choice');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRoles ? 'Role record created for $name.' : 'TV group "$name" created.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create ${isRoles ? 'role record' : 'TV group'}. Check Firebase write permissions and try again.',
          ),
        ),
      );
    }
  }
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .68),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  titleBlock,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                action,
              ],
            );
          },
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
      color: FxMasterC.primary.withValues(alpha: .20),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
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
