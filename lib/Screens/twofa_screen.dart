import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:requests/requests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valorant_shop/Screens/skins_screen.dart';

class TwoFaScreen extends StatefulWidget {
  const TwoFaScreen({Key? key, this.twoFactor, this.cookies}) : super(key: key);

  final dynamic twoFactor;
  final dynamic cookies;

  @override
  State<TwoFaScreen> createState() => _TwoFaScreenState();
}

class _TwoFaScreenState extends State<TwoFaScreen> {
  String _code = '';
  String _errorMessage = '';
  var dio = Dio();

  void onPressed() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
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

    if (data['error'] == 'multifactor_attempt_failed') {
      setState(() {
        _errorMessage = 'Invalid code';
      });
      return;
    }

    if (data['type'] == 'response' && res.headers['set-cookie'] != null) {
      var cookies = res.headers['set-cookie'] ?? '';
      await prefs.setString('cookies', cookies);
    }

    var token = data['response']['parameters']['uri']
        .toString()
        .split('access_token=')[1]
        .split('&scope')[0];
    await prefs.setString('token', token);
    pushToSkinRoute();
  }

  void pushToSkinRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SkinsScreen()),
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
            height: 270,
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
                    keyboardType: TextInputType.number,
                    onChanged: (text) {
                      setState(() {
                        _code = text;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _errorMessage.isNotEmpty
                    ? Text(_errorMessage)
                    : const SizedBox(height: 10),
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
