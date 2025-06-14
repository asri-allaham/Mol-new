import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:Mollni/Dartpages/HomePage/start_pages.dart';
import 'package:Mollni/Dartpages/sighUpIn/login_state.dart';
import 'package:Mollni/simple_functions/Language.dart';
import 'package:Mollni/firebaseSeting/firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  showLocalNotification(
    title: message.notification?.title ?? '',
    body: message.notification?.body ?? '',
  );
}

void showLocalNotification({required String title, required String body}) {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'chat_channel_id',
    'Chat Messages',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformDetails,
    payload: null,
  );
}

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

  // Init Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'chat_channel_id',
    'Chat Messages',
    description: 'Notifications for incoming chat messages',
    importance: Importance.max,
    enableVibration: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Request permissions
  if (await Permission.notification.isDenied ||
      await Permission.notification.isPermanentlyDenied) {
    await Permission.notification.request();
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? langCode = prefs.getString('language_code') ?? 'en';
  String? countryCode = prefs.getString('countryCode') ?? 'US';
  Locale startLocale = Locale(langCode, countryCode);
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("User granted permission");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? token = await messaging.getToken();
  print("FCM Token: $token");

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      showLocalNotification(
        title: notification.title!,
        body: notification.body!,
      );
    }
  });

  runApp(
    Phoenix(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
          ChangeNotifierProvider(create: (_) => LoginState()),
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
          fallbackLocale: Locale('en', 'US'),
          startLocale: startLocale,
          child: MyApp(firstTime: prefs.getBool('firstTime') ?? true),
        ),
      ),
    ),
  );
}
