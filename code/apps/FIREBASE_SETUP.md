# Firebase (FCM Push) sozlash — bir martalik

Kod (Flutter + Gradle) tayyor. Push haqiqatda ishlashi uchun **Firebase loyihasi**
yaratib, har ilovaga `google-services.json` qo'shish kerak. Quyidagi qadamlar
Firebase Console'da bajariladi (bepul "Spark" reja yetarli).

## 1. Firebase loyihasi yaratish
1. https://console.firebase.google.com → **Add project** → nom: `beshariq` (yoki ixtiyoriy).
2. Google Analytics — **ixtiyoriy** (o'chirib qo'ysa ham bo'ladi).

## 2. Ikkala Android ilovani qo'shish
Loyihada **2 ta Android app** ro'yxatdan o'tkaziladi (har biri alohida paket):

| Ilova | Android package name |
|---|---|
| Mijoz ilovasi | `com.beshariq.customer_app` |
| Haydovchi ilovasi | `com.beshariq.driver_app` |

Har biri uchun: **Add app → Android** → "Android package name" maydoniga
yuqoridagi nomni kirit (App nickname/SHA-1 shart emas, keyin ham qo'shsa bo'ladi).

## 3. google-services.json'ni joylashtirish
Har ilova uchun yuklab olingan `google-services.json` faylini quyidagi joyga qo'y:

```
code/apps/customer_app/android/app/google-services.json   ← customer_app paketiniki
code/apps/driver_app/android/app/google-services.json     ← driver_app paketiniki
```

> Bu fayllar `.gitignore`'da (har muhit o'ziniki qo'shadi). Ilova `flutter run`
> bo'lishi uchun fayl SHU joyda bo'lishi SHART — aks holda Gradle "File
> google-services.json is missing" deb xato beradi.

## 4. Cloud Messaging yoqilganligini tekshirish
Console → **Build → Cloud Messaging** ochiq bo'lsa kifoya (FCM API v1 standart yoqiq).

## 5. Backend'ni jonli rejimga o'tkazish (push haqiqatda yuborilishi uchun)
Hozir backend **dev rejim** (`FCM_DEV_MODE=true`) — push log'ga chiqadi, qurilmaga
bormaydi. Jonli yuborish uchun auth servisi `.env`:
```
FCM_DEV_MODE=false
FCM_ENABLED=true
FCM_PROJECT_ID=<firebase-project-id>
FCM_ACCESS_TOKEN=<service account OAuth2 access token>
```
`FCM_ACCESS_TOKEN` — service account (Console → Project settings → Service accounts →
"Generate new private key") asosida OAuth2 token. Deploy bosqichida avtomatlashtiriladi
(google-auth kutubxonasi bilan). Sinov uchun qo'lda token olib qo'yish ham mumkin.

## 6. Sinash (telefon = emulyator)
1. `google-services.json` o'z joyida.
2. Telefonni USB orqali ulang, `flutter devices` ko'rsatsin.
3. `cd code/apps/customer_app && flutter run` (yoki driver_app).
4. Kirish (telefon+OTP) → ilova FCM tokenni `/profile/device-token`'ga yuboradi.
5. Backend jonli rejimda bo'lsa: buyurtma/taksi/dostavka holati o'zgarganda push keladi.

## Eslatma — kod tomoni allaqachon tayyor
- `firebase_core` + `firebase_messaging` (pubspec), Gradle `google-services` plugin.
- `main()` da `Firebase.initializeApp()` (fayl yo'q bo'lsa ilova baribir ishlaydi, push'siz).
- Kirilgach FCM token avtomatik ro'yxatga olinadi; chiqishda o'chiriladi (`beshariq_core` `PushService`).
- Fon/yopiq holatda push'ni Android tizimi o'zi ko'rsatadi. Foreground ko'rsatish — keyingi yaxshilash.
