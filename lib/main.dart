import 'package:flutter/material.dart';

void main() {
  runApp(const VipMindApp());
}

class VipMindApp extends StatelessWidget {
  const VipMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VipMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A6FA5)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B2838),
              Color(0xFF4A6FA5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A6FA5), Color(0xFF9D4EDD)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A6FA5).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                // App Name
                const Text(
                  'VipMind',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Your Brain, Amplified.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 60),

                // Success Message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06D6A0).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF06D6A0).withOpacity(0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Color(0xFF06D6A0),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'App is running! 🎉',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF06D6A0),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Start Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MindmapScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A6FA5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    'Create Mindmap',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

class MindmapScreen extends StatefulWidget {
  const MindmapScreen({super.key});

  @override
  State<MindmapScreen> createState() => _MindmapScreenState();
}

class _MindmapScreenState extends State<MindmapScreen> {
  final List<MindNode> nodes = [
    MindNode(id: '1', text: 'Central Idea', x: 150, y: 250, color: const Color(0xFF4A6FA5)),
  ];

  int nodeCount = 1;

  void _addNode() {
    setState(() {
      nodeCount++;
      final colors = [
        const Color(0xFF06D6A0),
        const Color(0xFFFFD166),
        const Color(0xFF9D4EDD),
        const Color(0xFFEF476F),
        const Color(0xFF118AB2),
      ];
      nodes.add(MindNode(
        id: '$nodeCount',
        text: 'Idea $nodeCount',
        x: 50.0 + (nodeCount * 30) % 250,
        y: 100.0 + (nodeCount * 50) % 400,
        color: colors[nodeCount % colors.length],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Mindmap'),
        backgroundColor: const Color(0xFF4A6FA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Canvas
          ...nodes.map((node) => Positioned(
            left: node.x,
            top: node.y,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  node.x += details.delta.dx;
                  node.y += details.delta.dy;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: node.color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: node.color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  node.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNode,
        backgroundColor: const Color(0xFF4A6FA5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class MindNode {
  final String id;
  String text;
  double x;
  double y;
  Color color;

  MindNode({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.color,
  });
}