import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:valorant_shop/skin.dart';

class SkinsScreen extends StatelessWidget {
  const SkinsScreen({Key? key, required this.skins}) : super(key: key);

  final List<Skin> skins;

  List<Container> generateComponents() {
    var texts = skins
        .map((skin) => Container(
              width: 300,
              margin: const EdgeInsets.fromLTRB(0, 15, 0, 15),
              child: Material(
                elevation: 0.0,
                type: MaterialType.button,
                color: Colors.black54,
                shape: const BeveledRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15))),
                child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      Text(skin.name.toUpperCase(),
                          style:
                              GoogleFonts.oswald(color: Colors.red.shade400)),
                      const SizedBox(height: 10),
                      Image(
                        image: NetworkImage(skin.image),
                        height: 50,
                      )
                    ])),
              ),
            ))
        .toList();
    return texts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/unknown.png'), fit: BoxFit.cover)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: generateComponents(),
            ),
          )),
    );
  }
}
