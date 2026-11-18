"""Generates the app icon for every platform. Run: python3 tool/make_icon.py"""
from PIL import Image, ImageDraw, ImageFilter

S = 2048  # draw at 2x, then downscale for smooth edges


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def icon(full_bleed=False):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # Background gradient
    grad = Image.new("RGBA", (S, S))
    gd = ImageDraw.Draw(grad)
    top, bottom = (58, 46, 130), (24, 22, 46)
    for y in range(S):
        gd.line([(0, y), (S, y)], fill=lerp(top, bottom, y / S) + (255,))
    mask = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(mask)
    # macOS icon grid: 824/1024 body with ~185 radius
    m = 0 if full_bleed else int(S * 100 / 1024)
    md.rounded_rectangle([m, m, S - m, S - m], radius=int((S - 2 * m) * 0.225), fill=255)
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    c, r, w = S / 2, S * 0.27, int(S * 0.06)
    box = [c - r, c - r, c + r, c + r]
    d.ellipse(box, outline=(85, 83, 107, 255), width=w)
    d.arc(box, start=-90, end=170, fill=(106, 92, 245, 255), width=w)
    # rounded caps
    import math
    for ang in (-90, 170):
        a = math.radians(ang)
        x, y = c + (r - w / 2) * math.cos(a), c + (r - w / 2) * math.sin(a)
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=(106, 92, 245, 255))
    # centre dot
    cr = S * 0.05
    d.ellipse([c - cr, c - cr, c + cr, c + cr], fill=(242, 241, 248, 255))
    return img.resize((1024, 1024), Image.LANCZOS)


mac = icon()
for s in (16, 32, 64, 128, 256, 512, 1024):
    mac.resize((s, s), Image.LANCZOS).save(
        f"macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{s}.png")
flat = icon(full_bleed=False)
flat.save("windows/runner/resources/app_icon.ico",
          sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
flat.resize((512, 512), Image.LANCZOS).save("assets/icon.png")
flat.resize((192, 192), Image.LANCZOS).save("web/icons/Icon-192.png")
flat.resize((512, 512), Image.LANCZOS).save("web/icons/Icon-512.png")
flat.resize((32, 32), Image.LANCZOS).save("web/favicon.png")
print("icons written")
