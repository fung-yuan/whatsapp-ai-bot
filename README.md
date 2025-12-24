# 🤖 WhatsApp AI Bot

Build your own AI-powered WhatsApp customer support bot using **n8n**, **WAHA**, and **Google Gemini**.

## ✨ What This Does

- 💬 Responds to WhatsApp messages automatically using AI
- 🎤 Handles both text and voice messages
- 🧠 Remembers conversation history
- 🆓 100% free and self-hosted

## 🎥 Video Tutorial

**Full setup guide:** [Watch on YouTube](YOUR_VIDEO_LINK)

## 📦 What's Included

```
📁 whatsapp-ai-bot/
├── workflow.json          # n8n workflow (import this)
├── docker-compose.yml     # WAHA setup
├── manage-waha.sh         # Multi-client manager
├── .env.example           # Configuration template
└── docs/                  # Detailed documentation
```

## ⚡ Quick Setup

### Prerequisites
- VPS/Server with Docker installed
- Google Gemini API key ([Get it free](https://makersuite.google.com/app/apikey))

### Install

```bash
# 1. Clone repository
git clone https://github.com/fung-yuan/whatsapp-ai-bot.git
cd whatsapp-ai-bot

# 2. Configure
cp .env.example .env
nano .env  # Add your API keys

# 3. Start WAHA
docker-compose up -d

# 4. Install n8n
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n

# 5. Import workflow
# Open http://YOUR_IP:5678 and import workflow.json

# 6. Scan QR
# Open http://YOUR_IP:3000/dashboard and scan WhatsApp QR code
```

**Done! 🎉** Send a message to test your bot.

## 🔧 For Multiple Clients

Use the management script:

```bash
./manage-waha.sh
```

Easily add/remove clients with different WhatsApp numbers on different ports.

## 📚 Documentation

- [Detailed Setup Guide](docs/QUICKSTART.md)
- [Script Usage](docs/SCRIPT-USAGE.md)

## 🛠️ Tech Stack

- **WAHA** - WhatsApp HTTP API
- **n8n** - Workflow automation
- **Google Gemini** - AI responses
- **Docker** - Containerization

## 📄 License

MIT - Do whatever you want!

## ⭐ Support

If this helped you:
- 🌟 Star this repo
- 📢 Share with others
- 💬 Drop a comment on the [YouTube video](YOUR_VIDEO_LINK)

---

**Built for the automation community** ❤️
