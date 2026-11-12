"""Génère les visuels de la fiche Google Play à partir de captures brutes.

Usage : python3 tool/make_store_assets.py <captures brutes> [fr-FR|en-US|es-ES]

Captures attendues (1080 px de large) : 1_home.png, 2_input.png,
3_solution.png, 4_error.png.
Sortie : fastlane/metadata/android/<langue>/images/
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
METADATA = os.path.join(ROOT, "fastlane", "metadata", "android")
ICON = os.path.join(ROOT, "assets", "icon")
FONT_BOLD = "/usr/share/fonts/opentype/inter/Inter-ExtraBold.otf"
FONT_MED = "/usr/share/fonts/opentype/inter/Inter-Medium.otf"

VIOLET, BLUE, CYAN = (124, 77, 255), (41, 121, 255), (0, 176, 255)

CAPTIONS = {
    "fr-FR": [
        ("1_home", "Résolvez votre cube 3×3", "Scannez, vérifiez, résolvez"),
        ("2_input", "Détection des couleurs",
         "Corrigez une case d'un simple toucher"),
        ("3_solution", "Guidé pas à pas", "Une flèche montre chaque mouvement"),
        ("4_error", "Erreurs détectées", "Couleur mal lue ou pièce manipulée"),
    ],
    "en-US": [
        ("1_home", "Solve your 3×3 cube", "Scan, check, solve"),
        ("2_input", "Colour detection", "Fix any square with a single tap"),
        ("3_solution", "Step-by-step guide", "An arrow shows every move"),
        ("4_error", "Errors detected", "Misread colour or tampered piece"),
    ],
    "es-ES": [
        ("1_home", "Resuelve tu cubo 3×3", "Escanea, verifica, resuelve"),
        ("2_input", "Detección de colores",
         "Corrige una casilla con un toque"),
        ("3_solution", "Guía paso a paso", "Una flecha muestra cada movimiento"),
        ("4_error", "Errores detectados", "Color mal leído o pieza manipulada"),
    ],
}

TAGLINE = {
    "fr-FR": ("Scannez votre cube 3×3,", "suivez le guide, il est résolu."),
    "en-US": ("Scan your 3×3 cube,", "follow the guide, it’s solved."),
    "es-ES": ("Escanea tu cubo 3×3,", "sigue la guía y quedará resuelto."),
}


def gradient(w, h):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x / w + y / h) / 2
            if t < 0.5:
                a, b, k = VIOLET, BLUE, t * 2
            else:
                a, b, k = BLUE, CYAN, (t - 0.5) * 2
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))
    return img


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, img.width, img.height), radius=radius, fill=255
    )
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def centered_text(draw, y, text, font, width, fill):
    w = draw.textlength(text, font=font)
    draw.text(((width - w) / 2, y), text, font=font, fill=fill)


def screenshot(raw_dir, name, title, subtitle):
    W, H = 1080, 1920
    canvas = gradient(W, H).convert("RGBA")
    d = ImageDraw.Draw(canvas)
    centered_text(d, 110, title, ImageFont.truetype(FONT_BOLD, 76), W, "white")
    centered_text(d, 215, subtitle, ImageFont.truetype(FONT_MED, 42), W,
                  (255, 255, 255, 230))

    shot = Image.open(os.path.join(raw_dir, name + ".png")).convert("RGB")
    scale = 1460 / shot.height
    shot = shot.resize((int(shot.width * scale), 1460), Image.LANCZOS)
    shot = rounded(shot, 48)
    x, y = (W - shot.width) // 2, 360

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, y + 20, x + shot.width, y + shot.height + 20), 48,
        fill=(20, 0, 60, 110),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    # Cadre blanc façon téléphone.
    frame = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        (x - 14, y - 14, x + shot.width + 14, y + shot.height + 14), 60,
        fill=(255, 255, 255, 255),
    )
    canvas.alpha_composite(frame)
    canvas.alpha_composite(shot, (x, y))
    return canvas.convert("RGB")


def feature_graphic(lang):
    W, H = 1024, 500
    canvas = gradient(W, H).convert("RGBA")
    cube = Image.open(os.path.join(ICON, "icon_foreground.png")).convert("RGBA")
    # Le cube occupe ~250 px au centre de l'image : on le centre en x = 830.
    cube = cube.resize((680, 680), Image.LANCZOS)
    canvas.alpha_composite(cube, (830 - 340, (H - 680) // 2))
    d = ImageDraw.Draw(canvas)
    d.text((64, 150), "Cube Solver", font=ImageFont.truetype(FONT_BOLD, 92),
           fill="white")
    line1, line2 = TAGLINE[lang]
    font = ImageFont.truetype(FONT_MED, 40)
    while d.textlength(line2, font=font) > 600:  # ne pas toucher le cube
        font = ImageFont.truetype(FONT_MED, font.size - 2)
    d.text((68, 275), line1, font=font, fill=(255, 255, 255, 235))
    d.text((68, 325), line2, font=font, fill=(255, 255, 255, 235))
    return canvas.convert("RGB")


def main():
    raw_dir = sys.argv[1]
    lang = sys.argv[2] if len(sys.argv) > 2 else "fr-FR"
    out = os.path.join(METADATA, lang, "images")
    phone = os.path.join(out, "phoneScreenshots")
    os.makedirs(phone, exist_ok=True)
    for i, (name, title, subtitle) in enumerate(CAPTIONS[lang], 1):
        screenshot(raw_dir, name, title, subtitle).save(
            os.path.join(phone, f"{i}_{name.split('_', 1)[1]}.png"))
    feature_graphic(lang).save(os.path.join(out, "featureGraphic.png"))
    Image.open(os.path.join(ICON, "icon.png")).convert("RGB").resize(
        (512, 512), Image.LANCZOS).save(os.path.join(out, "icon.png"))
    print("Visuels générés dans", os.path.abspath(out))


if __name__ == "__main__":
    main()
