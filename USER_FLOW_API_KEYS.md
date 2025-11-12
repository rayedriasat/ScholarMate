# User Flow: Adding and Using API Keys

## 📱 User Journey

### Step 1: User Opens Settings
```
User opens ScholarMate app
  ↓
Navigates to Settings
  ↓
Sees "API Keys" option
  ↓
Taps on it
```

### Step 2: API Key Management Screen
```
┌─────────────────────────────────────┐
│  API Key Management            🔄   │
├─────────────────────────────────────┤
│                                     │
│  Usage Statistics (Last 30 Days)   │
│  ┌─────────────────────────────┐   │
│  │ GROQ                        │   │
│  │ 150 requests | 45K tokens  │   │
│  │ $0.00 | 98.5% success      │   │
│  └─────────────────────────────┘   │
│                                     │
│  Your API Keys          [+ Add Key]│
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🟢 GROQ                     │   │
│  │ Key: gsk_...xyz             │   │
│  │ ✓ Validated | Priority: 10 │   │
│  │                          ⋮  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🟢 OpenAI                   │   │
│  │ Key: sk-...abc              │   │
│  │ ✓ Validated | Priority: 5  │   │
│  │                          ⋮  │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
                 [+] FAB
```

### Step 3: User Adds New Key
```
User taps "+ Add Key"
  ↓
Dialog appears:

┌─────────────────────────────────────┐
│  Add API Key                    ✕   │
├─────────────────────────────────────┤
│                                     │
│  Provider: [Select Provider ▼]     │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ GROQ                        │   │
│  │ OpenAI                      │   │
│  │ Anthropic (Claude)          │   │
│  └─────────────────────────────┘   │
│                                     │
│  Format: gsk_*                      │
│  [?] How to get API key             │
│                                     │
│  API Key: [____________] 👁         │
│                                     │
│  Priority: [10_________]            │
│  (0-100, higher = preferred)        │
│                                     │
│  ☑ Validate key before saving       │
│                                     │
│         [Cancel]  [Save]            │
└─────────────────────────────────────┘
```

### Step 4: User Gets API Key from Provider

#### For GROQ (Free):
```
1. User taps "How to get API key"
2. Opens browser to console.groq.com
3. Signs up (free)
4. Creates API key
5. Copies key (gsk_...)
6. Returns to ScholarMate
7. Pastes key
```

#### For OpenAI (Paid):
```
1. Opens platform.openai.com
2. Signs up
3. Adds payment method
4. Creates API key
5. Copies key (sk-...)
6. Pastes in ScholarMate
```

### Step 5: Key Validation
```
User taps "Save"
  ↓
ScholarMate validates key:
  ↓
┌─────────────────────────────────────┐
│  Validating...                      │
│  ⏳ Testing API key with provider   │
└─────────────────────────────────────┘
  ↓
Success:
┌─────────────────────────────────────┐
│  ✓ API key saved successfully       │
└─────────────────────────────────────┘
  ↓
Key appears in list with ✓ Validated
```

### Step 6: Using the Key in Chat
```
User opens Chat/RAG screen
  ↓
Sees provider selector in app bar:

┌─────────────────────────────────────┐
│  Chat              [Auto ▼]    ⋮    │
├─────────────────────────────────────┤
│                                     │
│  User can select:                   │
│  • Auto (uses highest priority)     │
│  • GROQ                             │
│  • OpenAI                           │
│  • Anthropic                        │
│                                     │
│  [Type your question...]            │
│                                     │
└─────────────────────────────────────┘
```

### Step 7: Query with Provider
```
User types question
  ↓
Selects provider (or leaves as "Auto")
  ↓
Sends query
  ↓
Backend uses selected provider:
  1. If "Auto" → Uses highest priority key
  2. If specific → Uses that provider
  3. If fails → Falls back to next available
  ↓
Response displayed
  ↓
Usage logged automatically
```

### Step 8: Monitoring Usage
```
User returns to API Key Management
  ↓
Views Usage Statistics:

┌─────────────────────────────────────┐
│  Usage Statistics (Last 30 Days)   │
│                                     │
│  GROQ                               │
│  150 requests | 45,000 tokens      │
│  $0.00 | 98.5% success             │
│                                     │
│  OpenAI                             │
│  50 requests | 15,000 tokens       │
│  $0.23 | 100% success              │
│                                     │
│  Total Cost: $0.23                 │
└─────────────────────────────────────┘
```

## 🎯 Key User Benefits

### 1. Easy Setup
- Simple, guided process
- Clear instructions for each provider
- Validation before saving
- Helpful error messages

### 2. Flexibility
- Use multiple providers
- Set priorities
- Choose per query
- Automatic fallback

### 3. Cost Control
- See usage statistics
- Monitor costs
- Use free tier (GROQ)
- Set priorities to prefer free

### 4. Security
- Keys encrypted at rest
- Never exposed in UI (masked)
- Can revoke anytime
- Secure storage

## 🔄 Common User Scenarios

### Scenario 1: Student (Free Tier)
```
1. Adds GROQ key (free)
2. Sets priority: 10
3. Uses for all queries
4. Cost: $0/month
```

### Scenario 2: Professional (Mixed)
```
1. Adds GROQ key (priority: 5)
2. Adds OpenAI key (priority: 10)
3. OpenAI used first
4. Falls back to GROQ if needed
5. Cost: ~$5/month
```

### Scenario 3: Researcher (Quality Focus)
```
1. Adds OpenAI (priority: 8)
2. Adds Anthropic (priority: 10)
3. Uses Anthropic for complex docs
4. Uses OpenAI for quick queries
5. Cost: ~$20/month
```

## 📊 User Interface Elements

### API Key Card
```
┌─────────────────────────────────────┐
│ 🟢 GROQ                          ⋮  │
│ Key: gsk_...xyz                     │
│ ✓ Validated | Priority: 10         │
│                                     │
│ Actions (⋮):                        │
│ • Activate/Deactivate               │
│ • Edit Priority                     │
│ • Delete                            │
└─────────────────────────────────────┘
```

### Status Indicators
- 🟢 Green circle = Active & Validated
- 🔴 Red circle = Inactive
- ✓ Check = Validated
- ⚠️ Warning = Not validated
- ⏳ Loading = Validating

### Provider Selector (in Chat)
```
[Auto ▼]  ← Dropdown in app bar
  │
  ├─ Auto (Recommended)
  ├─ GROQ (Free)
  ├─ OpenAI ($)
  └─ Anthropic ($$)
```

## 🎨 Visual Design

### Colors
- **Green**: Active, validated, success
- **Orange**: Warning, not validated
- **Red**: Error, inactive
- **Blue**: Primary actions
- **Grey**: Disabled, secondary

### Icons
- 🔑 `vpn_key` - API Keys menu item
- ➕ `add` - Add new key
- ✏️ `edit` - Edit key
- 🗑️ `delete` - Delete key
- ✓ `check_circle` - Validated
- ⚠️ `warning` - Not validated
- 👁️ `visibility` - Show/hide key
- 🔄 `refresh` - Reload data
- 📊 `bar_chart` - Usage stats

## 💬 User Feedback Messages

### Success
- ✅ "API key saved successfully"
- ✅ "API key updated"
- ✅ "API key deleted"

### Errors
- ❌ "Invalid API key format"
- ❌ "Key validation failed"
- ❌ "Failed to save key"
- ❌ "Provider not available"

### Info
- ℹ️ "Validating key..."
- ℹ️ "Loading keys..."
- ℹ️ "No API keys yet"

## 🚀 Onboarding Flow

### First Time User
```
1. User opens app
2. Tries to use AI feature
3. Sees prompt:
   ┌─────────────────────────────────┐
   │  Add API Key                    │
   │                                 │
   │  To use AI features, add an     │
   │  API key from a provider.       │
   │                                 │
   │  [Learn More]  [Add Key]        │
   └─────────────────────────────────┘
4. Taps "Learn More" → Opens guide
5. Taps "Add Key" → Opens management screen
6. Follows steps to add key
7. Returns to feature
8. Feature now works!
```

## 📱 Mobile-Optimized

### Responsive Design
- Cards stack vertically
- Touch-friendly buttons (min 48x48)
- Swipe to delete (optional)
- Pull to refresh
- Bottom sheet for actions

### Accessibility
- Screen reader support
- High contrast mode
- Large text support
- Keyboard navigation
- Focus indicators

---

**Result**: Users can easily add, manage, and use their own API keys with a smooth, intuitive interface! 🎉
