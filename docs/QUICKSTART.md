# ⚡ Quick Setup (For Advanced Users)

If you know what you're doing, here's the fastest path:

## 1-Minute Setup

```bash
# Clone repo
git clone https://github.com/YOUR_USERNAME/whatsapp-ai-bot.git
cd whatsapp-ai-bot

# Configure
cp .env.example .env
nano .env  # Add your API keys

# Start WAHA
docker-compose up -d

# Install n8n
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n

# Import workflow
# Open http://YOUR_IP:5678
# Import workflow.json
# Add credentials (Google Gemini + WAHA)
# Update "YOUR_SERVER_IP" in HTTP Request node

# Connect WhatsApp
# Open http://YOUR_IP:3000/dashboard
# Scan QR code

# Done! 🎉
```

## Credentials Needed

1. **Google Gemini API Key** - [Get it here](https://makersuite.google.com/app/apikey)
2. **WAHA API Key** - Create any random string (e.g., `openssl rand -hex 32`)

## Node Names to Update

After importing workflow:
- **"Download Audio"** → Change `YOUR_SERVER_IP` to your actual IP
- **All n8n Table nodes** → Select your `chat_history` table
- **"Google Gemini"** → Add your API key credential
- **"Send WhatsApp Reply"** → Add WAHA credential

## Testing

```bash
# Send test message to bot
# Should reply within 5 seconds

# Check logs
docker logs n8n --tail 50
docker logs waha --tail 50
```

---

**For detailed instructions, see [README.md](README.md)**
