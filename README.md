# MR7 Chat v2.0 🔥

**تطبيق دردشة متكامل مع خدمات الذكاء الاصطناعي**

---

## 🚀 المميزات

### 💬 الدردشة
- رسائل نصية، صور، فيديو، صوتيات، ملصقات
- ردود على الرسائل وتعديل وحذف
- مؤشر الكتابة وعلامات القراءة
- مجموعات مع نظام الأدوار
- إشعارات داخل التطبيق بدون FCM

### 🤖 خدمات الذكاء الاصطناعي
| الخدمة | الوصف |
|--------|-------|
| Gemini 2.5 Flash | أذكى نماذج Google |
| DeepSeek V3.2/R1/Coder | ذاكرة محادثة كاملة |
| GPT Image 2 ✨ | توليد صور جديد |
| NanoBanana Pro | إنشاء وتعديل صور 4K |
| Veo 3.1 ✨ | فيديو سينمائي بصوت حقيقي |
| Seedance 1.5 Pro | صورة إلى فيديو |
| AI Music Generator | موسيقى بالذكاء الاصطناعي |

### 🎨 التصميم
- تصميم زجاجي Glassmorphism
- ألوان أحمر داكن + أسود
- خلفيات محادثة قابلة للتخصيص
- وضع RTL كامل للعربية

---

## 🔧 الإعداد

### Firebase
المفاتيح مضبوطة في `lib/firebase_options.dart`:
- Project: `mr7-chat`
- Storage: `mr7-chat.firebasestorage.app`

### تشغيل
```bash
flutter pub get
flutter run
```

### بناء APK
```bash
flutter build apk --release
```

### نشر Web (GitHub Pages)
```bash
flutter build web --release
# رفع محتوى build/web إلى gh-pages branch
```

---

## 📁 هيكل المشروع
```
lib/
├── config/         # الإعدادات، الألوان، المسارات
├── l10n/           # العربية والإنجليزية
├── models/         # نماذج البيانات
├── providers/      # إدارة الحالة (Provider)
├── screens/        # الشاشات
│   ├── ai/         # خدمات الذكاء الاصطناعي
│   ├── auth/       # تسجيل الدخول
│   ├── chat/       # الدردشة والمجموعات
│   ├── home/       # الشاشة الرئيسية
│   ├── notifications/ # الإشعارات
│   ├── profile/    # الملف الشخصي
│   └── settings/   # الإعدادات
├── services/       # Firebase، AI APIs، Storage
└── widgets/        # مكونات مشتركة
```

---

## 🛡️ الصلاحيات (Android)
- `CAMERA` - التصوير
- `RECORD_AUDIO` - الرسائل الصوتية
- `READ/WRITE_EXTERNAL_STORAGE` - الوسائط
- `INTERNET` - الشبكة
- `POST_NOTIFICATIONS` - الإشعارات

---

## 👑 المطور
- **الاسم:** جلال  
- **Username:** `a1`
- **الموقع:** [black3web.github.io/Blackweb](https://black3web.github.io/Blackweb/)
- **Telegram:** [@swc_t](https://t.me/swc_t)

---

*MR7 Chat v2.0.0 - جميع الحقوق محفوظة*
