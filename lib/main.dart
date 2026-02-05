import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox("database");
  runApp(MyApp(box: box));
}

class MyApp extends StatefulWidget {
  final Box box;
  const MyApp({super.key, required this.box});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Box box;
  @override
  void initState() {
    super.initState();
    box = widget.box;
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
        theme: CupertinoThemeData(
            primaryColor: CupertinoColors.label
        ),
        debugShowCheckedModeBanner: false,
        home: (box.get("username") == null) ? Signup(box: box) : Homepage(box: box)
    );
  }
}

class Homepage extends StatefulWidget {
  final Box box;
  const Homepage({super.key, required this.box});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final LocalAuthentication auth = LocalAuthentication();
  late final Box box;
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    box = widget.box;
  }

  Future<void> authenticate() async {
    try{
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        biometricOnly: true,
      );
      if (didAuthenticate) {
        setState(() {
          _username.text = box.get("username") ?? '';
          _password.text = box.get("password") ?? '';
        });
      } else {
        debugPrint('Failed');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login', style: TextStyle(fontWeight: FontWeight.w200, fontSize: 35),),
            CupertinoTextField(
              controller: _username,
              prefix: Icon(CupertinoIcons.person),
              placeholder: "Username",
            ),
            SizedBox(height: 3,),
            CupertinoTextField(
              controller: _password,
              prefix: Icon(CupertinoIcons.padlock),
              placeholder: "Password",
              obscureText: hidePassword,
              suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash), onPressed: (){
                setState(() {
                  hidePassword = !hidePassword;
                });
              }),
            ),

            Center(
              child: Column(
                children: [
                  CupertinoButton(
                    child: const Text('Login'),
                    onPressed: (){
                      if (_username.text.trim() == box.get("username") && _password.text.trim() == box.get("password")) {
                        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context)=> Home(box: box)),);
                      } else {
                        showCupertinoDialog(context: context, builder: (context){
                          return CupertinoAlertDialog(
                            title: const Text("Login Failed"),
                            content: const Text("Invalid username or password"),
                            actions: [
                              CupertinoButton(
                                child: const Text("OK"),
                                onPressed: (){
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          );
                        },
                        );
                      }
                    },
                  ),

                  (box.get("biometrics") == true) ? CupertinoButton(child: Icon(Icons.fingerprint), onPressed: (){
                    authenticate();
                  }) : SizedBox.shrink(),

                  CupertinoButton(child: Text('Erase Data'), onPressed: (){
                    showCupertinoDialog(context: context, builder: (context){
                      return CupertinoAlertDialog(
                        content: Text("Are you sure to delete all data?"),
                        actions: [
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text("Cancel"), onPressed: (){
                            Navigator.pop(context);
                          }),
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text("Yes"), onPressed: (){
                            box.clear();
                            Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context)=> Signup(box: box)));
                          }),
                        ],
                      );
                    },
                    );
                  }),
                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
}


class Signup extends StatefulWidget {
  final Box box;
  const Signup({super.key, required this.box});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  late final Box box;
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  bool hidePassword = true;

  @override
  void initState() {
    super.initState();
    box = widget.box;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Create a local account', style: TextStyle(fontWeight: FontWeight.w200, fontSize: 35),),
            CupertinoTextField(
              controller: _username,
              prefix: Icon(CupertinoIcons.person),
              placeholder: "Username",
            ),
            SizedBox(height: 3,),
            CupertinoTextField(
              controller: _password,
              prefix: Icon(CupertinoIcons.padlock),
              placeholder: "Password",
              obscureText: hidePassword,
              suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash), onPressed: (){
                setState(() {
                  hidePassword = !hidePassword;
                });
              }),
            ),

            Center(
              child: Column(
                children: [
                  CupertinoButton(child: Text('Signup'), onPressed: (){
                    box.put("username", _username.text.trim());
                    box.put("password", _password.text.trim());
                    box.put("biometrics", false);

                    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context)=> Homepage(box: box)));
                  }),

                ],
              ),
            )
          ],
        ),
      ),
    ));
  }
}

class Home extends StatefulWidget {
  final Box box;
  const Home({super.key, required this.box});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(tabBar: CupertinoTabBar(items: [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "home"),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: "settings"),
    ]), tabBuilder: (context, index){
      if (index == 0) {
        return HomeList();
      } else {
        return Settings(box: (context.findAncestorWidgetOfExactType<Home>()!).box);
      }
    });
  }
}

class HomeList extends StatefulWidget {
  const HomeList({super.key});

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  final bool isDark = false;

  Widget musicCard(String title, String imageUrl) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              CupertinoColors.white.withOpacity(0.75),
              CupertinoColors.white.withOpacity(0.05),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Good evening",
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://i.pinimg.com/736x/a4/71/31/a47131039ecbeffaf3ba573730976eb8.jpg",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // RECENTLY PLAYED
            const Text(
              "Recently Played",
              style: TextStyle(
                color: CupertinoColors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  musicCard(
                    "Daily Mix",
                    "https://i.scdn.co/image/ab676161000051744aac2151be750fecb674048a",
                  ),
                  musicCard(
                    "Top Hits",
                    "https://pickasso.spotifycdn.com/image/ab67c0de0000deef/dt/v1/img/thisisv3/1UwnrHfh8Kd8Y8Ax8a3qWy/en",
                  ),
                  musicCard(
                    "Chill Vibes",
                    "https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcQ_CL_vmiqJmPosWnL6BQ_ccnCKo0_vGRZR5wLL64i3MrLaPM8X",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // MADE FOR YOU
            const Text(
              "Made for You",
              style: TextStyle(
                color: CupertinoColors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  musicCard(
                    "Your Favorites",
                    "https://pickasso.spotifycdn.com/image/ab67c0de0000deef/dt/v1/img/thisisv3/6Dp4LInLyMVA2qhRqQ6AGL/en",
                  ),
                  musicCard(
                    "Trending Now",
                    "https://preview.redd.it/walang-ibang-gugustuhin-kundi-ikaw-v0-ki3o8ath5z2d1.jpeg",
                  ),
                  musicCard(
                    "Radio Mix",
                    "https://pickasso.spotifycdn.com/image/ab67c0de0000deef/dt/v1/img/radio/artist/2kxP07DLgs4xlWz8YHlvfh/de",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}


class Settings extends StatefulWidget {
  final Box box;
  const Settings({super.key, required this.box});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final Box box;

  @override
  void initState() {
    super.initState();
    box = widget.box;
  }

  Widget tiles(Color color, String title, dynamic trailing, IconData icon){
    return CupertinoListTile(
        trailing: trailing,
        leading: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: color,
          ),
          child: Icon(icon, size: 17),
        ),
        title: Text(title));
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: ListView(
        children: [
          CupertinoListSection.insetGrouped(
            children: [
              tiles(CupertinoColors.systemPurple, "Biometrics", CupertinoSwitch(value: box.get("biometrics") ?? false, onChanged: (value){
                setState(() {
                  box.put("biometrics", value);
                });
              }), Icons.fingerprint_rounded),
              GestureDetector(
                  onTap: (){
                    showCupertinoDialog(context: context, builder: (context){
                      return CupertinoAlertDialog(
                        title: Text("Sign out?"),
                        actions: [
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text("Cancel"), onPressed: (){
                            Navigator.pop(context);
                          }),
                          CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text("Yes"), onPressed: (){
                            Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context)=> Homepage(box: box)));
                          }),
                        ],
                      );
                    });
                  },
                  child: tiles(CupertinoColors.destructiveRed, "Signout", Icon(CupertinoIcons.chevron_forward), Icons.login_outlined))
            ],
          )
        ],
      ),
    );
  }
}