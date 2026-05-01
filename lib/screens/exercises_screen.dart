import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nindra/audio_player_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Map<String, dynamic>> exercisesItems = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final response = await Supabase.instance.client
          .from('exercises')
          .select()
          .order('title');

      setState(() {
        exercisesItems = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        errorMessage = response.isEmpty ? 'No exercises available.' : '';
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error loading exercises: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Exercises'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: exercisesItems.length,
                  itemBuilder: (context, index) {
                    final item = exercisesItems[index];
                    return ListTile(
                      title: Text(item['title'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(item['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MediaPlayerScreen(
                              playlist: exercisesItems,
                              currentIndex: index,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}