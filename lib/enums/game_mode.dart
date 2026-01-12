enum GameMode {
  couplesVs,
  partners;

  String toStringValue() {
    switch (this) {
      case GameMode.couplesVs:
        return 'couples_vs';
      case GameMode.partners:
        return 'partners';
    }
  }

  static GameMode fromString(String value) {
    switch (value) {
      case 'couples_vs':
        return GameMode.couplesVs;
      case 'partners':
        return GameMode.partners;
      default:
        return GameMode.partners;
    }
  }
}
