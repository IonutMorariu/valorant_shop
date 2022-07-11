import 'package:dio/dio.dart';
import 'package:requests/requests.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_shop/Screens/skins_screen.dart';
import 'package:valorant_shop/Screens/twofa_screen.dart';
import 'package:valorant_shop/skin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    Key? key,
    this.child,
  }) : super(key: key);

  final Widget? child;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var dio = Dio();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  //For check text loaded. bool textLoaded;
  bool textLoaded = false;

  String _username = '';
  String _password = '';

  @override
  void initState() {
    textLoaded = false;
    super.initState();
    setText();
  }

  Future<void> setText() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') != null
          ? prefs.getString('username').toString()
          : '';
      _password = prefs.getString('password') != null
          ? prefs.getString('password').toString()
          : '';

      _usernameController = TextEditingController(text: _username);
      _passwordController = TextEditingController(text: _password);

      textLoaded = true;
    });
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void onPressed() async {
    final prefs = await SharedPreferences.getInstance();
    if (_username.isNotEmpty && _password.isNotEmpty) {
      try {
        var response = await Requests.post(
            'https://auth.riotgames.com/api/v1/authorization',
            body: {
              "client_id": "play-valorant-web-prod",
              "nonce": "1",
              'response_type': 'token id_token',
              "redirect_uri": "https://playvalorant.com/opt_in"
            },
            bodyEncoding: RequestBodyEncoding.JSON);
        var res = await Requests.put(
            'https://auth.riotgames.com/api/v1/authorization',
            body: {
              'type': 'auth',
              'username': _username,
              'password': _password,
              'remember': false,
              'language': 'en_US'
            },
            bodyEncoding: RequestBodyEncoding.JSON);
        var data = res.json();
        if (data['type'] == 'multifactor') {
          pushToTwoFaRoute(data);
        }
        if (data['type'] == 'multifactor' || data['type'] == 'response') {
          await prefs.setString('username', _username);
          await prefs.setString('password', _password);
        }
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
        var storeItems =
            storeRequest.data['SkinsPanelLayout']['SingleItemOffers'];
        List<Skin> skins = [];
        storeItems.forEach((item) async {
          var skinRequest = await dio
              .get('https://valorant-api.com/v1/weapons/skinlevels/$item');
          Skin skin = Skin(skinRequest.data['data']['displayName'],
              skinRequest.data['data']['displayIcon']);
          skins.add(skin);
        });
        print(skins);
        pushToSkinRoute(skins);
      } catch (e) {
        if (e is DioError) {
          print(e.response);
          _showToast(context, e.response.toString());
        } else {
          print(e);
        }
      }
    }
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

  void pushToTwoFaRoute(twoFactor) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TwoFaScreen(
                twoFactor: twoFactor,
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
            height: 300,
            decoration: BoxDecoration(
                color: Colors.red.shade800,
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black26)
                ]),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: <Widget>[
                Text('VALORANT SHOP', style: GoogleFonts.oswald(fontSize: 25)),
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
                    controller: _usernameController,
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                    decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: TextStyle(color: Colors.red.shade100),
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                    keyboardType: TextInputType.text,
                    onChanged: (text) {
                      setState(() {
                        _username = text;
                      });
                    },
                  ),
                ),
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
                    controller: _passwordController,
                    style: TextStyle(
                      color: Colors.red.shade700,
                    ),
                    decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.red.shade100),
                        border: InputBorder.none,
                        fillColor: Colors.white,
                        filled: true),
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    onChanged: (text) {
                      setState(() {
                        _password = text;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 30),
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
                              "Submit",
                              style: TextStyle(
                                  fontSize: 15.0, color: Colors.red.shade700),
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
