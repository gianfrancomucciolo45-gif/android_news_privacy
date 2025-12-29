from PIL import Image
import os

# Leggi icona 512x512
icon_512 = Image.open('tools/play_store_assets/app_icon_512.png')

# Dimensioni mipmap Android
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

for folder, size in sizes.items():
    # Crea directory se non esiste
    target_dir = f'android/app/src/main/res/{folder}'
    os.makedirs(target_dir, exist_ok=True)
    
    # Ridimensiona e salva
    resized = icon_512.resize((size, size), Image.Resampling.LANCZOS)
    target_path = f'{target_dir}/ic_launcher.png'
    resized.save(target_path, 'PNG')
    print(f'[OK] {folder}/ic_launcher.png ({size}x{size})')

print('\nIcone Android generate con successo!')
