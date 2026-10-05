"""
Generate high-fidelity pixel-art GUI assets inspired by 'SIMPLE PIXEL GUI #1'
for the 3D Battle Simulator in Godot 4.
"""
from PIL import Image, ImageDraw
import os

ASSETS_DIR = "ui/assets"
ICONS_DIR = "ui/icons"
os.makedirs(ASSETS_DIR, exist_ok=True)
os.makedirs(ICONS_DIR, exist_ok=True)

# ----------------- Curated Retro Pixel Color Palette -----------------
C_DARK_OUTLINE = (56, 32, 20, 255)      # #382014 Darkest wood outline
C_WOOD_DARK    = (74, 43, 25, 255)      # #4a2b19 Base dark wood
C_WOOD_MID     = (107, 63, 35, 255)     # #6b3f23 Warm rich wood
C_WOOD_LIGHT   = (152, 97, 61, 255)     # #98613d Wood highlight
C_WOOD_BEVEL   = (186, 126, 82, 255)    # #ba7e52 Lightest wood grain

C_GOLD_DARK    = (123, 74, 18, 255)     # #7b4a12 Brass shadow
C_GOLD_MID     = (217, 156, 53, 255)    # #d99c35 Gold base
C_GOLD_LIGHT   = (247, 205, 103, 255)   # #f7cd67 Gold highlight
C_GOLD_SHINE   = (255, 241, 182, 255)   # #fff1b6 Pure gold rivet shine

C_PARCH_DARK   = (226, 197, 159, 255)   # #e2c59f Parchment shadow
C_PARCH_MID    = (240, 219, 188, 255)   # #f0dbbc Medium parchment
C_PARCH_LIGHT  = (249, 235, 213, 255)   # #f9ebd5 Light parchment
C_PARCH_BORDER = (210, 180, 142, 255)   # #d2b48e Fine inner border

C_BANNER_DARK  = (130, 48, 32, 255)     # Dark terracotta border
C_BANNER_MID   = (184, 88, 68, 255)     # Medium terracotta fill
C_BANNER_LIGHT = (217, 120, 100, 255)   # Highlight terracotta

def draw_brass_bracket(draw, x, y, size=10, corner="top_left"):
    if corner == "top_left":
        coords = [(x, y), (x + size, y), (x + size, y + 3), (x + 3, y + 3), (x + 3, y + size), (x, y + size)]
        rivet = (x + 2, y + 2)
    elif corner == "top_right":
        coords = [(x, y), (x - size, y), (x - size, y + 3), (x - 3, y + 3), (x - 3, y + size), (x, y + size)]
        rivet = (x - 3, y + 2)
    elif corner == "bottom_left":
        coords = [(x, y), (x + size, y), (x + size, y - 3), (x + 3, y - 3), (x + 3, y - size), (x, y - size)]
        rivet = (x + 2, y - 3)
    else: # bottom_right
        coords = [(x, y), (x - size, y), (x - size, y - 3), (x - 3, y - 3), (x - 3, y - size), (x, y - size)]
        rivet = (x - 3, y - 3)
        
    draw.polygon(coords, fill=C_GOLD_MID, outline=C_GOLD_DARK)
    draw.point(rivet, fill=C_GOLD_SHINE)

# 1. Parchment Panel (9-sliceable, 64x64)
def make_frame_parchment():
    w, h = 64, 64
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Outer dark outline
    d.rectangle([0, 0, w-1, h-1], outline=C_DARK_OUTLINE, fill=C_WOOD_MID)
    # Wood bevel
    d.rectangle([1, 1, w-2, 2], fill=C_WOOD_LIGHT)
    d.rectangle([1, 1, 2, h-2], fill=C_WOOD_LIGHT)
    d.rectangle([w-3, 1, w-2, h-2], fill=C_WOOD_DARK)
    d.rectangle([1, h-3, w-2, h-2], fill=C_WOOD_DARK)
    
    # Inner border
    d.rectangle([3, 3, w-4, h-4], outline=C_DARK_OUTLINE, fill=C_PARCH_MID)
    # Parchment fill
    d.rectangle([5, 5, w-6, h-6], fill=C_PARCH_LIGHT)
    # Subtle inner decorative line
    d.rectangle([7, 7, w-8, h-8], outline=C_PARCH_BORDER)
    
    # Gold corners with rivets
    draw_brass_bracket(d, 0, 0, 11, "top_left")
    draw_brass_bracket(d, w-1, 0, 11, "top_right")
    draw_brass_bracket(d, 0, h-1, 11, "bottom_left")
    draw_brass_bracket(d, w-1, h-1, 11, "bottom_right")
    
    img.save(os.path.join(ASSETS_DIR, "frame_parchment.png"))

# 2. Avatar Box Frame (56x56)
def make_frame_avatar_box():
    w, h = 56, 56
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Wood bezel
    d.rectangle([0, 0, w-1, h-1], outline=C_DARK_OUTLINE, fill=C_WOOD_DARK)
    d.rectangle([1, 1, w-2, 2], fill=C_WOOD_LIGHT)
    d.rectangle([1, 1, 2, h-2], fill=C_WOOD_LIGHT)
    
    # Cream interior for character
    d.rectangle([3, 3, w-4, h-4], outline=C_DARK_OUTLINE, fill=C_PARCH_LIGHT)
    
    # Gold corner rivets
    draw_brass_bracket(d, 0, 0, 7, "top_left")
    draw_brass_bracket(d, w-1, 0, 7, "top_right")
    draw_brass_bracket(d, 0, h-1, 7, "bottom_left")
    draw_brass_bracket(d, w-1, h-1, 7, "bottom_right")
    
    img.save(os.path.join(ASSETS_DIR, "frame_avatar_box.png"))

# 3. Terracotta Banner Title Pill (for hero name badge, 9-sliceable 48x24)
def make_banner_title_pill():
    w, h = 48, 24
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Rounded terracotta pill
    d.rounded_rectangle([0, 0, w-1, h-1], radius=6, outline=C_BANNER_DARK, fill=C_BANNER_MID)
    d.rounded_rectangle([1, 1, w-2, h-2], radius=5, outline=C_BANNER_LIGHT)
    d.rounded_rectangle([2, 3, w-3, h-3], radius=4, fill=C_BANNER_MID)
    
    # Gold decorative side dots
    d.point((4, 11), fill=C_GOLD_SHINE)
    d.point((4, 12), fill=C_GOLD_MID)
    d.point((w-5, 11), fill=C_GOLD_SHINE)
    d.point((w-5, 12), fill=C_GOLD_MID)
    
    img.save(os.path.join(ASSETS_DIR, "banner_title_pill.png"))

# 4. Wooden Button & States (48x48)
def make_wood_buttons():
    w, h = 48, 48
    states = [
        ("button_wood.png", C_WOOD_MID, C_WOOD_LIGHT, C_WOOD_DARK, C_PARCH_LIGHT, 0),
        ("button_wood_hover.png", C_WOOD_LIGHT, C_GOLD_LIGHT, C_WOOD_MID, (255, 245, 230, 255), 0),
        ("button_wood_pressed.png", C_WOOD_DARK, C_WOOD_DARK, C_WOOD_MID, (230, 205, 175, 255), 1),
    ]
    for filename, base_c, top_c, bot_c, center_c, y_off in states:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        
        d.rectangle([0, 0, w-1, h-1], outline=C_DARK_OUTLINE, fill=base_c)
        d.rectangle([1, 1, w-2, 2], fill=top_c)
        d.rectangle([1, 1, 2, h-2], fill=top_c)
        d.rectangle([w-3, 1, w-2, h-2], fill=bot_c)
        d.rectangle([1, h-3, w-2, h-2], fill=bot_c)
        
        # Center parchment pad
        d.rectangle([4, 4 + y_off, w-5, h-5 + y_off], outline=C_DARK_OUTLINE, fill=center_c)
        
        # Gold corner accents
        d.rectangle([0, 0, 3, 3], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
        d.rectangle([w-4, 0, w-1, 3], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
        d.rectangle([0, h-4, 3, h-1], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
        d.rectangle([w-4, h-4, w-1, h-1], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
        
        d.point((1, 1), fill=C_GOLD_SHINE)
        d.point((w-2, 1), fill=C_GOLD_SHINE)
        d.point((1, h-2), fill=C_GOLD_SHINE)
        d.point((w-2, h-2), fill=C_GOLD_SHINE)
        
        img.save(os.path.join(ASSETS_DIR, filename))

# 5. Royal Gold / Crimson Button (for "MULAI PERANG", 48x48)
def make_gold_buttons():
    w, h = 48, 48
    states = [
        ("button_gold.png", C_GOLD_MID, C_GOLD_LIGHT, C_GOLD_DARK, (200, 35, 35, 255), (235, 55, 55, 255), 0),
        ("button_gold_hover.png", C_GOLD_LIGHT, C_GOLD_SHINE, C_GOLD_MID, (230, 45, 45, 255), (255, 80, 80, 255), 0),
        ("button_gold_pressed.png", C_GOLD_DARK, C_GOLD_MID, C_GOLD_DARK, (160, 20, 20, 255), (140, 15, 15, 255), 1),
    ]
    for filename, border_base, border_top, border_bot, fill_c, top_c, y_off in states:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        
        d.rectangle([0, 0, w-1, h-1], outline=C_DARK_OUTLINE, fill=border_base)
        d.rectangle([1, 1, w-2, 2], fill=border_top)
        d.rectangle([1, 1, 2, h-2], fill=border_top)
        d.rectangle([w-3, 1, w-2, h-2], fill=border_bot)
        d.rectangle([1, h-3, w-2, h-2], fill=border_bot)
        
        # Center red banner
        d.rectangle([4, 4 + y_off, w-5, h-5 + y_off], outline=C_DARK_OUTLINE, fill=fill_c)
        d.rectangle([5, 5 + y_off, w-6, 6 + y_off], fill=top_c)
        
        # Corner gold studs
        d.point((1, 1), fill=C_GOLD_SHINE)
        d.point((w-2, 1), fill=C_GOLD_SHINE)
        d.point((1, h-2), fill=C_GOLD_SHINE)
        d.point((w-2, h-2), fill=C_GOLD_SHINE)
        
        img.save(os.path.join(ASSETS_DIR, filename))

# 6. Tubular Crystal Capsule (for Ultimate / Mana, 9-sliceable 64x24)
def make_capsule_tubes():
    w, h = 64, 24
    tubes = [
        ("capsule_tube_gold.png", (220, 150, 30, 255), (255, 215, 90, 255), (140, 85, 10, 255)),
        ("capsule_tube_blue.png", (25, 140, 240, 255), (110, 215, 255, 255), (10, 70, 150, 255)),
        ("capsule_tube_red.png", (225, 45, 45, 255), (255, 120, 120, 255), (135, 15, 15, 255)),
        ("capsule_tube_green.png", (45, 185, 75, 255), (120, 245, 150, 255), (20, 110, 40, 255)),
        ("capsule_tube_bg.png", (45, 28, 18, 255), (75, 48, 32, 255), (25, 15, 10, 255)),
    ]
    for filename, core_c, high_c, shad_c in tubes:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        
        # Outer bronze/wood casing
        d.rounded_rectangle([0, 0, w-1, h-1], radius=7, outline=C_DARK_OUTLINE, fill=C_WOOD_MID)
        d.rounded_rectangle([1, 1, w-2, h-2], radius=6, fill=C_WOOD_DARK)
        
        # Inner crystal cavity
        d.rounded_rectangle([4, 3, w-5, h-4], radius=5, outline=C_DARK_OUTLINE, fill=core_c)
        # Deep shadow
        d.rectangle([5, h-6, w-6, h-4], fill=shad_c)
        # Specular light gleam across top
        d.rectangle([6, 4, w-7, 6], fill=high_c)
        d.point((7, 5), fill=(255, 255, 255, 255))
        d.point((8, 5), fill=(255, 255, 255, 255))
        
        # Gold end collars
        d.rectangle([1, 2, 4, h-3], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
        d.rectangle([w-5, 2, w-2, h-3], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
        d.point((2, 3), fill=C_GOLD_SHINE)
        d.point((w-3, 3), fill=C_GOLD_SHINE)
        
        img.save(os.path.join(ASSETS_DIR, filename))

# 7. Pill Badge (for counters, FPS, time, 9-sliceable 48x24)
def make_pill_badge():
    w, h = 48, 24
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Outer dark outline
    d.rounded_rectangle([0, 0, w-1, h-1], radius=6, outline=C_DARK_OUTLINE, fill=C_WOOD_MID)
    # Inner cream parchment
    d.rounded_rectangle([2, 2, w-3, h-3], radius=5, outline=C_DARK_OUTLINE, fill=C_PARCH_LIGHT)
    # Soft inner border
    d.rounded_rectangle([4, 4, w-5, h-5], radius=3, outline=C_PARCH_DARK)
    
    # Left & Right brass rivets
    d.point((3, 3), fill=C_GOLD_SHINE)
    d.point((w-4, 3), fill=C_GOLD_SHINE)
    d.point((3, h-4), fill=C_GOLD_SHINE)
    d.point((w-4, h-4), fill=C_GOLD_SHINE)
    
    img.save(os.path.join(ASSETS_DIR, "pill_badge.png"))

# 8. Slender Pixel Bars (HP, AP, EXP)
def make_thin_bars():
    w, h = 48, 12
    # 8a. Groove Under
    groove = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(groove)
    d.rectangle([0, 2, w-1, h-3], outline=C_DARK_OUTLINE, fill=(40, 24, 15, 255))
    d.rectangle([1, 3, w-2, h-4], fill=(25, 14, 8, 255))
    # Brass end knobs
    d.rectangle([0, 0, 3, h-1], outline=C_DARK_OUTLINE, fill=C_GOLD_MID)
    d.rectangle([w-4, 0, w-1, h-1], outline=C_DARK_OUTLINE, fill=C_GOLD_MID)
    d.point((1, 2), fill=C_GOLD_SHINE)
    d.point((w-3, 2), fill=C_GOLD_SHINE)
    groove.save(os.path.join(ASSETS_DIR, "bar_groove.png"))
    
    # 8b. Progress fills
    bars = [
        ("bar_green.png", (50, 195, 80, 255), (20, 120, 45, 255), (135, 245, 160, 255)),
        ("bar_blue.png", (35, 145, 245, 255), (15, 75, 165, 255), (130, 220, 255, 255)),
        ("bar_orange.png", (240, 140, 30, 255), (160, 75, 10, 255), (255, 215, 110, 255)),
    ]
    for fname, mid_c, bot_c, top_c in bars:
        img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        d.rectangle([1, 3, w-2, h-4], outline=C_DARK_OUTLINE, fill=mid_c)
        d.rectangle([1, 3, w-2, 4], fill=top_c)
        d.rectangle([1, h-4, w-2, h-4], fill=bot_c)
        # End pin knob
        d.rectangle([w-4, 1, w-1, h-2], outline=C_DARK_OUTLINE, fill=C_GOLD_SHINE)
        img.save(os.path.join(ASSETS_DIR, fname))

# 9. Button Pedestal Plinth (Middle row style in user reference)
def make_plinth():
    w, h = 64, 20
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Carved wooden pedestal plinth
    # Bottom tier
    d.rectangle([2, 10, w-3, h-1], outline=C_DARK_OUTLINE, fill=C_WOOD_DARK)
    d.rectangle([4, 11, w-5, 13], fill=C_WOOD_LIGHT)
    # Middle stepped ridge
    d.rectangle([6, 4, w-7, 10], outline=C_DARK_OUTLINE, fill=C_WOOD_MID)
    d.rectangle([7, 5, w-8, 6], fill=C_WOOD_LIGHT)
    # Metal side brackets
    d.rectangle([3, 4, 8, 14], outline=C_DARK_OUTLINE, fill=C_GOLD_MID)
    d.rectangle([w-9, 4, w-4, 14], outline=C_DARK_OUTLINE, fill=C_GOLD_MID)
    d.point((5, 6), fill=C_GOLD_SHINE)
    d.point((w-7, 6), fill=C_GOLD_SHINE)
    
    img.save(os.path.join(ASSETS_DIR, "pedestal_plinth.png"))

# 10. Pixel Art Icons & Avatars
def make_pixel_icons():
    # 10a. Avatar A: Detailed Viking Commander with Sunglasses & Cigar (64x64)
    av_a = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(av_a)
    # Background warm cream
    d.rectangle([0, 0, 63, 63], fill=(245, 230, 205, 255))
    
    # Hair / Undercut
    d.rectangle([18, 8, 44, 17], fill=(225, 105, 40, 255))
    d.rectangle([20, 6, 38, 10], fill=(245, 140, 65, 255))
    
    # Face skin
    d.rectangle([18, 17, 44, 34], fill=(255, 195, 155, 255))
    # Ear
    d.rectangle([14, 23, 18, 30], fill=(240, 170, 135, 255))
    # Sunglasses (Dark purple-black with cool specular shine)
    d.rectangle([16, 21, 46, 28], outline=C_DARK_OUTLINE, fill=(40, 30, 55, 255))
    d.rectangle([20, 22, 29, 26], fill=(120, 80, 175, 255))
    d.rectangle([33, 22, 43, 26], fill=(120, 80, 175, 255))
    d.rectangle([22, 22, 24, 24], fill=(235, 220, 255, 255)) # shine
    d.rectangle([35, 22, 37, 24], fill=(235, 220, 255, 255))
    
    # Big Beard (Vibrant red/orange)
    d.rectangle([16, 32, 47, 50], fill=(225, 105, 40, 255))
    d.rectangle([19, 50, 43, 56], fill=(195, 80, 25, 255))
    d.rectangle([22, 56, 39, 59], fill=(160, 60, 15, 255))
    
    # Grinning Teeth
    d.rectangle([26, 33, 36, 36], fill=(255, 255, 255, 255), outline=C_DARK_OUTLINE)
    # Cigar sticking out of mouth
    d.rectangle([36, 34, 48, 37], fill=(245, 245, 240, 255), outline=C_DARK_OUTLINE)
    d.point((48, 35), fill=(255, 75, 25, 255)) # burning ember
    d.point((47, 35), fill=(255, 160, 30, 255))
    # Smoke puffs
    d.point((51, 33), fill=(210, 210, 220, 200))
    d.point((53, 31), fill=(190, 190, 205, 160))
    
    # Shoulders / Blue Armor & Suspenders
    d.rectangle([12, 52, 52, 63], fill=(70, 130, 180, 255), outline=C_DARK_OUTLINE)
    d.rectangle([24, 52, 29, 63], fill=(185, 120, 50, 255)) # suspender left
    d.rectangle([35, 52, 40, 63], fill=(185, 120, 50, 255)) # suspender right
    
    # Outer frame
    d.rectangle([0, 0, 63, 63], outline=C_DARK_OUTLINE)
    draw_brass_bracket(d, 0, 0, 6, "top_left")
    draw_brass_bracket(d, 63, 0, 6, "top_right")
    draw_brass_bracket(d, 0, 63, 6, "bottom_left")
    draw_brass_bracket(d, 63, 63, 6, "bottom_right")
    av_a.save(os.path.join(ICONS_DIR, "avatar_a.png"))
    
    # 10b. Avatar B: Detailed Cyber Mecha Enforcer (64x64)
    av_b = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(av_b)
    # Background cool grey/cyan
    d.rectangle([0, 0, 63, 63], fill=(215, 230, 240, 255))
    
    # Mecha Helmet
    d.rectangle([16, 12, 47, 44], outline=C_DARK_OUTLINE, fill=(65, 85, 110, 255))
    d.rectangle([20, 8, 43, 14], fill=(105, 130, 160, 255))
    
    # Ear Antennas
    d.rectangle([11, 18, 15, 36], outline=C_DARK_OUTLINE, fill=(150, 165, 185, 255))
    d.rectangle([48, 18, 52, 36], outline=C_DARK_OUTLINE, fill=(150, 165, 185, 255))
    d.point((13, 19), fill=(0, 220, 255, 255))
    d.point((50, 19), fill=(0, 220, 255, 255))
    
    # Cyan Glowing Visor
    d.rectangle([18, 22, 45, 30], outline=C_DARK_OUTLINE, fill=(0, 200, 255, 255))
    d.rectangle([21, 23, 31, 26], fill=(210, 250, 255, 255)) # reflection
    
    # Grille / Mouth Vent
    for gy in [34, 37, 40]:
        d.line([(22, gy), (41, gy)], fill=(35, 45, 60, 255), width=2)
        
    # Heavy Chest Armor
    d.rectangle([12, 46, 51, 63], outline=C_DARK_OUTLINE, fill=(45, 65, 85, 255))
    d.rectangle([26, 48, 37, 56], fill=(0, 200, 255, 255)) # chest power core
    d.rectangle([28, 50, 35, 54], fill=(220, 255, 255, 255))
    
    d.rectangle([0, 0, 63, 63], outline=C_DARK_OUTLINE)
    draw_brass_bracket(d, 0, 0, 6, "top_left")
    draw_brass_bracket(d, 63, 0, 6, "top_right")
    draw_brass_bracket(d, 0, 63, 6, "bottom_left")
    draw_brass_bracket(d, 63, 63, 6, "bottom_right")
    av_b.save(os.path.join(ICONS_DIR, "avatar_b.png"))

    # 10c. Crossed Swords (36x36)
    swords = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(swords)
    for i in range(20):
        x, y = 8 + i, 28 - i
        d.point((x, y), fill=(240, 245, 255, 255))
        d.point((x+1, y), fill=(170, 185, 205, 255))
    for i in range(20):
        x, y = 27 - i, 28 - i
        d.point((x, y), fill=(240, 245, 255, 255))
        d.point((x+1, y), fill=(170, 185, 205, 255))
    d.rectangle([5, 27, 10, 32], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
    d.rectangle([25, 27, 30, 32], fill=C_GOLD_MID, outline=C_DARK_OUTLINE)
    swords.save(os.path.join(ICONS_DIR, "icon_swords.png"))

    # 10d. Backpack Satchel (36x36)
    bag = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(bag)
    d.rectangle([6, 9, 29, 29], outline=C_DARK_OUTLINE, fill=(165, 105, 55, 255))
    d.rectangle([8, 11, 27, 16], fill=(130, 80, 40, 255))
    d.rectangle([16, 13, 19, 18], fill=C_GOLD_SHINE, outline=C_GOLD_DARK)
    d.rectangle([9, 20, 26, 27], outline=C_DARK_OUTLINE, fill=(185, 120, 65, 255))
    bag.save(os.path.join(ICONS_DIR, "icon_backpack.png"))

    # 10e. Quest Scroll (36x36)
    scroll = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(scroll)
    d.rectangle([8, 6, 27, 30], outline=C_DARK_OUTLINE, fill=C_PARCH_LIGHT)
    d.line([(12, 11), (23, 11)], fill=(160, 130, 95, 255), width=2)
    d.line([(12, 16), (23, 16)], fill=(160, 130, 95, 255), width=2)
    d.line([(12, 21), (20, 21)], fill=(160, 130, 95, 255), width=2)
    d.rectangle([15, 24, 20, 29], outline=C_DARK_OUTLINE, fill=(210, 40, 40, 255)) # wax seal
    scroll.save(os.path.join(ICONS_DIR, "icon_scroll.png"))

    # 10f. Island / Map (36x36 - matches map icon in reference image)
    map_img = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(map_img)
    # Ocean blue background
    d.rectangle([5, 5, 30, 30], outline=C_DARK_OUTLINE, fill=(45, 150, 225, 255))
    # Green Island
    d.polygon([(10, 14), (16, 10), (26, 12), (28, 22), (22, 27), (12, 25)], fill=(65, 185, 75, 255))
    d.polygon([(13, 16), (18, 13), (24, 15), (25, 20), (20, 23), (14, 22)], fill=(115, 220, 105, 255))
    # Sand beach border
    d.point((10, 25), fill=(245, 220, 140, 255))
    d.point((27, 22), fill=(245, 220, 140, 255))
    # Red Pin
    d.ellipse([17, 14, 21, 18], fill=(235, 45, 45, 255), outline=C_DARK_OUTLINE)
    d.point((19, 19), fill=C_DARK_OUTLINE)
    # Gold corners
    d.point((5, 5), fill=C_GOLD_SHINE)
    d.point((30, 5), fill=C_GOLD_SHINE)
    d.point((5, 30), fill=C_GOLD_SHINE)
    d.point((30, 30), fill=C_GOLD_SHINE)
    map_img.save(os.path.join(ICONS_DIR, "icon_map.png"))

    # 10g. Market Stall / Shop (36x36 - matches shop icon in reference image)
    shop = Image.new("RGBA", (36, 36), (0, 0, 0, 0))
    d = ImageDraw.Draw(shop)
    # Red-white striped awning
    d.rectangle([6, 7, 29, 14], outline=C_DARK_OUTLINE, fill=(230, 50, 50, 255))
    for sx in [10, 11, 16, 17, 22, 23, 28]:
        d.line([(sx, 8), (sx, 14)], fill=(255, 255, 255, 255))
    # Wooden counter & poles
    d.line([(7, 14), (7, 28)], fill=C_WOOD_DARK, width=2)
    d.line([(28, 14), (28, 28)], fill=C_WOOD_DARK, width=2)
    d.rectangle([8, 20, 27, 29], outline=C_DARK_OUTLINE, fill=(155, 95, 50, 255))
    # Produce on counter
    d.rectangle([10, 18, 14, 21], fill=(245, 170, 40, 255)) # oranges
    d.rectangle([16, 18, 20, 21], fill=(225, 45, 45, 255))  # apples
    d.rectangle([22, 18, 25, 21], fill=(70, 190, 60, 255))  # melons
    shop.save(os.path.join(ICONS_DIR, "icon_shop.png"))

    # 10h. Coin Medallion (32x32)
    coin = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(coin)
    d.ellipse([1, 1, 30, 30], fill=C_GOLD_DARK, outline=C_DARK_OUTLINE)
    d.ellipse([3, 3, 28, 28], fill=C_GOLD_LIGHT)
    d.ellipse([5, 5, 26, 26], fill=C_GOLD_MID)
    # Embossed 'G'
    d.rectangle([10, 9, 21, 12], fill=C_GOLD_SHINE)
    d.rectangle([10, 12, 13, 22], fill=C_GOLD_SHINE)
    d.rectangle([10, 20, 21, 23], fill=C_GOLD_SHINE)
    d.rectangle([18, 15, 21, 21], fill=C_GOLD_SHINE)
    d.rectangle([15, 15, 19, 18], fill=C_GOLD_SHINE)
    coin.save(os.path.join(ICONS_DIR, "icon_coin.png"))

    # 10i. Diamond Gem Medallion (32x32)
    gem = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(gem)
    d.polygon([(8, 8), (23, 8), (30, 15), (15, 30), (1, 15)], fill=(15, 95, 190, 255), outline=C_DARK_OUTLINE)
    d.polygon([(9, 9), (22, 9), (27, 14), (15, 14)], fill=(120, 210, 255, 255))
    d.polygon([(9, 9), (15, 14), (8, 15), (3, 15)], fill=(65, 165, 245, 255))
    d.polygon([(15, 14), (27, 14), (15, 28)], fill=(30, 130, 235, 255))
    d.point((11, 11), fill=(255, 255, 255, 255))
    gem.save(os.path.join(ICONS_DIR, "icon_gem.png"))

    # 10j. Retro Alarm Clock Medallion (32x32)
    clock = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(clock)
    d.arc([3, 1, 11, 8], 180, 360, fill=(215, 60, 35, 255), width=3)
    d.arc([20, 1, 28, 8], 180, 360, fill=(215, 60, 35, 255), width=3)
    d.ellipse([2, 5, 29, 31], fill=(215, 60, 35, 255), outline=C_DARK_OUTLINE)
    d.ellipse([6, 9, 25, 27], fill=(255, 250, 240, 255), outline=(160, 40, 20, 255))
    d.line([(15, 18), (15, 12)], fill=C_DARK_OUTLINE, width=2)
    d.line([(15, 18), (21, 18)], fill=C_DARK_OUTLINE, width=2)
    d.point((15, 18), fill=(215, 60, 35, 255))
    d.point((5, 30), fill=C_DARK_OUTLINE)
    d.point((26, 30), fill=C_DARK_OUTLINE)
    clock.save(os.path.join(ICONS_DIR, "icon_clock.png"))

if __name__ == "__main__":
    make_frame_parchment()
    make_frame_avatar_box()
    make_banner_title_pill()
    make_wood_buttons()
    make_gold_buttons()
    make_capsule_tubes()
    make_pill_badge()
    make_thin_bars()
    make_plinth()
    make_pixel_icons()
    print("Successfully generated all enhanced pixel UI assets!")
