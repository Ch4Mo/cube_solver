"""Génère l'icône de l'application (assets/icon/*.png).

Usage : python3 tool/make_icon.py

Le cube est dessiné en perspective isométrique : chaque face est une texture
3×3 d'autocollants arrondis, projetée par transformation affine.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
SS = 4  # suréchantillonnage pour l'anticrénelage
S = 1024 * SS

WHITE, YELLOW = (250, 250, 247), (255, 214, 0)
GREEN, BLUE = (0, 176, 90), (20, 110, 235)
RED, ORANGE = (235, 40, 50), (255, 128, 0)


def gradient(size, top, bottom):
    """Dégradé diagonal (haut-gauche → bas-droite)."""
    g = Image.new("RGB", (size, size))
    px = g.load()
    for y in range(0, size, SS):
        for x in range(0, size, SS):
            t = (x + y) / (2 * size)
            c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
            for dy in range(SS):
                for dx in range(SS):
                    px[x + dx, y + dy] = c
    return g


def face_texture(colors, shade):
    """Texture carrée d'une face : 3×3 autocollants arrondis sur fond noir."""
    n = 900
    tex = Image.new("RGBA", (n, n), (18, 18, 22, 255))
    d = ImageDraw.Draw(tex)
    cell = n / 3
    gap = cell * 0.07
    for r in range(3):
        for c in range(3):
            col = tuple(int(v * shade) for v in colors[r][c])
            box = (
                c * cell + gap, r * cell + gap,
                (c + 1) * cell - gap, (r + 1) * cell - gap,
            )
            d.rounded_rectangle(box, radius=cell * 0.2, fill=col + (255,))
    return tex


def paste_face(canvas, tex, origin, ea, eb):
    """Projette `tex` sur le parallélogramme origin + u·ea + v·eb."""
    n = tex.size[0]
    # Sortie (X, Y) = O + (u/n)·ea + (v/n)·eb  → on inverse la matrice.
    a, b, c, d = ea[0] / n, eb[0] / n, ea[1] / n, eb[1] / n
    det = a * d - b * c
    ia, ib, ic, id_ = d / det, -b / det, -c / det, a / det
    ox, oy = origin
    coeffs = (ia, ib, -(ia * ox + ib * oy), ic, id_, -(ic * ox + id_ * oy))
    warped = tex.transform(canvas.size, Image.AFFINE, coeffs,
                           resample=Image.BICUBIC)
    canvas.alpha_composite(warped)


def draw_cube(canvas, cx, cy, edge, faces):
    """Cube isométrique centré en (cx, cy), arête projetée de longueur `edge`."""
    c30 = math.cos(math.pi / 6)
    right = (edge * c30, edge * 0.5)
    left = (-edge * c30, edge * 0.5)
    down = (0, edge)
    top = (cx, cy - edge)  # sommet arrière du dessus
    front = (cx, cy)  # coin avant-haut

    # Silhouette noire arrondie (corps du cube).
    sil = [
        (cx, cy - edge),
        (cx + right[0], cy - edge + right[1]),
        (cx + right[0], cy + right[1]),
        (cx, cy + edge),
        (cx + left[0], cy + left[1]),
        (cx + left[0], cy - edge + left[1]),
    ]
    body = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(body).polygon(sil, fill=(18, 18, 22, 255))
    canvas.alpha_composite(body)

    # Dessus : origine au coin arrière-gauche (sommet de l'image).
    paste_face(canvas, face_texture(faces["U"], 1.0), top, right, left)
    # Face avant (gauche de l'image) : origine au sommet gauche du dessus.
    paste_face(canvas, face_texture(faces["F"], 0.88),
               (cx + left[0], cy - left[1]), right, down)
    # Face droite : origine au coin avant-haut.
    paste_face(canvas, face_texture(faces["R"], 0.74),
               front, (-left[0], -left[1]), down)

def render(path, background, scale, shadow=True):
    if background is None:
        canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    else:
        canvas = background.convert("RGBA")
    edge = S * scale / 2
    cx, cy = S / 2, S / 2 + edge * 0.02

    if shadow:
        sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(sh).ellipse(
            (cx - edge * 0.95, cy + edge * 0.85,
             cx + edge * 0.95, cy + edge * 1.25),
            fill=(10, 0, 40, 120),
        )
        canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(S / 60)))

    faces = {
        "U": [[WHITE, WHITE, BLUE], [WHITE, WHITE, WHITE], [ORANGE, WHITE, WHITE]],
        "F": [[GREEN, GREEN, GREEN], [GREEN, GREEN, YELLOW], [GREEN, GREEN, GREEN]],
        "R": [[RED, RED, RED], [WHITE, RED, RED], [RED, RED, RED]],
    }
    draw_cube(canvas, cx, cy, edge, faces)
    canvas.resize((1024, 1024), Image.LANCZOS).save(path)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    bg = gradient(S, (124, 77, 255), (0, 176, 255))
    render(os.path.join(OUT, "icon.png"), bg, 0.62)
    # Premier plan de l'icône adaptative Android (zone sûre ≈ 66 %).
    render(os.path.join(OUT, "icon_foreground.png"), None, 0.42, shadow=False)
    # Image du lancement de l'application.
    render(os.path.join(OUT, "splash.png"), None, 0.55, shadow=False)
    print("Icônes générées dans", os.path.abspath(OUT))
