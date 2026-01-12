enum GameType {
  heartShooter,
  quiz;

  String toStringValue() {
    switch (this) {
      case GameType.heartShooter:
        return 'heart_shooter';
      case GameType.quiz:
        return 'quiz';
    }
  }

  static GameType fromString(String value) {
    switch (value) {
      case 'heart_shooter':
        return GameType.heartShooter;
      case 'quiz':
        return GameType.quiz;
      default:
        return GameType.quiz;
    }
  }
}
