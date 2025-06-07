import 'package:MOLLILE/Dartpages/Communicate%20with%20investor/business%20owners/masseges.dart';
import 'package:MOLLILE/Dartpages/HomePage/Home_page.dart';
import 'package:MOLLILE/project%20post/ProjectAdd.dart';
import 'package:MOLLILE/Dartpages/sighUpIn/LoginPage.dart';
import 'package:MOLLILE/Dartpages/sighUpIn/login_state.dart';
import 'package:MOLLILE/i18n/LanguageScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'rowprofile.dart';
import 'privacy.dart';
import 'edid_profile.dart';
import '../simple_functions/Language.dart';
import 'Notifications.dart';
import 'profile info display/UIDisplay.dart';
// import 'package:pages/simple_functions/Language.dart';

class ProfileInformation extends StatefulWidget {
  const ProfileInformation({super.key});

  @override
  State<ProfileInformation> createState() => _ProfileInformationState();
}

class _ProfileInformationState extends State<ProfileInformation> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool isDarkMode = false;
  int _selectedIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appLang = Provider.of<AppLanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xffECECEC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 38),
                Container(
                  color: const Color(0xffD2E4DC),
                  child: Row(
                    children: const [
                      SizedBox(width: 18),
                      Icon(Icons.notifications,
                          size: 35, color: Color(0xff002114)),
                      Spacer(),
                      Icon(Icons.restore, size: 35, color: Color(0xff002114)),
                      SizedBox(width: 23),
                      Icon(Icons.menu, size: 35, color: Color(0xff002114)),
                      SizedBox(width: 17),
                    ],
                  ),
                ),
                Center(
                  child: Stack(
                    children: [
                      Image.asset('lib/img/img.png',
                          width: 500, height: 198, fit: BoxFit.cover),
                      Positioned(
                        bottom: 5,
                        right: 130,
                        child: Stack(
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: (_userData?['imageUrl'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? Image.network(_userData!['imageUrl'],
                                        fit: BoxFit.cover)
                                    : Image.asset("lib/img/person1.png",
                                        fit: BoxFit.cover),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      color: Color(0xff00130B), size: 25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _userData?['name'] ?? user?.displayName ?? 'No name',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff012113)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, size: 20, color: Color(0xff002114)),
                    const SizedBox(width: 5),
                    Text(
                      _userData?['email'] ?? user?.email ?? 'No email',
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xff012113)),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, size: 20, color: Color(0xff002114)),
                    const SizedBox(width: 5),
                    Text(
                      _userData?['phone'] ?? 'No phone',
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xff012113)),
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                _buildSettingsSection(context, appLang),
              ],
            ),
      bottomNavigationBar: Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff54826D),
                Color(0xff03361F),
                Color(0xff03361F),
                Color(0xff03361F),
                Color(0xff03361F),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 0),
              _buildNavItem(Icons.add, 1),
              _buildNavItem(Icons.message, 2),
              _buildNavItem(Icons.person, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, AppLanguageProvider appLang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          buildSettingsGroup([
            buildRow(
              icon: Icons.newspaper_sharp,
              label: "Edit profile information",
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => EdidProfile())),
              trailing: "On",
            ),
            buildRow(
              icon: Icons.notifications,
              label: "Notifications",
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => Notifications())),
              trailing: "On",
            ),
            buildRow(
              icon: Icons.translate,
              label: "Language".tr(),
              trailing: appLang.currentLanguage,
              onTap: () async {
                final selected = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(builder: (_) => LanguageScreen()),
                );
                if (selected != null) {
                  try {
                    final appLanguage = Provider.of<AppLanguageProvider>(
                        context,
                        listen: false);
                    await appLanguage.changeLanguageByIndex(selected);
                    await context.setLocale(appLanguage.appLocal);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Need a restart to applay it..')),
                    ); // Phoenix.rebirth(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('chose dirfint language!')),
                    );
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 25),
          buildSettingsGroup([
            buildRow(icon: Icons.security, label: "Security"),
            buildRow(
              icon: Icons.color_lens,
              label: "Theme",
              onTap: () => setState(() => isDarkMode = !isDarkMode),
              trailing: isDarkMode ? "Dark mode" : "Light mode",
            ),
          ]),
          const SizedBox(height: 25),
          buildSettingsGroup([
            buildRow(icon: Icons.help_outline, label: "Help & Support"),
            buildRow(icon: Icons.contact_mail, label: "Contact us"),
            buildRow(
              icon: Icons.lock_outline,
              label: "Privacy policy",
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => privacy())),
            ),
          ]),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<LoginState>(context, listen: false).logout();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const Homepage()));
            },
            child: Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (_selectedIndex == 0) {
          if (user != null) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Homepage()));
          }
        } else if (_selectedIndex == 1) {
          if (user != null) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProjectAdd()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        } else if (_selectedIndex == 2) {
          if (user != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => MessagesPage()));
          } else {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()));
          }
        }
      },
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}
