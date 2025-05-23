import 'package:MOLLILE/Dartpages/CustomWidget/buttom.dart';
import 'package:MOLLILE/Dartpages/HomePage/Home_page.dart';
import 'package:flutter/material.dart';

class StartThreePages extends StatefulWidget {
  static String IDPuchName = "StartThreePages";

  final int Number_page;

  const StartThreePages({
    super.key,
    required this.Number_page,
  });

  @override
  State<StartThreePages> createState() => _StartThreePagesState();
}

class _StartThreePagesState extends State<StartThreePages> {
  late final List<Map<String, String>> items;

  @override
  void initState() {
    super.initState();
    items = [
      {
        'image': 'lib/Images/image_one.jpeg',
        'title': 'Achieve Your Dream with Smart\nInvestment',
        'subtitle':
            'Whether you\'re a business owner looking for funding or an investor seeking opportunities, we provide the perfect platform for success!'
      },
      {
        'image': 'lib/Images/image_two.jpeg',
        'title': 'Endless Opportunities Await',
        'subtitle':
            'Use smart search and filters to find the best projects or investors that match your interests'
      },
      {
        'image': 'lib/Images/image_three.jpeg',
        'title': 'Connect & Start Your Journey Today',
        'subtitle':
            'Chat with business owners and investors, and join public or private rooms to explore more opportunities'
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD3E4DC),
        actions: [
          TextButton(
            child: const Text(
              "Skip >",
              style: TextStyle(fontSize: 15, color: Color(0xFF003621)),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Homepage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFECECEC),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: 300,
                  child: Image.asset(
                    items[widget.Number_page]['image']!,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    items[widget.Number_page]['title']!,
                    style: const TextStyle(
                      fontSize: 25,
                      color: Color(0xFF003621),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    items[widget.Number_page]['subtitle']!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFA2C0AE),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                height: 7,
                width: 7,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: index == widget.Number_page
                      ? const Color(0xff004D2D)
                      : const Color(0xffA2C0AE),
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          GradientButton(
            text: "Next",
            onTap: () async {
              if (widget.Number_page < 2) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => StartThreePages(
                      Number_page: widget.Number_page + 1,
                    ),
                  ),
                );
              } else {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const Homepage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
