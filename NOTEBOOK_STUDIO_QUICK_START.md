# Notebook Studio - Quick Start Guide

## Setup (One-time)

### 1. Start Backend
```bash
cd backend
uv run python run.py
```

### 2. Configure API Keys
- Open app → Settings → API Key Management
- Add your preferred AI provider key (OpenRouter, OpenAI, Claude, etc.)

### 3. Index Your Files
- Go to Files tab
- Upload PDFs or documents
- Wait for indexing to complete (check status in app)

## Using Notebook Studio

### Create Your First Workspace

1. **Open Notebook Studio**
   - Tap "Notebook Studio" in bottom navigation

2. **Create Workspace**
   - Tap "New Workspace" button
   - Name it (e.g., "Research Project")
   - Add description (optional)
   - Tap "Create"

3. **Add Files**
   - Go to "Files" tab
   - Tap "Add from Drive"
   - Select indexed files from your Drive
   - Tap "Add X file(s)"

### Chat with AI

1. **Go to Chat Tab**
   - Files must be added first
   - Type your question
   - Tap send

2. **Example Questions:**
   - "What are the main topics covered?"
   - "Summarize the key findings"
   - "What does the author say about [topic]?"
   - "Compare the approaches in these documents"

3. **View Citations**
   - AI responses show source files
   - Citations appear as chips below response
   - Shows file name and page number

### Generate Study Materials

1. **Go to AI Studio Tab**
   - See 5 tools: Quiz, Summary, Mind Map, Flashcards, Audio

2. **Generate Content**
   - **Long press** any tool to generate
   - Wait 10-30 seconds
   - Content appears in list below

3. **View Generated Content**
   - Tap any item to view full content
   - Delete unwanted items with trash icon

### Tool Descriptions

**Quiz Generator**
- Creates 5 multiple-choice questions
- Includes correct answers and explanations
- Based on your workspace files

**Summarizer**
- Comprehensive summary of all files
- Key points as bullet list
- Covers main themes and findings

**Flashcard Creator**
- 10 study flashcards
- Question/term on front
- Answer/definition on back

**Mind Map** (Coming Soon)
- Visual concept mapping
- Shows relationships between topics

**Audio Review** (Coming Soon)
- Text-to-speech summaries
- Listen while studying

## Tips & Tricks

### For Best Results:

1. **Add Relevant Files Only**
   - Only add files related to your topic
   - More files = more context but slower

2. **Ask Specific Questions**
   - Good: "What are the three main arguments?"
   - Bad: "Tell me about this"

3. **Use Multiple Workspaces**
   - Separate by project or topic
   - Keeps context focused

4. **Generate Multiple Times**
   - Each generation is unique
   - Try again if not satisfied

### Troubleshooting:

**"No files in workspace"**
- Add files from Drive first

**"No response from AI"**
- Check internet connection
- Verify API key is configured
- Ensure files are indexed

**"Generation taking too long"**
- Normal for large files
- Wait up to 30 seconds
- Check backend is running

**Citations not showing**
- Files may not be indexed
- Re-index files in main app

## Workflow Example

### Research Paper Workflow:

1. **Setup**
   ```
   Create workspace: "Thesis Research"
   Add files: 5 research papers (PDFs)
   ```

2. **Understand Content**
   ```
   Chat: "What are the main methodologies used?"
   Chat: "Compare the findings across papers"
   ```

3. **Study Materials**
   ```
   Generate: Quiz (test understanding)
   Generate: Summary (quick reference)
   Generate: Flashcards (memorization)
   ```

4. **Review**
   ```
   Take quiz
   Review flashcards
   Read summary
   ```

### Exam Prep Workflow:

1. **Setup**
   ```
   Create workspace: "Biology Exam"
   Add files: Lecture notes, textbook chapters
   ```

2. **Generate Materials**
   ```
   Generate: Flashcards (key terms)
   Generate: Quiz (practice questions)
   Generate: Summary (review sheet)
   ```

3. **Study**
   ```
   Review flashcards daily
   Take practice quiz
   Ask clarifying questions in chat
   ```

## Keyboard Shortcuts

- **Enter** in chat: Send message
- **Long press** tool: Generate content
- **Swipe** message: (Future: Delete)

## Limits & Quotas

- **Files per workspace**: Unlimited
- **Chat messages**: Unlimited
- **AI generations**: Based on your API key limits
- **Storage**: Local device + Google Drive

## Privacy & Data

- **Local Storage**: All data stored on device
- **Cloud Sync**: Via Google Drive (your account)
- **AI Processing**: Sent to your configured provider
- **No Tracking**: Your data stays yours

## Next Steps

1. **Explore Features**
   - Try all AI Studio tools
   - Experiment with different questions
   - Create multiple workspaces

2. **Optimize Usage**
   - Learn what questions work best
   - Find your ideal file organization
   - Develop study workflows

3. **Share Feedback**
   - Report bugs
   - Suggest features
   - Share use cases

## Support

- Check `NOTEBOOK_STUDIO_AI_INTEGRATION.md` for technical details
- Review `NOTEBOOK_STUDIO_FEATURE.md` for architecture
- See main app documentation for general help

---

**Happy Studying! 📚✨**
