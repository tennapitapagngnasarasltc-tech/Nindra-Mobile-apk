import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:line_icons/line_icons.dart';
import 'package:nindra/audio_player_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EntertainmentScreen extends StatefulWidget {
  final void Function(int)? onTabChange;
  const EntertainmentScreen({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen>
    with TickerProviderStateMixin {

  // 🌙 Dark Theme Colors
  static const Color kAccentGreen = Color(0xFF10A98E);
  static const Color kBackgroundDark = Color(0xFF121212);
  static const Color kCardDark = Color(0xFF1E1E1E);
  static const Color kTextPrimary = Color(0xFFEAEAEA);
  static const Color kTextSecondary = Color(0xFFB0B0B0);

  List<Map<String, dynamic>> entertainmentItems = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meditation', 'Music Track', 'Video'];

  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadData();
    });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_tabController.index == 0) {
      await fetchAllEntertainmentContent();
    } else {
      await fetchRecommendedEntertainmentContent();
    }
  }

  Future<void> fetchAllEntertainmentContent() async {
    try {
      final response = await Supabase.instance.client
          .from('entertainments')
          .select()
          .order('title');

      setState(() {
        entertainmentItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        errorMessage = response.isEmpty
            ? 'No entertainment content available.'
            : '';
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading content: $e";
        isLoading = false;
      });
    }
  }

  Future<void> fetchRecommendedEntertainmentContent() async {
    try {
      try {
        final baseUrl = Config.apiBaseUrl;
        final apiUrl = '$baseUrl/recommend_entertainment/api/suggestions/1';

        await http.get(Uri.parse(apiUrl));
        await Future.delayed(const Duration(seconds: 1));
      } catch (_) {}

      final response = await Supabase.instance.client
          .from('recommended_entertainments')
          .select('entertainments(*), recommended_at');

      final items = response.map<Map<String, dynamic>>((item) {
        final entertainment = item['entertainments'];
        return {...entertainment, 'recommended_at': item['recommended_at']};
      }).toList();

      setState(() {
        entertainmentItems = items;
        isLoading = false;
        errorMessage = items.isEmpty
            ? 'No recommendations yet'
            : '';
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading recommendations: $e";
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') return entertainmentItems;
    return entertainmentItems
        .where((item) => item['type'] == selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onTabChange?.call(0);
        return false;
      },
      child: Scaffold(
        backgroundColor: kBackgroundDark,

        appBar: AppBar(
          backgroundColor: kBackgroundDark,
          elevation: 0,
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LineIcons.music, color: kAccentGreen),
                const SizedBox(width: 8),
                Text(
                  'Entertainment',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: kAccentGreen),
              onPressed: _loadData,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: kAccentGreen,
            labelColor: kAccentGreen,
            unselectedLabelColor: kTextSecondary,
            tabs: const [
              Tab(text: "All Content"),
              Tab(text: "For You"),
            ],
          ),
        ),

        body: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Find peace through music, meditation, and reflection.",
                style: TextStyle(
                  color: kTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (!isLoading && errorMessage.isEmpty && _tabController.index == 0)
              _buildCategoryFilter(),

            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : _buildContentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.all(6),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              backgroundColor: kCardDark,
              selectedColor: kAccentGreen.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? kAccentGreen : kTextSecondary,
              ),
              onSelected: (_) {
                setState(() => selectedCategory = category);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(color: kAccentGreen),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Text(
        errorMessage,
        style: TextStyle(color: kTextSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContentList() {
    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          "No content found",
          style: TextStyle(color: kTextSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (_, index) {
        final item = filteredItems[index];
        return _buildEntertainmentItem(item);
      },
    );
  }

  Widget _buildEntertainmentItem(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final type = item['type'] ?? '';
    final coverImgUrl = item['cover_img_url'];

    return Card(
      color: kCardDark,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: coverImgUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  coverImgUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.music_note, color: kAccentGreen),

        title: Text(
          title,
          style: TextStyle(color: kTextPrimary),
        ),

        subtitle: Text(
          type,
          style: TextStyle(color: kAccentGreen),
        ),

        trailing: Icon(
          Icons.play_circle_fill,
          color: kAccentGreen,
          size: 30,
        ),

        onTap: () => _navigateToPlayer(item),
      ),
    );
  }

  void _navigateToPlayer(Map<String, dynamic> item) {
    final playlistItems = filteredItems
        .where((element) => element['media_file_url'] != null)
        .toList();

    final currentIndex = playlistItems.indexWhere((element) => element == item);
    if (currentIndex == -1) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaPlayerScreen(
          playlist: playlistItems,
          currentIndex: currentIndex,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}