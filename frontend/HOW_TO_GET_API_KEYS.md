# How to Get API Keys for ScholarMate

This guide shows you how to obtain API keys from different AI providers to use with ScholarMate.

---

## 🆓 GROQ (Free - Recommended for Starting)

**Cost**: FREE (with rate limits)  
**Best for**: Testing, personal use, students

### Steps:
1. Go to: https://console.groq.com
2. Click "Sign Up" (or "Sign In" if you have an account)
3. Sign up with Google, GitHub, or email
4. Once logged in, go to "API Keys" in the left sidebar
5. Click "Create API Key"
6. Give it a name (e.g., "ScholarMate")
7. Copy the key (starts with `gsk_`)
8. **Important**: Save it somewhere safe - you won't see it again!

### In ScholarMate:
1. Go to Settings → API Keys
2. Click "Add Key"
3. Select "GROQ"
4. Paste your key
5. Set priority (e.g., 10)
6. Click "Save"

---

## 💰 OpenAI (Paid - Most Popular)

**Cost**: Pay-as-you-go (starts at ~$0.0015 per 1K tokens)  
**Best for**: Production use, high quality responses

### Steps:
1. Go to: https://platform.openai.com
2. Click "Sign Up" (or "Sign In")
3. Complete account setup
4. **Add payment method** (required even for free trial)
5. Go to: https://platform.openai.com/api-keys
6. Click "Create new secret key"
7. Give it a name (e.g., "ScholarMate")
8. Copy the key (starts with `sk-`)
9. **Important**: Save it immediately - you can't view it again!

### In ScholarMate:
1. Go to Settings → API Keys
2. Click "Add Key"
3. Select "OpenAI"
4. Paste your key
5. Set priority (e.g., 10)
6. Click "Save"

### Cost Management:
- Set usage limits in OpenAI dashboard
- Monitor usage in ScholarMate's usage statistics
- gpt-4o-mini is cheapest (~$0.15 per 1M tokens)

---

## 🤖 Anthropic (Claude) (Paid - High Quality)

**Cost**: Pay-as-you-go (starts at ~$3 per 1M tokens)  
**Best for**: Complex reasoning, long documents

### Steps:
1. Go to: https://console.anthropic.com
2. Click "Sign Up"
3. Complete account setup
4. **Add payment method** (required)
5. Go to "API Keys" section
6. Click "Create Key"
7. Give it a name (e.g., "ScholarMate")
8. Copy the key (starts with `sk-ant-`)
9. **Important**: Save it securely!

### In ScholarMate:
1. Go to Settings → API Keys
2. Click "Add Key"
3. Select "Anthropic"
4. Paste your key
5. Set priority (e.g., 10)
6. Click "Save"

---

## 🌐 OpenRouter (Paid - Access to Many Models)

**Cost**: Pay-as-you-go (varies by model, starts at ~$0.0015 per 1M tokens)  
**Best for**: Access to multiple models through one API

### Steps:
1. Go to: https://openrouter.ai
2. Click "Sign In" (supports Google, GitHub)
3. Complete account setup
4. **Add credits** (minimum $5)
5. Go to "Keys" section
6. Click "Create Key"
7. Give it a name (e.g., "ScholarMate")
8. Copy the key (starts with `sk-or-`)
9. **Important**: Save it securely!

### In ScholarMate:
1. Go to Settings → API Keys
2. Click "Add Key"
3. Select "OpenRouter"
4. Paste your key
5. Set priority (e.g., 10)
6. Click "Save"

### Why OpenRouter?
- Access to GPT-4, Claude, Llama, and many more
- Pay only for what you use
- Automatic fallback if one model is down
- Competitive pricing

---

## 🔷 Google (Gemini) (Free Tier Available!)

**Cost**: FREE tier available (Gemini Flash), paid tiers for Pro models  
**Best for**: Free high-quality AI, multimodal capabilities

### Steps:
1. Go to: https://aistudio.google.com/app/apikey
2. Sign in with Google account
3. Click "Create API Key"
4. Select or create a Google Cloud project
5. Copy the key (starts with `AIza`)
6. **Important**: Save it securely!

### In ScholarMate:
1. Go to Settings → API Keys
2. Click "Add Key"
3. Select "Google"
4. Paste your key
5. Set priority (e.g., 10)
6. Click "Save"

### Why Google Gemini?
- Gemini Flash is FREE with generous limits
- Fast responses
- Good quality
- No credit card required for free tier

---

## 🔐 Security Best Practices

### ✅ DO:
- Store keys securely (ScholarMate encrypts them)
- Use different keys for different apps
- Set usage limits in provider dashboards
- Monitor usage regularly
- Rotate keys periodically

### ❌ DON'T:
- Share your API keys with anyone
- Commit keys to Git repositories
- Use the same key across multiple apps
- Ignore usage alerts
- Use production keys for testing

---

## 💡 Which Provider Should I Choose?

### For Students / Personal Use (FREE):
**GROQ** or **Google Gemini**
- ✅ Free tier with generous limits
- ✅ Fast responses
- ✅ Good quality
- ✅ No credit card required
- ❌ Rate limits apply

**Recommendation**: Start with GROQ, add Google Gemini as backup

### For Professional Use:
**OpenAI** or **OpenRouter**
- ✅ Most popular and reliable
- ✅ Good balance of cost/quality
- ✅ gpt-4o-mini is very affordable
- ❌ Requires payment method

**Recommendation**: OpenRouter gives you access to multiple models

### For Complex Research:
**Anthropic Claude**
- ✅ Excellent for long documents
- ✅ Strong reasoning capabilities
- ✅ Good at following instructions
- ❌ More expensive

### For Maximum Flexibility:
**OpenRouter**
- ✅ Access to 100+ models
- ✅ One API key for everything
- ✅ Automatic fallback
- ✅ Competitive pricing

### Pro Tip: Use Multiple Providers!
Add keys for multiple providers and set priorities:
- GROQ (priority: 5) - Free fallback
- Google Gemini (priority: 6) - Free backup
- OpenRouter (priority: 10) - Primary (access to all models)
- OpenAI (priority: 8) - Direct OpenAI access

ScholarMate will automatically use the highest priority available key!

---

## 📊 Monitoring Usage

### In ScholarMate:
1. Go to Settings → API Keys
2. View "Usage Statistics" section
3. See:
   - Total requests per provider
   - Tokens used
   - Estimated costs
   - Success rates

### In Provider Dashboards:
- **GROQ**: https://console.groq.com/usage
- **OpenAI**: https://platform.openai.com/usage
- **Anthropic**: https://console.anthropic.com/settings/usage

---

## 🆘 Troubleshooting

### "Invalid API Key" Error
- Check you copied the entire key
- Verify key format matches provider:
  - GROQ: `gsk_...`
  - OpenAI: `sk-...`
  - Anthropic: `sk-ant-...`
- Ensure key hasn't been revoked
- Try creating a new key

### "Rate Limit Exceeded"
- Wait a few minutes and try again
- Add a paid provider as backup
- Increase priority of paid providers

### "Validation Failed"
- Check internet connection
- Verify provider service is online
- Try again in a few minutes
- Check provider dashboard for issues

### Key Not Working
1. Delete the key in ScholarMate
2. Revoke the key in provider dashboard
3. Create a new key
4. Add it to ScholarMate again

---

## 💰 Cost Estimates

### Typical Usage (1000 queries/month):

**GROQ** (Free):
- Cost: $0
- Limits: May hit rate limits
- ✅ Best for: Students, personal use

**Google Gemini Flash** (Free):
- Cost: $0
- Limits: 15 requests/minute, 1500/day
- ✅ Best for: Free high-quality AI

**OpenRouter gpt-4o-mini**:
- Average: ~150 tokens per query
- Cost: ~$0.23/month
- ✅ Best for: Professional use, multiple models

**OpenAI gpt-4o-mini**:
- Average: ~150 tokens per query
- Cost: ~$0.23/month
- ✅ Best for: Direct OpenAI access

**Anthropic Claude Sonnet**:
- Average: ~150 tokens per query
- Cost: ~$0.45/month
- ✅ Best for: Complex reasoning

### Tips to Reduce Costs:
1. Use GROQ or Google Gemini for simple queries (FREE)
2. Use OpenRouter for flexibility (access to cheap models)
3. Use OpenAI gpt-4o-mini for most paid queries
4. Reserve Claude for complex documents
5. Set priorities to use free tier first
6. Monitor usage regularly

---

## 🔄 Switching Providers

You can change which provider is used for each query:

### Method 1: Set Priority
Higher priority keys are used first:
- GROQ: priority 5
- OpenAI: priority 10 ← Will be used first
- Anthropic: priority 8

### Method 2: Choose Per Query
When asking a question, select preferred provider from dropdown.

### Method 3: Automatic Fallback
If your preferred provider fails, ScholarMate automatically tries the next available provider!

---

## 📞 Need Help?

- **GROQ Support**: https://console.groq.com/docs
- **OpenAI Support**: https://help.openai.com
- **Anthropic Support**: https://support.anthropic.com

---

## ✅ Quick Start Checklist

- [ ] Choose a provider (GROQ recommended for starting)
- [ ] Sign up for an account
- [ ] Create an API key
- [ ] Copy and save the key securely
- [ ] Open ScholarMate → Settings → API Keys
- [ ] Click "Add Key"
- [ ] Select provider and paste key
- [ ] Set priority (10 is good default)
- [ ] Click "Save"
- [ ] Test with a query!

---

**Remember**: Your API keys are encrypted and stored securely in ScholarMate. They are never shared or exposed to anyone else!
