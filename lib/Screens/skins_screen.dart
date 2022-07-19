import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_shop/Screens/login_screen.dart';
import 'package:valorant_shop/skin.dart';

class SkinsScreen extends StatefulWidget {
  SkinsScreen({Key? key}) : super(key: key);

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  late Future<List<Skin>> skinFuture;

  @override
  void initState() {
    super.initState();
    skinFuture = getSkinData();
  }

  Future<List<Skin>> getSkinData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var dio = Dio();
    var token = prefs.getString('token');
    if (token == null) {
      throw 'No token';
    }
    var bearer = 'Bearer $token';
    var tokenData = await dio.post(
        'https://entitlements.auth.riotgames.com/api/token/v1',
        options: Options(
            contentType: 'application/json',
            headers: {'Authorization': bearer}));
    var entitlementsToken = tokenData.data['entitlements_token'];
    var userData = await dio.get('https://auth.riotgames.com/userinfo',
        options: Options(
            contentType: 'application/json',
            headers: {'Authorization': bearer}));
    var puuid = userData.data['sub'];
    var storeRequest = await dio.get(
        'https://pd.eu.a.pvp.net/store/v2/storefront/$puuid',
        options: Options(headers: {
          'Authorization': bearer,
          'X-Riot-Entitlements-JWT': entitlementsToken
        }));
    var storeItems = storeRequest.data['SkinsPanelLayout']['SingleItemOffers'];
    List<Skin> skins = [];
    for (var item in storeItems) {
      var skinRequest =
          await dio.get('https://valorant-api.com/v1/weapons/skinlevels/$item');
      Skin skin = Skin(skinRequest.data['data']['displayName'],
          skinRequest.data['data']['displayIcon']);
      skins.add(skin);
    }
    return skins;
  }

  ListView generateComponents(List<Skin> skins) {
    List<Container> texts = skins
        .map((skin) => Container(
              width: 250,
              margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
              child: Material(
                elevation: 0.0,
                type: MaterialType.button,
                color: Colors.black54,
                shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15))),
                child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                    child: Column(children: [
                      Text(skin.name.toUpperCase(),
                          style: GoogleFonts.oswald(color: Colors.white)),
                      const SizedBox(height: 15),
                      Image(
                        image: NetworkImage(skin.image),
                        height: 60,
                      )
                    ])),
              ),
            ))
        .toList();
    return ListView(
      children: [
        ...texts,
        TextButton(
            onPressed: onLogout,
            child: Material(
              elevation: 0.0,
              type: MaterialType.button,
              color: Colors.white,
              shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5))),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: Colors.white.withOpacity(.8),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    widthFactor: 2.0,
                    heightFactor: 1.0,
                    child: Text(
                      "LOGOUT",
                      style:
                          GoogleFonts.oswald(fontSize: 15, color: Colors.red),
                    ),
                  ),
                ),
              ),
            ))
      ],
    );
  }

  void onLogout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    pushLoginRoute();
  }

  void pushLoginRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Container(
          padding: const EdgeInsets.only(top: 50),
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/unknown.png'), fit: BoxFit.cover)),
          child: Center(
              child: Container(
                  width: 250,
                  alignment: Alignment.center,
                  child: FutureBuilder<List<Skin>>(
                    future: skinFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        return generateComponents(snapshot.data!);
                      }

                      return CircularProgressIndicator(
                        color: Colors.red.shade500,
                      );
                    },
                  )))),
    );
  }
}
