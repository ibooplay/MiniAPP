# MINI APP SHOP VPN Auto Installer

این پکیج یک اسکریپت کامل برای نصب خودکار پروژه MINI APP SHOP VPN روی Ubuntu 22.04 است.

## اجرا روی سرور

```bash
sudo bash install.sh
```

اسکریپت خودش این موارد را از شما می‌پرسد:

- دامنه سایت
- آیدی ربات تلگرام
- آیدی پشتیبانی
- رمز API برای اتصال ربات به سایت
- ایمیل برای SSL

## اجرای یک‌خطی

```bash
sudo bash install.sh --domain iropen.rova.cam --bot iropen_bot --support IROPN_Supports --secret IROPEN_SECRET_2026 --email you@example.com
```

## بعد از نصب

در BotFather لینک Mini App را روی دامنه HTTPS بگذارید:

```text
https://YOUR_DOMAIN
```

## API ثبت خرید از سمت ربات

```bash
curl -X POST https://YOUR_DOMAIN/api/bot/purchase \
  -H "Content-Type: application/json" \
  -H "x-api-secret: IROPEN_SECRET_2026" \
  -d '{"telegram_id":"123456789","username":"test","full_name":"Test User","plan_name":"پلن ۱ گیگ یک ماهه","volume_gb":1,"price_toman":160000,"started_at":"2026-05-13","expires_at":"2026-06-13","status":"active"}'
```

## چک کردن سرویس‌ها

```bash
sudo systemctl status nginx
sudo systemctl status iropen-api
```
