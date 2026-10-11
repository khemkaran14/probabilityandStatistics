"""Draw the Chance app icon and splash logo, and write every platform size.

Usage:  python3 tool/make_icons.py   (needs Pillow: pip install pillow)

The icon is a Galton-board histogram: five white bars in a bell shape under a
falling yellow ball, on a pink-to-violet gradient.
"""
import pathlib

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
PINK = (255, 61, 139)
VIOLET = (155, 92, 255)
YELLOW = (255, 201, 60)
WHITE = (255, 255, 255)
CREAM = (255, 249, 242)
SS = 4  # supersampling factor for smooth edges


def gradient(size):
    """Diagonal pink (top left) to violet (bottom right)."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(PINK, VIOLET))
    return img


def motif(size, scale, bar=WHITE, ball=YELLOW):
    """Transparent layer with the bars and ball, filling `scale` of the canvas."""
    big = size * SS
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    box = big * scale
    x0 = (big - box) / 2
    y0 = (big - box) / 2
    heights = [0.26, 0.55, 0.78, 0.55, 0.26]
    gap = box * 0.05
    bw = (box - gap * 4) / 5
    base = y0 + box
    radius = bw * 0.28
    for i, h in enumerate(heights):
        bx = x0 + i * (bw + gap)
        d.rounded_rectangle([bx, base - box * h, bx + bw, base], radius=radius, fill=bar)
    r = bw * 0.42
    cx = big / 2
    cy = y0 + r
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ball)
    return layer.resize((size, size), Image.LANCZOS)


def full_icon(size, rounded=False):
    """Opaque square icon (iOS, web) or rounded-corner icon (legacy Android)."""
    img = gradient(size).convert("RGBA")
    img.alpha_composite(motif(size, 0.58))
    if rounded:
        mask = Image.new("L", (size * SS, size * SS), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, size * SS - 1, size * SS - 1], radius=size * SS * 0.22, fill=255)
        img.putalpha(mask.resize((size, size), Image.LANCZOS))
    return img


def save(img, path):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def android():
    res = "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for name, f in densities.items():
        save(full_icon(round(48 * f), rounded=True), f"{res}/mipmap-{name}/ic_launcher.png")
        # Adaptive icon layers are 108 dp; the motif stays inside the 66 dp safe zone.
        s = round(108 * f)
        save(gradient(s), f"{res}/mipmap-{name}/ic_launcher_background.png")
        save(motif(s, 0.46), f"{res}/mipmap-{name}/ic_launcher_foreground.png")
        save(motif(s, 0.46, bar=WHITE, ball=WHITE), f"{res}/mipmap-{name}/ic_launcher_monochrome.png")
        # Notification icon: white silhouette on transparent, 24 dp.
        save(motif(round(24 * f), 0.86, bar=WHITE, ball=WHITE), f"{res}/drawable-{name}/ic_notification.png")
        # Splash logo for Android 11 and older (Android 12+ shows the adaptive icon).
        save(full_icon(round(96 * f), rounded=True), f"{res}/drawable-{name}/splash_logo.png")


def ios():
    folder = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    sizes = {
        "20x20@1x": 20, "20x20@2x": 40, "20x20@3x": 60,
        "29x29@1x": 29, "29x29@2x": 58, "29x29@3x": 87,
        "40x40@1x": 40, "40x40@2x": 80, "40x40@3x": 120,
        "60x60@2x": 120, "60x60@3x": 180,
        "76x76@1x": 76, "76x76@2x": 152, "83.5x83.5@2x": 167,
        "1024x1024@1x": 1024,
    }
    for name, px in sizes.items():
        save(full_icon(px).convert("RGB"), f"{folder}/Icon-App-{name}.png")  # App Store rejects alpha
    launch = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    for suffix, f in {"": 1, "@2x": 2, "@3x": 3}.items():
        save(full_icon(96 * f, rounded=True), f"{launch}/LaunchImage{suffix}.png")


def web():
    save(full_icon(32, rounded=True), "web/favicon.png")
    for s in (192, 512):
        save(full_icon(s, rounded=True), f"web/icons/Icon-{s}.png")
        # Maskable icons may be cropped to a circle: keep the motif small, background full.
        img = gradient(s).convert("RGBA")
        img.alpha_composite(motif(s, 0.46))
        save(img, f"web/icons/Icon-maskable-{s}.png")


def _font(size):
    """A bold sans font if one is installed, else Pillow's default."""
    from PIL import ImageFont

    for name in ("InterDisplay-Bold.otf", "Inter-Bold.otf", "DejaVuSans-Bold.ttf", "Arial Bold.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            for folder in ("/usr/share/fonts/opentype/inter", "/usr/share/fonts/truetype/dejavu", "/Library/Fonts"):
                try:
                    return ImageFont.truetype(f"{folder}/{name}", size)
                except OSError:
                    pass
    return ImageFont.load_default(size=size)


def feature_graphic():
    """Play Store feature graphic, 1024 × 500."""
    w, h = 1024, 500
    img = Image.new("RGBA", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / (w - 1)) * 0.8 + (y / (h - 1)) * 0.2
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(PINK, VIOLET)) + (255,)
    img.alpha_composite(motif(380, 0.62), (600, 70))
    d = ImageDraw.Draw(img)
    d.text((64, 120), "Chance", font=_font(104), fill=WHITE)
    d.text((68, 262), "Probability & statistics,", font=_font(40), fill=WHITE)
    d.text((68, 314), "animated.", font=_font(40), fill=YELLOW)
    d.text((68, 392), "90 lessons you can play with", font=_font(26), fill=CREAM)
    save(img.convert("RGB"), "docs/store/feature-graphic.png")


def store():
    save(full_icon(512).convert("RGB"), "docs/store/icon-512.png")
    feature_graphic()


if __name__ == "__main__":
    android()
    ios()
    web()
    store()
    print("Icons written.")
