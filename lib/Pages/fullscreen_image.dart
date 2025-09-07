import 'package:flutter/material.dart';
import 'package:studhome/constants/app_colors.dart';

class FullScreenImagePage extends StatefulWidget {
  final List<Map<String, String>> images;
  final int initialIndex;

  const FullScreenImagePage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  late int currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.darkBackground),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${currentIndex + 1}/${widget.images.length}",
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w500,
                color: AppColors.darkBackground,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              widget.images[currentIndex]["caption"] ??
                  "Image ${currentIndex + 1}",
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w500,
                color: AppColors.darkBackground,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  widget.images[index]["file_url"]!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: screenHeight * 0.5,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/roomimage.jpg',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: screenHeight * 0.5,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            child: Row(
              children: widget.images.asMap().entries.map((entry) {
                final index = entry.key;
                final imageData = entry.value;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.015,
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        currentIndex = index;
                        _pageController.jumpToPage(index);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: currentIndex == index
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: Image.network(
                          imageData["file_url"]!,
                          height: screenWidth * 0.15,
                          width: screenWidth * 0.15,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'assets/images/roomimage.jpg',
                                height: screenWidth * 0.15,
                                width: screenWidth * 0.15,
                                fit: BoxFit.cover,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }
}
