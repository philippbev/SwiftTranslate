#!/usr/bin/env python3
"""
Generates a 1024x1024 iOS app icon for "Saarland Rechner".
Design:
  - #003B6F solid background
  - White filled Saarland-shaped polygon, centered (580x580 footprint)
  - Dark blue bold '×' symbol centered on the polygon
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# Canvas size
SIZE = 1024
OUTPUT_PATH = "/tmp/AppIcon.png"

# Colors
BG_COLOR = "#003B6F"
WHITE = (255, 255, 255, 255)
DARK_BLUE = (0, 59, 111, 255)

# Create image with RGBA for clean rendering, then convert to RGB
img = Image.new("RGBA", (SIZE, SIZE), BG_COLOR)
draw = ImageDraw.Draw(img)

# --- Saarland polygon ---
# Normalized points (0..1), scaled to 580x580 box
POLY_NORM = [
    (0.30, 0.10),
    (0.50, 0.05),
    (0.72, 0.12),
    (0.85, 0.28),
    (0.88, 0.48),
    (0.82, 0.62),
    (0.68, 0.75),
    (0.52, 0.82),
    (0.35, 0.80),
    (0.20, 0.68),
    (0.12, 0.52),
    (0.15, 0.32),
    (0.22, 0.18),
]

POLY_SIZE = 580
X_OFFSET = (SIZE - POLY_SIZE) / 2        # 222
Y_OFFSET = (SIZE - POLY_SIZE) / 2 - 30  # 192  — slightly above center

poly_points = [
    (
        x * POLY_SIZE + X_OFFSET,
        y * POLY_SIZE + Y_OFFSET,
    )
    for x, y in POLY_NORM
]

# Draw Saarland shape with a slight drop-shadow effect for depth
# Shadow (dark, semi-transparent, offset)
shadow_offset = 12
shadow_pts = [(px + shadow_offset, py + shadow_offset) for px, py in poly_points]
shadow_color = (0, 0, 0, 80)
draw.polygon(shadow_pts, fill=shadow_color)

# Main white shape
draw.polygon(poly_points, fill=WHITE)

# Optional: subtle inner highlight border on the polygon
draw.polygon(poly_points, outline=(255, 255, 255, 180), width=4)

# --- Compute bounding box center of the polygon for the × symbol ---
xs = [p[0] for p in poly_points]
ys = [p[1] for p in poly_points]
cx = (min(xs) + max(xs)) / 2
cy = (min(ys) + max(ys)) / 2

# --- Draw '×' symbol centered on the polygon ---
# We draw the × as two rotated thick rounded rectangles (line caps give round ends)
# Stroke width proportional to icon size
LINE_W = 28       # thickness of each arm
ARM_LEN = 110     # half-length of each arm (total arm span ~220px)
ANGLE = 45        # degrees

def draw_rounded_line(draw_obj, x0, y0, x1, y1, width, fill):
    """Draw a thick line with round caps using a polygon approximation."""
    dx = x1 - x0
    dy = y1 - y0
    length = math.hypot(dx, dy)
    if length == 0:
        return
    # Unit perpendicular
    ux = -dy / length
    uy = dx / length
    hw = width / 2
    # Four corners of the rectangle
    pts = [
        (x0 + ux * hw, y0 + uy * hw),
        (x1 + ux * hw, y1 + uy * hw),
        (x1 - ux * hw, y1 - uy * hw),
        (x0 - ux * hw, y0 - uy * hw),
    ]
    draw_obj.polygon(pts, fill=fill)
    # Round caps
    draw_obj.ellipse(
        [x0 - hw, y0 - hw, x0 + hw, y0 + hw], fill=fill
    )
    draw_obj.ellipse(
        [x1 - hw, y1 - hw, x1 + hw, y1 + hw], fill=fill
    )

# Arm 1: top-left to bottom-right (45°)
ang1 = math.radians(45)
x1s = cx - ARM_LEN * math.cos(ang1)
y1s = cy - ARM_LEN * math.sin(ang1)
x1e = cx + ARM_LEN * math.cos(ang1)
y1e = cy + ARM_LEN * math.sin(ang1)
draw_rounded_line(draw, x1s, y1s, x1e, y1e, LINE_W, DARK_BLUE)

# Arm 2: top-right to bottom-left (135°)
ang2 = math.radians(135)
x2s = cx - ARM_LEN * math.cos(ang2)
y2s = cy - ARM_LEN * math.sin(ang2)
x2e = cx + ARM_LEN * math.cos(ang2)
y2e = cy + ARM_LEN * math.sin(ang2)
draw_rounded_line(draw, x2s, y2s, x2e, y2e, LINE_W, DARK_BLUE)

# --- Add "Saarland Rechner" branding text at the bottom ---
# Try to use a bold system font; fall back to default
FONT_PATH_CANDIDATES = [
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/SFNSDisplay.ttf",
    "/System/Library/Fonts/SFNSText.ttf",
    "/Library/Fonts/Arial Bold.ttf",
    "/Library/Fonts/Arial.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
]

font_small = None
for fp in FONT_PATH_CANDIDATES:
    if os.path.exists(fp):
        try:
            font_small = ImageFont.truetype(fp, size=52)
            break
        except Exception:
            continue

if font_small is None:
    font_small = ImageFont.load_default()

# Draw "SAARLAND RECHNER" at the bottom, white, centered
label = "SAARLAND RECHNER"
bbox = draw.textbbox((0, 0), label, font=font_small)
text_w = bbox[2] - bbox[0]
text_h = bbox[3] - bbox[1]
text_x = (SIZE - text_w) / 2
text_y = SIZE - text_h - 52  # 52px from bottom

draw.text((text_x, text_y), label, font=font_small, fill=WHITE)

# --- Save ---
# Flatten to RGB for PNG compatibility with iOS
final = Image.new("RGB", (SIZE, SIZE), BG_COLOR)
final.paste(img, mask=img.split()[3])
final.save(OUTPUT_PATH, "PNG", dpi=(72, 72))

print(f"Icon saved to {OUTPUT_PATH}")
print(f"Size: {final.size}")
