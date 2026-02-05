import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

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

class PlansPage extends StatefulWidget {
  final Box box;
  const PlansPage({super.key, required this.box});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final String secretKey =
      "xnd_development_GLxc5Y02G2w5Sh2KjMVUUDKRcrHao7tgPNYAoE9TkgIPlZuKtczqjk9ZNIV";

  Widget planCard(String name, int price, String duration) {
    return GestureDetector(
      onTap: () => payNow(context, name, price, duration),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name,
                style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("₱$price / $duration",
                style: const TextStyle(color: CupertinoColors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> payNow(
      BuildContext context, String plan, int price, String duration) async {

    // Show loading
    showCupertinoDialog(
      context: context,
      builder: (_) => const CupertinoAlertDialog(
        title: Text("Redirecting to payment"),
        content: CupertinoActivityIndicator(),
      ),
    );

    // Make Xendit request
    final auth = 'Basic ${base64Encode(utf8.encode(secretKey))}';
    final response = await http.post(
      Uri.parse("https://api.xendit.co/v2/invoices/"),
      headers: {
        "Authorization": auth,
        "Content-Type": "application/json"
      },
      body: jsonEncode({
        "external_id": "plan_$plan",
        "amount": price,
      }),
    );

    final data = jsonDecode(response.body);

    // Close loading
    Navigator.pop(context);

    // Open payment page
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => PaymentPage(
          url: data['invoice_url'],
          box: widget.box,
          planName: plan,
          planPrice: price,
          planDuration: duration,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Plans")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              planCard("Student", 99, "1 Month"),
              planCard("Individual", 199, "1 Month"),
              planCard("Duo", 299, "1 Month"),
              planCard("Family", 349, "1 Month"),
            ],
          ),
        ),
      ),
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
    try {
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network(
                  'https://storage.googleapis.com/pr-newsroom-wp/1/2018/11/Spotify_Logo_CMYK_Green.png',
                  width: 150,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to your account',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoTextField(
                  controller: _username,
                  placeholder: 'Username',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.person, color: CupertinoColors.black),
                  ),
                  style: const TextStyle(color: CupertinoColors.black),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _password,
                  placeholder: 'Password',
                  obscureText: hidePassword,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.lock, color: CupertinoColors.black),
                  ),
                  suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        color: CupertinoColors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      }),
                  style: const TextStyle(color: CupertinoColors.black),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(50),
                    color: const Color(0xFF1DB954),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16, color: CupertinoColors.white),
                    ),
                    onPressed: () {
                      if (_username.text.trim() == box.get("username") &&
                          _password.text.trim() == box.get("password")) {
                        Navigator.pushReplacement(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => Home(box: box)));
                      } else {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoAlertDialog(
                              title: const Text("Login Failed"),
                              content: const Text("Invalid username or password"),
                              actions: [
                                CupertinoButton(
                                  child: const Text("OK"),
                                  onPressed: () {
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
                ),
                const SizedBox(height: 16),
                if (box.get("biometrics") == true)
                  CupertinoButton(
                    child: const Icon(Icons.fingerprint, color: CupertinoColors.black),
                    onPressed: () {
                      authenticate();
                    },
                  ),
                CupertinoButton(
                  child: const Text(
                    'Erase Data',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          content: const Text("Are you sure to delete all data?"),
                          actions: [
                            CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Text("Cancel"),
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
                            CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Text("Yes"),
                                onPressed: () {
                                  box.clear();
                                  Navigator.pushReplacement(
                                    context,
                                    CupertinoPageRoute(
                                        builder: (context) => Signup(box: box)),
                                  );
                                }),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network(
                  'https://storage.googleapis.com/pr-newsroom-wp/1/2018/11/Spotify_Logo_CMYK_Green.png',
                  width: 150,
                ),
                const SizedBox(height: 40),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up for a free account',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                CupertinoTextField(
                  controller: _username,
                  placeholder: 'Username',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.person, color: CupertinoColors.black),
                  ),
                  style: const TextStyle(color: CupertinoColors.black),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _password,
                  placeholder: 'Password',
                  obscureText: hidePassword,
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(CupertinoIcons.lock, color: CupertinoColors.black),
                  ),
                  suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                        color: CupertinoColors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      }),
                  style: const TextStyle(color: CupertinoColors.black),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(50),
                    color: const Color(0xFF1DB954),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text('Sign Up',
                        style: TextStyle(fontSize: 16, color: CupertinoColors.white)),
                    onPressed: () {
                      box.put("username", _username.text.trim());
                      box.put("password", _password.text.trim());
                      box.put("biometrics", false);

                      Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(
                              builder: (context) => Homepage(box: box)));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cart), label: "Plans"),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: "Settings"),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomeList();
          case 1:
            return PlansPage(box: widget.box);
          case 2:
            return Settings(box: widget.box);
          default:
            return const SizedBox();
        }
      },
    );
  }
}

class PaymentPage extends StatefulWidget {
  final String url;
  final Box box;
  final String planName;
  final int planPrice;
  final String planDuration;

  const PaymentPage({super.key, required this.url, required this.box, required this.planName, required this.planPrice, required this.planDuration});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) async {
          // Check if payment is successful
          if (url.contains("success") || url.contains("paid")) {
            widget.box.put("plan_active", true);
            widget.box.put("plan_name", widget.planName);
            widget.box.put("plan_price", widget.planPrice);
            widget.box.put("plan_duration", widget.planDuration);

            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Payment"),
      ),
      child: WebViewWidget(controller: controller),
    );
  }
}

class HomeList extends StatefulWidget {
  const HomeList({super.key});

  @override
  State<HomeList> createState() => _HomeListState();
}

class _HomeListState extends State<HomeList> {
  final bool isDark = false;

  Widget activePlanCard(Box box) {
    if (box.get("plan_active") != true) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.systemGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Active Plan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${box.get("plan_name")} • ₱${box.get("plan_price")} / ${box.get("plan_duration")}",
            style: const TextStyle(color: CupertinoColors.black),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(
                CupertinoIcons.largecircle_fill_circle,
                color: CupertinoColors.systemGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text("Subscription Active"),
            ],
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text(
              "Cancel Subscription",
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              box.put("plan_active", false);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

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
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(8),
      child: Text(title, style: const TextStyle(color: CupertinoColors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box("database");
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Home"),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            activePlanCard(box),
            const SizedBox(height: 16),
            const Text("New Releases", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  musicCard("Album 1", "https://picsum.photos/id/1011/200/200"),
                  musicCard("Album 2", "https://picsum.photos/id/1012/200/200"),
                  musicCard("Album 3", "https://picsum.photos/id/1013/200/200"),
                ],
              ),
            ),
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