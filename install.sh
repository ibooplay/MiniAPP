#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# MINI APP SHOP VPN Auto Installer
# Ubuntu 22.04 / Hetzner VPS
#
# Run:
#   sudo bash install.sh
#
# Or non-interactive:
#   sudo bash install.sh --domain example.com --bot iropen_bot --support IROPN_Supports --secret YOUR_SECRET --email you@example.com
# ==========================================================

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

DOMAIN=""
BOT_USERNAME=""
SUPPORT_USERNAME=""
API_SECRET=""
LE_EMAIL=""
ENABLE_SSL="yes"
SITE_DIR="/var/www/iropen"
API_DIR="/opt/iropen-api"
API_PORT="3000"
SERVICE_NAME="iropen-api"

log(){ echo -e "${GREEN}[IROPEN]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){ echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  cat <<EOF
MINI APP SHOP VPN Auto Installer

Options:
  --domain DOMAIN           Domain, example: iropen.rova.cam
  --bot USERNAME            Telegram bot username without @, example: iropen_bot
  --support USERNAME        Support username/channel without @, example: IROPN_Supports
  --secret SECRET           API secret for bot-to-site purchase sync
  --email EMAIL             Email for Let's Encrypt SSL
  --no-ssl                  Skip SSL
  -h, --help                Show help

Example:
  sudo bash install.sh --domain iropen.rova.cam --bot iropen_bot --support IROPN_Supports --secret IROPEN_SECRET --email you@example.com
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="${2:-}"; shift 2;;
    --bot) BOT_USERNAME="${2:-}"; shift 2;;
    --support) SUPPORT_USERNAME="${2:-}"; shift 2;;
    --secret) API_SECRET="${2:-}"; shift 2;;
    --email) LE_EMAIL="${2:-}"; shift 2;;
    --no-ssl) ENABLE_SSL="no"; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown option: $1"; usage; exit 1;;
  esac
done

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Run as root: sudo bash install.sh"
    exit 1
  fi
}

ask_questions() {
  echo
  echo -e "${BLUE}========= MINI APP SHOP VPN Installer =========${NC}"
  echo

  if [[ -z "$DOMAIN" ]]; then
    read -rp "دامنه سایت را وارد کن، مثال iropen.rova.cam: " DOMAIN
  fi

  if [[ -z "$BOT_USERNAME" ]]; then
    read -rp "آیدی ربات بدون @، مثال iropen_bot: " BOT_USERNAME
  fi

  if [[ -z "$SUPPORT_USERNAME" ]]; then
    read -rp "آیدی پشتیبانی/چنل بدون @، مثال IROPN_Supports: " SUPPORT_USERNAME
  fi

  if [[ -z "$API_SECRET" ]]; then
    read -rsp "رمز API برای اتصال ربات به سایت، مثال IROPEN_SECRET_2026: " API_SECRET
    echo
  fi

  if [[ "$ENABLE_SSL" == "yes" && -z "$LE_EMAIL" ]]; then
    read -rp "ایمیل برای SSL رایگان Let’s Encrypt، اگر نداری خالی بزن: " LE_EMAIL
  fi

  if [[ -z "$DOMAIN" || -z "$BOT_USERNAME" || -z "$SUPPORT_USERNAME" || -z "$API_SECRET" ]]; then
    err "دامنه، آیدی ربات، آیدی پشتیبانی و رمز API اجباری هستند."
    exit 1
  fi

  BOT_USERNAME="${BOT_USERNAME#@}"
  SUPPORT_USERNAME="${SUPPORT_USERNAME#@}"
}

install_packages() {
  log "Installing required packages..."
  export DEBIAN_FRONTEND=noninteractive
  apt update
  apt install -y nginx ufw curl wget unzip nano ca-certificates gnupg lsb-release certbot python3-certbot-nginx nodejs npm
}

create_site() {
  log "Creating website files..."
  mkdir -p "$SITE_DIR/assets"

  cat > "$SITE_DIR/index.html" <<EOF
<!doctype html>
<html lang="fa" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#030712">
  <title>IROPEN VPN | خرید سریع و امن</title>
  <link rel="stylesheet" href="/assets/style.css?v=10">
</head>
<body>
  <header class="topbar">
    <a class="logo" href="/"><span>IRO</span><b>PEN</b></a>
    <nav>
      <a class="active" href="/">خانه</a>
      <a href="/features.html">ویژگی‌ها</a>
      <a href="/plans.html">پلن‌ها</a>
      <a href="/profile.html">مشخصات من</a>
      <a href="https://t.me/${SUPPORT_USERNAME}" target="_blank" rel="noopener">پشتیبانی</a>
    </nav>
    <a class="glass-btn tiny" href="https://t.me/${BOT_USERNAME}" target="_blank" rel="noopener">ورود به ربات</a>
  </header>

  <main>
    <section class="hero">
      <div class="hero-text">
        <div class="pill">⚡ اتصال بدون محدودیت</div>
        <h1>خرید سریع و امن<br><span>VPN با IROPEN</span></h1>
        <p>با IROPEN تجربه‌ای متفاوت از اینترنت آزاد و امن داشته باشید. خرید اشتراک فقط با چند کلیک از طریق ربات تلگرام انجام می‌شود.</p>
        <div class="actions">
          <a class="glass-btn" href="https://t.me/${BOT_USERNAME}" target="_blank" rel="noopener">ورود به ربات</a>
          <a class="blue-btn" href="/plans.html">خرید اشتراک</a>
        </div>
      </div>

      <div class="shield-card">
        <div class="shield">🔒<span>IROPEN</span></div>
      </div>

      <aside class="feature-panel">
        <h3>چرا <span>IROPEN</span>؟</h3>
        <div>🚀 <b>سرعت بالا</b><small>سرورهای قدرتمند و پرسرعت</small></div>
        <div>📶 <b>اتصال پایدار</b><small>اتصال مطمئن و بدون قطعی</small></div>
        <div>⚡ <b>تحویل خودکار</b><small>فعال‌سازی آنی پس از پرداخت</small></div>
        <div>🎧 <b>پشتیبانی سریع</b><small>پشتیبانی از طریق تلگرام</small></div>
      </aside>
    </section>

    <section class="section light">
      <p class="eyebrow">پلن‌های یک ماهه</p>
      <h2>انتخاب حجم مناسب برای شما</h2>
      <div class="plans">
        <article class="plan"><h3>پلن ۱ گیگ</h3><p>مدت اعتبار: یک ماه</p><strong>۱۶۰,۰۰۰ <small>تومان</small></strong><ul><li>حجم ۱ گیگابایت</li><li>اتصال پایدار و سریع</li><li>تحویل از طریق ربات</li></ul><a href="https://t.me/${BOT_USERNAME}" target="_blank" rel="noopener">خرید از ربات</a></article>
        <article class="plan featured"><em>پیشنهاد ویژه</em><h3>پلن ۲ گیگ</h3><p>مدت اعتبار: یک ماه</p><strong>۳۲۰,۰۰۰ <small>تومان</small></strong><ul><li>حجم ۲ گیگابایت</li><li>اتصال پایدار و سریع</li><li>تحویل از طریق ربات</li></ul><a href="https://t.me/${BOT_USERNAME}" target="_blank" rel="noopener">خرید از ربات</a></article>
        <article class="plan"><h3>پلن ۳ گیگ</h3><p>مدت اعتبار: یک ماه</p><strong>۴۸۰,۰۰۰ <small>تومان</small></strong><ul><li>حجم ۳ گیگابایت</li><li>اتصال پایدار و سریع</li><li>تحویل از طریق ربات</li></ul><a href="https://t.me/${BOT_USERNAME}" target="_blank" rel="noopener">خرید از ربات</a></article>
      </div>
    </section>
  </main>

  <footer>
    <span>IROPEN VPN</span>
    <a href="https://t.me/${SUPPORT_USERNAME}" target="_blank" rel="noopener">پشتیبانی</a>
  </footer>
</body>
</html>
EOF

  cat > "$SITE_DIR/plans.html" <<EOF
<!doctype html>
<html lang="fa" dir="rtl">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><title>پلن‌های IROPEN</title><link rel="stylesheet" href="/assets/style.css?v=10"></head>
<body>
<header class="topbar"><a class="logo" href="/"><span>IRO</span><b>PEN</b></a><nav><a href="/">خانه</a><a href="/features.html">ویژگی‌ها</a><a class="active" href="/plans.html">پلن‌ها</a><a href="/profile.html">مشخصات من</a><a href="https://t.me/${SUPPORT_USERNAME}" target="_blank">پشتیبانی</a></nav><a class="glass-btn tiny" href="https://t.me/${BOT_USERNAME}" target="_blank">ورود به ربات</a></header>
<section class="page-head"><p class="eyebrow">پلن‌ها</p><h1>پلن‌های یک ماهه IROPEN</h1><p>هر پلن را انتخاب کن و خرید را از طریق ربات انجام بده.</p></section>
<section class="section"><div class="plans single">
<article class="plan"><h3>پلن ۱ گیگ</h3><p>مدت اعتبار: یک ماه</p><strong>۱۶۰,۰۰۰ <small>تومان</small></strong><ul><li>۱ گیگابایت حجم</li><li>اتصال پایدار</li><li>تحویل خودکار</li></ul><a href="https://t.me/${BOT_USERNAME}" target="_blank">خرید</a></article>
<article class="plan featured"><em>پیشنهاد ویژه</em><h3>پلن ۲ گیگ</h3><p>مدت اعتبار: یک ماه</p><strong>۳۲۰,۰۰۰ <small>تومان</small></strong><ul><li>۲ گیگابایت حجم</li><li>اتصال پایدار</li><li>تحویل خودکار</li></ul><a href="https://t.me/${BOT_USERNAME}" target="_blank">خرید</a></article>
<article class="plan"><h3>پلن ۳ گیگ</h3><p>مدت اعتبار: یک ماه</p><strong>۴۸۰,۰۰۰ <small>تومان</small></strong><ul><li>۳ گیگابایت حجم</li><li>اتصال پایدار</li><li>تحویل خودکار</li></ul><a href="https://t.me/${BOT_USERNAME}" target="_blank">خرید</a></article>
</div></section>
<footer><span>IROPEN VPN</span><a href="https://t.me/${SUPPORT_USERNAME}" target="_blank">پشتیبانی</a></footer>
</body></html>
EOF

  cat > "$SITE_DIR/features.html" <<EOF
<!doctype html>
<html lang="fa" dir="rtl">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><title>ویژگی‌های IROPEN</title><link rel="stylesheet" href="/assets/style.css?v=10"></head>
<body>
<header class="topbar"><a class="logo" href="/"><span>IRO</span><b>PEN</b></a><nav><a href="/">خانه</a><a class="active" href="/features.html">ویژگی‌ها</a><a href="/plans.html">پلن‌ها</a><a href="/profile.html">مشخصات من</a><a href="https://t.me/${SUPPORT_USERNAME}" target="_blank">پشتیبانی</a></nav><a class="glass-btn tiny" href="https://t.me/${BOT_USERNAME}" target="_blank">ورود به ربات</a></header>
<section class="page-head"><p class="eyebrow">ویژگی‌ها</p><h1>چرا IROPEN؟</h1><p>تمرکز روی سرعت، پایداری، تحویل سریع و پشتیبانی.</p></section>
<section class="section"><div class="feature-grid">
<div class="feature-box">🚀<h3>سرعت بالا</h3><p>اتصال پرسرعت و مناسب استفاده روزمره.</p></div>
<div class="feature-box">📶<h3>اتصال پایدار</h3><p>تجربه اتصال مطمئن و کم‌قطعی.</p></div>
<div class="feature-box">⚡<h3>تحویل خودکار</h3><p>پس از خرید، اطلاعات اشتراک از طریق ربات ثبت می‌شود.</p></div>
<div class="feature-box">🎧<h3>پشتیبانی سریع</h3><p>ارتباط با پشتیبانی از طریق تلگرام.</p></div>
</div></section>
<footer><span>IROPEN VPN</span><a href="https://t.me/${SUPPORT_USERNAME}" target="_blank">پشتیبانی</a></footer>
</body></html>
EOF

  cat > "$SITE_DIR/profile.html" <<EOF
<!doctype html>
<html lang="fa" dir="rtl">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"><title>مشخصات من | IROPEN</title><link rel="stylesheet" href="/assets/style.css?v=10"></head>
<body>
<header class="topbar"><a class="logo" href="/"><span>IRO</span><b>PEN</b></a><nav><a href="/">خانه</a><a href="/features.html">ویژگی‌ها</a><a href="/plans.html">پلن‌ها</a><a class="active" href="/profile.html">مشخصات من</a><a href="https://t.me/${SUPPORT_USERNAME}" target="_blank">پشتیبانی</a></nav><a class="glass-btn tiny" href="https://t.me/${BOT_USERNAME}" target="_blank">ورود به ربات</a></header>
<section class="page-head"><p class="eyebrow">مشخصات من</p><h1>اشتراک‌های خریداری‌شده</h1><p>این صفحه وقتی از داخل Mini App تلگرام باز شود، مشخصات کاربر را دریافت می‌کند.</p></section>
<section class="section"><div class="profile-card" id="profileBox"><h3>در حال بررسی اطلاعات...</h3><p>اگر اطلاعاتی نمایش داده نشد، از داخل ربات وارد وب‌اپ شوید.</p></div></section>
<footer><span>IROPEN VPN</span><a href="https://t.me/${SUPPORT_USERNAME}" target="_blank">پشتیبانی</a></footer>
<script src="https://telegram.org/js/telegram-web-app.js"></script>
<script src="/assets/script.js?v=10"></script>
</body></html>
EOF

  cat > "$SITE_DIR/assets/style.css" <<'EOF'
@font-face{font-family:VazirLocal;src:local("Tahoma")}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;font-family:VazirLocal,Tahoma,Arial,sans-serif;background:#030712;color:#fff;overflow-x:hidden}a{text-decoration:none;color:inherit}.topbar{position:sticky;top:0;z-index:50;margin:14px auto 0;width:min(1160px,calc(100% - 28px));min-height:68px;padding:10px 14px;border:1px solid rgba(255,255,255,.15);border-radius:22px;background:rgba(3,7,18,.78);backdrop-filter:blur(18px);display:flex;align-items:center;justify-content:space-between;gap:14px;box-shadow:0 18px 50px rgba(0,0,0,.32)}.logo{font-size:27px;font-weight:900;letter-spacing:.5px}.logo span{color:#fff}.logo b{color:#28a8ff}nav{display:flex;gap:8px;align-items:center;flex-wrap:wrap;justify-content:center}nav a{padding:10px 12px;border-radius:14px;color:#dbeafe;font-size:14px;transition:.25s}.active,nav a:hover{background:rgba(37,99,235,.22);color:#fff}.glass-btn,.blue-btn,.plan a{display:inline-flex;align-items:center;justify-content:center;border:1px solid rgba(255,255,255,.75);border-radius:18px;padding:14px 24px;background:rgba(255,255,255,.88);color:#07111f;font-weight:900;box-shadow:inset 0 1px 0 rgba(255,255,255,.9),0 14px 38px rgba(0,0,0,.18);transition:.25s}.glass-btn:hover,.glass-btn:active,.blue-btn,.plan a:hover{background:#0a84ff;color:#fff;border-color:#79bdff;box-shadow:0 0 0 4px rgba(10,132,255,.18),0 18px 45px rgba(10,132,255,.35);transform:translateY(-2px)}.tiny{padding:10px 15px;border-radius:15px;white-space:nowrap}.hero{position:relative;isolation:isolate;min-height:680px;width:min(1180px,100%);margin:0 auto;padding:92px 22px 76px;display:grid;grid-template-columns:1.15fr .75fr .9fr;gap:24px;align-items:center}.hero:before{content:"";position:absolute;inset:-160px -30px 0;background:radial-gradient(circle at 64% 35%,rgba(0,132,255,.45),transparent 26%),radial-gradient(circle at 35% 0,rgba(255,255,255,.12),transparent 24%),linear-gradient(180deg,#030712 0%,#061a37 68%,#030712 100%);z-index:-2}.hero:after{content:"";position:absolute;inset:55% -20px -30px;background:radial-gradient(ellipse at center,rgba(28,148,255,.2),transparent 60%);z-index:-1}.pill,.eyebrow{display:inline-block;color:#62c7ff;background:rgba(14,165,233,.13);border:1px solid rgba(96,199,255,.25);padding:9px 16px;border-radius:999px;font-weight:800}.hero h1,.page-head h1{font-size:clamp(34px,5vw,66px);line-height:1.25;margin:18px 0 16px}.hero h1 span{color:#29aaff;text-shadow:0 0 32px rgba(41,170,255,.42)}.hero p,.page-head p{color:#cbd5e1;font-size:18px;line-height:2;max-width:620px}.actions{display:flex;gap:12px;flex-wrap:wrap;margin-top:26px}.shield-card{min-height:290px;display:grid;place-items:center}.shield{width:230px;height:270px;border-radius:45% 45% 34% 34%;background:linear-gradient(145deg,rgba(255,255,255,.18),rgba(0,132,255,.32));border:1px solid rgba(147,197,253,.45);display:grid;place-items:center;font-size:68px;box-shadow:0 0 80px rgba(0,132,255,.35),inset 0 0 40px rgba(255,255,255,.08)}.shield span{display:block;font-size:26px;color:#fff;font-weight:900}.feature-panel,.plan,.feature-box,.profile-card{border:1px solid rgba(255,255,255,.16);border-radius:28px;background:rgba(255,255,255,.08);backdrop-filter:blur(18px);box-shadow:0 25px 70px rgba(0,0,0,.25)}.feature-panel{padding:22px}.feature-panel h3{font-size:26px;margin:0 0 18px}.feature-panel h3 span{color:#29aaff}.feature-panel div{display:grid;gap:4px;padding:14px;margin:10px 0;border-radius:18px;background:rgba(255,255,255,.08)}small{opacity:.76}.section{padding:72px 22px;width:min(1160px,100%);margin:0 auto}.light{width:100%;max-width:none;background:linear-gradient(180deg,#f8fbff,#eef6ff);color:#06111f;text-align:center}.light>.eyebrow,.light>h2,.light>.plans{max-width:1160px;margin-left:auto;margin-right:auto}.section h2{font-size:clamp(28px,4vw,46px);margin:14px 0 34px}.plans{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;text-align:right}.plans.single{max-width:1160px;margin:auto}.plan{padding:28px;color:#06111f;background:#fff;position:relative;overflow:hidden}.plan.featured{background:linear-gradient(180deg,#071d3f,#0a4a95);color:#fff;transform:translateY(-10px);box-shadow:0 26px 70px rgba(10,132,255,.3)}.plan em{position:absolute;top:16px;left:16px;background:#38bdf8;color:#031226;padding:7px 12px;border-radius:999px;font-style:normal;font-weight:900}.plan h3{font-size:26px;margin:12px 0}.plan strong{display:block;font-size:34px;color:#0a84ff;margin:16px 0}.featured strong{color:#7dd3fc}.plan ul{padding:0;margin:18px 0;list-style:none}.plan li{margin:10px 0}.plan li:before{content:"✓";color:#0a84ff;font-weight:900;margin-left:8px}.plan a{width:100%;margin-top:10px}.page-head{padding:72px 22px 36px;width:min(1160px,100%);margin:auto;text-align:center}.page-head p{margin:auto}.feature-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:18px}.feature-box{padding:28px;text-align:center;background:rgba(255,255,255,.09)}.feature-box h3{color:#60c7ff}.profile-card{max-width:760px;margin:auto;padding:28px;min-height:210px}.profile-item{background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);border-radius:18px;padding:16px;margin:12px 0}footer{border-top:1px solid rgba(255,255,255,.1);padding:26px 22px;display:flex;justify-content:center;gap:20px;color:#cbd5e1;background:#020617}
@media (max-width:900px){.topbar{align-items:flex-start}.logo{font-size:22px}nav{order:3;width:100%;justify-content:flex-start;overflow-x:auto;flex-wrap:nowrap;padding-bottom:2px}nav a{white-space:nowrap;font-size:13px}.tiny{font-size:13px;padding:9px 12px}.hero{grid-template-columns:1fr;min-height:auto;padding-top:48px;text-align:right}.hero p{font-size:16px}.shield-card{min-height:210px}.shield{width:180px;height:210px}.feature-panel{margin-top:4px}.plans{grid-template-columns:1fr;max-width:520px}.plan.featured{transform:none}.feature-grid{grid-template-columns:1fr 1fr}.actions a{flex:1;min-width:150px}.page-head{padding-top:45px}}
@media (max-width:520px){body{background:#030712}.topbar{width:calc(100% - 18px);margin-top:8px;border-radius:18px;padding:10px}.logo{font-size:20px}.hero{padding:36px 14px 44px}.hero h1{font-size:34px}.hero p{font-size:15px;line-height:1.9}.feature-panel{padding:14px;border-radius:22px}.feature-panel div{padding:12px}.section{padding:48px 14px}.plans{gap:14px}.plan{padding:22px;border-radius:22px}.plan strong{font-size:29px}.feature-grid{grid-template-columns:1fr}.glass-btn,.blue-btn{width:100%;padding:13px 16px}.shield-card{display:none}footer{flex-direction:column;text-align:center;gap:10px}}
EOF

  cat > "$SITE_DIR/assets/script.js" <<'EOF'
(function(){
  const box = document.getElementById("profileBox");
  if(!box) return;

  const tg = window.Telegram && window.Telegram.WebApp ? window.Telegram.WebApp : null;
  if(tg) {
    tg.ready();
    tg.expand();
  }

  const user = tg && tg.initDataUnsafe && tg.initDataUnsafe.user ? tg.initDataUnsafe.user : null;
  const params = new URLSearchParams(location.search);
  const testId = params.get("telegram_id");
  const telegramId = user ? user.id : testId;

  if(!telegramId) {
    box.innerHTML = "<h3>اطلاعات کاربر پیدا نشد</h3><p>برای دیدن مشخصات، سایت را از داخل Mini App ربات تلگرام باز کنید.</p>";
    return;
  }

  fetch("/api/user/" + encodeURIComponent(telegramId))
    .then(r => r.json())
    .then(data => {
      const name = user ? ((user.first_name || "") + " " + (user.last_name || "")).trim() : (data.user && data.user.full_name ? data.user.full_name : "کاربر");
      if(!data.purchases || data.purchases.length === 0) {
        box.innerHTML = `<h3>${name}</h3><p>هنوز اشتراکی برای شما ثبت نشده است.</p>`;
        return;
      }
      const items = data.purchases.map(p => `
        <div class="profile-item">
          <b>${p.plan_name || "اشتراک IROPEN"}</b>
          <p>حجم: ${p.volume_gb || "-"} گیگ</p>
          <p>قیمت: ${Number(p.price_toman || 0).toLocaleString("fa-IR")} تومان</p>
          <p>شروع: ${p.started_at || "-"}</p>
          <p>پایان: ${p.expires_at || "-"}</p>
          <p>وضعیت: ${p.status || "active"}</p>
        </div>`).join("");
      box.innerHTML = `<h3>${name}</h3>${items}`;
    })
    .catch(() => {
      box.innerHTML = "<h3>خطا در دریافت اطلاعات</h3><p>API سایت را بررسی کنید.</p>";
    });
})();
EOF

  chown -R www-data:www-data "$SITE_DIR"
  chmod -R 755 "$SITE_DIR"
}

create_api() {
  log "Creating API service..."
  mkdir -p "$API_DIR"
  cat > "$API_DIR/package.json" <<EOF
{"name":"iropen-api","version":"1.0.0","main":"server.js","scripts":{"start":"node server.js"},"dependencies":{"express":"^4.18.3","cors":"^2.8.5"}}
EOF

  cat > "$API_DIR/server.js" <<'EOF'
const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = Number(process.env.PORT || 3000);
const API_SECRET = process.env.API_SECRET || "";
const DATA_FILE = path.join(__dirname, "purchases.json");

app.use(cors());
app.use(express.json({ limit: "1mb" }));

function readData() {
  try { return JSON.parse(fs.readFileSync(DATA_FILE, "utf8")); }
  catch { return { purchases: [] }; }
}
function writeData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

app.get("/api/health", (req, res) => {
  res.json({ ok: true, service: "iropen-api" });
});

app.post("/api/bot/purchase", (req, res) => {
  const secret = req.headers["x-api-secret"];
  if (!API_SECRET || secret !== API_SECRET) {
    return res.status(401).json({ ok: false, error: "unauthorized" });
  }

  const b = req.body || {};
  if (!b.telegram_id) {
    return res.status(400).json({ ok: false, error: "telegram_id is required" });
  }

  const item = {
    id: Date.now().toString(),
    telegram_id: String(b.telegram_id),
    username: b.username || "",
    full_name: b.full_name || "",
    plan_name: b.plan_name || "اشتراک IROPEN",
    volume_gb: Number(b.volume_gb || 0),
    price_toman: Number(b.price_toman || 0),
    started_at: b.started_at || "",
    expires_at: b.expires_at || "",
    status: b.status || "active",
    created_at: new Date().toISOString()
  };

  const data = readData();
  data.purchases.push(item);
  writeData(data);
  res.json({ ok: true, purchase: item });
});

app.get("/api/user/:telegram_id", (req, res) => {
  const tid = String(req.params.telegram_id);
  const data = readData();
  const purchases = data.purchases.filter(p => String(p.telegram_id) === tid);
  const latest = purchases[purchases.length - 1] || {};
  res.json({
    ok: true,
    user: {
      telegram_id: tid,
      username: latest.username || "",
      full_name: latest.full_name || ""
    },
    purchases
  });
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`IROPEN API running on 127.0.0.1:${PORT}`);
});
EOF

  cd "$API_DIR"
  npm install --omit=dev

  if [[ ! -f "$API_DIR/purchases.json" ]]; then
    echo '{"purchases":[]}' > "$API_DIR/purchases.json"
  fi

  cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=IROPEN API
After=network.target

[Service]
Type=simple
WorkingDirectory=${API_DIR}
Environment=PORT=${API_PORT}
Environment=API_SECRET=${API_SECRET}
ExecStart=/usr/bin/node ${API_DIR}/server.js
Restart=always
RestartSec=3
User=root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable "$SERVICE_NAME"
  systemctl restart "$SERVICE_NAME"
}

configure_nginx() {
  log "Configuring Nginx..."
  cat > /etc/nginx/sites-available/iropen <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${DOMAIN} www.${DOMAIN};

    root ${SITE_DIR};
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:${API_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

  rm -f /etc/nginx/sites-enabled/default
  ln -sf /etc/nginx/sites-available/iropen /etc/nginx/sites-enabled/iropen
  nginx -t
  systemctl enable nginx
  systemctl restart nginx
}

configure_firewall() {
  log "Configuring firewall..."
  ufw allow OpenSSH || true
  ufw allow 'Nginx Full' || true
  yes | ufw enable || true
}

setup_ssl() {
  if [[ "$ENABLE_SSL" != "yes" ]]; then
    warn "SSL skipped."
    return
  fi

  log "Trying to issue SSL certificate for ${DOMAIN}..."
  if [[ -n "$LE_EMAIL" ]]; then
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m "$LE_EMAIL" --redirect || warn "SSL failed. Check DNS A records."
  else
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect || warn "SSL failed. Check DNS A records."
  fi

  systemctl reload nginx || true
}

final_test() {
  log "Testing services..."
  systemctl --no-pager --full status nginx | head -n 12 || true
  systemctl --no-pager --full status "$SERVICE_NAME" | head -n 12 || true

  echo
  echo -e "${GREEN}==========================================================${NC}"
  echo -e "${GREEN}MINI APP SHOP VPN نصب شد.${NC}"
  echo
  echo "Site:"
  echo "  https://${DOMAIN}"
  echo
  echo "Bot link:"
  echo "  https://t.me/${BOT_USERNAME}"
  echo
  echo "Support:"
  echo "  https://t.me/${SUPPORT_USERNAME}"
  echo
  echo "API test:"
  echo "  curl https://${DOMAIN}/api/health"
  echo
  echo "Bot purchase API:"
  echo "  POST https://${DOMAIN}/api/bot/purchase"
  echo "  Header: x-api-secret: ${API_SECRET}"
  echo
  echo "برای BotFather / Mini App این لینک را بده:"
  echo "  https://${DOMAIN}"
  echo -e "${GREEN}==========================================================${NC}"
}

require_root
ask_questions
install_packages
create_site
create_api
configure_nginx
configure_firewall
setup_ssl
final_test
