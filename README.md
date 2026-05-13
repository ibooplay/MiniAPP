# MINI APP SHOP VPN

Automatic Telegram Mini App VPN shop installer for Ubuntu servers.

---

## Description

**MINI APP SHOP VPN** is an easy-to-use automated installer for launching a VPN shop website connected to a Telegram bot.

This project installs and configures a complete VPN shop Mini App with Nginx, SSL, API service, multi-page website, Telegram bot links, support link, and user purchase profile system.

It is designed for **Ubuntu 22.04 VPS servers**, especially Hetzner VPS, but it can also work on other Ubuntu-based servers.

---

## Important

This project is only for personal and legal usage.

Do not use this project for illegal purposes or in a production environment without proper testing and security review.

---

## Features

- Simple one-command installation
- Supports Ubuntu 22.04 VPS
- Suitable for Hetzner VPS
- Telegram Mini App ready
- Modern VPN shop landing page
- Black, white, and blue theme
- Mobile and desktop responsive design
- Multi-page website structure
- Telegram bot link integration
- Telegram support link integration
- User profile page
- Purchase sync API
- Nginx automatic configuration
- Free SSL with Let's Encrypt
- UFW firewall setup
- Systemd service for API
- Auto-start after server reboot

---

## Website Pages

After installation, the following pages will be available:

## Installation

To install MINI APP SHOP VPN on your server, first clone the repository:

```bash
cd /root
sudo apt update
sudo apt install -y git
git clone https://github.com/USERNAME/MiniAPP.git
cd MiniAPP
sudo bash install.sh

```
After installation, your website will be available at:
```bash
https://YOUR_DOMAIN
```
Update Installation

If you already installed the project and want to update it from GitHub, run:
```bash
cd /root
rm -rf MiniAPP
git clone https://github.com/USERNAME/MiniAPP.git
cd MiniAPP
sudo bash install.sh
```

```text
Home:
https://YOUR_DOMAIN/

Plans:
https://YOUR_DOMAIN/plans.html

Features:
https://YOUR_DOMAIN/features.html

My Profile:
https://YOUR_DOMAIN/profile.html
