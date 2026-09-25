# متجر متصل بـ Supabase

هذا الإصدار يحول المتجر من localStorage إلى Supabase:
- المنتجات والأسعار والوصف والألوان والصور في PostgreSQL/Storage.
- إعدادات المتجر في `store_settings`.
- الطلبات في `orders`.
- لوحة الإدارة `admin.html` محمية بتسجيل دخول Supabase Auth.
- الصور ترفع إلى Storage bucket باسم `product-images`.

## 1) إعداد قاعدة البيانات
1. افتح مشروع Supabase: `https://supabase.com/dashboard/project/jwltoaotyiktspqgzsjv`
2. افتح SQL Editor.
3. الصق محتوى `schema.sql` كله ثم Run.

## 2) إنشاء حساب الإدارة
1. من Supabase Dashboard افتح Authentication > Users.
2. أنشئ مستخدم Email/Password بالبريد الذي ستستخدمه للوحة الإدارة.
3. انسخ User UID.
4. في SQL Editor شغّل:

```sql
insert into public.admins (user_id)
values ('ضع-UID-المستخدم-هنا');
```

بعدها افتح `admin.html` وسجّل الدخول بنفس البريد وكلمة المرور.

## 3) تشغيل الموقع
يمكن رفع الملفات الثلاثة الأساسية `index.html`, `admin.html`, `supabase-config.js` إلى GitHub Pages.

مهم: `supabase-config.js` يحتوي فقط على Publishable Key، وليس Secret Key. لا تضع أي `sb_secret_...` في الموقع.

## 4) ربط GitHub Pages
ارفع الملفات إلى نفس مستودع الموقع الحالي، واستبدل `index.html` القديم، وأضف `admin.html` و`supabase-config.js`.

بعد النشر:
- المتجر: `https://jfjku2r4-sudo.github.io/MYSTORE/`
- لوحة الإدارة: `https://jfjku2r4-sudo.github.io/MYSTORE/admin.html`

## ملاحظات
- سلة العميل تبقى محلية في المتصفح، بينما المنتجات والطلبات والإعدادات أصبحت مشتركة على Supabase.
- الصور العامة يمكن للمتجر عرضها، لكن سياسات Storage تمنع الرفع/التعديل/الحذف إلا للمدير.
- يجب أن تكون RLS والسياسات في `schema.sql` مفعلة قبل استخدام الموقع.
