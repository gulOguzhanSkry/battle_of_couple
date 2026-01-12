import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/marimo.dart';
import '../services/marimo_service.dart';
import '../widgets/marimo_painter.dart';
import '../models/bubble.dart';
import '../models/food_pellet.dart';

/// Marimo Ana Ekranı - Sürükle Bırak Besleme
class MarimoScreen extends StatefulWidget {
  const MarimoScreen({super.key});

  @override
  State<MarimoScreen> createState() => _MarimoScreenState();
}

class _MarimoScreenState extends State<MarimoScreen> with TickerProviderStateMixin {
  final MarimoService _service = MarimoService();
  final Uuid _uuid = const Uuid();
  
  Marimo? _marimo;
  List<MarimoAction> _recentActions = [];
  bool _isLoading = true;
  
  late AnimationController _swayController;
  
  bool _isFabExpanded = false;
  int _remainingFood = 3;
  
  final List<Bubble> _bubbles = [];
  final List<FoodPellet> _foodPellets = [];
  final Random _random = Random();
  Timer? _decayTimer;
  Timer? _movementTimer;
  Timer? _physicsTimer;

  Alignment _marimoAlignment = Alignment.center;
  FoodPellet? _targetFood;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this)..repeat(reverse: true);
    _loadMarimo();
    _loadFoodCount();
    _startBubbleGenerator();
    _startDecayTimer();
    _startMarimoMovement();
    _startPhysicsLoop();
  }

  @override
  void dispose() {
    _swayController.dispose();
    _decayTimer?.cancel();
    _movementTimer?.cancel();
    _physicsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMarimo() async {
    if (_marimo == null) setState(() => _isLoading = true);
    final marimo = await _service.getOrCreateMarimo();
    if (marimo != null) {
      final actions = await _service.getRecentActions(marimo.id);
      if (mounted) setState(() { _marimo = marimo; _recentActions = actions; _isLoading = false; });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFoodCount() async {
    final remaining = await _service.getRemainingFood();
    if (mounted) setState(() => _remainingFood = remaining);
  }

  void _startPhysicsLoop() {
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      _updatePhysics();
    });
  }

  void _updatePhysics() {
    setState(() {
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final bubble = _bubbles[i];
        if (bubble.isPopping) {
          bubble.size += 1.0; bubble.opacity -= 0.15;
          if (bubble.opacity <= 0) _bubbles.removeAt(i);
        } else {
          bubble.y -= bubble.speed; bubble.x += sin(bubble.y * 10) * 0.002;
          if (bubble.y < 0.8 && _random.nextDouble() > 0.995) bubble.isPopping = true;
          if (bubble.y < -0.1) _bubbles.removeAt(i);
        }
      }

      for (int i = _foodPellets.length - 1; i >= 0; i--) {
        final pellet = _foodPellets[i];
        if (pellet.isBeingEaten) {
          pellet.size -= 2.0;
          if (pellet.size <= 0) { _foodPellets.removeAt(i); _targetFood = null; _onFoodEaten(); }
        } else if (!pellet.hasLanded) {
          pellet.y += 0.008;
          if (pellet.y >= 0.7) { pellet.hasLanded = true; pellet.y = 0.7; _targetFood = pellet; }
        }
      }
    });
  }

  void _onFoodEaten() async {
    if (_marimo != null && !_marimo!.isDead) {
      final success = await _service.addFood();
      if (success) {
        await _loadMarimo();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('🌱 Yem yendi! +15 XP'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16)));
      }
    }
  }

  void _startMarimoMovement() {
    _movementTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      _updateMarimoMovement();
    });
  }

  void _updateMarimoMovement() {
    if (_targetFood != null && _targetFood!.hasLanded && !_targetFood!.isBeingEaten) {
      final targetX = (_targetFood!.x - 0.5) * 2;
      final targetY = (_targetFood!.y - 0.5) * 2;
      setState(() => _marimoAlignment = Alignment(targetX.clamp(-0.8, 0.8), targetY.clamp(-0.5, 0.5)));
      final currentX = (_marimoAlignment.x + 1) / 2;
      final currentY = (_marimoAlignment.y + 1) / 2;
      final distance = sqrt(pow(currentX - _targetFood!.x, 2) + pow(currentY - _targetFood!.y, 2));
      if (distance < 0.15) setState(() => _targetFood!.isBeingEaten = true);
    } else if (_targetFood == null && _random.nextDouble() > 0.95) {
      setState(() => _marimoAlignment = Alignment((_random.nextDouble() * 0.8) - 0.4, (_random.nextDouble() * 0.6) - 0.3));
    }
  }

  void _startBubbleGenerator() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_bubbles.length < 50 && _random.nextDouble() > 0.85) {
        setState(() => _bubbles.add(Bubble(id: _uuid.v4(), x: _random.nextDouble(), y: 1.1, size: _random.nextDouble() * 10 + 4, speed: _random.nextDouble() * 0.004 + 0.002, opacity: _random.nextDouble() * 0.3 + 0.1)));
      }
    });
  }

  void _startDecayTimer() {
    _decayTimer = Timer.periodic(const Duration(minutes: 1), (_) => _loadMarimo());
  }

  // ==================== SÜRÜKLE BIRAK ====================

  Future<void> _dropFoodAt(Offset globalPosition) async {
    if (_marimo == null || _marimo!.isDead) return;
    if (_foodPellets.length >= 3) return;

    if (_remainingFood <= 0) {
      _showNoFoodDialog();
      return;
    }

    final success = await _service.consumeFood();
    if (!success) { _showNoFoodDialog(); return; }
    await _loadFoodCount();

    final screenSize = MediaQuery.of(context).size;
    final x = globalPosition.dx / screenSize.width;
    final y = globalPosition.dy / screenSize.height;

    setState(() => _foodPellets.add(FoodPellet(id: _uuid.v4(), x: x, y: y, size: 20.0)));
  }

  void _showNoFoodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Text('🌿', style: TextStyle(fontSize: 24)), SizedBox(width: 8), Text('Yem Bitti!')]),
        content: const Text('Bugünlük ücretsiz yemleriniz bitti.\n\nReklam izleyerek +3 yem kazanabilirsiniz!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kapat')),
          ElevatedButton.icon(
            onPressed: () async { Navigator.pop(context); await _watchAdForFood(); },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Reklam İzle (+3)'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _watchAdForFood() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📺 Reklam izleniyor... (Simülasyon)'), duration: Duration(seconds: 2)));
    await Future.delayed(const Duration(seconds: 2));
    await _service.addBonusFood(3);
    await _loadFoodCount();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 +3 yem kazandınız!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF1A1A2E), body: Center(child: CircularProgressIndicator(color: Colors.teal)));
    if (_marimo == null) return _buildNoPartnerScaffold();

    final marimo = _marimo!;
    final waterColor = _getWaterColor(marimo.waterQuality);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Akvaryum (DragTarget)
          DragTarget<String>(
            onAcceptWithDetails: (details) => _dropFoodAt(details.offset),
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildWaterBackground(waterColor),
                  _buildSandLayer(),
                  ..._bubbles.map((b) => _buildBubble(b)),
                  ..._foodPellets.map((p) => _buildFoodPellet(p, screenSize)),
                  _buildLightRays(),
                  _buildFloatingMarimo(marimo),
                  if (marimo.isDead) _buildDeadOverlay(),
                  
                  // Bırakma alanı göstergesi
                  if (isHovering)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green.withOpacity(0.5), width: 4),
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                ],
              );
            },
          ),

          // Minimal UI (Sol Alt)
          if (!marimo.isDead)
            Positioned(left: 12, bottom: 80, child: _buildMinimalStats(marimo)),

          // Sürüklenebilir Yem (Sağ Alt)
          if (!marimo.isDead && _remainingFood > 0)
            Positioned(
              right: 20,
              bottom: 100,
              child: _buildDraggableFood(),
            ),

          // FAB
          if (!marimo.isDead)
            Positioned(right: 16, bottom: 16, child: _buildExpandableFab()),
        ],
      ),
    );
  }

  Widget _buildDraggableFood() {
    return Draggable<String>(
      data: 'food',
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(colors: [Color(0xFF8BC34A), Color(0xFF558B2F)]),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
          ),
          child: const Center(child: Text('🌿', style: TextStyle(fontSize: 24))),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFoodIcon(),
      ),
      child: _buildFoodIcon(),
    );
  }

  Widget _buildFoodIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF8BC34A), Color(0xFF558B2F)]),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 20)),
          Text('$_remainingFood', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFoodPellet(FoodPellet pellet, Size screenSize) {
    return Positioned(
      left: pellet.x * screenSize.width - pellet.size / 2,
      top: pellet.y * screenSize.height - pellet.size / 2,
      child: Container(
        width: pellet.size,
        height: pellet.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFF8BC34A), Color(0xFF558B2F)]),
          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 6)],
        ),
        child: pellet.size > 10 ? const Center(child: Text('🌿', style: TextStyle(fontSize: 12))) : null,
      ),
    );
  }

  Widget _buildMinimalStats(Marimo marimo) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(marimo.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildMiniBar(Icons.favorite, marimo.health, Colors.red),
          _buildMiniBar(Icons.water_drop, marimo.waterQuality, Colors.blue),
          _buildMiniBar(Icons.eco, marimo.foodLevel, Colors.green),
          _buildMiniBar(Icons.star, (marimo.growthProgress * 100).toInt(), Colors.amber),
        ],
      ),
    );
  }

  Widget _buildMiniBar(IconData icon, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        SizedBox(width: 50, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: value / 100, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation(color)))),
      ]),
    );
  }

  Widget _buildFloatingMarimo(Marimo marimo) {
    // Yarı boyut: 30 + (level * 8) piksel
    final size = 30.0 + (marimo.stage.level * 8.0);
    return AnimatedAlign(
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutSine,
      alignment: _marimoAlignment,
      child: AnimatedBuilder(animation: _swayController, builder: (context, child) => CustomPaint(size: Size(size, size), painter: MarimoPainter(stage: marimo.stage, isSick: marimo.isSick, isDead: marimo.isDead, animationValue: _swayController.value))),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context))),
      actions: [Container(margin: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.bug_report, color: Colors.amber, size: 20), onPressed: _showDebugMenu))],
    );
  }

  Widget _buildExpandableFab() {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (_isFabExpanded) ...[
        _buildFabAction('Su', Icons.water_drop, Colors.blue, () async { setState(() => _isFabExpanded = false); final success = await _service.changeWater(); if (success) await _loadMarimo(); }),
        const SizedBox(height: 8),
      ],
      FloatingActionButton.small(onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded), backgroundColor: Colors.teal, child: Icon(_isFabExpanded ? Icons.close : Icons.menu, size: 20)),
    ]);
  }

  Widget _buildFabAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
      const SizedBox(width: 8),
      FloatingActionButton.small(heroTag: label, onPressed: onTap, backgroundColor: color, child: Icon(icon, size: 18)),
    ]);
  }

  void _showDebugMenu() {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🛠️ Debug', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: List.generate(6, (i) => ElevatedButton(onPressed: () { _service.debugSetStage(_marimo!.id, i + 1); _loadMarimo(); Navigator.pop(context); }, child: Text('Lvl ${i + 1}')))),
        const SizedBox(height: 12),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { _service.debugDamage(_marimo!.id, 30); _loadMarimo(); }, child: const Text('-30 HP')),
        const SizedBox(height: 8),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () async { await _service.addBonusFood(10); await _loadFoodCount(); Navigator.pop(context); }, child: const Text('+10 Yem')),
      ]),
    ));
  }

  // === Helpers ===
  Widget _buildBubble(Bubble b) => Positioned(left: b.x * MediaQuery.of(context).size.width, bottom: b.y * MediaQuery.of(context).size.height, child: Container(width: b.size, height: b.size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(b.opacity))));
  Widget _buildWaterBackground(Color c) => AnimatedContainer(duration: const Duration(milliseconds: 1000), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.withOpacity(0.5), c.withOpacity(0.8), c])));
  Widget _buildSandLayer() => Positioned(bottom: 0, left: 0, right: 0, height: 120, child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, const Color(0xFFA1887F).withOpacity(0.8)]))));
  Widget _buildLightRays() => Positioned(top: -50, right: -50, child: Transform.rotate(angle: -pi / 4, child: Container(width: 150, height: 500, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.transparent])))));
  Widget _buildNoPartnerScaffold() => Scaffold(backgroundColor: const Color(0xFF1A1A2E), appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0), body: const Center(child: Text('Partner gerekli', style: TextStyle(color: Colors.white))));
  Widget _buildDeadOverlay() => Container(color: Colors.black54, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('💀', style: TextStyle(fontSize: 60)), const Text('Marimo öldü', style: TextStyle(color: Colors.white, fontSize: 24)), const SizedBox(height: 16), ElevatedButton(onPressed: () async { await _service.restartMarimo(); _loadMarimo(); }, child: const Text('Yeniden Başla'))])));
  Color _getWaterColor(int q) { if (q >= 80) return const Color(0xFF00B0FF); if (q >= 60) return const Color(0xFF00ACC1); if (q >= 40) return const Color(0xFF00897B); if (q >= 20) return const Color(0xFF827717); return const Color(0xFF5D4037); }
}
