import Foundation

struct TurkishCity: Identifiable {
    let id: String
    let name: String
    let districts: [String]

    init(_ name: String, _ districts: [String]) {
        self.id = name
        self.name = name
        self.districts = districts.sorted()
    }
}

let turkishCities: [TurkishCity] = [
    TurkishCity("Adana", [
        "Aladağ", "Ceyhan", "Çukurova", "Feke", "İmamoğlu",
        "Karaisalı", "Karataş", "Kozan", "Pozantı", "Saimbeyli",
        "Sarıçam", "Seyhan", "Tufanbeyli", "Yumurtalık", "Yüreğir"
    ]),
    TurkishCity("Adıyaman", [
        "Besni", "Çelikhan", "Gerger", "Gölbaşı", "Kahta",
        "Merkez", "Samsat", "Sincik", "Tut"
    ]),
    TurkishCity("Afyonkarahisar", [
        "Başmakçı", "Bayat", "Bolvadin", "Çay", "Çobanlar",
        "Dazkırı", "Dinar", "Emirdağ", "Evciler", "Hocalar",
        "İhsaniye", "İscehisar", "Kızılören", "Merkez", "Sandıklı",
        "Sinanpaşa", "Sultandağı", "Şuhut"
    ]),
    TurkishCity("Ağrı", [
        "Diyadin", "Doğubayazıt", "Eleşkirt", "Hamur",
        "Merkez", "Patnos", "Taşlıçay", "Tutak"
    ]),
    TurkishCity("Aksaray", [
        "Ağaçören", "Eskil", "Gülağaç", "Güzelyurt",
        "Merkez", "Ortaköy", "Sarıyahşi", "Sultanhanı"
    ]),
    TurkishCity("Amasya", [
        "Göynücek", "Gümüşhacıköy", "Hamamözü", "Merkez",
        "Merzifon", "Suluova", "Taşova"
    ]),
    TurkishCity("Ankara", [
        "Akyurt", "Altındağ", "Ayaş", "Balâ", "Beypazarı",
        "Çamlıdere", "Çankaya", "Çubuk", "Elmadağ", "Etimesgut",
        "Evren", "Gölbaşı", "Güdül", "Haymana", "Kahramankazan",
        "Kalecik", "Keçiören", "Kızılcahamam", "Mamak", "Nallıhan",
        "Polatlı", "Pursaklar", "Sincan", "Şereflikoçhisar", "Yenimahalle"
    ]),
    TurkishCity("Antalya", [
        "Aksu", "Alanya", "Demre", "Döşemealtı", "Elmalı",
        "Finike", "Gazipaşa", "Gündoğmuş", "İbradı", "Kaş",
        "Kemer", "Kepez", "Konyaaltı", "Korkuteli", "Kumluca",
        "Manavgat", "Muratpaşa", "Serik"
    ]),
    TurkishCity("Ardahan", [
        "Çıldır", "Damal", "Göle", "Hanak", "Merkez", "Posof"
    ]),
    TurkishCity("Artvin", [
        "Ardanuç", "Arhavi", "Borçka", "Hopa", "Kemalpaşa",
        "Merkez", "Murgul", "Şavşat", "Yusufeli"
    ]),
    TurkishCity("Aydın", [
        "Bozdoğan", "Buharkent", "Çine", "Didim", "Efeler",
        "Germencik", "İncirliova", "Karacasu", "Karpuzlu", "Koçarlı",
        "Köşk", "Kuşadası", "Kuyucak", "Nazilli", "Söke",
        "Sultanhisar", "Yenipazar"
    ]),
    TurkishCity("Balıkesir", [
        "Altıeylül", "Ayvalık", "Balya", "Bandırma", "Bigadiç",
        "Burhaniye", "Dursunbey", "Edremit", "Erdek", "Gömeç",
        "Gönen", "Havran", "İvrindi", "Karesi", "Kepsut",
        "Manyas", "Marmara", "Savaştepe", "Sındırgı", "Susurluk"
    ]),
    TurkishCity("Bartın", [
        "Amasra", "Kurucaşile", "Merkez", "Ulus"
    ]),
    TurkishCity("Batman", [
        "Beşiri", "Gercüş", "Hasankeyf", "Kozluk", "Merkez", "Sason"
    ]),
    TurkishCity("Bayburt", [
        "Aydıntepe", "Demirözü", "Merkez"
    ]),
    TurkishCity("Bilecik", [
        "Bozüyük", "Gölpazarı", "İnhisar", "Merkez",
        "Osmaneli", "Pazaryeri", "Söğüt", "Yenipazar"
    ]),
    TurkishCity("Bingöl", [
        "Adaklı", "Genç", "Karlıova", "Kiğı", "Merkez",
        "Solhan", "Yayladere", "Yedisu"
    ]),
    TurkishCity("Bitlis", [
        "Adilcevaz", "Ahlat", "Güroymak", "Hizan",
        "Merkez", "Mutki", "Tatvan"
    ]),
    TurkishCity("Bolu", [
        "Dörtdivan", "Gerede", "Göynük", "Kıbrıscık",
        "Mengen", "Merkez", "Mudurnu", "Seben", "Yeniçağa"
    ]),
    TurkishCity("Burdur", [
        "Ağlasun", "Altınyayla", "Bucak", "Çavdır",
        "Çeltikçi", "Gölhisar", "Karamanlı", "Kemer",
        "Merkez", "Tefenni", "Yeşilova"
    ]),
    TurkishCity("Bursa", [
        "Büyükorhan", "Gemlik", "Gürsu", "Harmancık", "İnegöl",
        "İznik", "Karacabey", "Keles", "Kestel", "Mudanya",
        "Mustafakemalpaşa", "Nilüfer", "Orhaneli", "Orhangazi",
        "Osmangazi", "Yenişehir", "Yıldırım"
    ]),
    TurkishCity("Çanakkale", [
        "Ayvacık", "Bayramiç", "Biga", "Bozcaada", "Çan",
        "Eceabat", "Ezine", "Gelibolu", "Gökçeada", "Lapseki",
        "Merkez", "Yenice"
    ]),
    TurkishCity("Çankırı", [
        "Atkaracalar", "Bayramören", "Çerkeş", "Eldivan",
        "Ilgaz", "Kızılırmak", "Korgun", "Kurşunlu",
        "Merkez", "Orta", "Şabanözü", "Yapraklı"
    ]),
    TurkishCity("Çorum", [
        "Alaca", "Bayat", "Boğazkale", "Dodurga", "İskilip",
        "Kargı", "Laçin", "Mecitözü", "Merkez", "Oğuzlar",
        "Ortaköy", "Osmancık", "Sungurlu", "Uğurludağ"
    ]),
    TurkishCity("Denizli", [
        "Acıpayam", "Babadağ", "Baklan", "Bekilli", "Beyağaç",
        "Bozkurt", "Buldan", "Çal", "Çameli", "Çardak",
        "Çivril", "Güney", "Honaz", "Kale", "Merkezefendi",
        "Pamukkale", "Sarayköy", "Serinhisar", "Tavas"
    ]),
    TurkishCity("Diyarbakır", [
        "Bağlar", "Bismil", "Çermik", "Çınar", "Çüngüş",
        "Dicle", "Eğil", "Ergani", "Hani", "Hazro",
        "Kayapınar", "Kocaköy", "Kulp", "Lice", "Silvan",
        "Sur", "Yenişehir"
    ]),
    TurkishCity("Düzce", [
        "Akçakoca", "Cumayeri", "Çilimli", "Gölyaka",
        "Gümüşova", "Kaynaşlı", "Merkez", "Yığılca"
    ]),
    TurkishCity("Edirne", [
        "Enez", "Havsa", "İpsala", "Keşan", "Lalapaşa",
        "Meriç", "Merkez", "Süloğlu", "Uzunköprü"
    ]),
    TurkishCity("Elazığ", [
        "Ağın", "Alacakaya", "Arıcak", "Baskil", "Karakoçan",
        "Keban", "Kovancılar", "Maden", "Merkez", "Palu", "Sivrice"
    ]),
    TurkishCity("Erzincan", [
        "Çayırlı", "İliç", "Kemah", "Kemaliye", "Merkez",
        "Otlukbeli", "Refahiye", "Tercan", "Üzümlü"
    ]),
    TurkishCity("Erzurum", [
        "Aşkale", "Aziziye", "Çat", "Hınıs", "Horasan",
        "İspir", "Karaçoban", "Karayazı", "Köprüköy", "Narman",
        "Oltu", "Olur", "Palandöken", "Pasinler", "Pazaryolu",
        "Şenkaya", "Tekman", "Tortum", "Uzundere", "Yakutiye"
    ]),
    TurkishCity("Eskişehir", [
        "Alpu", "Beylikova", "Çifteler", "Günyüzü", "Han",
        "İnönü", "Mahmudiye", "Mihalgazi", "Mihalıççık",
        "Odunpazarı", "Sarıcakaya", "Seyitgazi", "Sivrihisar",
        "Tepebaşı"
    ]),
    TurkishCity("Gaziantep", [
        "Araban", "İslahiye", "Karkamış", "Nizip", "Nurdağı",
        "Oğuzeli", "Şahinbey", "Şehitkâmil", "Yavuzeli"
    ]),
    TurkishCity("Giresun", [
        "Alucra", "Bulancak", "Çamoluk", "Çanakçı", "Dereli",
        "Doğankent", "Espiye", "Eynesil", "Görele", "Güce",
        "Keşap", "Merkez", "Piraziz", "Şebinkarahisar",
        "Tirebolu", "Yağlıdere"
    ]),
    TurkishCity("Gümüşhane", [
        "Kelkit", "Köse", "Kürtün", "Merkez", "Şiran", "Torul"
    ]),
    TurkishCity("Hakkari", [
        "Çukurca", "Derecik", "Merkez", "Şemdinli", "Yüksekova"
    ]),
    TurkishCity("Hatay", [
        "Altınözü", "Antakya", "Arsuz", "Belen", "Defne",
        "Dörtyol", "Erzin", "Hassa", "İskenderun", "Kırıkhan",
        "Kumlu", "Payas", "Reyhanlı", "Samandağ", "Yayladağı"
    ]),
    TurkishCity("Iğdır", [
        "Aralık", "Karakoyunlu", "Merkez", "Tuzluca"
    ]),
    TurkishCity("Isparta", [
        "Aksu", "Atabey", "Eğirdir", "Gelendost", "Gönen",
        "Keçiborlu", "Merkez", "Senirkent", "Sütçüler",
        "Şarkikaraağaç", "Uluborlu", "Yalvaç", "Yenişarbademli"
    ]),
    TurkishCity("İstanbul", [
        "Adalar", "Arnavutköy", "Ataşehir", "Avcılar", "Bağcılar",
        "Bahçelievler", "Bakırköy", "Başakşehir", "Bayrampaşa",
        "Beşiktaş", "Beykoz", "Beylikdüzü", "Beyoğlu",
        "Büyükçekmece", "Çatalca", "Çekmeköy", "Esenler",
        "Esenyurt", "Eyüpsultan", "Fatih", "Gaziosmanpaşa",
        "Güngören", "Kadıköy", "Kağıthane", "Kartal",
        "Küçükçekmece", "Maltepe", "Pendik", "Sancaktepe",
        "Sarıyer", "Silivri", "Sultanbeyli", "Sultangazi",
        "Şile", "Şişli", "Tuzla", "Ümraniye", "Üsküdar",
        "Zeytinburnu"
    ]),
    TurkishCity("İzmir", [
        "Aliağa", "Balçova", "Bayındır", "Bayraklı", "Bergama",
        "Beydağ", "Bornova", "Buca", "Çeşme", "Çiğli",
        "Dikili", "Foça", "Gaziemir", "Güzelbahçe", "Karabağlar",
        "Karaburun", "Karşıyaka", "Kemalpaşa", "Kınık", "Kiraz",
        "Konak", "Menderes", "Menemen", "Narlıdere", "Ödemiş",
        "Seferihisar", "Selçuk", "Tire", "Torbalı", "Urla"
    ]),
    TurkishCity("Kahramanmaraş", [
        "Afşin", "Andırın", "Çağlayancerit", "Dulkadiroğlu",
        "Ekinözü", "Elbistan", "Göksun", "Nurhak",
        "Onikişubat", "Pazarcık", "Türkoğlu"
    ]),
    TurkishCity("Karabük", [
        "Eflani", "Eskipazar", "Merkez", "Ovacık",
        "Safranbolu", "Yenice"
    ]),
    TurkishCity("Karaman", [
        "Ayrancı", "Başyayla", "Ermenek", "Kazımkarabekir",
        "Merkez", "Sarıveliler"
    ]),
    TurkishCity("Kars", [
        "Akyaka", "Arpaçay", "Digor", "Kağızman",
        "Merkez", "Sarıkamış", "Selim", "Susuz"
    ]),
    TurkishCity("Kastamonu", [
        "Abana", "Ağlı", "Araç", "Azdavay", "Bozkurt",
        "Cide", "Çatalzeytin", "Daday", "Devrekani", "Doğanyurt",
        "Hanönü", "İhsangazi", "İnebolu", "Küre", "Merkez",
        "Pınarbaşı", "Seydiler", "Şenpazar", "Taşköprü", "Tosya"
    ]),
    TurkishCity("Kayseri", [
        "Akkışla", "Bünyan", "Develi", "Felahiye", "Hacılar",
        "İncesu", "Kocasinan", "Melikgazi", "Özvatan", "Pınarbaşı",
        "Sarıoğlan", "Sarız", "Talas", "Tomarza", "Yahyalı",
        "Yeşilhisar"
    ]),
    TurkishCity("Kilis", [
        "Elbeyli", "Merkez", "Musabeyli", "Polateli"
    ]),
    TurkishCity("Kırıkkale", [
        "Bahşili", "Balışeyh", "Çelebi", "Delice",
        "Karakeçili", "Keskin", "Merkez", "Sulakyurt", "Yahşihan"
    ]),
    TurkishCity("Kırklareli", [
        "Babaeski", "Demirköy", "Kofçaz", "Lüleburgaz",
        "Merkez", "Pehlivanköy", "Pınarhisar", "Vize"
    ]),
    TurkishCity("Kırşehir", [
        "Akçakent", "Akpınar", "Boztepe", "Çiçekdağı",
        "Kaman", "Merkez", "Mucur"
    ]),
    TurkishCity("Kocaeli", [
        "Başiskele", "Çayırova", "Darıca", "Derince", "Dilovası",
        "Gebze", "Gölcük", "İzmit", "Kandıra", "Karamürsel",
        "Kartepe", "Körfez"
    ]),
    TurkishCity("Konya", [
        "Ahırlı", "Akören", "Akşehir", "Altınekin", "Beyşehir",
        "Bozkır", "Cihanbeyli", "Çeltik", "Çumra", "Derbent",
        "Derebucak", "Doğanhisar", "Emirgazi", "Ereğli", "Güneysınır",
        "Hadım", "Halkapınar", "Hüyük", "Ilgın", "Kadınhanı",
        "Karapınar", "Karatay", "Kulu", "Meram", "Sarayönü",
        "Selçuklu", "Seydişehir", "Taşkent", "Tuzlukçu",
        "Yalıhüyük", "Yunak"
    ]),
    TurkishCity("Kütahya", [
        "Altıntaş", "Aslanapa", "Çavdarhisar", "Domaniç",
        "Dumlupınar", "Emet", "Gediz", "Hisarcık", "Merkez",
        "Pazarlar", "Simav", "Şaphane", "Tavşanlı"
    ]),
    TurkishCity("Malatya", [
        "Akçadağ", "Arapgir", "Arguvan", "Battalgazi", "Darende",
        "Doğanşehir", "Doğanyol", "Hekimhan", "Kale",
        "Kuluncak", "Pütürge", "Yazıhan", "Yeşilyurt"
    ]),
    TurkishCity("Manisa", [
        "Ahmetli", "Akhisar", "Alaşehir", "Demirci", "Gölmarmara",
        "Gördes", "Kırkağaç", "Köprübaşı", "Kula", "Salihli",
        "Sarıgöl", "Saruhanlı", "Selendi", "Soma", "Şehzadeler",
        "Turgutlu", "Yunusemre"
    ]),
    TurkishCity("Mardin", [
        "Artuklu", "Dargeçit", "Derik", "Kızıltepe", "Mazıdağı",
        "Midyat", "Nusaybin", "Ömerli", "Savur", "Yeşilli"
    ]),
    TurkishCity("Mersin", [
        "Akdeniz", "Anamur", "Aydıncık", "Bozyazı", "Çamlıyayla",
        "Erdemli", "Gülnar", "Mezitli", "Mut", "Silifke",
        "Tarsus", "Toroslar", "Yenişehir"
    ]),
    TurkishCity("Muğla", [
        "Bodrum", "Dalaman", "Datça", "Fethiye", "Kavaklıdere",
        "Köyceğiz", "Marmaris", "Menteşe", "Milas", "Ortaca",
        "Seydikemer", "Ula", "Yatağan"
    ]),
    TurkishCity("Muş", [
        "Bulanık", "Hasköy", "Korkut", "Malazgirt",
        "Merkez", "Varto"
    ]),
    TurkishCity("Nevşehir", [
        "Acıgöl", "Avanos", "Derinkuyu", "Gülşehir",
        "Hacıbektaş", "Kozaklı", "Merkez", "Ürgüp"
    ]),
    TurkishCity("Niğde", [
        "Altunhisar", "Bor", "Çamardı", "Çiftlik",
        "Merkez", "Ulukışla"
    ]),
    TurkishCity("Ordu", [
        "Akkuş", "Altınordu", "Aybastı", "Çamaş", "Çatalpınar",
        "Çaybaşı", "Fatsa", "Gölköy", "Gülyalı", "Gürgentepe",
        "İkizce", "Kabadüz", "Kabataş", "Korgan", "Kumru",
        "Mesudiye", "Perşembe", "Ulubey", "Ünye"
    ]),
    TurkishCity("Osmaniye", [
        "Bahçe", "Düziçi", "Hasanbeyli", "Kadirli",
        "Merkez", "Sumbas", "Toprakkale"
    ]),
    TurkishCity("Rize", [
        "Ardeşen", "Çamlıhemşin", "Çayeli", "Derepazarı",
        "Fındıklı", "Güneysu", "Hemşin", "İkizdere",
        "İyidere", "Kalkandere", "Merkez", "Pazar"
    ]),
    TurkishCity("Sakarya", [
        "Adapazarı", "Akyazı", "Arifiye", "Erenler", "Ferizli",
        "Geyve", "Hendek", "Karapürçek", "Karasu", "Kaynarca",
        "Kocaali", "Pamukova", "Sapanca", "Serdivan", "Söğütlü",
        "Taraklı"
    ]),
    TurkishCity("Samsun", [
        "Alaçam", "Asarcık", "Atakum", "Ayvacık", "Bafra",
        "Canik", "Çarşamba", "Havza", "İlkadım", "Kavak",
        "Ladik", "Ondokuzmayıs", "Salıpazarı", "Tekkeköy",
        "Terme", "Vezirköprü", "Yakakent"
    ]),
    TurkishCity("Siirt", [
        "Baykan", "Eruh", "Kurtalan", "Merkez",
        "Pervari", "Şirvan", "Tillo"
    ]),
    TurkishCity("Sinop", [
        "Ayancık", "Boyabat", "Dikmen", "Durağan",
        "Erfelek", "Gerze", "Merkez", "Saraydüzü", "Türkeli"
    ]),
    TurkishCity("Sivas", [
        "Akıncılar", "Altınyayla", "Divriği", "Doğanşar",
        "Gemerek", "Gölova", "Gürün", "Hafik", "İmranlı",
        "Kangal", "Koyulhisar", "Merkez", "Suşehri",
        "Şarkışla", "Ulaş", "Yıldızeli", "Zara"
    ]),
    TurkishCity("Şanlıurfa", [
        "Akçakale", "Birecik", "Bozova", "Ceylanpınar",
        "Eyyübiye", "Halfeti", "Haliliye", "Harran",
        "Hilvan", "Karaköprü", "Siverek", "Suruç",
        "Viranşehir"
    ]),
    TurkishCity("Şırnak", [
        "Beytüşşebap", "Cizre", "Güçlükonak", "İdil",
        "Merkez", "Silopi", "Uludere"
    ]),
    TurkishCity("Tekirdağ", [
        "Çerkezköy", "Çorlu", "Ergene", "Hayrabolu", "Kapaklı",
        "Malkara", "Marmaraereğlisi", "Muratlı", "Saray",
        "Süleymanpaşa", "Şarköy"
    ]),
    TurkishCity("Tokat", [
        "Almus", "Artova", "Başçiftlik", "Erbaa", "Merkez",
        "Niksar", "Pazar", "Reşadiye", "Sulusaray", "Turhal",
        "Yeşilyurt", "Zile"
    ]),
    TurkishCity("Trabzon", [
        "Akçaabat", "Araklı", "Arsin", "Beşikdüzü", "Çarşıbaşı",
        "Çaykara", "Dernekpazarı", "Düzköy", "Hayrat", "Köprübaşı",
        "Maçka", "Of", "Ortahisar", "Sürmene", "Şalpazarı",
        "Tonya", "Vakfıkebir", "Yomra"
    ]),
    TurkishCity("Tunceli", [
        "Çemişgezek", "Hozat", "Mazgirt", "Merkez",
        "Nazımiye", "Ovacık", "Pertek", "Pülümür"
    ]),
    TurkishCity("Uşak", [
        "Banaz", "Eşme", "Karahallı", "Merkez", "Sivaslı", "Ulubey"
    ]),
    TurkishCity("Van", [
        "Bahçesaray", "Başkale", "Çaldıran", "Çatak", "Edremit",
        "Erciş", "Gevaş", "Gürpınar", "İpekyolu", "Muradiye",
        "Özalp", "Saray", "Tuşba"
    ]),
    TurkishCity("Yalova", [
        "Altınova", "Armutlu", "Çınarcık", "Çiftlikköy",
        "Merkez", "Termal"
    ]),
    TurkishCity("Yozgat", [
        "Akdağmadeni", "Aydıncık", "Boğazlıyan", "Çandır",
        "Çayıralan", "Çekerek", "Kadışehri", "Merkez",
        "Saraykent", "Sarıkaya", "Sorgun", "Şefaatli",
        "Yenifakılı", "Yerköy"
    ]),
    TurkishCity("Zonguldak", [
        "Alaplı", "Çaycuma", "Devrek", "Ereğli", "Gökçebey",
        "Kilimli", "Kozlu", "Merkez"
    ])
].sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
