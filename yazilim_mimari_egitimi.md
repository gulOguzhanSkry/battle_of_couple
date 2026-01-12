# Battle of Couples Projesi: Yazılım Mimarisi ve OOP Prensipleri Eğitimi

Bu doküman, `lib/core/constants/strings` klasöründe kurduğumuz yapının arkasındaki yazılım mühendisliği mantığını, Nesne Yönelimli Programlama (Object Oriented Programming - OOP) prensiplerini ve kullanılan tasarım desenlerini (Design Patterns) yeni başlayan birine anlatır gibi detaylıca açıklamaktadır.

---

## 📚 1. Temel Sorun: Neden Buna İhtiyacımız Var?

Yazılıma yeni başlayanların sıkça yaptığı bir hata "Hardcoding" dediğimiz işlemdir. Yani metinleri doğrudan kodun içine gömmek.

**Kötü Yaklaşım (Hardcoding):**
```dart
// Login ekranında
Text('Giriş Yap');

// Ayarlar ekranında
Text('Giriş Yap');
```

**Sorunlar:**
1.  **Tekrar (Repetition):** "Giriş Yap" yazısını 50 farklı yerde kullandıysan ve bunu "Oturum Aç" olarak değiştirmek istersen, 50 yeri tek tek bulup değiştirmen gerekir.
2.  **Çoklu Dil (Localization):** Uygulamayı İngilizceye çevirmek istediğinde, kodun içine gömülü tüm Türkçe metinleri bulup `if (dil == 'tr') ... else ...` gibi karmaşık yapılar kurman gerekir. Bu imkansıza yakın bir karmaşa yaratır.

Bunu çözmek için uyguladığımız mimariyi parçalayarak inceleyelim.

---

## 🏗️ 2. Kullandığımız OOP Prensipleri

Bu yapıda Nesne Yönelimli Programlamanın (OOP) 4 temel taşından 3'ünü aktif olarak kullandık: **Soyutlama (Abstraction)**, **Kalıtım (Inheritance)** ve **Çok Biçimlilik (Polymorphism)**.

### A. Soyutlama (Abstraction) - `AppStringsBase`

**Dosya:** `lib/core/constants/strings/app_strings_base.dart`

Soyutlama, detaylardan arındırıp "ne olması gerektiğini" tanımlamaktır.
`AppStringsBase` sınıfımız bir **Abstract Class** (Soyut Sınıf)'tır.

```dart
abstract class AppStringsBase {
  String get appTitle;
  String get playNow;
  String get error;
}
```

**Mantığı:**
- Bu sınıf der ki: "Herhangi bir dil dosyasında mutlaka `appTitle`, `playNow` ve `error` isminde stringler OLMALIDIR."
- Ama bu stringlerin içeriğinin "Battle of Couples" mı, "Çiftlerin Savaşı" mı olduğuyla ilgilenmez.
- Bu bir **Sözleşme (Contract)** gibidir. Bu sınıfı miras alan herkes bu kurallara uymak zorundadır.

### B. Kalıtım (Inheritance) - `AppStringsTr` & `AppStringsEn`

**Dosya:** `lib/core/constants/strings/app_strings_tr.dart`

Kalıtım, bir sınıfın özelliklerini başka bir sınıfa aktarmasıdır.

```dart
class AppStringsTr extends AppStringsBase {
  @override
  String get appTitle => 'Battle of Couples';

  @override
  String get playNow => 'Oyna';
}
```

**Mantığı:**
- `AppStringsTr`, `AppStringsBase`'in çocuğudur (child class).
- `extends` anahtar kelimesi ile babasının (parent/super class) tüm özelliklerini alır.
- `@override` (Ezmek/Üzerine Yazmak): Babasının "böyle bir alan olmalı" dediği kuralı alır ve "Tamam, benim için bu alanın değeri BUDUR" der.

### C. Çok Biçimlilik (Polymorphism)

Bu, mimarimizin en güçlü yanıdır. Uygulamanın geri kalanı (UI kodları), hangi dilin seçili olduğunu bilmez. Sadece `AppStringsBase` tipinde bir nesneyle konuştuğunu bilir.

O anki nesne `AppStringsTr` de olabilir, `AppStringsEn` de olabilir. UI sadece şunu der:
*"Bana `playNow` butonunun yazısını ver."*

Cevap Türkçe sınıfından geliyorsa "Oyna", İngilizce sınıfından geliyorsa "Play Now" döner. Kodun geri kalanı değişmez.

---

## 🛠️ 3. Kullanılan Tasarım Desenleri (Design Patterns)

### A. Singleton / Static Factory Pattern Yaklaşımı

**Dosya:** `lib/core/constants/app_strings.dart`

Uygulamanın her yerinden stringlere kolayca ulaşmak istiyoruz. Her seferinde `new AppStringsTr()` diyerek yeni bir nesne oluşturmak hafıza (RAM) israfıdır ve yönetimi zordur.

```dart
class AppStrings {
  // Gizli ve statik bir ana değişken.
  // Başlangıçta Türkçe yüklü.
  static AppStringsBase _instance = AppStringsTr();

  // Dili değiştiren mekanizma
  static void setLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.turkish:
        _instance = AppStringsTr(); // instance artık Türkçe
        break;
      case AppLanguage.english:
        _instance = AppStringsEn(); // instance artık İngilizce
        break;
    }
  }

  // Dışarıya açılan kapılar (Getters)
  static String get playNow => _instance.playNow;
}
```

**Mantığı:**
- `static`: Bu değişkene veya metoda sınıfın kendisi üzerinden (`AppStrings.playNow`) ulaşılır, nesne üretilmez.
- `_instance`: Alt tire ile başladığı için **private** (gizli) değişkendir. Dışarıdan kimse bunu doğrudan değiştiremez (Encapsulation - Kapsülleme).
- Biz sadece `AppStrings.playNow` çağırırız. Arka planda o an `_instance` hangi dili tutuyorsa onun cevabını verir.

### B. Strategy Pattern (Strateji Deseni)

Burada uyguladığımız yapı aslında basit bir Strategy Pattern örneğidir.
- **Problem:** Bir işin (string döndürme) birden fazla yolu var (Türkçe, İngilizce, İtalyanca).
- **Çözüm:** Bu yolları çalışma zamanında (runtime) değiştirebiliriz. Kullanıcı ayarlardan dili değiştirdiğinde, tüm uygulamanın stratejisini değiştirmiş oluyoruz.

---

## 🔍 4. Kod Okuma & 'get' Anahtar Kelimesi

Dart diline özgü bir detay olan `get` keyword'ünü çokça kullandık.

```dart
String get welcomeMessage => 'Hoşgeldin';
```

Bu aslında şuna eşittir:

```dart
String welcomeMessage() {
  return 'Hoşgeldin';
}
```

**Neden `get` kullanıyoruz?**
- Sözdizimi (Syntax) daha temizdir. Kullanırken `AppStrings.welcomeMessage()` yerine `AppStrings.welcomeMessage` yazarız. Parantez kullanmayız. Sanki bir değişkenmiş gibi davranır ama aslında her çağrıldığında taze veri döndüren bir fonksiyondur.

---

## 🚀 5. Bu Mimarinin Avantajları (Özet)

Eğer arkadaşın "Neden bu kadar kod yazdık, direkt tırnak içinde yazsaydık?" derse ona şunları söyle:

1.  **Bakım Kolaylığı (Maintainability):**
    Uygulamadaki "Tamam" butonunu "Onayla" yapmak istersen sadece `app_strings_tr.dart` dosyasına girip bir satırı değiştirirsin. Tüm uygulama anında güncellenir.

2.  **Ölçeklenebilirlik (Scalability):**
    Yarın Almanca eklemek istedik. Yapacağımız tek şey:
    - `app_strings_de.dart` oluştur.
    - `AppStringsBase`'i miras al (extend et).
    - IDE sana "Hadi bakalım şu 100 tane metnin Almancasını yaz" diyecek.
    - `main` dosyasına tek bir `case` ekle.
    - Bitti! Kodun geri kalanına dokunmadın bile.

3.  **Hata Önleme:**
    `AppStringsTr` dosyasında bir çeviriyi unutsan bile IDE (Geliştirme ortamı) sana kızar: *"Hey, AppStringsBase sözleşmesinde `errorTitle` var ama sen bunu Türkçe dosyasına eklemedin!"* der. Bu sayede eksik çeviriyle canlıya çıkma riskin sıfıra iner.

4.  **Temiz Kod (Clean Code):**
    UI (Arayüz) kodların tertemiz olur.
    Yerine:
    ```dart
    Text(language == 'tr' ? 'Hoşgeldiniz' : (language == 'en' ? 'Welcome' : 'Benvenuto'))
    ```
    Sadece şunu yazarsın:
    ```dart
    Text(AppStrings.welcome)
    ```
    Kod okunabilirliği muazzam artar.

---

## 🎓 Sonuç

Bu projede yaptığımız şey sadece "yazı yazmak" değil. Geleceği düşünerek, genişletilebilir, hataya kapalı ve bakımı kolay bir **"Mimari"** kurmaktır. Profesyonel yazılım dünyasında Junior ile Senior geliştiriciyi ayıran en temel fark budur: Biri o an kodu çalıştırır, diğeri kodu yıllarca yaşayacak şekilde tasarlar.
