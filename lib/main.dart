import 'dart:io';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_shop/Screens/login_screen.dart';
import 'package:valorant_shop/Screens/skins_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:background_fetch/background_fetch.dart';
import 'package:valorant_shop/notification_helper.dart';
import 'package:valorant_shop/skin.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// [Android-only] This "Headless Task" is run when the Android app
// is terminated with enableHeadless: true
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // Do your work here...
  BackgroundFetch.finish(taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var validCookie = await checkCookie();
  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  runApp(MyApp(validCookie: validCookie));
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

List<String> parseCookie(String cookie) {
  String newString = cookie.replaceAllMapped(RegExp(r',\s'), (match) {
    return '^^';
  });
  var strings = newString.split(',');
  var cookies = strings.map((string) {
    return string.replaceAll('^^', ', ');
  }).toList();
  return cookies;
}

Future<bool> checkCookie() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  var cookie = prefs.getString('cookies');
  if (cookie == null) {
    return false;
  }
  var cookieList = parseCookie(cookie);
  var parsedCookies =
      cookieList.map((cookie) => Cookie.fromSetCookieValue(cookie));
  for (var c in parsedCookies) {
    await Requests.addCookie('auth.riotgames.com', c.name, c.value);
  }
  var response = await Requests.post(
    'https://auth.riotgames.com/api/v1/authorization',
    body: {
      "client_id": "play-valorant-web-prod",
      "nonce": "1",
      'response_type': 'token id_token',
      "redirect_uri": "https://playvalorant.com/opt_in"
    },
    bodyEncoding: RequestBodyEncoding.JSON,
  );
  var data = response.json();
  print(data);
  if (data['type'] == 'response') {
    var token = data['response']['parameters']['uri']
        .toString()
        .split('access_token=')[1]
        .split('&scope')[0];
    await prefs.setString('token', token);
    var cookies = response.headers['set-cookie'] ?? '';
    await prefs.setString('cookies', cookies);
    return true;
  }
  return false;
}

Future<String> getSkinsContent() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  var dio = Dio();
  var token = prefs.getString('token');
  if (token == null) {
    return 'NO_TOKEN';
  }
  var bearer = 'Bearer $token';
  var tokenData = await dio.post(
      'https://entitlements.auth.riotgames.com/api/token/v1',
      options: Options(
          contentType: 'application/json', headers: {'Authorization': bearer}));
  if (tokenData.data['errorCode'] == 'CREDENTIALS_EXPIRED') {
    return 'EXPIRED_TOKEN';
  }
  var entitlementsToken = tokenData.data['entitlements_token'];
  var userData = await dio.get('https://auth.riotgames.com/userinfo',
      options: Options(
          contentType: 'application/json', headers: {'Authorization': bearer}));
  var puuid = userData.data['sub'];
  var storeRequest = await dio.get(
      'https://pd.eu.a.pvp.net/store/v2/storefront/$puuid',
      options: Options(headers: {
        'Authorization': bearer,
        'X-Riot-Entitlements-JWT': entitlementsToken
      }));
  var storeItems = storeRequest.data['SkinsPanelLayout']['SingleItemOffers'];
  String content = '';
  int counter = 0;
  for (var item in storeItems) {
    counter++;
    var skinRequest =
        await dio.get('https://valorant-api.com/v1/weapons/skinlevels/$item');
    content += skinRequest.data['data']['displayName'];
    if (counter < 4) {
      content += '<br/>';
    }
  }
  return content;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key, required this.validCookie}) : super(key: key);

  final bool validCookie;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationHelper _notificationHelper = NotificationHelper();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _notificationHelper.initializeNotification();
    BackgroundFetch.start().then((int status) {
      print('[BackgroundFetch] start success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] start FAILURE: $e');
    });
    //Seila TQM
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    int status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY), (String taskId) async {
      // <-- Event handler
      // This is the fetch-event callback.
      List<String>? prevLogs =
          prefs.getStringList('logs') ?? List.empty(growable: true);
      print("[BackgroundFetch] Event received $taskId");
      checkCookie();

      final tz.TZDateTime now = tz.TZDateTime.now(tz.UTC);
      String time =
          "${now.day}/${now.month} T ${now.hour}:${now.minute}:${now.second}";

      prevLogs.add('Trigger Background task | $time');

      print(now.hour);

      var gotSkins = prefs.getBool('gotSkins');

      if (now.hour == 0 && (gotSkins == null || gotSkins == false)) {
        //1. Get skins
        String skinContent = await getSkinsContent();

        if (skinContent == 'NO_TOKEN' || skinContent == 'EXPIRED_TOKEN') {
          //If token is bad, don't send the notification
          return;
        }

        prevLogs.add('Got skins $skinContent | $time');

        String username = prefs.getString('username') != null
            ? prefs.getString('username').toString()
            : '';
        //2. Send notitification
        _notificationHelper.sendNotification(
            username, 'New skins', skinContent);

        prevLogs.add('Attempted to send notification $skinContent | $time');
        //3. set gotSkins true
        prefs.setBool('gotSkins', true);
      } else if (now.hour != 0 && (gotSkins == true)) {
        //4. After sending the notification, reset tag
        prefs.setBool('gotSkins', false);
        prevLogs.add('Reset gotSkins for next time | $time');
      }

      prefs.setStringList('logs', prevLogs);

      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }, (String taskId) async {
      // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Valorant Shop',
      theme: ThemeData(
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
      /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
      debugShowCheckedModeBanner: false,
      home: widget.validCookie ? SkinsScreen() : const LoginScreen(),
    );
  }
}
