import 'dart:io';

import 'package:flutter/material.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_shop/Screens/login_screen.dart';
import 'package:valorant_shop/Screens/skins_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var validCookie = await checkCookie();
  runApp(MyApp(validCookie: validCookie));
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
    return true;
  }
  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.validCookie}) : super(key: key);

  final bool validCookie;

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
      home: validCookie ? SkinsScreen() : const LoginScreen(),
    );
  }
}
