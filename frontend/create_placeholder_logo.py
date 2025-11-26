#!/usr/bin/env python3
"""
Simple script to create a placeholder ScholarMate logo
Requires: pip install pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_scholarmate_logo():
    # Create a 1024x1024 image with transparent background
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw a circular background (blue)
    margin = 50
    circle_bbox = [margin, margin, size - margin, size - margin]
    draw.ellipse(circle_bbox, fill='#2196F3')
    
    # Draw a book icon (simplified)
    book_color = '#FFFFFF'
    book_width = 400
    book_height = 500
    book_x = (size - book_width) // 2
    book_y = (size - book_height) // 2
    
    # Book cover
    draw.rectangle(
        [book_x, book_y, book_x + book_width, book_y + book_height],
        fill=book_color,
        outline='#1976D2',
        width=8
    )
    
    # Book spine
    spine_width = 40
    draw.rectangle(
        [book_x, book_y, book_x + spine_width, book_y + book_height],
        fill='#1976D2'
    )
    
    # Pages effect
    page_offset = 10
    for i in range(3):
        offset = (i + 1) * page_offset
        draw.line(
            [book_x + spine_width + offset, book_y + 50,
             book_x + spine_width + offset, book_y + book_height - 50],
            fill='#BBDEFB',
            width=2
        )
    
    # Add "S" letter in the center
    try:
        # Try to use a system font
        font_size = 200
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        # Fallback to default font
        font = ImageFont.load_default()
    
    text = "S"
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = book_x + (book_width - text_width) // 2 + 20
    text_y = book_y + (book_height - text_height) // 2 - 20
    
    draw.text((text_x, text_y), text, fill='#1976D2', font=font)
    
    # Save the image
    output_path = os.path.join('assets', 'scholarmate_logo.png')
    os.makedirs('assets', exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"✅ Logo created: {output_path}")
    print(f"   Size: {size}x{size}px")
    print(f"\nNext steps:")
    print(f"1. Review the logo at: {output_path}")
    print(f"2. Run: flutter pub run flutter_launcher_icons")
    print(f"3. Rebuild your app: flutter build apk")

if __name__ == '__main__':
    create_scholarmate_logo()
