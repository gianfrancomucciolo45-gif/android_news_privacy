#!/usr/bin/env python3
"""Generate placeholder screenshots for Play Store"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_screenshot(width, height, text, filename):
    """Create a simple placeholder screenshot"""
    img = Image.new('RGB', (width, height), (61, 220, 132))  # Android green
    draw = ImageDraw.Draw(img)
    
    try:
        font = ImageFont.truetype("arial.ttf", 60)
    except:
        font = ImageFont.load_default()
    
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = (width - text_width) // 2 - bbox[0]
    text_y = (height - text_height) // 2 - bbox[1]
    
    draw.text((text_x, text_y), text, fill=(255, 255, 255), font=font)
    
    return img

def main():
    output_dir = os.path.join(os.path.dirname(__file__), 'play_store_assets')
    os.makedirs(output_dir, exist_ok=True)
    
    # Phone screenshots (9:16 ratio, 1080x1920)
    screenshots = [
        ("Android News - Home", "screenshot_1_home.png"),
        ("Android News - Articles", "screenshot_2_articles.png"),
        ("Android News - Settings", "screenshot_3_settings.png"),
        ("Android News - Sources", "screenshot_4_sources.png"),
    ]
    
    for text, filename in screenshots:
        img = create_screenshot(1080, 1920, text, filename)
        path = os.path.join(output_dir, filename)
        img.save(path, 'PNG')
        print(f"✓ Created: {filename}")
    
    # Tablet 7" screenshots (optional, same size)
    for i, (text, filename) in enumerate(screenshots[:2]):
        img = create_screenshot(1080, 1920, f"{text} (Tablet)", f"tablet_7_{i+1}.png")
        path = os.path.join(output_dir, f"tablet_7_{i+1}.png")
        img.save(path, 'PNG')
        print(f"✓ Created: tablet_7_{i+1}.png")
    
    # Tablet 10" screenshots (16:9 ratio, 1920x1080)
    for i, (text, filename) in enumerate(screenshots[:2]):
        img = create_screenshot(1920, 1080, f"{text} (Tablet 10\")", f"tablet_10_{i+1}.png")
        path = os.path.join(output_dir, f"tablet_10_{i+1}.png")
        img.save(path, 'PNG')
        print(f"✓ Created: tablet_10_{i+1}.png")
    
    print(f"\n✓ All screenshots created in {output_dir}")

if __name__ == '__main__':
    main()
