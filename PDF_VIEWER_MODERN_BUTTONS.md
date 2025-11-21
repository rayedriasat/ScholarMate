# PDF Viewer Modern & Colorful Buttons ✨

## What Changed

All buttons in the PDF viewer have been modernized with:
- **Vibrant gradient colors** for visual appeal
- **Outlined icon pack** (20px) for refined, lightweight appearance
- **Rounded corners** (10px border radius)
- **Consistent sizing** across all buttons

## Button Styles

### 1. **Split View** (Web only)
- Gradient: Purple to Violet (`#667EEA` → `#764BA2`)
- Icon: `view_column_outlined` (20px)

### 2. **Collaboration**
- Gradient: Pink to Yellow (`#FA709A` → `#FEE140`)
- Icon: `people_outline` (20px)
- Disabled state: Gray when offline

### 3. **Refresh/Sync**
- Gradient: Cyan to Deep Purple (`#30CFD0` → `#330867`)
- Icon: `refresh_outlined` (20px)
- Disabled state: Gray when offline

### 4. **Read Aloud (TTS)**
- Active: Red to Yellow gradient (`#FF6B6B` → `#FFE66D`)
- Inactive: Blue to Cyan gradient (`#4FACFE` → `#00F2FE`)
- Icon: `volume_up_outlined` / `volume_off_outlined` (20px)

### 5. **Annotations Toolbar**
- Active: Orange to Pink gradient (`#FF9A56` → `#FF6A88`)
- Inactive: Mint to Pink gradient (`#A8EDEA` → `#FED6E3`)
- Icon: `edit_outlined` / `edit_off_outlined` (20px)

### 6. **Show Annotations**
- Active: Purple to Red gradient (`#F093FB` → `#F5576C`)
- Inactive: Blue to Cyan gradient (`#4FACFE` → `#00F2FE`)
- Icon: `bookmark_outline` (20px)

### 7. **Upload to Drive**
- Gradient: Teal to Green (`#11998E` → `#38EF7D`)
- Icon: `cloud_upload_outlined` (20px)
- Only visible when annotations exist

### 8. **Search**
- Active: Red to Yellow gradient (`#FF6B6B` → `#FFE66D`)
- Inactive: Peach to Blue gradient (`#FFD89B` → `#19547B`)
- Icon: `search_outlined` / `close_outlined` (20px)

### 9. **Go to Page**
- Gradient: Purple to Blue (`#6A11CB` → `#2575FC`)
- Icon: `format_list_numbered_outlined` (20px)

### 10. **Metadata & Citations**
- Active: Pink to Blue gradient (`#FC466B` → `#3F5EFB`)
- Inactive: Cyan to Green gradient (`#00C9FF` → `#92FE9D`)
- Icon: `info_outlined` (20px)

### 11. **Chat with PDF (FAB)**
- Gradient: Red to Peach (`#FF0844` → `#FFB199`)
- Icon: `chat_bubble_outline` (24px)
- Enhanced shadow effect

### 12. **Bottom Navigation Bar**
- Background: Purple gradient (`#667EEA` → `#764BA2`)
- Previous/Next buttons: `chevron_left_outlined` / `chevron_right_outlined` (24px)
- White icons with semi-transparent background
- Slider: White track with custom styling

## Design Features

✅ **Gradient backgrounds** - Each button has a unique, vibrant gradient
✅ **Outlined icons** - Refined, lightweight icon pack (20px for toolbar, 24px for navigation)
✅ **Soft shadows** - Subtle shadow effects for depth
✅ **Rounded corners** - 10px border radius for modern look
✅ **White icons** - High contrast against colorful backgrounds
✅ **State-based colors** - Different gradients for active/inactive states
✅ **Consistent sizing** - All toolbar icons are 20px, navigation icons are 24px
✅ **Consistent spacing** - 4px horizontal margins between buttons
✅ **Accessibility** - Tooltips on all buttons
✅ **Responsive** - Adapts to online/offline states

## Testing

Run the app and open any PDF to see the new colorful buttons:

```bash
flutter run -d chrome
```

Navigate to a PDF file and observe:
- All toolbar buttons with vibrant gradients
- Smooth hover effects
- State changes (active/inactive)
- Bottom navigation bar with gradient background
- Floating action button with gradient and shadow
