# 🤖 WhatsApp AI Bot

AI-powered WhatsApp customer support bot using **n8n**, **WAHA**, and **Google Gemini**.

**Features:** Text & voice messages • Conversation memory • 100% free & self-hosted

---

## 📦 What's Inside

- `workflow.json` - n8n workflow to import
- `docker-compose.yml` - Single WAHA instance
- `manage-waha.sh` - Multi-client manager script
- `.env.example` - Configuration template

---

## 🚀 Setup

### Prerequisites

- VPS with Docker
- Google Gemini API key - [Get free](https://makersuite.google.com/app/apikey)

### Installation

```bash
# Clone repo
git clone https://github.com/fung-yuan/whatsapp-ai-bot.git
cd whatsapp-ai-bot

# Configure
cp .env.example .env
nano .env  # Add your keys

# Start WAHA
docker-compose up -d

# Install n8n
docker run -d --name n8n -p 5678:5678 -v n8n_data:/home/node/.n8n n8nio/n8n

# Import workflow
# 1. Open http://YOUR_IP:5678
# 2. Import workflow.json
# 3. Add credentials (Gemini API + WAHA)
# 4. Create n8n Table: "chat_history" with columns: phone, role, content

# Connect WhatsApp
# 1. Open http://YOUR_IP:3000/dashboard
# 2. Get credentials: docker logs waha | grep DASHBOARD
# 3. Scan QR code
```

**Done!** Test by sending a message.

---

## 🔧 Multi-Client Management Script

### What It Does

The `manage-waha.sh` script lets you run **multiple WhatsApp bots** (one per client) on the same server. Each client gets:
- Dedicated WAHA container
- Unique port (3000, 3001, 3002...)
- Own WhatsApp number
- Isolated data

### Why You Need It

**Without script:** Manual docker-compose editing, port conflicts, credential tracking  
**With script:** Interactive menu, auto port detection, credential management

### How to Use

```bash
./manage-waha.sh
```

**Menu:**
1. **Add New Client** - Creates new WAHA instance, shows credentials
2. **List All Clients** - View all clients with ports/credentials/status
3. **Stop Client** - Pause a client
4. **Remove Client** - Delete client completely

**Example - Adding Client:**
```
Enter client name: Pizza Shop
Select port [3000-3010]: 3001
Generate API key automatically? [Y/n]: Y

✅ Client Created!
Dashboard: http://YOUR_IP:3001/dashboard
Username: admin
Password: (auto-generated)
API Key: waha_abc123...
```

Then update n8n workflow to use port 3001 for this client.

---

## 📝 Configuration

Edit `.env`:

```bash
WAHA_API_KEY=your-secure-key
SERVER_IP=your.server.ip
GOOGLE_GEMINI_API_KEY=your-gemini-key
```

---

## 🎯 Workflow Logic

1. **Receive message** → Webhook catches WhatsApp message
2. **Check if audio** → If yes: download → transcribe with Gemini
3. **Save to history** → Store in n8n Table
4. **Get conversation** → Load past messages
5. **AI response** → Gemini generates reply
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
- Verify WAHA session: `curl http://localhost:3000/api/sessions/default -H 'X-Api-Key: your-key'`
- Check webhook URL in WAHA matches n8n

**Voice not working:**
- Verify Gemini API has enough quota
- Check audio download URL has correct port

**Multi-client issues:**
- Run `./manage-waha.sh` → Option 2 to see all clients
- Each client needs unique port
- Update n8n workflow port for each client

---

## 📄 License

MIT

---

**Questions?** Open an issue or watch the tutorial video!
