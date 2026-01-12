import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../enums/quiz_difficulty.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/points_service.dart';
import '../../../services/matchmaking_service.dart';
import '../../../models/question_model.dart';
import '../../../models/game_room.dart';
import '../models/quiz_config.dart';
import '../services/quiz_question_service.dart';
import '../widgets/quiz_widgets.dart';
import '../services/quiz_settings_service.dart';

/// Tüm quiz kategorileri için ortak oyun ekranı
class GenericQuizGameScreen extends StatefulWidget {
  final QuizConfig config;
  final QuizDifficulty difficulty;
  final String? roomCode;
  final bool isMultiplayer;
  
  /// Karışık zorluk modu - tüm zorluk seviyelerinden soru gelir
  final bool useMixedDifficulty;

  const GenericQuizGameScreen({
    super.key,
    required this.config,
    required this.difficulty,
    this.roomCode,
    this.isMultiplayer = false,
    this.useMixedDifficulty = false,
  });

  @override
  State<GenericQuizGameScreen> createState() => _GenericQuizGameScreenState();
}

class _GenericQuizGameScreenState extends State<GenericQuizGameScreen>
    with TickerProviderStateMixin {
  final QuizQuestionService _questionService = QuizQuestionService();
  final MatchmakingService _matchmaking = MatchmakingService();
  final QuizSettingsService _settingsService = QuizSettingsService();
  
  List<QuestionModel> _questions = [];
  List<AnswerRecord> _answers = [];
  int _currentIndex = 0;
  int _score = 0;
  int _minSuccessRate = 0;
  int _selectedOption = -1;
  bool _showResult = false;
  bool _isLoading = true;
  bool _isFinished = false;
  
  GameRoom? _gameRoom;
  StreamSubscription? _roomSubscription;
  bool _waitingForOpponent = false;
  
  Timer? _timer;
  int _remainingSeconds = 30;
  
  late AnimationController _pulseController;

  int get _correctCount => _answers.where((a) => a.isCorrect).length;
  int get _wrongCount => _answers.where((a) => !a.isCorrect).length;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.difficulty.timePerQuestion * widget.difficulty.questionCount;
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    
    setState(() => _isLoading = true);
    
    // Load config first
    _minSuccessRate = await _settingsService.getMinSuccessRate(widget.config.categoryId);

    List<QuestionModel> questions;
    
    if (widget.isMultiplayer && widget.roomCode != null) {
      questions = await _questionService.getQuestionsForMultiplayer(
        categoryId: widget.config.categoryId,
        roomCode: widget.roomCode!,
        count: widget.config.defaultQuestionCount,
      );
    } else if (widget.useMixedDifficulty) {
      // Karışık zorluk modu - tüm zorluk seviyelerinden soru çek
      questions = await _questionService.getQuestionsForMixedDifficulty(
        categoryId: widget.config.categoryId,
        count: widget.config.defaultQuestionCount,
      );
    } else {
      questions = await _questionService.getQuestionsForSolo(
        categoryId: widget.config.categoryId,
        difficulty: widget.difficulty,
        count: widget.config.defaultQuestionCount,
      );
    }
    
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
      
      if (widget.isMultiplayer && widget.roomCode != null) {
        await _markReadyAndWait();
      } else {
        _startTimer();
      }
    }
  }

  Future<void> _markReadyAndWait() async {
    await _matchmaking.markReady(
      roomCode: widget.roomCode!,
      questionCount: widget.difficulty.questionCount,
      gameDuration: widget.difficulty.timePerQuestion * widget.difficulty.questionCount,
    );
    
    setState(() => _waitingForOpponent = true);
    
    _roomSubscription = _matchmaking.listenToRoom(widget.roomCode!).listen((room) async {
      if (room != null && mounted) {
        setState(() => _gameRoom = room);
        
        if (room.isAllReady && _waitingForOpponent) {
          _waitingForOpponent = false;
          _remainingSeconds = room.gameDuration;
          _startTimer();
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finishGame();
      }
    });
  }

  void _selectOption(int index) {
    if (_showResult || _isFinished) return;
    
    final question = _questions[_currentIndex];
    final isCorrect = index == question.correctOptionIndex;
    
    _answers.add(AnswerRecord(
      question: question,
      selectedIndex: index,
      isCorrect: isCorrect,
    ));
    
    setState(() {
      _selectedOption = index;
      _showResult = true;
      if (isCorrect) _score += 10;
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOption = -1;
          _showResult = false;
        });
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _timer?.cancel();
    setState(() => _isFinished = true);
    
    if (widget.isMultiplayer && widget.roomCode != null) {
      _submitScoreAndWait();
    } else {
      _savePoints();
    }
  }

  Future<void> _submitScoreAndWait() async {
    final score = _correctCount * 2;
    await _matchmaking.submitGameScore(
      roomCode: widget.roomCode!,
      score: score,
      correctCount: _correctCount,
    );
    
    setState(() => _waitingForOpponent = true);
    
    _roomSubscription = _matchmaking.listenToRoom(widget.roomCode!).listen((room) {
      if (room != null && mounted) {
        setState(() => _gameRoom = room);
        
        if (room.isGameComplete) {
          _savePointsWithResult(room);
        }
      }
    });
  }

  Future<void> _savePointsWithResult(GameRoom room) async {
    final isHost = await _matchmaking.amIHost(widget.roomCode!);
    final myScore = isHost ? room.hostScore : room.guestScore;
    final opponentScore = isHost ? room.guestScore : room.hostScore;
    
    int earnedPoints = myScore;
    if (myScore > opponentScore) earnedPoints += 50;
    else if (myScore == opponentScore) earnedPoints += 10;
    
    if (earnedPoints > 0) {
      await PointsService().addPoints(
        points: earnedPoints,
        source: widget.config.gameType,
        description: myScore > opponentScore ? 'Kazandınız! +50 bonus'
            : myScore == opponentScore ? 'Berabere! +10 bonus' : 'Çift VS Çift',
      );
    }
  }

  Future<void> _savePoints() async {
    final percentage = _questions.isEmpty ? 0 : (_correctCount / _questions.length * 100).round();
    
    if (percentage < _minSuccessRate) {
      debugPrint('Score $percentage% below threshold $_minSuccessRate%. Points skipped.');
      return; 
    }

    try {
      await PointsService().addPoints(
        points: _score,
        source: widget.config.gameType,
        description: '${widget.config.title} - Solo',
      );
    } catch (e) {
      debugPrint('[GenericQuizGameScreen] Points save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0F0C29), // Match background color
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0C29), 
        body: Container(
          decoration: _buildGradient(),
          child: SafeArea(child: _buildContent()),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const QuizLoadingScreen();
    if (_questions.isEmpty) return QuizNoQuestionsScreen(categoryTitle: widget.config.title, onBack: () => Navigator.pop(context));
    if (_waitingForOpponent) return QuizWaitingScreen(currentScore: _isFinished ? _correctCount * 2 : null);
    
    if (_isFinished) {
      if (widget.isMultiplayer && _gameRoom != null && _gameRoom!.isGameComplete) {
        return _buildMultiplayerResultScreen();
      }
      return _buildResultScreen();
    }
    return _buildGameScreen();
  }

  BoxDecoration _buildGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        QuizHeader(
          remainingSeconds: _remainingSeconds,
          score: _score,
          correctCount: _correctCount,
          pulseAnimation: _pulseController,
          onExit: _showExitDialog,
        ),
        const SizedBox(height: 8),
        QuizProgress(
          currentIndex: _currentIndex,
          totalQuestions: _questions.length,
          correctCount: _correctCount,
          wrongCount: _wrongCount,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                QuizQuestionCard(question: _questions[_currentIndex]),
                const SizedBox(height: 16),
                QuizOptionsList(
                  question: _questions[_currentIndex],
                  selectedOption: _selectedOption,
                  showResult: _showResult,
                  onOptionSelected: _selectOption,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplayerResultScreen() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          QuizMatchResult(room: _gameRoom!),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(AppStrings.mainMenu, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final percentage = (_correctCount / _questions.length * 100).round();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48), // 48 is total vertical padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(percentage >= 80 ? '🏆' : percentage >= 50 ? '👍' : '📚', style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      percentage >= 80 ? AppStrings.msgPerfect : percentage >= 50 ? AppStrings.msgGood : AppStrings.msgPractice,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (percentage < _minSuccessRate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          AppStrings.msgSuccessRateTooLow.replaceAll('{rate}', '$_minSuccessRate'),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 16),
                    QuizSummaryCard(score: _score, correctCount: _correctCount, wrongCount: _wrongCount, percentage: percentage),
                    const SizedBox(height: 24),
                    QuizAnswerList(answers: _answers),
                    // AI Sınav Raporu - Solo modda göster
                    if (!widget.isMultiplayer)
                      QuizAIReportWidget(
                        answers: _answers,
                        categoryId: widget.config.categoryId,
                        categoryName: widget.config.title,
                        userName: 'Kullanıcı', // TODO: FirebaseAuth'dan al
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildResultButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.white30)),
            child: Text(AppStrings.exit, style: const TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => GenericQuizGameScreen(config: widget.config, difficulty: widget.difficulty, isMultiplayer: false))),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: const Color(0xFF6C63FF)),
            child: Text(AppStrings.retry),
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.quitGameTitle),
        content: Text(AppStrings.quitGameContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text(AppStrings.quit)),
        ],
      ),
    );
  }
}
