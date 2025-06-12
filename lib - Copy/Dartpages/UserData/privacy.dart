import 'package:flutter/material.dart';
import '../../simple_functions/col.dart';

class privacy extends StatefulWidget {
  const privacy({super.key});

  @override
  State<privacy> createState() => _MyprivacyState();
}

class _MyprivacyState extends State<privacy> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xffFFFFFF),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Color(0xff002114)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: Color(0xff002114)),
        title: Text(
          "Privacy Policy",
          style: TextStyle(
            color: Color(0xff002114),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 21),
        children: [
          PrivacySection(
            title: "1. Types data we collect",
            content:
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do\n eiusmod tempor incididunt ut labore et "
                "dolore magna \naliqua. Ut enim ad minim veniam, quis nostrud exercitation\n ullamco laboris nisi ut aliquip "
                "ex ea commodo consequat. \n\nDuis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore "
                "eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.",
          ),
          PrivacySection(
              title: "2. Use of your personal data",
              content:
                  "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium,"
                  " totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae.\n\nNemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit."),
          PrivacySection(
              title: "3. Disclosure of your personal data",
              content:
                  "At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. \n\n"
                  "Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. \n\n"
                  "Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus\n\n\n")
        ],
      ),
    );
  }
}
