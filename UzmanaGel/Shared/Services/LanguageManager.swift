import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("pref_language") var languageCode: String = "tr" {
        didSet {
            // Notify SwiftUI views to update
            objectWillChange.send()
        }
    }
    
    func translate(_ key: String) -> String {
        if languageCode == "en" {
            return translations[key] ?? key
        }
        return key
    }
    
    // Translation dictionary for Turkish keys to English values (deduplicated)
    private let translations: [String: String] = [
        // Tab / Navigation / Section Titles
        "Tercihler": "Preferences",
        "Profil": "Profile",
        "Hesap Bilgileri": "Account Info",
        "Kişisel Bilgiler": "Personal Info",
        "Bilgilerinizi ve şifrenizi güncelleyin": "Update your info & password",
        "Adreslerim": "My Addresses",
        "Kayıtlı teslimat adresleri": "Saved delivery addresses",
        "Ödeme Yöntemleri": "Payment Methods",
        "Kayıtlı kredi kartları ve cüzdan": "Saved cards and wallet",
        "Ayarlar ve Tercihler": "Settings & Preferences",
        "Bildirim, tema ve dil ayarları": "Notification, theme and language settings",
        "Yardım ve Destek": "Help & Support",
        "Sıkça sorulan sorular ve destek talepleri": "FAQs and support tickets",
        "Çıkış Yap": "Log Out",
        "Oturumu sonlandır": "End session",
        "TERCİHLER": "PREFERENCES",
        "GÜVENLİK": "SECURITY",
        "Giriş Yap": "Log In",
        "Kayıt Ol": "Sign Up",
        "Favorilerim": "My Favorites",
        "Şifre Değiştir": "Change Password",
        "Telefon Doğrulama": "Phone Verification",
        "E-posta Doğrulama": "Email Verification",
        "Kullanıcı Bilgileri": "User Information",
        "Ödeme Yöntemlerim": "My Payment Methods",
        "Kayıtlı kartlarınız ve Apple Pay": "Saved cards & Apple Pay",
        "Geçmiş ve Favoriler": "History & Favorites",
        "Geçmiş siparişleriniz ve favori ustalar": "Your past orders and favorite experts",
        "Yardım": "Help",
        "Destek": "Support",
        "Yardım merkezi ve müşteri hizmetleri": "Help center & customer service",
        "Destek ve Yardım Ekranı": "Support & Help Screen",
        
        // Preferences Page / View
        "BİLDİRİM AYARLARI": "NOTIFICATION SETTINGS",
        "Bildirim Ayarları": "Notification Settings",
        "Anlık Bildirimler (Push)": "Push Notifications",
        "E-posta Bildirimleri": "Email Notifications",
        "SMS Bildirimleri": "SMS Notifications",
        "Rezervasyon Güncellemeleri": "Booking Updates",
        "Kampanya ve Tanıtımlar": "Campaigns & Promos",
        "Sistem ve Güvenlik": "System & Security",
        "Rezervasyon": "Bookings",
        "Kampanya & Promosyon": "Campaigns & Promos",
        "Sistem Bildirimleri": "System Notifications",
        "Bildirim izni reddedilmiş.": "Notification permission denied.",
        "Bildirim Türleri": "Notification Types",
        "Profilim Herkese Açık": "My Profile is Public",
        "Veri Toplama Onayı": "Data Collection Consent",
        "GÖRÜNÜM AYARLARI": "APPEARANCE SETTINGS",
        "Görünüm Ayarları": "Appearance Settings",
        "Tema": "Theme",
        "Sistem": "System",
        "Açık": "Light",
        "Koyu": "Dark",
        "DİL SEÇİMİ": "LANGUAGE SELECTION",
        "Dil Ayarları": "Language Settings",
        "Uygulama Dili": "App Language",
        "Tema Seçimi": "Theme Selection",
        "Dil": "Language",
        "GİZLİLİK AYARLARI": "PRIVACY SETTINGS",
        "Gizlilik Ayarları": "Privacy Settings",
        "Konum Paylaşımı": "Location Sharing",
        "Profil Görünürlüğü (Herkese Açık)": "Profile Visibility (Public)",
        "Kullanım Verisi Analiz İzni": "Data Collection Analytics",
        "Tüm tercihler otomatik olarak kaydedilir.": "All preferences are automatically saved.",
        "Tercihler kaydedildi!": "Preferences saved!",
        "Ayarları Kaydet": "Save Settings",
        
        // General UI & Loadings
        "Profil yükleniyor...": "Loading profile...",
        "Tercihleriniz yükleniyor...": "Loading preferences...",
        "Hata Oluştu": "Error Occurred",
        "Bir Hata Oluştu": "An Error Occurred",
        "Tekrar Dene": "Retry",
        "Kapat": "Close",
        
        // Homepage & History
        "Hoş Geldiniz": "Welcome",
        "Uzman Bul": "Find an Expert",
        "Ara": "Search",
        "Kategoriler": "Categories",
        "Popüler Hizmetler": "Popular Services",
        "Tümünü Gör": "See All",
        "Geçmiş": "History",
        "Favoriler": "Favorites",
        "Verileriniz yükleniyor...": "Loading your data...",
        "Kartlarınız yükleniyor...": "Loading your cards...",
        "Adresleriniz yükleniyor...": "Loading your addresses...",
        "Henüz rezervasyon bulunmuyor.": "No bookings found yet.",
        "Favori uzmanınız bulunmuyor.": "No favorite experts found.",
        
        // Edit Profile Page & SMS / Crop
        "Fotoğrafı Değiştir": "Change Photo",
        "Ad Soyad": "Full Name",
        "E-posta": "Email",
        "E-posta değişikliği doğrulama maili gerektirir.": "Email change requires a validation email.",
        "Telefon Numarası": "Phone Number",
        "Doğrula": "Verify",
        "Değişiklikleri Kaydet": "Save Changes",
        "Mevcut Şifre": "Current Password",
        "Yeni Şifre": "New Password",
        "Yeni Şifre (Tekrar)": "Confirm New Password",
        "Şifre Gücü: ": "Password Strength: ",
        "Çok Zayıf": "Very Weak",
        "Zayıf": "Weak",
        "Orta": "Medium",
        "Güçlü": "Strong",
        "Çok Güçlü": "Very Strong",
        "Şifreyi Güncelle": "Update Password",
        "Bilgileri Düzenle": "Edit Profile",
        "SMS Doğrulama": "SMS Verification",
        "%@ numaralı telefona gönderilen 4 haneli doğrulama kodunu girin.\n(Mock Kodu: 1234)": "Enter the 4-digit verification code sent to %@.\n(Mock Code: 1234)",
        "Doğrulama Kodu": "Verification Code",
        "Onayla ve Telefonu Güncelle": "Confirm & Update Phone",
        "Doğrulama": "Verification",
        "Görseli Kırp / Ölçeklendir": "Crop / Scale Image",
        "Ölçek: %%%d": "Scale: %%%d",
        "Kırp ve Uygula": "Crop & Apply",
        "Kırpma": "Cropping",
        "Profil bilgileriniz başarıyla güncellendi.": "Your profile info has been successfully updated.",
        "Yeni şifreler eşleşmiyor.": "New passwords do not match.",
        "Şifreniz başarıyla değiştirildi.": "Your password has been successfully changed.",
        "Telefon numaranız doğrulandı.": "Your phone number has been verified.",
        
        // Homepage & Login & Logout & Categories
        "Konumunuz": "Your Location",
        "Hizmet, uzman veya kategori ara…": "Search services, experts or categories...",
        "Hizmet, uzman veya kategori ara...": "Search services, experts or categories...",
        "(0 yorum)": "(0 reviews)",
        "başlangıç fiyatı": "starting price",
        "Hoşgeldiniz": "Welcome",
        "Beni Hatırla": "Remember Me",
        "Şifremi Unuttum": "Forgot Password",
        "GİRİŞ YAP": "LOG IN",
        "VEYA": "OR",
        "Hesabın yok mu?": "Don't have an account?",
        "Uzman mısın?": "Are you an expert?",
        "Başvuru Yap": "Apply Now",
        "Hesabınızdan çıkmak istediğinizden emin misiniz?": "Are you sure you want to log out of your account?",
        "İptal": "Cancel",
        "su tesisatı": "plumbing",
        "Kombi & Klima Bakımı": "Boiler & AC Maintenance",
        "Yazılım & Teknoloji": "Software & Tech",
        "Boya & Badana": "Painting & Whitewash",
        "Su tesisatı bakım": "Plumbing maintenance",
        "Yıllık bakım": "Annual maintenance",
        "Mobil uygulama (iOS)": "Mobile app (iOS)",
        "Profesyonel Boya": "Professional Painting",
        
        // Side Menu & Customer Profile View
        "Ana Sayfa": "Home",
        "Profilim": "My Profile",
        "Mesajlar": "Messages",
        "Ayarlar": "Settings",
        "Kullanıcı": "User",
        "Yeni Üye": "New Member",
        "%d Ay Üye": "%d Months Member",
        "%d Yıl Üye": "%d Years Member",
        "Siparişlerim": "My Orders",
        "İLETİŞİM BİLGİLERİ": "CONTACT INFO",
        "Telefon": "Phone",
        "DOĞRULANDI": "VERIFIED",
        "DOĞRULA": "VERIFY",
        "HESAP AYARLARI": "ACCOUNT SETTINGS",
        "GEÇMİŞ & FAVORİLER": "HISTORY & FAVORITES",
        "Düzenle": "Edit",
        
        // Filter Sheet
        "Kategori": "Category",
        "Tüm Kategoriler": "All Categories",
        "Şehir": "City",
        "Tüm Şehirler": "All Cities",
        "Fiyat Aralığı": "Price Range",
        "Sıralama": "Sort By",
        "Varsayılan": "Default",
        "Fiyat: Düşükten Yükseğe": "Price: Low to High",
        "Fiyat: Yüksekten Düşüğe": "Price: High to Low",
        "Sıfırla": "Reset",
        "Uygula": "Apply",
        "Filtrele & Sırala": "Filter & Sort",
        "Filtre aktif": "Filter active",
        "Temizle": "Clear",
        
        // Messages Page & Settings Page
        "Henüz mesaj bulunmuyor.": "No messages found yet.",
        "Uygulama": "App",
        "Bildirimler": "Notifications",
        "KVKK ve Gizlilik": "KVKK & Privacy",
        "Hakkında": "About",
        
        // User Info Edit View
        "Ad": "First Name",
        "Soyad": "Last Name",
        "Doğrulandı": "Verified",
        "SMS ile Doğrula": "Verify with SMS",
        "Hesap şifreni güvenli şekilde güncelle": "Update your account password securely",
        "DEĞİŞİKLİKLERİ KAYDET": "SAVE CHANGES",
        
        // Order History & Favorites additions
        "Sipariş Geçmişim": "My Order History",
        "Sipariş Geçmişi": "Order History",
        "Tümü": "All",
        "Tamamlandı": "Completed",
        "İptal Edildi": "Cancelled",
        "Bekliyor": "Pending",
        "Değerlendir": "Rate",
        "Tekrarla": "Repeat",
        "Sipariş geçmişi bulunamadı": "No order history found",
        "Tamamlanan siparişleriniz burada görünecek.": "Your completed orders will appear here.",
        "Favorin yok": "No favorites",
        "Ana sayfadan kalp ikonuna basarak favori ekleyebilirsin.": "You can add favorites by tapping the heart icon on the homepage.",
        "Hata": "Error",
        "Tamam": "OK",
        "Bilinmeyen hata": "Unknown error",
        "Henüz favori yok": "No favorites yet",
        "Beğendiğiniz uzmanları favorilere ekleyin.": "Add the experts you like to your favorites.",
        "İletişim": "Contact"
    ]
}

extension String {
    var localized: String {
        return LanguageManager.shared.translate(self)
    }
    
    func decodeBase64ToImage() -> UIImage? {
        var cleanString = self
        if cleanString.hasPrefix("data:image") {
            let components = cleanString.components(separatedBy: ",")
            if components.count > 1 {
                cleanString = components[1]
            }
        }
        guard let data = Data(base64Encoded: cleanString) else { return nil }
        return UIImage(data: data)
    }
}
