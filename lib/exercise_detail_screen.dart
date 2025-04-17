import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../menstruation_phase_utils.dart'; // Where ExerciseRecommendation is defined

class ExerciseDetailScreen extends StatefulWidget {
  final String phase;
  final ExerciseRecommendation recommendation;

  const ExerciseDetailScreen({
    Key? key,
    required this.phase,
    required this.recommendation,
  }) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late String _currentExercise;
  YoutubePlayerController? _controller;
  bool _isFullScreen = false;

  final Map<String, String> _descriptions = {
    "Light Walking": "Gentle cardio to improve blood flow and reduce cramps.",
    "Gentle Yoga": "Relaxes muscles and helps with emotional balance.",
    "Stretching": "Reduces tightness and improves mobility.",
    "Breathing Exercises": "Calms the nervous system and lowers stress.",
    "Foam Rolling": "Relieves tension and boosts circulation.",
    "Running or Jogging": "Builds endurance and boosts mood through cardio.",
    "HIIT": "High-intensity bursts to increase metabolism and strength.",
    "Weight Training": "Enhances muscle growth and energy utilization.",
    "Dance Workouts": "Fun cardio that improves coordination and energy.",
    "Cycling": "Great aerobic activity to enhance stamina.",
    "Sprinting": "Short bursts to build explosive strength.",
    "CrossFit": "High-intensity strength and functional workouts.",
    "Powerlifting": "Boosts strength and hormones during peak energy.",
    "Team Sports": "Social, active, and energizing full-body movement.",
    "Yoga (restorative)": "Helps relax the body and improve sleep.",
    "Pilates": "Core strength and flexibility with low intensity.",
    "Walking": "Gentle movement to reduce bloating and tension.",
    "Swimming": "Soothes muscles and joints with full-body motion.",
    "Low-impact Cardio": "Maintains energy and mood with less strain.",
  };

  @override
  void initState() {
    super.initState();
    _currentExercise = '';
  }

  void _onFullscreenChange() {
    if (_controller == null) return;
    final isFullScreen = _controller!.value.isFullScreen;

    if (_isFullScreen != isFullScreen) {
      setState(() {
        _isFullScreen = isFullScreen;
      });

      if (isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    }
  }

  Future<void> _switchVideo(String newExercise) async {
    if (_currentExercise == newExercise) return;

    final newVideoUrl = widget.recommendation.videoLinks[newExercise];
    final newVideoId = YoutubePlayer.convertUrlToId(newVideoUrl ?? '');
    if (newVideoId == null) return;

    final oldController = _controller;
    oldController?.removeListener(_onFullscreenChange);
    oldController?.pause();

    setState(() {
      _controller = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    oldController?.dispose();

    final newController = YoutubePlayerController(
      initialVideoId: newVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        useHybridComposition: true,
        forceHD: true,
        controlsVisibleAtStart: true,
      ),
    )..addListener(_onFullscreenChange);

    setState(() {
      _currentExercise = newExercise;
      _controller = newController;
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onFullscreenChange);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  String _getIconPath(String title) {
    final customMap = {
      "Light Walking": "light_walking.png",
      "Gentle Yoga": "gentle_yoga.png",
      "Stretching": "stretching.png",
      "Breathing Exercises": "breathing.jpg",
      "Foam Rolling": "foam_rolling.png",
      "Running or Jogging": "running.jpg",
      "HIIT": "hiit.png",
      "Weight Training": "weight_training.jpg",
      "Dance Workouts": "dance_workouts.jpg",
      "Cycling": "cycling.jpg",
      "Sprinting": "sprinting.png",
      "CrossFit": "crossfit.png",
      "Powerlifting": "powerlifting.png",
      "Team Sports": "games.jpg", // optional placeholder
      "Yoga (restorative)": "restorative_yoga.png",
      "Pilates": "pilates.png",
      "Walking": "light_walking.png",
      "Swimming": "swimming.jpg",
      "Low-impact Cardio": "low-impact_cardio.jpg",
    };

    final fileName = customMap[title] ?? 'default_avatar.png';
    return 'assets/icons/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.recommendation.suggestedExercises;

    return Scaffold(
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                title: const Text('Exercise Details'),
                backgroundColor: Colors.deepPurple,
              ),
      body: Container(
        color: const Color(0xFFFCEEF5),
        child:
            _controller == null
                ? Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Select an exercise to begin.",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: exercises.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final title = exercises[index];
                          final description = _descriptions[title] ?? '';
                          return ListTile(
                            leading: Image.asset(
                              _getIconPath(title),
                              height: 36,
                              width: 36,
                              fit: BoxFit.contain,
                            ),
                            title: Text(title),
                            subtitle:
                                description.isNotEmpty
                                    ? Text(description)
                                    : null,
                            trailing:
                                _currentExercise == title
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : const Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.deepPurple,
                                    ),
                            onTap: () => _switchVideo(title),
                          );
                        },
                      ),
                    ),
                  ],
                )
                : YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    onReady: () => debugPrint('Player is ready'),
                  ),
                  builder: (context, player) {
                    return Column(
                      children: [
                        AspectRatio(aspectRatio: 16 / 9, child: player),
                        if (!_isFullScreen) ...[
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: exercises.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final title = exercises[index];
                                final description = _descriptions[title] ?? '';
                                return ListTile(
                                  leading: Image.asset(
                                    _getIconPath(title),
                                    height: 36,
                                    width: 36,
                                    fit: BoxFit.contain,
                                  ),
                                  title: Text(title),
                                  subtitle:
                                      description.isNotEmpty
                                          ? Text(description)
                                          : null,
                                  trailing:
                                      _currentExercise == title
                                          ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                          : const Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.deepPurple,
                                          ),
                                  onTap: () => _switchVideo(title),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
      ),
    );
  }
}
