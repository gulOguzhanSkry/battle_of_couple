/// Kabarcık ve diğer fizik modelleri
class Bubble {
  final String id;
  double x; // 0.0 - 1.0 (Ekran genişliği oranı)
  double y; // 0.0 - 1.0 (Ekran yüksekliği oranı)
  double size;
  double speed;
  double opacity;
  bool isPopping;
  double popScale; // Patlama animasyonu için skala

  Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    this.opacity = 0.5,
    this.isPopping = false,
    this.popScale = 1.0,
  });
}
