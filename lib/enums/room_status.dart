/// Oyun odası durumları
enum RoomStatus {
  waiting,   // Rakip bekleniyor
  matched,   // Eşleşme tamamlandı
  playing,   // Oyun devam ediyor
  finished,  // Oyun bitti
  cancelled, // İptal edildi
}
