import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:requests/requests.dart';
import 'package:valorant_shop/Screens/skins_screen.dart';
import 'package:valorant_shop/skin.dart';
import 'package:cookie_jar/cookie_jar.dart';

class TwoFaScreen extends StatefulWidget {
  const TwoFaScreen({Key? key, this.twoFactor, this.cookies}) : super(key: key);

  final dynamic twoFactor;
  final dynamic cookies;

  @override
  State<TwoFaScreen> createState() => _TwoFaScreenState();
}

class _TwoFaScreenState extends State<TwoFaScreen> {
  String _code = '';
  var dio = Dio();

  void onPressed() async {
    var res =
        await Requests.put('https://auth.riotgames.com/api/v1/authorization',
            body: {
              'type': 'multifactor',
              'code': _code,
              'rememberDevice': true,
              'language': 'en_US'
            },
            bodyEncoding: RequestBodyEncoding.JSON);

    var data = res.json();
    var token = data['response']['parameters']['uri']
        .toString()
        .split('access_token=')[1]
        .split('&scope')[0];
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
      print(skinRequest.data);
    }
    pushToSkinRoute(skins);
  }

  void pushToSkinRoute(skins) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SkinsScreen(
                skins: skins,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/unknown.png'), fit: BoxFit.cover)),
      child: Center(
        child: Container(
            width: 300,
            height: 260,
            decoration: BoxDecoration(
                color: Colors.red.shade800,
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black26)
                ]),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: <Widget>[
                Text('VALORANT SHOP', style: GoogleFonts.oswald(fontSize: 25)),
                const SizedBox(height: 10),
                Text('ENTER YOUR 2FA CODE',
                    style: GoogleFonts.oswald(fontSize: 14)),
                const SizedBox(height: 20),
                Material(
                  color: Colors.black,
                  clipBehavior: Clip.antiAlias,
                  shape: const BeveledRectangleBorder(
                    side: BorderSide(
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        10,
                      ),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  child: TextFormField(
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                    decoration: InputDecoration(
                        hintText: 'TWO FA CODE',
                        hintStyle: TextStyle(color: Colors.red.shade100),
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                    keyboardType: TextInputType.text,
                    onChanged: (text) {
                      setState(() {
                        _code = text;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                    onPressed: onPressed,
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
                              "SUBMIT",
                              style: GoogleFonts.oswald(
                                  fontSize: 15, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            )),
      ),
    ));
  }
}
