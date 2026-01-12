/// Yem modeli - Akvaryuma bırakılan yem
class FoodPellet {
  final String id;
  double x; // 0.0 - 1.0 (Ekran genişliği oranı)
  double y; // 0.0 - 1.0 (Ekran yüksekliği oranı)
  double size;
  bool isBeingEaten;
  bool hasLanded;

  FoodPellet({
    required this.id,
    required this.x,
    required this.y,
    this.size = 24.0,
    this.isBeingEaten = false,
    this.hasLanded = false,
  });
}
