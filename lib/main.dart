import 'package:MOLLILE/Dartpages/HomePage/Home_page.dart';
import 'package:MOLLILE/Dartpages/HomePage/start_pages.dart';
import 'package:MOLLILE/Dartpages/simple_functions/Language.dart';
import 'package:MOLLILE/firebaseSeting/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  final bool firstTime;

  const MyApp({super.key, required this.firstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: firstTime ? StartThreePages(Number_page: 0) : Homepage(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? langCode = prefs.getString('language_code') ?? 'en';
  String? countryCode = prefs.getString('countryCode') ?? 'US';
  Locale startLocale = Locale(langCode, countryCode);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final bool firstTime = prefs.getBool('firstTime') ?? true;

  await EasyLocalization.ensureInitialized();

  runApp(
    Phoenix(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
        ],
        child: EasyLocalization(
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            Locale('hi', 'IN'),
            Locale('ar', 'SA'),
            Locale('ru', 'RU'),
            Locale('id', 'ID'),
            Locale('vi', 'VN'),
            Locale('zh', 'CN'),
          ],
          path: 'lib/i18n',
          fallbackLocale: const Locale('en', 'US'),
          startLocale: startLocale,
          child: MyApp(firstTime: firstTime),
        ),
      ),
    ),
  );
}
