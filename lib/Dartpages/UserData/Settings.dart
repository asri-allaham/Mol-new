import 'package:Mollni/Dartpages/Communicate%20with%20investor/business%20owners/messages_page.dart';
import 'package:Mollni/Dartpages/HomePage/Home_page.dart';
import 'package:Mollni/Dartpages/HomePage/favorites.dart';
import 'package:Mollni/Dartpages/UserData/edit_profile.dart';
import 'package:Mollni/Dartpages/project%20post%20Contracts/ProjectAdd.dart';
import 'package:Mollni/Dartpages/sighUpIn/LoginPage.dart';
import 'package:Mollni/Dartpages/sighUpIn/login_state.dart';
import 'package:Mollni/i18n/LanguageScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher/url_launcher.dart';
import 'privacy.dart';
import '../../simple_functions/Language.dart';
import 'Notifications/Notifications.dart';
import 'profile info display/UIDisplay.dart';

class settings extends StatefulWidget {
  const settings({super.key});

  @override
  State<settings> createState() => _settingsState();
}

class _settingsState extends State<settings> {
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
      appBar: AppBar(
        toolbarHeight: 2,
        backgroundColor: Color(0xffD2E4DC),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xffECECEC),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Container(
                  color: Color(0xffD2E4DC),
                  height: 50,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 12,
                        left: 12,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xff012113),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rest of your original code remains unchanged
                Container(height: 30, color: Color(0xffD2E4DC)),
                Container(
                  color: const Color(0xffD2E4DC),
                  child: Row(children: [
                    SizedBox(width: 18),
                    Spacer(),
                  ]),
                ),
                Center(
                  child: Stack(
                    children: [
                      Image.asset('lib/img/img.png',
                          width: 500, height: 210, fit: BoxFit.cover),
                      Positioned(
                        bottom: 0,
                        right: 127,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 0),
                Center(
                  child: Text(
                    _userData?['username'] ?? user?.displayName ?? 'No name',
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
                SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_userData?['phone'] != null &&
                        _userData!['phone'].toString().trim().isNotEmpty) ...[
                      const Icon(Icons.phone,
                          size: 20, color: Color(0xff002114)),
                      const SizedBox(width: 5),
                      Text(
                        _userData!['phone'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xff012113),
                        ),
                      ),
                    ],
                  ],
                ),
                _buildSettingsSection(context, appLang),
              ],
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
            ),
            SizedBox(
              height: 10,
            ),
            buildRow(
              icon: Icons.notifications,
              label: "Notifications",
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => Notifications())),
            ),
            SizedBox(
              height: 10,
            ),
            buildRow(
              icon: Icons.translate,
              label: "Language".tr(),
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
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('chose dirfint language!')),
                    );
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 15),
          buildSettingsGroup([
            buildRow(
              icon: Icons.contact_mail,
              label: "Contact us",
              onTap: () async {
                final Uri uri =
                    Uri.parse("https://www.linkedin.com/in/asrilaham/");

                if (!await launchUrl(uri,
                    mode: LaunchMode.externalApplication)) {
                  throw 'Could not launch $uri';
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            buildRow(
              icon: Icons.help_outline,
              label: "Help & Support",
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'asri.allaham@gmail.com',
                  query: Uri.encodeFull(
                      'subject=Help Request&body=Hello, I need assistance with...'),
                );

                if (!await launchUrl(emailLaunchUri)) {
                  throw 'Could not launch $emailLaunchUri';
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            buildRow(
              icon: Icons.lock_outline,
              label: "Privacy policy",
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => privacy())),
            ),
          ]),
          const SizedBox(height: 15),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffE5E5E5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.centerLeft,
              ),
              onPressed: () async {
                await Provider.of<LoginState>(context, listen: false).logout();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const Homepage()));
              },
              child: Row(
                children: [
                  SizedBox(width: 6),
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  Text("    Logout",
                      style: TextStyle(color: Colors.red, fontSize: 18)),
                ],
              )),
        ],
      ),
    );
  }
}
