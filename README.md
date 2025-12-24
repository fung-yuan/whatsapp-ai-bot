# 🤖 WhatsApp AI Bot

AI-powered WhatsApp customer support bot using **n8n**, **WAHA**, and **AI** (Gemini/OpenAI/etc).

**Features:** Text & voice messages • Conversation memory • 100% free & self-hosted

---

## 📦 What's Inside

- `workflow.json` - n8n workflow to import
- `manage-waha.sh` - Multi-client manager script

---

## 🚀 Setup

### Prerequisites

- VPS with Docker
- AI API key (your choice: [Gemini](https://makersuite.google.com/app/apikey), [OpenAI](https://platform.openai.com/api-keys), etc.)

### Installation

```bash
# Clone repo
git clone https://github.com/fung-yuan/whatsapp-ai-bot.git
cd whatsapp-ai-bot

# Make script globally available
sudo ln -s $(pwd)/manage-waha.sh /usr/local/bin/manage-waha

# Install n8n
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n

# Create WAHA instance
manage-waha
# Choose option 1: Add New Client
# Enter client name, select port 3000, generate API key

# Import workflow
# 1. Open http://YOUR_IP:5678
# 2. Import workflow.json
# 3. Add AI credentials (Gemini/OpenAI/whatever you prefer)
# 4. Create n8n Table: "chat_history" with columns: phone, role, content
# 5. Update "Download Audio" node URL with your server IP

# Connect WhatsApp
# Open dashboard URL shown by script and scan QR code
```

**Done!** Test by sending a message.

---

## 🔧 Multi-Client Management

The `manage-waha` command lets you run **multiple WhatsApp bots** (one per client) on the same server.

### Usage

```bash
manage-waha  # Run from anywhere!
```

**Menu:**
1. **Add New Client** - Creates new WAHA instance, shows credentials
2. **List All Clients** - View all clients with ports/credentials/status
3. **Stop Client** - Pause a client
4. **Remove Client** - Delete client completely

Each client gets:
- Dedicated WAHA container
- Unique port (3000, 3001, 3002...)
- Own WhatsApp number
- Isolated data

**Example:**
```
$ manage-waha

Enter client name: Pizza Shop
Select port: 3001
Generate API key automatically? Y

✅ Client Created!
Dashboard: http://YOUR_IP:3001/dashboard
Username: admin
Password: (auto-generated)
API Key: waha_abc123...
```

---

## 🎯 Workflow Logic

1. **Receive message** → Webhook catches WhatsApp message
2. **Check if audio** → If yes: download → transcribe with AI
3. **Save to history** → Store in n8n Table
4. **Get conversation** → Load past messages
5. **AI response** → AI generates reply
6. **Save bot reply** → Store in history
7. **Send to WhatsApp** → Deliver via WAHA

---

## 🛠️ Customization

### Change AI Personality

Edit "Basic LLM Chain" node in n8n workflow:

```
You are a friendly assistant for [YOUR BUSINESS]

Services:
- [List your services]

Rules:
- Speak [LANGUAGE]
- Keep replies SHORT
```

### Update Server IP

In workflow, find "Download Audio" node:
```
URL: http://YOUR_IP:3000{{ $json.mediaPath }}
```

Change `YOUR_IP` to your actual server IP.

---

## 🔍 Troubleshooting

**Bot doesn't reply:**
- Check workflow is active (toggle in n8n)
- Verify WAHA session: Run `manage-waha` → Option 2
- Check webhook URL matches n8n

**Voice not working:**
- Verify AI API quota
- Check audio download URL has correct port

**Script command not found:**
- Re-run: `sudo ln -s $(pwd)/manage-waha.sh /usr/local/bin/manage-waha`

---

## 📄 License

MIT

---

**Questions?** Open an issue or watch the tutorial video!
