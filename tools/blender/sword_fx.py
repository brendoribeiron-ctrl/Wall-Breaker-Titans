# Texturas dos efeitos da espada do Asta (src/client/SwordFx.luau), desenhadas com o numpy do Blender.
# Brancas com alfa: a cor da aura entra no jogo (Color do Beam, Trail, partícula).
#
#   blender -b --factory-startup -P tools/blender/sword_fx.py
#
# Beams e Trails: x da textura = comprimento (0 = Attachment0 / ponto mais novo), y = largura.
#
#   energy_body   corpo do corte: cabeça forte em x = 1, cauda em fios que se desfazem até x = 0,
#                 borda de fora (y alto) acesa e o lado de dentro macio
#   energy_trail  o mesmo, espelhado em x (o Trail começa no ponto mais novo)
#   energy_core   fio quente fino, cabeça em x = 1 e cauda longa (a borda branca do corte)
#   blade_flow    fios de energia correndo ao longo da lâmina, emenda em x (rola com TextureSpeed)
#   bolt          raio quebrado com brilho (descargas na lâmina)
#   spark         faísca em pé com miolo branco (partícula que estica na direção da velocidade)
#   ring_glow     anel fino e quente com brilho dos dois lados (ondas no chão e no impacto)
#   energy_profile  fita de corte: dentro macio, borda de fora acesa, estrias que emendam (rastros e meia-lua)

import math
import os

import bpy
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "textures")
SS = 2


def grid(w, h):
    x = (np.arange(w * SS) + 0.5) / (w * SS)
    y = 1 - (np.arange(h * SS) + 0.5) / (h * SS)
    return np.meshgrid(x, y)


def smooth(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def vnoise(x, y, seed):
    xi = np.floor(x).astype(np.int64)
    yi = np.floor(y).astype(np.int64)
    xf = x - xi
    yf = y - yi
    u = xf * xf * (3 - 2 * xf)
    v = yf * yf * (3 - 2 * yf)

    def h(i, j):
        n = (i * 374761393 + j * 668265263 + seed * 1442695041) & 0xFFFFFFFF
        n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
        return ((n ^ (n >> 16)) & 0xFFFF) / 65535.0

    a = h(xi, yi) * (1 - u) + h(xi + 1, yi) * u
    b = h(xi, yi + 1) * (1 - u) + h(xi + 1, yi + 1) * u
    return a * (1 - v) + b * v


def fbm(x, y, seed, octaves=4):
    total = np.zeros_like(x)
    amp = 0.5
    for o in range(octaves):
        total += amp * vnoise(x * 2**o, y * 2**o, seed + o * 17)
        amp *= 0.5
    return total / (1 - 0.5**octaves)


def down(a, w, h):
    return a.reshape(h, SS, w, SS).mean(axis=(1, 3))


def save(name, alpha):
    hs, ws = alpha.shape
    w, h = ws // SS, hs // SS
    a = np.clip(down(alpha, w, h), 0, 1)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., 3] = a
    image = bpy.data.images.get(name) or bpy.data.images.new(name, w, h, alpha=True)
    image.pixels.foreach_set(rgba[::-1].ravel())
    image.filepath_raw = os.path.join(OUT, name + ".png")
    image.file_format = "PNG"
    image.save()
    print("gravado", name, w, "x", h)


def energy_body():
    X, Y = grid(512, 128)
    # fios: ruído esticado ao longo do corte
    wisp = fbm(X * 2.2, Y * 16, 3)
    fine = fbm(X * 6, Y * 40, 8)
    # perfil na largura: borda de fora acesa, dentro macio, nada encostando nas bordas
    edge = np.exp(-((Y - 0.8) / 0.07) ** 2)
    body = smooth(0.04, 0.75, Y) * (1 - smooth(0.86, 0.97, Y))
    across = np.maximum(edge, 0.55 * body)
    # ao longo: cresce até a cabeça e corta seco no fim
    along = smooth(0.0, 0.9, X) ** 1.4 * (1 - smooth(0.96, 1.0, X))
    # a cauda se desfaz em fios: o limiar sobe para o lado da cauda
    cut = smooth(0.35 + 0.55 * (1 - X), 0.5 + 0.55 * (1 - X), wisp * 0.7 + fine * 0.5)
    alpha = across * along * (0.35 + 0.65 * cut)
    alpha = np.maximum(alpha, edge * smooth(0.55, 0.98, X) * 0.9 * (1 - smooth(0.97, 1.0, X)))
    return alpha


def energy_core():
    X, Y = grid(512, 64)
    wobble = (fbm(X * 6, np.zeros_like(X) + 2, 5) - 0.5) * 0.12 * (1 - X)
    d = np.abs(Y - 0.5 - wobble)
    width = 0.05 + 0.12 * smooth(0.0, 0.9, X)
    line = np.exp(-(d / (width * 0.35)) ** 2) + 0.35 * np.exp(-(d / width) ** 2)
    along = smooth(0.0, 0.85, X) ** 2 * (1 - smooth(0.965, 1.0, X))
    return np.clip(line * along, 0, 1)


def blade_flow():
    X, Y = grid(512, 128)

    def flow(x):
        return fbm(x * 3, Y * 14, 21) * 0.6 + fbm(x * 8, Y * 34, 31) * 0.4

    # emenda em x: mistura o ruído com ele mesmo deslocado de um período
    n = flow(X) * X + flow(X + 1) * (1 - X)
    streak = smooth(0.52, 0.68, n)
    across = smooth(0.0, 0.25, Y) * (1 - smooth(0.75, 1.0, Y))
    return streak * across


def bolt():
    w, h = 512, 64
    X, Y = grid(w, h)
    rng = np.random.default_rng(7)
    pts = np.array([[0.0, 0.5], [1.0, 0.5]])
    for depth in range(7):
        new = [pts[0]]
        for a, b in zip(pts[:-1], pts[1:]):
            m = (a + b) / 2
            m[1] += rng.uniform(-1, 1) * 0.32 / (depth + 1)
            new += [m, b]
        pts = np.array(new)
    pts[:, 1] = np.clip(pts[:, 1], 0.18, 0.82)
    yline = np.interp(X, pts[:, 0], pts[:, 1])
    d = np.abs(Y - yline)
    alpha = np.exp(-(d / 0.025) ** 2) + 0.45 * np.exp(-(d / 0.09) ** 2)
    ends = smooth(0.0, 0.06, X) * (1 - smooth(0.94, 1.0, X))
    return np.clip(alpha * ends, 0, 1)


def spark():
    # em pé: a partícula com VelocityParallel estica no eixo vertical da textura
    X, Y = grid(32, 128)
    x = (Y - 0.5) * 2
    y = (X - 0.5) * 2
    shape = np.clip(1 - x * x, 0, 1) ** 0.8
    core = np.exp(-(y / (0.22 * shape + 1e-3)) ** 2)
    glow = 0.35 * np.exp(-(y / (0.7 * shape + 1e-3)) ** 2)
    return np.clip((core + glow) * shape, 0, 1)


def ring_glow():
    X, Y = grid(256, 256)
    r = np.hypot(X - 0.5, Y - 0.5)
    d = r - 0.4
    core = np.exp(-(d / 0.012) ** 2)
    glow = 0.5 * np.exp(-(d / 0.05) ** 2) + 0.18 * np.exp(-(np.minimum(d, 0) / 0.16) ** 2) * (d < 0)
    return np.clip(core + glow, 0, 1) * (r < 0.49)


def energy_profile():
    # perfil na largura (y): dentro macio, borda de fora (y alto) acesa; no comprimento (x) só estrias
    # suaves que emendam (x = 0 e x = 1 iguais): serve para Trail e Beam em vários trechos seguidos
    X, Y = grid(256, 64)

    def streak(x):
        return fbm(x * 4, Y * 18, 41)

    n = streak(X) * X + streak(X + 1) * (1 - X)
    body = smooth(0.02, 0.8, Y) ** 1.6 * 0.7 * (0.7 + 0.6 * (n - 0.5))
    edge = np.exp(-((Y - 0.86) / 0.05) ** 2)
    alpha = np.maximum(body, edge) * (1 - smooth(0.93, 0.99, Y))
    return np.clip(alpha, 0, 1)


def slash_streaks():
    # "slash texture" do tutorial de swipe: riscos finos de vento ao longo do corte (x), mais densos
    # e fortes na borda de fora (y alto); emenda em x para rolar com TextureSpeed (máscara andando)
    X, Y = grid(512, 128)
    rng = np.random.default_rng(11)
    alpha = np.zeros_like(X)
    for _ in range(34):
        y0 = 0.2 + 0.72 * rng.uniform() ** 0.6
        thick = rng.uniform(0.006, 0.02) * (0.6 + y0)
        start = rng.uniform()
        length = rng.uniform(0.25, 0.8)
        power = rng.uniform(0.35, 1.0) * (0.45 + 0.55 * y0)
        u = np.mod(X - start, 1.0) / length  # 0..1 dentro do risco, emenda sozinho em x
        inside = (u < 1).astype(np.float32)
        taper = np.sin(np.clip(u, 0, 1) * math.pi) ** 0.7
        bend = 0.025 * np.sin((u + y0) * math.pi)  # leve curva no risco
        d = np.abs(Y - y0 - bend)
        line = np.exp(-(d / thick) ** 2) + 0.25 * np.exp(-(d / (thick * 3.5)) ** 2)
        alpha = np.maximum(alpha, line * taper * inside * power)
    edge = np.exp(-((Y - 0.9) / 0.03) ** 2) * 0.85
    haze = smooth(0.05, 0.85, Y) ** 2 * 0.22
    alpha = np.maximum(np.maximum(alpha, edge), haze)
    return np.clip(alpha * (1 - smooth(0.95, 0.995, Y)), 0, 1)


def main():
    save("slash_streaks", slash_streaks())
    save("energy_profile", energy_profile())
    body = energy_body()
    save("energy_body", body)
    save("energy_trail", body[:, ::-1])
    save("energy_core", energy_core())
    save("blade_flow", blade_flow())
    save("bolt", bolt())
    save("spark", spark())
    save("ring_glow", ring_glow())


main()
