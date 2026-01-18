import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/providers/mindmap_provider.dart';
import '../../../data/models/mindmap_model.dart';
import '../widgets/mindmap_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/home_header.dart';
import '../widgets/home_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMindmaps();
  }

  void _loadMindmaps() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<MindmapProvider>().loadMindmaps(user.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            FadeInDown(
              child: HomeHeader(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onSearchChanged: (query) {
                  setState(() => _searchQuery = query);
                },
              ),
            ),

            // Quick Actions
            FadeInLeft(
              delay: const Duration(milliseconds: 200),
              child: const QuickActions(),
            ),

            const SizedBox(height: 16),

            // Tabs
            FadeIn(
              delay: const Duration(milliseconds: 300),
              child: _buildTabBar(),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMindmapsGrid('all'),
                  _buildMindmapsGrid('recent'),
                  _buildMindmapsGrid('favorites'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: _buildFAB(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Recent'),
          Tab(text: 'Favorites'),
        ],
      ),
    );
  }

  Widget _buildMindmapsGrid(String filter) {
    return Consumer<MindmapProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }

        List<MindmapModel> mindmaps = provider.mindmaps;

        // Apply filters
        if (filter == 'favorites') {
          mindmaps = mindmaps.where((m) => m.isFavorite).toList();
        } else if (filter == 'recent') {
          mindmaps = List.from(mindmaps)
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          mindmaps = mindmaps.take(10).toList();
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          mindmaps = mindmaps
              .where((m) =>
              m.title.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (mindmaps.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => _loadMindmaps(),
          color: AppColors.primaryBlue,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isGridView
                ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: mindmaps.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: MindmapCard(
                    mindmap: mindmaps[index],
                    onTap: () => _openMindmap(mindmaps[index]),
                    onFavorite: () => _toggleFavorite(mindmaps[index]),
                    onDelete: () => _deleteMindmap(mindmaps[index]),
                  ),
                );
              },
            )
                : ListView.builder(
              itemCount: mindmaps.length,
              itemBuilder: (context, index) {
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MindmapCard(
                      mindmap: mindmaps[index],
                      isListView: true,
                      onTap: () => _openMindmap(mindmaps[index]),
                      onFavorite: () => _toggleFavorite(mindmaps[index]),
                      onDelete: () => _deleteMindmap(mindmaps[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 64,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No mindmaps yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first mindmap to get started',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewMindmap,
            icon: const Icon(Icons.add),
            label: const Text('Create Mindmap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreateOptions,
      backgroundColor: AppColors.primaryBlue,
      icon: const Icon(Icons.add),
      label: const Text('New'),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateOptionsSheet(
        onBlankMindmap: _createNewMindmap,
        onFromTemplate: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.templateGallery);
        },
        onFromText: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.textToMindmap);
        },
        onFromVoice: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.voiceToMindmap);
        },
        onFromImage: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRoutes.imageToMindmap);
        },
      ),
    );
  }

  Future<void> _createNewMindmap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mindmap = await context.read<MindmapProvider>().createMindmap(
      title: 'Untitled Mindmap',
      ownerId: user.uid,
    );

    if (mindmap != null && mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.mindmapEditor,
        arguments: {'mindmapId': mindmap.id},
      );
    }
  }

  void _openMindmap(MindmapModel mindmap) {
    Navigator.pushNamed(
      context,
      AppRoutes.mindmapEditor,
      arguments: {'mindmapId': mindmap.id},
    );
  }

  void _toggleFavorite(MindmapModel mindmap) {
    // Implement toggle favorite
  }

  void _deleteMindmap(MindmapModel mindmap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mindmap'),
        content: Text('Are you sure you want to delete "${mindmap.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<MindmapProvider>().deleteMindmap(mindmap.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOptionsSheet extends StatelessWidget {
  final VoidCallback onBlankMindmap;
  final VoidCallback onFromTemplate;
  final VoidCallback onFromText;
  final VoidCallback onFromVoice;
  final VoidCallback onFromImage;

  const _CreateOptionsSheet({
    required this.onBlankMindmap,
    required this.onFromTemplate,
    required this.onFromText,
    required this.onFromVoice,
    required this.onFromImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Create New Mindmap',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Options Grid
          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  icon: Icons.add_box_outlined,
                  label: 'Blank',
                  color: AppColors.primaryBlue,
                  onTap: () {
                    Navigator.pop(context);
                    onBlankMindmap();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptionTile(
                  icon: Icons.dashboard_customize_outlined,
                  label: 'Template',
                  color: AppColors.creativePurple,
                  onTap: onFromTemplate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _OptionTile(
                  icon: Icons.text_fields,
                  label: 'From Text',
                  color: AppColors.calmGreen,
                  onTap: onFromText,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _OptionTile(
                  icon: Icons.mic_outlined,
                  label: 'From Voice',
                  color: AppColors.accentYellow,
                  onTap: onFromVoice,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _OptionTile(
            icon: Icons.image_outlined,
            label: 'From Image',
            color: AppColors.warningOrange,
            onTap: onFromImage,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}