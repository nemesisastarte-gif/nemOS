#!/usr/bin/env python3
"""Generate nemOS wallpapers using Pillow."""

import math
import random
from PIL import Image, ImageDraw, ImageFilter

WIDTH, HEIGHT = 1920, 1080
OUTPUT_DIR = "/home/z/my-project/nemOS/nemOS/nemOS-assets/wallpapers"


def hex_to_rgb(hex_color):
    """Convert hex color string to RGB tuple."""
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i : i + 2], 16) for i in (0, 2, 4))


def create_gradient(width, height, color_top, color_bottom):
    """Create a vertical gradient image."""
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    r1, g1, b1 = color_top
    r2, g2, b2 = color_bottom
    for y in range(height):
        ratio = y / (height - 1)
        r = int(r1 + (r2 - r1) * ratio)
        g = int(g1 + (g2 - g1) * ratio)
        b = int(b1 + (b2 - b1) * ratio)
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    return img


def create_multi_gradient(width, height, stops):
    """Create a vertical gradient with multiple color stops.
    stops: list of (position_0_to_1, (r, g, b))
    """
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    for y in range(height):
        ratio = y / (height - 1)
        # Find the two stops we're between
        for i in range(len(stops) - 1):
            pos0, col0 = stops[i]
            pos1, col1 = stops[i + 1]
            if pos0 <= ratio <= pos1:
                t = (ratio - pos0) / (pos1 - pos0) if pos1 != pos0 else 0
                r = int(col0[0] + (col1[0] - col0[0]) * t)
                g = int(col0[1] + (col1[1] - col0[1]) * t)
                b = int(col0[2] + (col1[2] - col0[2]) * t)
                draw.line([(0, y), (width, y)], fill=(r, g, b))
                break
    return img


def draw_hexagon_pattern(draw, width, height, size=80, opacity=25):
    """Draw a hexagon grid overlay."""
    h_spacing = size * 1.5
    v_spacing = size * math.sqrt(3)
    color = (255, 255, 255, opacity)  # ~10% opacity on 255 scale = 25

    rows = int(height / v_spacing) + 2
    cols = int(width / h_spacing) + 2

    for row in range(rows):
        for col in range(cols):
            cx = col * h_spacing
            cy = row * v_spacing + (col % 2) * (v_spacing / 2)
            points = []
            for i in range(6):
                angle = math.radians(60 * i - 30)
                px = cx + size * 0.5 * math.cos(angle)
                py = cy + size * 0.5 * math.sin(angle)
                points.append((px, py))
            draw.polygon(points, outline=color)


def draw_n_logo(draw, cx, cy, scale, color=(255, 255, 255, 13)):
    """Draw the nemOS 'n' logo shape using lines.
    Very subtle watermark - ~5% opacity = 13 on 255 scale.
    """
    # Scale parameters
    half_w = scale * 0.45
    top_y = cy - scale * 0.5
    bot_y = cy + scale * 0.5
    left_x = cx - half_w
    right_x = cx + half_w
    thickness = max(int(scale * 0.06), 4)

    # Left vertical bar
    draw.line([(left_x, top_y), (left_x, bot_y)], fill=color, width=thickness)

    # Arc from top-left, going right then down (the curve of 'n')
    # We'll approximate the arc with line segments
    num_segments = 40
    arc_points = []
    for i in range(num_segments + 1):
        t = i / num_segments  # 0 to 1
        # Parametric arc: starts at top-left, arcs right, ends at bottom-right
        # Using a semicircular arc
        angle = math.pi * t  # 0 to pi
        px = left_x + (right_x - left_x) * t
        # Arc bulges to the right
        arc_x = px + scale * 0.08 * math.sin(angle)
        arc_y = top_y + (bot_y - top_y) * t
        arc_points.append((arc_x, arc_y))

    for i in range(len(arc_points) - 1):
        draw.line([arc_points[i], arc_points[i + 1]], fill=color, width=thickness)

    # Right vertical bar (just the bottom portion, since arc connects)
    # Actually for a clean 'n', the right bar goes from top to bottom
    draw.line([(right_x, top_y), (right_x, bot_y)], fill=color, width=thickness)


def generate_default():
    """1. nemos-default.png - gradient + hexagons + n watermark."""
    print("Generating nemos-default.png ...")
    img = create_gradient(WIDTH, HEIGHT, hex_to_rgb("#0A1628"), hex_to_rgb("#1A73E8"))

    # Add hexagon overlay
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw_hexagon_pattern(draw, WIDTH, HEIGHT, size=80, opacity=25)
    img.paste(Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB"))

    # Add 'n' watermark
    overlay2 = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw2 = ImageDraw.Draw(overlay2)
    draw_n_logo(draw2, WIDTH // 2, HEIGHT // 2, scale=400, color=(255, 255, 255, 13))
    final = Image.alpha_composite(img.convert("RGBA"), overlay2).convert("RGB")
    final.save(f"{OUTPUT_DIR}/nemos-default.png")
    print("  -> Saved nemos-default.png")


def generate_dark():
    """2. nemos-dark.png - near-black gradient + scattered stars."""
    print("Generating nemos-dark.png ...")
    img = create_gradient(WIDTH, HEIGHT, hex_to_rgb("#0A0F1A"), hex_to_rgb("#0D2137"))

    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    random.seed(42)
    for _ in range(300):
        x = random.randint(0, WIDTH - 1)
        y = random.randint(0, HEIGHT - 1)
        opacity = random.randint(15, 120)
        radius = random.choice([1, 1, 1, 2])
        draw.ellipse(
            [(x - radius, y - radius), (x + radius, y + radius)],
            fill=(255, 255, 255, opacity),
        )

    final = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    final.save(f"{OUTPUT_DIR}/nemos-dark.png")
    print("  -> Saved nemos-dark.png")


def generate_sunset():
    """3. nemos-sunset.png - navy to blue-purple with horizon glow."""
    print("Generating nemos-sunset.png ...")
    img = create_multi_gradient(
        WIDTH,
        HEIGHT,
        [
            (0.0, hex_to_rgb("#0A1628")),
            (0.5, hex_to_rgb("#2D1B69")),
            (1.0, hex_to_rgb("#1A3A6E")),
        ],
    )

    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Horizon glow at 70% height
    horizon_y = int(HEIGHT * 0.7)
    glow_height = 120
    for dy in range(-glow_height, glow_height + 1):
        y = horizon_y + dy
        if 0 <= y < HEIGHT:
            # Gaussian-like falloff
            dist = abs(dy) / glow_height
            intensity = int(40 * math.exp(-3 * dist * dist))
            draw.line([(0, y), (WIDTH, y)], fill=(100, 120, 255, intensity))

    # Bright thin horizon line
    draw.line([(0, horizon_y), (WIDTH, horizon_y)], fill=(120, 140, 255, 50), width=2)

    final = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    final.save(f"{OUTPUT_DIR}/nemos-sunset.png")
    print("  -> Saved nemos-sunset.png")


def generate_ocean():
    """4. nemos-ocean.png - dark blue gradient + sine wave lines."""
    print("Generating nemos-ocean.png ...")
    img = create_multi_gradient(
        WIDTH,
        HEIGHT,
        [
            (0.0, hex_to_rgb("#071426")),
            (0.5, hex_to_rgb("#0F3460")),
            (1.0, hex_to_rgb("#1A73E8")),
        ],
    )

    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Draw wavy sine lines
    num_waves = 12
    for i in range(num_waves):
        base_y = int(HEIGHT * 0.2 + (HEIGHT * 0.6) * (i / (num_waves - 1)))
        amplitude = 8 + i * 2
        frequency = 0.003 + i * 0.0005
        phase = i * 0.8
        opacity = 20 + i * 3

        points = []
        for x in range(0, WIDTH, 3):
            y = base_y + amplitude * math.sin(x * frequency + phase)
            points.append((x, y))

        for j in range(len(points) - 1):
            draw.line(
                [points[j], points[j + 1]],
                fill=(100, 180, 255, opacity),
                width=1,
            )

    final = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    final.save(f"{OUTPUT_DIR}/nemos-ocean.png")
    print("  -> Saved nemos-ocean.png")


def generate_minimal():
    """5. nemos-minimal.png - solid color + single angled line."""
    print("Generating nemos-minimal.png ...")
    img = Image.new("RGB", (WIDTH, HEIGHT), hex_to_rgb("#0F1629"))

    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Single thin angled line from bottom-left area to upper-right area
    # 30% opacity of #1A73E8 = (26, 115, 232, 77)
    draw.line(
        [(200, HEIGHT - 150), (WIDTH - 250, 200)],
        fill=(26, 115, 232, 77),
        width=2,
    )

    final = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    final.save(f"{OUTPUT_DIR}/nemos-minimal.png")
    print("  -> Saved nemos-minimal.png")


def main():
    print("=" * 50)
    print("nemOS Wallpaper Generator")
    print(f"Resolution: {WIDTH}x{HEIGHT}")
    print(f"Output: {OUTPUT_DIR}/")
    print("=" * 50)

    generate_default()
    generate_dark()
    generate_sunset()
    generate_ocean()
    generate_minimal()

    print("=" * 50)
    print("All wallpapers generated successfully!")
    print("=" * 50)


if __name__ == "__main__":
    main()