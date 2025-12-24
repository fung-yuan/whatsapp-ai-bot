# 🤖 WhatsApp AI Bot - Complete Setup Guide

Build your own **AI-powered WhatsApp customer support bot** using **n8n**, **WAHA**, and **Google Gemini**. No coding required!

## ✨ Features

- 💬 **Text & Voice Messages** - Handles both text and audio messages
- 🧠 **AI-Powered Responses** - Uses Google Gemini for intelligent conversations
- 📝 **Conversation Memory** - Remembers chat history using n8n Tables
- 🎤 **Audio Transcription** - Converts voice messages to text automatically
- 🚀 **Self-Hosted** - Full control over your data
- 🆓 **Free to Use** - All components are free (within API limits)

---

## 📋 Prerequisites

Before you begin, make sure you have:

- **VPS or Server** (Ubuntu 20.04+ recommended)
  - Minimum: 2GB RAM, 2 CPU cores
  - Recommended: 4GB RAM, 2+ CPU cores
- **Domain name** (optional, but recommended for production)
- **Basic terminal knowledge**

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Install Docker & Docker Compose

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose -y

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Step 2: Install n8n

```bash
# Create n8n directory
mkdir -p ~/n8n
cd ~/n8n

# Start n8n
docker run -d \\
  --name n8n \\
  -p 5678:5678 \\
  -v n8n_data:/home/node/.n8n \\
  n8nio/n8n:latest

# Check if running
docker ps | grep n8n
```

**Access n8n:** `http://YOUR_SERVER_IP:5678`

### Step 3: Install WAHA (WhatsApp API)

```bash
# Clone this repository
git clone https://github.com/YOUR_USERNAME/whatsapp-ai-bot.git
cd whatsapp-ai-bot

# Copy environment file
cp .env.example .env

# Edit .env file (add your API keys)
nano .env

# Start WAHA
docker-compose up -d

# Check if running
docker ps | grep waha
```

**Access WAHA Dashboard:** `http://YOUR_SERVER_IP:3000/dashboard`

---

## 🔧 Configuration

### 1. Get Google Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click **"Get API Key"**
3. Copy the key and save it

### 2. Configure Environment Variables

Edit `.env` file:

```bash
# WAHA Configuration
WAHA_API_KEY=your-secure-api-key-here  # Create a random string

# Server Configuration
SERVER_IP=your.server.ip.address  # Replace with your server's IP

# Google Gemini API Key
GOOGLE_GEMINI_API_KEY=AIzaSy...  # Paste your Gemini API key
```

### 3. Import n8n Workflow

1. Open n8n: `http://YOUR_SERVER_IP:5678`
2. Create an account/login
3. Click **"+"** → **"Import from File"**
4. Select `workflow.json` from this repository
5. Click **"Import"**

### 4. Configure n8n Workflow

#### 4.1 Create n8n Table

1. Go to **Settings** → **Community Nodes**
2. Install: `n8n-nodes-waha` (for WAHA integration)
3. Go to **Data** → **Tables**
4. Click **"Create Table"**
5. Name it: `chat_history`
6. Add columns:
   - `phone` (text)
   - `role` (text)
   - `content` (text)

#### 4.2 Add Credentials

**Google Gemini:**
1. Open the workflow
2. Click on "Google Gemini Chat Model"
3. Click "Select Credential"
4. Click "+ Create New"
5. Paste your Gemini API key
6. Save

**WAHA:**
1. Click on "Send a text message" node
2. Click "Select Credential"
3. Click "+ Create New"
4. Enter:
   - **Base URL:** `http://YOUR_SERVER_IP:3000`
   - **API Key:** (same as in `.env` file)
5. Save

#### 4.3 Update Server IP

1. Find the "HTTP Request" node (downloads audio)
2. Change URL to: `http://YOUR_SERVER_IP:3000{{ $json.mediaPath }}`
3. Save workflow

---

## 📱 Connect WhatsApp

### 1. Start WAHA Session

1. Open WAHA Dashboard: `http://YOUR_SERVER_IP:3000/dashboard`
2. Login with credentials from docker logs:
   ```bash
   docker logs waha | grep -A 5 "Generated credentials"
   ```
3. Click **"+ New Session"**
4. Session name: `default`
5. Click **"Start"**

### 2. Scan QR Code

1. Open **WhatsApp** on your phone
2. Go to **Settings** → **Linked Devices**
3. Click **"Link a Device"**
4. Scan the QR code shown in WAHA dashboard

✅ **Status should show "WORKING"**

---

## 🎨 Customize Your Bot

### Change AI Personality

Edit the "Basic LLM Chain" node in n8n:

```
You are the friendly AI assistant for "YOUR BUSINESS NAME" 🍵

## Services:
- List your products/services here

## Rules:
- Speak YOUR_LANGUAGE
- Keep replies SHORT
- Be helpful and friendly

## Contact:
📞 YOUR_PHONE
📍 YOUR_ADDRESS
```

### Adjust Response Style

- **Short answers:** Add "Keep replies under 50 words"
- **Formal tone:** Add "Use professional language"
- **Multilingual:** Add "Respond in the same language as the customer"

---

## 🧪 Testing

### Test Text Message

1. Send a message to your WhatsApp bot number
2. Check n8n execution log (should succeed)
3. Bot should reply within 5 seconds

### Test Voice Message

1. Send a voice note to your WhatsApp bot
2. Bot should transcribe and respond
3. Check `chat_history` table to see the transcription

---

## 📊 Monitoring

### View Conversation History

1. Go to n8n: **Data** → **Tables** → `chat_history`
2. See all conversations with timestamps

### Check Bot Performance

```bash
# View n8n logs
docker logs n8n --tail 100

# View WAHA logs
docker logs waha --tail 100

# Check if containers are running
docker ps
```

---

## 🔧 Troubleshooting

### Bot doesn't respond

**Check webhook connection:**
```bash
# Test webhook
curl -X POST http://YOUR_SERVER_IP:5678/webhook/whatsapp \\
  -H "Content-Type: application/json" \\
  -d '{"test": true}'
```

**Verify n8n workflow is active:**
1. Open workflow in n8n
2. Check "Active" toggle at top (should be ON)

### "QR code not showing"

**Restart WAHA:**
```bash
docker restart waha
```

Then refresh dashboard page.

### Voice messages not working

**Check Gemini API quota:**
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Check API usage

**Verify audio download:**
- Test URL: `http://YOUR_SERVER_IP:3000/api/files/default/test.oga`

---

## 💡 Advanced Features

### Add Business Hours

1. Add an "If" node after "Code in JavaScript"
2. Check current time
3. If outside hours, send auto-reply

### Handle Images

1. Modify "Code in JavaScript"
2. Add image download logic
3. Use Gemini Vision API to analyze images

### Multi-Language Support

The bot automatically detects and responds in the customer's language (if using Gemini)!

---

## 📚 Resources

- [n8n Documentation](https://docs.n8n.io/)
- [WAHA Documentation](https://waha.devlike.pro/)
- [Google Gemini API](https://ai.google.dev/)

---

## 🆘 Support

- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/whatsapp-ai-bot/issues)
- **Discussions:** [GitHub Discussions](https://github.com/YOUR_USERNAME/whatsapp-ai-bot/discussions)

---

## 📄 License

MIT License - Do whatever you want with this!

---

## ⭐ Show Your Support

If this helped you, please:
- ⭐ Star this repository
- 📢 Share with others
- 💬 Tell me what you built!

---

**Built with ❤️ for the automation community**
