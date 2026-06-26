import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() async {
  runApp(const ProductSpotterApp());
}

class ProductSpotterApp extends StatelessWidget {
  const ProductSpotterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProductSpotter - Find & Identify Products',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  List<RecognizedProduct> recognizedProducts = [];
  bool isLoading = false;
  late ImageLabeler _imageLabeler;

  @override
  void initState() {
    super.initState();
    // Initialize ML Kit Image Labeler
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions());
  }

  @override
  void dispose() {
    _imageLabeler.close();
    super.dispose();
  }

  Future<void> pickImageAndRecognize() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => isLoading = true);
        
        // Recognize product from image
        final result = await recognizeProduct(File(pickedFile.path));
        
        setState(() {
          recognizedProducts.insert(0, result);
          isLoading = false;
        });

        _showRecognitionDialog(result);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() => isLoading = true);
        
        final result = await recognizeProduct(File(pickedFile.path));
        
        setState(() {
          recognizedProducts.insert(0, result);
          isLoading = false;
        });

        _showRecognitionDialog(result);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<RecognizedProduct> recognizeProduct(File imageFile) async {
    try {
      // Use Google ML Kit for on-device image recognition
      final inputImage = InputImage.fromFile(imageFile);
      final labels = await _imageLabeler.processImage(inputImage);
      
      if (labels.isNotEmpty) {
        // Get the top label
        final topLabel = labels.first;
        return RecognizedProduct(
          name: topLabel.label,
          confidence: topLabel.confidence,
          category: _categorizeItem(topLabel.label),
          estimatedValue: _estimateValue(topLabel.label, topLabel.confidence),
        );
      } else {
        throw Exception('No items detected in image');
      }
    } catch (e) {
      print('ML Kit Recognition error: $e');
      _showErrorDialog('Recognition failed: $e');
      return RecognizedProduct(
        name: 'Unknown Item',
        confidence: 0.0,
        category: 'Other',
        estimatedValue: 'N/A',
      );
    }
  }

  String _estimateValue(String itemName, double confidence) {
    // Simple valuation logic based on item type and confidence
    itemName = itemName.toLowerCase();
    
    int minValue = 5;
    int maxValue = 20;
    
    if (itemName.contains('shoe') || itemName.contains('sneaker') || itemName.contains('boot')) {
      minValue = 25;
      maxValue = 75;
    } else if (itemName.contains('jacket') || itemName.contains('coat') || itemName.contains('sweater')) {
      minValue = 20;
      maxValue = 65;
    } else if (itemName.contains('phone') || itemName.contains('tablet') || itemName.contains('laptop')) {
      minValue = 75;
      maxValue = 300;
    } else if (itemName.contains('watch') || itemName.contains('jewelry')) {
      minValue = 30;
      maxValue = 150;
    } else if (itemName.contains('bag') || itemName.contains('backpack')) {
      minValue = 20;
      maxValue = 80;
    }
    
    // Adjust based on confidence
    if (confidence > 0.9) {
      maxValue = (maxValue * 1.2).toInt();
    } else if (confidence < 0.7) {
      minValue = (minValue * 0.8).toInt();
    }
    
    return '\$$minValue-$maxValue';
  }

  String _categorizeItem(String itemName) {
    itemName = itemName.toLowerCase();
    
    if (itemName.contains('shoe') || itemName.contains('sneaker') || itemName.contains('boot') || itemName.contains('sandal')) {
      return 'Footwear';
    } else if (itemName.contains('shirt') || itemName.contains('jacket') || itemName.contains('coat') || itemName.contains('sweater') || itemName.contains('jeans') || itemName.contains('pants')) {
      return 'Clothing';
    } else if (itemName.contains('phone') || itemName.contains('tablet') || itemName.contains('laptop') || itemName.contains('camera') || itemName.contains('speaker')) {
      return 'Electronics';
    } else if (itemName.contains('watch') || itemName.contains('ring') || itemName.contains('necklace') || itemName.contains('bracelet')) {
      return 'Jewelry';
    } else if (itemName.contains('bag') || itemName.contains('wallet') || itemName.contains('belt') || itemName.contains('hat')) {
      return 'Accessories';
    } else if (itemName.contains('cup') || itemName.contains('mug') || itemName.contains('plate') || itemName.contains('bowl')) {
      return 'Home';
    } else if (itemName.contains('book')) {
      return 'Books';
    } else {
      return 'Other';
    }
  }

  void _showRecognitionDialog(RecognizedProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Recognized! ✓'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Category: ${product.category}'),
            Text('Confidence: ${(product.confidence * 100).toStringAsFixed(0)}%'),
            Text('Est. Value: ${product.estimatedValue}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add to eBay listing
              Navigator.pop(context);
              _showEbayDialog(product);
            },
            child: const Text('List on eBay'),
          ),
        ],
      ),
    );
  }

  void _showEbayDialog(RecognizedProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ready to List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Item: ${product.name}'),
            const SizedBox(height: 16),
            const Text('Configure shipping and list on eBay:'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening eBay in browser...')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Go to eBay'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ProductSpotter'),
            Text(
              'Recognize & List Products',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.blue.shade50,
                    child: Column(
                      children: [
                        const Icon(Icons.photo_camera, size: 48, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Snap & Recognize Products',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Take a photo or upload from gallery to identify items',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: pickImageAndRecognize,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: pickFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Recognized Products List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recognized Items (${recognizedProducts.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        recognizedProducts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'No items recognized yet.\nTap Camera or Gallery to start!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recognizedProducts.length,
                                itemBuilder: (context, index) {
                                  final product = recognizedProducts[index];
                                  return ProductCard(product: product);
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final RecognizedProduct product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(product.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(product.category, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(product.estimatedValue, 
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Listing ${product.name} on eBay...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
              ),
              child: const Text('List on eBay'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecognizedProduct {
  final String name;
  final double confidence;
  final String category;
  final String estimatedValue;

  RecognizedProduct({
    required this.name,
    required this.confidence,
    required this.category,
    required this.estimatedValue,
  });
}