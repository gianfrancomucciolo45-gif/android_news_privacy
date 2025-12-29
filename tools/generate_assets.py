#!/usr/bin/env python3
"""
Generate Google Play Store assets for Android News app
- App icon: 512x512 PNG with transparency
- Feature graphic: 1024x500 PNG
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon():
    """Create 512x512 app icon with Android News theme"""
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Green gradient background circle
    center = size // 2
    radius = size // 2 - 20
    
    # Draw circular background with Android green color
    draw.ellipse(
        [(center - radius, center - radius), (center + radius, center + radius)],
        fill=(61, 220, 132, 255)  # Android green
    )
    
    # Draw white "A" for Android News
    try:
        font = ImageFont.truetype("arial.ttf", 280)
    except:
        font = ImageFont.load_default()
    
    text = "A"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = (size - text_width) // 2 - bbox[0]
    text_y = (size - text_height) // 2 - bbox[1] - 10
    
    draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
    
    # Add small "NEWS" text at bottom
    try:
        small_font = ImageFont.truetype("arial.ttf", 48)
    except:
        small_font = ImageFont.load_default()
    
    news_text = "NEWS"
    bbox = draw.textbbox((0, 0), news_text, font=small_font)
    news_width = bbox[2] - bbox[0]
    news_x = (size - news_width) // 2 - bbox[0]
    news_y = center + radius - 80
    
    draw.text((news_x, news_y), news_text, fill=(255, 255, 255, 255), font=small_font)
    
    return img

def create_feature_graphic():
    """Create 1024x500 feature graphic"""
    width, height = 1024, 500
    img = Image.new('RGB', (width, height), (61, 220, 132))  # Android green
    draw = ImageDraw.Draw(img)
    
    # Add title
    try:
        title_font = ImageFont.truetype("arial.ttf", 90)
        subtitle_font = ImageFont.truetype("arial.ttf", 40)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    title = "Android News"
    bbox = draw.textbbox((0, 0), title, font=title_font)
    title_width = bbox[2] - bbox[0]
    title_x = (width - title_width) // 2 - bbox[0]
    title_y = 150
    
    draw.text((title_x, title_y), title, fill=(255, 255, 255), font=title_font)
    
    subtitle = "Tutte le notizie tech italiane in un'unica app"
    bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_width = bbox[2] - bbox[0]
    subtitle_x = (width - subtitle_width) // 2 - bbox[0]
    subtitle_y = 280
    
    draw.text((subtitle_x, subtitle_y), subtitle, fill=(255, 255, 255), font=subtitle_font)
    
    return img

def main():
    """Generate all assets"""
    output_dir = os.path.join(os.path.dirname(__file__), 'play_store_assets')
    os.makedirs(output_dir, exist_ok=True)
    
    print("Generating app icon (512x512)...")
    icon = create_app_icon()
    icon_path = os.path.join(output_dir, 'app_icon_512.png')
    icon.save(icon_path, 'PNG')
    print(f"✓ App icon saved: {icon_path}")
    
    print("\nGenerating feature graphic (1024x500)...")
    feature = create_feature_graphic()
    feature_path = os.path.join(output_dir, 'feature_graphic_1024x500.png')
    feature.save(feature_path, 'PNG')
    print(f"✓ Feature graphic saved: {feature_path}")
    
    print("\n✓ All assets generated successfully!")
    print(f"\nAssets location: {output_dir}")
    print("\nNote: For screenshots, run the app and capture screens using:")
    print("  flutter run --release")
    print("  Then take screenshots of: home, settings, article view, sources list")

if __name__ == '__main__':
    main()
