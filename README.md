# ⚔️ Battle of Couples
### *Çiftler İçin Rekabetçi ve Eğlenceli Oyun Platformu*

**Battle of Couples**, partnerinizle birlikte veya birbirinize karşı oynayabileceğiniz, bilgi yarışmalarından mini oyunlara kadar geniş bir yelpaze sunan modern bir mobil uygulamadır. İlişkinizi güçlendirirken eğlenin, öğrenin ve rekabet edin!

---

## 📸 Ekran Görüntüleri (Screenshots)

*Uygulamanın öne çıkan ekranlarından bazıları:*

| **Ana Ekran & Dashboard** | **Oyun Modu Seçimi** |
|:---:|:---:|
| ![Dashboard](docs/screenshots/dashboard.png?raw=true) <br> *Kullanıcı istatistikleri, sıralamalar ve hızlı erişim menüsü.* | ![Game Modes](docs/screenshots/modes.png?raw=true) <br> *Solo pratik veya "Coppia VS Coppia" rekabet modu.* |

| **Oyun İçi (Quiz)** | **Sonuç Ekranı & AI Raporu** |
|:---:|:---:|
| ![Quiz Game](docs/screenshots/gameplay.png?raw=true) <br> *Zamanlayıcı, jokerler ve dinamik soru kartları.* | ![Results](docs/screenshots/results.png?raw=true) <br> *Yapay zeka destekli performans analizi ve öneriler.* |

| **Profil & Eşleşme** | **Liderlik Tablosu** |
|:---:|:---:|
| ![Profile](docs/screenshots/profile.png?raw=true) <br> *Partner eşleşme durumu ve takım ayarları.* | ![Leaderboard](docs/screenshots/leaderboard.png?raw=true) <br> *Haftalık ve genel sıralamalar.* |

*(Ekran görüntülerini `docs/screenshots` klasörüne ekleyin ve isimlerini yukarıdaki gibi düzenleyin)*

---

## ✨ Öne Çıkan Özellikler

### 🎯 Quiz Hub (Bilgi Yarışmaları)
*   **Geniş Kategori Yelpazesi:** Genel Kültür, Kelime Avı, TUS, KPPS ve daha fazlası.
*   **Yapay Zeka Destekli Analiz:** Her oyun sonunda performansınıza göre AI (Gemini) tarafından hazırlanan **kişisel gelişim raporu**.
*   **PDF Raporu:** Sınav sonucunuzu PDF olarak indirip paylaşabilme.
*   **Dinamik Zorluk Seviyesi:** Başarınıza göre şekillenen sorular.

### ❤️ Eşleşme Sistemi
*   Partnerinizi QR kod veya e-posta ile davet edin.
*   **"Coppia VS Coppia" Modu:** Başka çiftlere karşı bir takım olarak yarışın.
*   Ortak puanlar ve takım sıralamaları.

### 🎮 Mini Oyunlar
*   **Heart Shooter:** Reflekslerinizi ölçen hızlı bir arcade oyunu.
*   **Marimo Pet:** (Yakında) Birlikte büyüteceğiniz sanal evcil hayvan.

### 🛠️ Yönetim Paneli
*   Oyun içi içerikleri, soruları ve başarı oranlarını yönetebileceğiniz gelişmiş yönetim araçları.
*   Dinamik konfigürasyon (Firebase Remote Config benzeri yapı).

---

## 🛠️ Teknolojiler

Bu proje, modern mobil geliştirme standartlarına uygun olarak geliştirilmiştir:

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend:** [Firebase](https://firebase.google.com/)
    *   **Auth:** Google Sign-In, Apple Sign-In, Email/Password
    *   **Firestore:** Realtime Veritabanı (NoSQL)
    *   **Cloud Functions:** Sunucu taraflı mantık (Notifications, Matchmaking)
    *   **Storage:** Medya dosyaları
*   **State Management:** Provider / Riverpod mantığı
*   **AI Entegrasyonu:** Google Gemini API (Soru analizi ve raporlama)

---

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
*   Flutter SDK (3.9.0+)
*   Dart SDK
*   Firebase Hesabı

### Adımlar

1.  **Depoyu Klonlayın:**
    ```bash
    git clone https://github.com/gulOguzhanSkry/battle_of_couple.git
    cd battle_of_couple
    ```

2.  **Bağımlılıkları Yükleyin:**
    ```bash
    flutter pub get
    ```

3.  **Çevresel Değişkenler (.env):**
    Proje kök dizininde `.env` dosyası oluşturun ve gerekli API anahtarlarını ekleyin:
    ```env
    AI_API_KEY=YOUR_GEMINI_API_KEY
    ```

4.  **Başlatın:**
    ```bash
    flutter run
    ```

---

## 📱 İzinler

Uygulama aşağıdaki izinleri kullanır:
*   **İnternet:** Sunucu iletişimi.
*   **Bildirimler:** Oyun davetleri ve eşleşme bildirimleri.
*   **Depolama:** PDF raporlarını kaydetmek ve paylaşmak için.

---

*Geliştirici: [Oğuzhan OFT]*
