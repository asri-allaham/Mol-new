import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class ProjectImagesCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const ProjectImagesCarousel({required this.imageUrls, super.key});

  @override
  State<ProjectImagesCarousel> createState() => _ProjectImagesCarouselState();
}

class _ProjectImagesCarouselState extends State<ProjectImagesCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: widget.imageUrls.map((image) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            );
          }).toList(),
          options: CarouselOptions(
            height: 200,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.imageUrls.asMap().entries.map((entry) {
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == entry.key
                    ? Colors.blueAccent
                    : Colors.grey[400],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
