/// Her quiz kategorisi için özel prompt şablonları.
/// Strategy Pattern kullanılarak her kategori kendi prompt mantığını tanımlar.
library;

import 'ai_constants.dart';

/// Prompt oluşturucu abstract base class.
/// Her kategori bu sınıfı extend ederek kendi promptunu tanımlar.
abstract class CategoryPromptBuilder {
  /// Kategori ID'si
  String get categoryId;
  
  /// Kategori açıklaması
  String get categoryDescription;
  
  /// Soru üretme prompt'unu oluşturur
  /// 
  /// [subCategory] - Alt kategori (opsiyonel, örn: "Tarih")
  /// [topic] - Konu başlığı (opsiyonel, örn: "Osmanlı Kuruluş Dönemi")
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  });
  
  /// Zorluk seviyesi açıklamasını döndürür
  String getDifficultyDescription(String difficulty);
}

/// TUS (Tıpta Uzmanlık Sınavı) kategorisi için prompt builder
class TUSPromptBuilder extends CategoryPromptBuilder {
  @override
  String get categoryId => 'TUS';
  
  @override
  String get categoryDescription => 'Tıpta Uzmanlık Sınavı';
  
  @override
  String getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'KOLAY - Temel kavramlar, terminoloji ve basit tanımlar. Mezuniyet öncesi düzey.';
      case 'medium':
        return 'ORTA - Klinik uygulamalar, ayırıcı tanı ve tedavi prensipleri. TUS sınav düzeyi.';
      case 'hard':
        return 'ZOR - İleri düzey vaka analizleri, nadir durumlar, karmaşık mekanizmalar. TUS üst düzey.';
      default:
        return 'ORTA - Standart TUS sınav düzeyi.';
    }
  }
  
  @override
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    final difficultyDesc = getDifficultyDescription(difficulty);
    final subCatText = subCategory?.isNotEmpty == true ? subCategory! : 'Genel TUS konuları';
    final topicDetail = topic?.isNotEmpty == true ? topic! : 'Bu alt başlık altındaki tüm önemli konular';
    
    return '''
Sen Türkiye'de TUS (Tıpta Uzmanlık Sınavı) için uzmanlaşmış profesyonel bir soru hazırlayıcısısın.

## GÖREV
"$subCatText" branşından, "$topicDetail" konusunda $count adet çoktan seçmeli soru hazırla.

## ZORLUK SEVİYESİ
$difficultyDesc

## SORU KRİTERLERİ
1. **KONU SADAKATI**: Sorular MUTLAKA "$subCatText" branşı ve "$topicDetail" konusuyla DOĞRUDAN ilgili olmalı.
2. **TUS FORMATI**: Gerçek TUS sorularının formatını kullan:
   - Klinik vaka veya senaryo tabanlı sorular
   - Hasta hikayesi, fizik muayene ve laboratuvar bulgusu içeren sorular
   - "Bu hastada en olası tanı nedir?", "İlk yapılması gereken nedir?", "Hangi tedavi uygulanmalıdır?" kalıpları
3. **ŞIK KALİTESİ**: 
   - 4 şık, hepsi tıbbi açıdan mantıklı ve inandırıcı
   - Çeldirici şıklar aynı branştan, benzer durumlar olmalı
4. **BİLİMSEL DOĞRULUK**: Güncel tıbbi kılavuzlara ve Türkiye uygulamalarına dayalı

${_getJsonFormat()}
${_getRules()}
''';
  }
}

/// KPSS kategorisi için prompt builder
class KPSSPromptBuilder extends CategoryPromptBuilder {
  @override
  String get categoryId => 'kpss';
  
  @override
  String get categoryDescription => 'Kamu Personeli Seçme Sınavı';
  
  @override
  String getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'KOLAY - Temel bilgiler, basit hatırlatma soruları.';
      case 'medium':
        return 'ORTA - Analiz ve yorumlama gerektiren sorular. KPSS standart düzey.';
      case 'hard':
        return 'ZOR - Detaylı bilgi ve çıkarım gerektiren sorular. KPSS A grubu düzey.';
      default:
        return 'ORTA - Standart KPSS düzeyi.';
    }
  }
  
  @override
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    final difficultyDesc = getDifficultyDescription(difficulty);
    final subCatText = subCategory?.isNotEmpty == true ? subCategory! : 'Genel KPSS konuları';
    final topicDetail = topic?.isNotEmpty == true ? topic! : 'Bu alan altındaki tüm önemli konular';
    
    return '''
Sen Türkiye'de KPSS (Kamu Personeli Seçme Sınavı) için uzmanlaşmış profesyonel bir soru hazırlayıcısısın.

## GÖREV
"$subCatText" alanından, "$topicDetail" konusunda $count adet çoktan seçmeli soru hazırla.

## ZORLUK SEVİYESİ
$difficultyDesc

## SORU KRİTERLERİ
1. **KONU SADAKATI**: Sorular MUTLAKA "$subCatText" ve "$topicDetail" konusuyla ilgili olmalı.
2. **KPSS FORMATI**: Gerçek KPSS sorularının formatını kullan:
   - Genel Yetenek: Sözel ve sayısal mantık soruları
   - Genel Kültür: Tarih, Coğrafya, Vatandaşlık, Güncel
   - Eğitim Bilimleri: Pedagoji, psikoloji, ölçme-değerlendirme
3. **ŞIK KALİTESİ**: 
   - 4 şık, hepsi mantıklı ama sadece biri doğru
   - Çeldirici şıklar konuyla alakalı yaygın hatalar olmalı
4. **GÜNCELLIK**: Güncel mevzuat ve Türkiye gerçeklerine uygun

${_getJsonFormat()}
${_getRules()}
''';
  }
}

/// AYT/YKS kategorisi için prompt builder
class AYTYKSPromptBuilder extends CategoryPromptBuilder {
  @override
  String get categoryId => 'ayt_yks';
  
  @override
  String get categoryDescription => 'Yükseköğretim Kurumları Sınavı';
  
  @override
  String getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'KOLAY - Temel kavramlar, TYT düzeyi sorular.';
      case 'medium':
        return 'ORTA - AYT standart düzey, analiz gerektiren sorular.';
      case 'hard':
        return 'ZOR - AYT üst düzey, karmaşık problem çözümü gerektiren sorular.';
      default:
        return 'ORTA - Standart AYT düzeyi.';
    }
  }
  
  @override
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    final difficultyDesc = getDifficultyDescription(difficulty);
    final subCatText = subCategory?.isNotEmpty == true ? subCategory! : 'Genel AYT/YKS konuları';
    final topicDetail = topic?.isNotEmpty == true ? topic! : 'Bu ders altındaki tüm önemli konular';
    
    return '''
Sen Türkiye'de YKS/AYT sınavı için uzmanlaşmış profesyonel bir soru hazırlayıcısısın.

## GÖREV
"$subCatText" dersinden, "$topicDetail" konusunda $count adet çoktan seçmeli soru hazırla.

## ZORLUK SEVİYESİ
$difficultyDesc

## SORU KRİTERLERİ
1. **KONU SADAKATI**: Sorular MUTLAKA "$subCatText" dersi ve "$topicDetail" konusuyla ilgili olmalı.
2. **YKS FORMATI**: Gerçek YKS/AYT sorularının formatını kullan:
   - Paragraf veya kaynak tabanlı sorular
   - Grafik, tablo veya görsel yorumlama
   - Çıkarım ve analiz gerektiren sorular
3. **MEB MÜFREDATI**: Türkiye MEB lise müfredatına uygun içerik
4. **ŞIK KALİTESİ**: 
   - 5 şık (A,B,C,D,E) yerine 4 şık kullan (uyumluluk için)
   - Çeldirici şıklar öğrencilerin sık yaptığı hatalar olmalı

${_getJsonFormat()}
${_getRules()}
''';
  }
}

/// Genel Kültür kategorisi için prompt builder
class GeneralCulturePromptBuilder extends CategoryPromptBuilder {
  @override
  String get categoryId => 'general_culture';
  
  @override
  String get categoryDescription => 'Genel Kültür';
  
  @override
  String getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'KOLAY - Herkesin bilmesi gereken temel bilgiler.';
      case 'medium':
        return 'ORTA - Genel kültür meraklılarına yönelik sorular.';
      case 'hard':
        return 'ZOR - Detaylı ve derin bilgi gerektiren sorular.';
      default:
        return 'ORTA - Standart genel kültür düzeyi.';
    }
  }
  
  @override
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    final difficultyDesc = getDifficultyDescription(difficulty);
    final subCatText = subCategory?.isNotEmpty == true ? subCategory! : 'Genel kültür konuları';
    final topicDetail = topic?.isNotEmpty == true ? topic! : 'Bu alan altındaki ilginç konular';
    
    return '''
Sen eğlenceli ve öğretici genel kültür soruları hazırlayan profesyonel bir içerik üreticisisin.

## GÖREV
"$subCatText" alanından, "$topicDetail" konusunda $count adet çoktan seçmeli soru hazırla.

## ZORLUK SEVİYESİ
$difficultyDesc

## SORU KRİTERLERİ
1. **KONU SADAKATI**: Sorular MUTLAKA "$subCatText" ve "$topicDetail" konusuyla ilgili olmalı.
2. **EĞLENCELİ FORMAT**: Quiz oyunu formatına uygun:
   - İlgi çekici ve şaşırtıcı bilgiler
   - Tarih, coğrafya, sanat, bilim, spor gibi alanlardan
   - "Hangisi doğrudur?", "Hangi ülkede...", "Kim tarafından..." kalıpları
3. **ŞIK KALİTESİ**: 
   - 4 şık, hepsi inandırıcı
   - Yanlış şıklar da gerçekçi olmalı
4. **DOĞRULUK**: Tüm bilgiler doğrulanabilir gerçeklere dayalı

${_getJsonFormat()}
${_getRules()}
''';
  }
}

/// Kelime (Vocabulary) kategorisi için prompt builder
class VocabularyPromptBuilder extends CategoryPromptBuilder {
  @override
  String get categoryId => 'vocabulary_quiz';
  
  @override
  String get categoryDescription => 'İngilizce Kelime Bilgisi';
  
  @override
  String getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'KOLAY - A1-A2 seviye, günlük hayatta sık kullanılan kelimeler.';
      case 'medium':
        return 'ORTA - B1-B2 seviye, akademik ve iş hayatında kullanılan kelimeler.';
      case 'hard':
        return 'ZOR - C1-C2 seviye, ileri düzey ve nadir kullanılan kelimeler.';
      default:
        return 'ORTA - B1-B2 seviye kelimeler.';
    }
  }
  
  @override
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    final difficultyDesc = getDifficultyDescription(difficulty);
    final subCatText = subCategory?.isNotEmpty == true ? subCategory! : 'Genel kelime kategorileri';
    final topicDetail = topic?.isNotEmpty == true ? topic! : 'Genel kelime dağarcığı';
    
    return '''
Sen İngilizce-Türkçe kelime eğitimi konusunda uzmanlaşmış profesyonel bir dil eğitimcisisin.

## GÖREV
"$subCatText" kategorisinden, "$topicDetail" konusunda $count adet kelime sorusu hazırla.

## ZORLUK SEVİYESİ
$difficultyDesc

## SORU KRİTERLERİ
1. **KONU SADAKATI**: Kelimeler MUTLAKA "$subCatText" ve "$topicDetail" kategorisiyle ilgili olmalı.
2. **KELİME FORMATI**: 
   - İngilizce kelime verilir, Türkçe karşılığı sorulur
   - Veya cümle içinde boşluk doldurma
   - Eş anlamlı/zıt anlamlı sorular
3. **ŞIK KALİTESİ**: 
   - 4 Türkçe şık
   - Çeldirici şıklar anlam olarak yakın veya ses olarak benzer kelimeler olmalı
4. **KULLANIM**: Kelimelerin günlük kullanımdaki anlamları tercih edilmeli

${_getJsonFormat()}
${_getRules()}
''';
  }
}

/// PDR (Psikolojik Danışmanlık ve Rehberlik) kategorisi için prompt builder
class PDRPromptBuilder extends CategoryPromptBuilder {
  @override
  String get categoryId => 'PDR';
  
  @override
  String get categoryDescription => 'Psikolojik Danışmanlık ve Rehberlik';
  
  @override
  String getDifficultyDescription(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'KOLAY - Temel kavramlar, kuramcılar ve tanımlar. Lisans düzeyi bilgiler.';
      case 'medium':
        return 'ORTA - Uygulama ve vaka analizleri, teknikler ve müdahale yöntemleri. KPSS-EB düzeyi.';
      case 'hard':
        return 'ZOR - İleri düzey kuramsal analiz, karmaşık vakalar, araştırma metodolojisi. PDR alan sınavı düzeyi.';
      default:
        return 'ORTA - Standart PDR sınav düzeyi.';
    }
  }
  
  @override
  String buildPrompt({
    String? subCategory,
    String? topic,
    required String difficulty,
    required int count,
    String? style,
  }) {
    final difficultyDesc = getDifficultyDescription(difficulty);
    final subCatText = subCategory?.isNotEmpty == true ? subCategory! : 'Genel PDR konuları';
    final topicDetail = topic?.isNotEmpty == true ? topic! : 'Bu alt başlık altındaki tüm önemli konular';
    
    // Stil bazlı özel talimatlar
    String styleInstruction = '';
    if (style != null && style.isNotEmpty) {
      switch (style) {
        case 'vaka':
          styleInstruction = '''
## ÖZEL GÖREV: VAKA ANALİZİ ODAKLI
Lütfen üretilen $count sorunun TAMAMI "Vaka Analizi" formatında olsun.
- Her soruda kısa bir danışan/öğrenci/öğretmen senaryosu ver.
- Adayın bu senaryodaki en uygun müdahaleyi, teşhisi veya yaklaşımı bulmasını iste.
- "Aşağıdakilerden hangisi..." gibi bilgi soruları SORMA.''';
          break;
        case 'durumsal':
          styleInstruction = '''
## ÖZEL GÖREV: DURUMSAL/UYGULAMA ODAKLI
Lütfen üretilen $count sorunun TAMAMI "Okul/Danışma Ortamı Durumları" olsun.
- "Sınıfta X sorunu yaşanırsa...", "Veli görüşmesinde Y olursa..." gibi pratik durumlar kurgula.
- Etik kurallar, kriz müdahalesi ve müşavirlik becerilerine odaklan.''';
          break;
        case 'karsilastirma':
          styleInstruction = '''
## ÖZEL GÖREV: KARŞILAŞTIRMA VE AYIRT ETME
Lütfen üretilen $count sorunun TAMAMI "Kavram Karşılaştırma" olsun.
- İki kuramcıyı, iki tekniği veya iki benzer kavramı kıyasla.
- "Freud ile Erikson arasındaki temel fark...", "Sistematik duyarsızlaştırma ile taşırma arasındaki fark..." gibi.''';
          break;
        case 'kavram':
          styleInstruction = '''
## ÖZEL GÖREV: KAVRAMSAL BİLGİ
Lütfen üretilen $count sorunun TAMAMI akademik kavram bilgisi olsun.
- Tanımlar, kuramcı eşleştirmeleri ve teknik terimler.
- Net bilgi soruları.''';
          break;
      }
    }

    return '''
Sen Türkiye'de Psikolojik Danışmanlık ve Rehberlik (PDR) alanında uzmanlaşmış profesyonel bir soru hazırlayıcısısın.

## GÖREV
"$subCatText" konusundan, "$topicDetail" alt başlığında $count adet çoktan seçmeli soru hazırla.

## ZORLUK SEVİYESİ
$difficultyDesc

$styleInstruction

## PDR ALT ALANLARI VE KONU ÖRNEKLERİ
- **Gelişim Psikolojisi**: Piaget, Erikson, Kohlberg, Vygotsky, Freud kuramları
- **Öğrenme Psikolojisi**: Davranışçı, bilişsel, sosyal öğrenme kuramları
- **Rehberlik ve PDR**: Bireysel/grup rehberliği, danışma teorileri, etik kurallar
- **Ölçme ve Değerlendirme**: Test türleri, güvenirlik, geçerlilik, norm/kriter
- **Özel Eğitim**: Engel türleri, BEP, kaynaştırma, erken müdahale
- **Kişilik Kuramları**: Psikanalitik, hümanistik, davranışçı yaklaşımlar
- **Kariyer Danışmanlığı**: Holland, Super, Roe, Gottfredson kuramları
- **Eğitim Psikolojisi**: Motivasyon, öğretim stratejileri, sınıf yönetimi

## SORU TİPİ ÇEŞİTLİLİĞİ (ÇOK ÖNEMLİ)
${(style == null || style.isEmpty) ? '''
1. **EZBERDEN KAÇIN**: Sadece "Aşağıdakilerden hangisi yanlıştır/doğrudur?" şeklindeki soruları en aza indir.
2. **VAKA ANALİZİ**: Öğrenci/danışan senaryoları verip "Bu durumda psikolojik danışman ne yapmalıdır?" gibi uygulama soruları sor.
3. **DURUMSAL SORULAR**: "Bir öğretmenin sınıfta X davranışı sergileyen öğrenciye yaklaşımı nasıl olmalıdır?" gibi pedagojik sorular ekle.
4. **KARŞILAŞTIRMA**: İki kuram veya kavramı kıyaslayan sorular sor.
5. **ÖRNEK OLAY**: Somut örnekler üzerinden kuram veya kavram sor.
''' : 'Seçilen "$style" formatına SADIK KAL.'}

## SORU KRİTERLERİ
1. **KONU SADAKATI**: Sorular MUTLAKA "$subCatText" ve "$topicDetail" konusuyla DOĞRUDAN ilgili olmalı.
2. **AKADEMİK DİL**: PDR ve Eğitim Bilimleri literatürüne uygun akademik bir dil kullan.
3. **ŞIK KALİTESİ**: 
   - 4 şık, hepsi PDR alanına uygun ve inandırıcı
   - Çeldirici şıklar benzer kuramlar, teknikler veya kavramlar olmalı
   - "Hiçbiri" veya "Hepsi" gibi basit şıklardan kaçın
4. **BİLİMSEL DOĞRULUK**: 
   - Türkiye MEB ve üniversite müfredatlarına uygun
   - Güncel DSM-5 ve ICD-11 kriterlerine uygun (klinik konularda)
   - Alan terminolojisini doğru kullan

## ÖNEMLİ KURAMCILAR VE KAVRAMLAR
- Rogers (Koşulsuz olumlu kabul, Empatik anlayış)
- Freud (Savunma mekanizmaları, Psikoseksüel dönemler)
- Erikson (Psikososyal gelişim)
- Piaget (Bilişsel gelişim evreleri)
- Bandura (Sosyal öğrenme, Öz-yeterlik)
- Kohlberg (Ahlak gelişimi)
- Maslow (İhtiyaçlar hiyerarşisi)
- Glasser (Gerçeklik terapisi)
- Ellis (Akılcı Duygusal Davranış Terapisi)
- Beck (Bilişsel terapi)

${_getJsonFormat()}
${_getRules()}
''';
  }
}

// === Factory Pattern ===

/// Kategori ID'sine göre uygun PromptBuilder döndüren factory
class PromptBuilderFactory {
  static final Map<String, CategoryPromptBuilder> _builders = {
    'TUS': TUSPromptBuilder(),
    'kpss': KPSSPromptBuilder(),
    'ayt_yks': AYTYKSPromptBuilder(),
    'general_culture': GeneralCulturePromptBuilder(),
    'vocabulary_quiz': VocabularyPromptBuilder(),
    'PDR': PDRPromptBuilder(),
  };
  
  /// Kategori ID'sine göre builder döndürür
  /// Bulunamazsa varsayılan olarak GeneralCulturePromptBuilder döner
  static CategoryPromptBuilder getBuilder(String categoryId) {
    return _builders[categoryId] ?? GeneralCulturePromptBuilder();
  }
  
  /// Tüm kayıtlı kategori ID'lerini döndürür
  static List<String> get availableCategories => _builders.keys.toList();
}

// === Private helper functions ===

String _getJsonFormat() => '''
## JSON ÇIKTI FORMATI
[
  {
    "questionText": "Soru metni",
    "options": ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı"],
    "correctOptionIndex": 0,
    "topic": "Konu başlığı (opsiyonel ama önerilir)",
    "explanation": "Doğru cevabın kısa açıklaması (opsiyonel ama önerilir)"
  }
]''';

String _getRules() => '''

## ZORUNLU KURALLAR
- Sadece saf JSON array döndür. Markdown blokları (\`\`\`json) KULLANMA.
- Şıklar (options) DAİMA ${AIConstants.optionsCount} adet olmalı.
- correctOptionIndex 0, 1, 2 veya 3 değerlerinden biri olmalı.
- Her soru FARKLI bir yönü veya alt konuyu kapsamalı.
- Sorular Türkçe dilinde yazılmalı.
''';
