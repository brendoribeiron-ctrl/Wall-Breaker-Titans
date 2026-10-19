# Espada de antimagia do Asta (Black Clover): a Exterminadora de Demônios (Demon Slayer).
# Roda no Blender e grava:
#   assets/models/asta_sword.fbx     peças separadas por tipo (o Roblox pinta pelo nome)
#   assets/textures/asta_blade.png   textura da lâmina (mapa plano das faces largas)
#   E:\Projetos roblox\Blender\Asta Sword\asta_sword.blend   fonte editável
#   imagens de conferência em SWORD_SHOTS (padrão: pasta shots/ do projeto)
#
#   blender -b --factory-startup -P tools/blender/asta_sword.py
#
# Medidas em studs (escala de um boneco R15 de ~5,3 studs). Eixos do Kit: X = largura da
# lâmina (direita), Y = espessura (frente), Z = ponta da lâmina (cima). A origem (Pivot) é o
# ponto de pegada da mão direita, logo abaixo da guarda.
#
# Peças (prefixo do nome):
#   Blade   lâmina, com UV plano para a textura asta_blade
#   Guard   guarda em cruz, anel do centro, presilhas sobre a lâmina, pomo
#   Grip    cabo enrolado em couro
#   Tip / Base   cubinhos marcadores da ponta e da raiz da lâmina: o jogo vira Attachments
#                (pontos de partida dos VFX de combate) e apaga

import math
import os
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MODELS = os.path.join(ROOT, "assets", "models")
TEXTURES = os.path.join(ROOT, "assets", "textures")
BLEND = r"E:\Projetos roblox\Blender\Asta Sword\asta_sword.blend"
SHOTS = os.environ.get("SWORD_SHOTS", os.path.join(ROOT, "shots"))

# ---------------------------------------------------------------------------------------------
# Medidas
GUARD_Z = 0.30          # centro da barra da guarda
BLADE_Z0 = 0.40         # raiz da lâmina
BLADE_HW0 = 0.47        # meia largura na raiz
BLADE_HW1 = 0.45        # meia largura antes da ponta (afina um pouco)
SHOULDER_R = 3.80       # onde o gume direito começa o corte diagonal da ponta
SHOULDER_L = 4.08       # onde o gume esquerdo começa a fechar
APEX = (-0.17, 4.55)    # ponta (x, z): fora do centro, como no anime
T_EDGE = 0.018          # meia espessura no gume
T_BEVEL = 0.075         # meia espessura onde o chanfro do gume começa
T_RIDGE = 0.105         # meia espessura na aresta central
BEVEL = 0.12            # largura do chanfro do gume
GRIP_Z0, GRIP_Z1 = -0.80, 0.24
GRIP_R = 0.08
UV_X = (-0.55, 0.55)      # faixa de X que a textura cobre
UV_Z = (BLADE_Z0, APEX[1])


def edge_x(z):
    """Gumes (esquerdo, direito) na altura z."""
    t = (z - BLADE_Z0) / (SHOULDER_R - BLADE_Z0)
    hw = BLADE_HW0 + (BLADE_HW1 - BLADE_HW0) * min(max(t, 0), 1)
    left, right = -hw, hw
    if z > SHOULDER_R:
        k = (z - SHOULDER_R) / (APEX[1] - SHOULDER_R)
        right = BLADE_HW1 + (APEX[0] - BLADE_HW1) * k
    if z > SHOULDER_L:
        k = (z - SHOULDER_L) / (APEX[1] - SHOULDER_L)
        left = -BLADE_HW1 + (APEX[0] + BLADE_HW1) * k
    return left, right


def blade(k):
    """Lâmina: anéis de 8 vértices (gume, chanfro, aresta central, chanfro) dos dois lados,
    da raiz até a ponta. Seção em losango achatado, como as lâminas largas do anime."""
    bm = k.bm("Blade")
    uv = bm.loops.layers.uv.new("UVMap")
    zs = [BLADE_Z0, 0.55, 1.2, 2.0, 2.8, 3.4, SHOULDER_R, 3.95, SHOULDER_L, 4.2, 4.32, 4.42]
    rings = []
    for z in zs:
        left, right = edge_x(z)
        width = right - left
        mid = (left + right) / 2
        # perto da ponta a espessura cai junto com a largura
        f = min(1.0, width / (2 * BLADE_HW1)) ** 0.7
        bev = min(BEVEL, width * 0.3)
        tr, tb, te = T_RIDGE * f, T_BEVEL * f, T_EDGE
        pts = [
            (right, 0, z),
            (right - bev, -tb, z), (mid, -tr, z), (left + bev, -tb, z),
            (left, 0, z),
            (left + bev, tb, z), (mid, tr, z), (right - bev, tb, z),
        ]
        rings.append([bm.verts.new(Vector(p)) for p in pts])
    apex = bm.verts.new(Vector((APEX[0], 0, APEX[1])))
    faces = []
    for a, b in zip(rings, rings[1:]):
        for i in range(8):
            j = (i + 1) % 8
            faces.append(bm.faces.new((a[i], a[j], b[j], b[i])))
    last = rings[-1]
    for i in range(8):
        j = (i + 1) % 8
        faces.append(bm.faces.new((last[i], last[j], apex)))
    faces.append(bm.faces.new(list(reversed(rings[0]))))
    bm.normal_update()
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for face in bm.faces:
        for loop in face.loops:
            co = loop.vert.co
            loop[uv].uv = ((co.x - UV_X[0]) / (UV_X[1] - UV_X[0]), (co.z - UV_Z[0]) / (UV_Z[1] - UV_Z[0]))


def guard(k):
    # barra da guarda: seção quadrada chanfrada, pontas subindo um pouco para a lâmina
    span = 0.74
    pts, radii = [], []
    for i in range(13):
        s = -1 + 2 * i / 12
        x = s * span
        z = GUARD_Z + 0.07 * abs(s) ** 3
        pts.append((x, 0, z))
        radii.append(0.052 + 0.012 * abs(s) ** 4)
    k.tube("Guard", pts, radii, segs=6)
    # pontas da guarda: botão alargado
    for s in (-1, 1):
        x = s * (span + 0.035)
        z = GUARD_Z + 0.07
        k.tube("Guard", [(x - s * 0.03, 0, z), (x + s * 0.02, 0, z + 0.01), (x + s * 0.07, 0, z + 0.02)], [0.07, 0.085, 0.0], segs=8)
    # anel no cruzamento (plano XZ, visto de frente e de trás)
    ring_r, ring_t = 0.165, 0.034
    ring = [(ring_r * math.cos(2 * math.pi * i / 16), 0, GUARD_Z + ring_r * math.sin(2 * math.pi * i / 16)) for i in range(17)]
    bm = k.bm("Guard")
    loops = []
    for i in range(16):
        c = Vector(ring[i])
        out = (c - Vector((0, 0, GUARD_Z))).normalized()
        loops.append([bm.verts.new(c + (out * math.cos(2 * math.pi * q / 6) + Vector((0, 1, 0)) * math.sin(2 * math.pi * q / 6)) * ring_t) for q in range(6)])
    for i in range(16):
        a, b = loops[i], loops[(i + 1) % 16]
        for q in range(6):
            r = (q + 1) % 6
            bm.faces.new((a[q], a[r], b[r], b[q]))
    # miolo do anel: disco com bossa dos dois lados
    k.loft("Guard", [(0, 0, -0.07, 0), (0, 0, -0.055, 0.075), (0, 0, 0.055, 0.075), (0, 0, 0.07, 0)], 10,
           matrix=Matrix.Translation((0, 0, GUARD_Z)) @ Matrix.Rotation(math.pi / 2, 4, "X"))
    # presilhas (langets) que sobem pela lâmina, uma de cada lado
    for side in (-1, 1):
        y0 = side * (T_RIDGE * 0.92)
        pts2 = [(-0.05, GUARD_Z + 0.06), (0.05, GUARD_Z + 0.06), (0.035, BLADE_Z0 + 0.12), (0, BLADE_Z0 + 0.18), (-0.035, BLADE_Z0 + 0.12)]
        m = Matrix.Translation((0, y0 if side > 0 else y0 - 0.03, 0))
        k.prism("Guard", pts2, 0.03, m)
    # colar logo abaixo da guarda
    k.cyl("Guard", 0.105, GRIP_Z1 - 0.01, GUARD_Z - 0.03, segs=10, r2=0.09)


def grip(k):
    # couro enrolado: o raio sobe e desce a cada volta, com uma leve espiral
    rings = []
    turns = 11
    steps = turns * 4
    for i in range(steps + 1):
        z = GRIP_Z0 + (GRIP_Z1 - GRIP_Z0) * i / steps
        bulge = 0.012 * (0.5 + 0.5 * math.cos(2 * math.pi * i / 4))
        rings.append((0, 0, z, GRIP_R + bulge))
    k.loft("Grip", rings, 10, wobble=lambda n, q: 1 + 0.04 * math.cos(2 * math.pi * q / 10 + n * 0.6))
    # anel de metal no meio do cabo
    mid = (GRIP_Z0 + GRIP_Z1) / 2 - 0.12
    k.cyl("Guard", GRIP_R + 0.03, mid - 0.035, mid + 0.035, segs=10)
    # pomo: gargalo, bola achatada e tampa
    zp = GRIP_Z0
    k.loft("Guard", [(0, 0, zp + 0.02, 0.095), (0, 0, zp - 0.04, 0.07), (0, 0, zp - 0.08, 0.06)], 10)
    k.ball("Guard", 0, 0, zp - 0.15, 0.1, segs=10, squash=0.85)
    k.loft("Guard", [(0, 0, zp - 0.23, 0.055), (0, 0, zp - 0.27, 0.09), (0, 0, zp - 0.3, 0.07), (0, 0, zp - 0.31, 0)], 10)


# ---------------------------------------------------------------------------------------------
# Textura da lâmina: aço escuro azulado, manchas pretas de desgaste (como no anime), gume e
# aresta central marcados. Mapa plano: u = X da lâmina, v = Z (raiz embaixo, ponta em cima).
TEX_W, TEX_H = 256, 1024


def value_noise(rng, h, w, cells_y, cells_x):
    grid = rng.random((cells_y + 2, cells_x + 2))
    ys = np.linspace(0, cells_y, h)
    xs = np.linspace(0, cells_x, w)
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = ys - y0
    fx = xs - x0
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a = grid[y0][:, x0]
    b = grid[y0][:, x0 + 1]
    c = grid[y0 + 1][:, x0]
    d = grid[y0 + 1][:, x0 + 1]
    top = a + (b - a) * fx[None, :]
    bot = c + (d - c) * fx[None, :]
    return top + (bot - top) * fy[:, None]


def blade_texture(path):
    rng = np.random.default_rng(7)
    h, w = TEX_H, TEX_W
    # coordenadas de cada pixel em studs (linha 0 = ponta, como uma imagem)
    zz = np.linspace(UV_Z[1], UV_Z[0], h)[:, None] * np.ones((1, w))
    xx = np.linspace(UV_X[0], UV_X[1], w)[None, :] * np.ones((h, 1))
    left = np.zeros_like(zz)
    right = np.zeros_like(zz)
    for r in range(h):
        left[r, :], right[r, :] = edge_x(zz[r, 0])
    mid = (left + right) / 2
    half = np.maximum((right - left) / 2, 1e-3)
    across = (xx - mid) / half  # -1 gume esquerdo, 0 aresta, 1 gume direito

    steel_dark = np.array([0.17, 0.185, 0.225])
    steel_light = np.array([0.46, 0.50, 0.60])
    # brilho grande e suave descendo pela lâmina (o reflexo azulado da referência)
    broad = value_noise(rng, h, w, 6, 2)
    sheen = np.clip(1 - np.abs(across + 0.25) * 1.3, 0, 1) ** 1.5 * (0.55 + 0.45 * broad)
    color = steel_dark[None, None, :] + (steel_light - steel_dark)[None, None, :] * (sheen * 0.75)[:, :, None]
    # variação fina do metal
    grain = value_noise(rng, h, w, 120, 16) - 0.5
    color += grain[:, :, None] * 0.035

    # manchas pretas de desgaste: contorno duro, estilo cel
    blot = value_noise(rng, h, w, 22, 6) * 0.65 + value_noise(rng, h, w, 60, 14) * 0.35
    mask = np.clip((blot - 0.6) / 0.025, 0, 1)
    mask *= np.clip((1 - np.abs(across)) / 0.15, 0, 1)  # não come o gume
    black = np.array([0.07, 0.07, 0.095])
    color = color * (1 - mask[:, :, None]) + black[None, None, :] * mask[:, :, None]

    # chanfro do gume: mais claro, com uma linha de fio bem clara
    bevel_in = 1 - BEVEL / half
    bevel = np.clip((np.abs(across) - bevel_in) / 0.02, 0, 1)
    color = color * (1 - 0.25 * bevel[:, :, None]) + np.array([0.50, 0.54, 0.63])[None, None, :] * (0.25 * bevel[:, :, None])
    edge_line = np.clip((np.abs(across) - 0.965) / 0.02, 0, 1)
    color = color * (1 - edge_line[:, :, None]) + np.array([0.72, 0.76, 0.85])[None, None, :] * edge_line[:, :, None]
    # linha do começo do chanfro (risco escuro fino)
    bevel_line = np.clip(1 - np.abs(np.abs(across) - bevel_in) / 0.012, 0, 1)
    color *= (1 - 0.45 * bevel_line)[:, :, None]

    # aresta central: risco escuro com um filete claro ao lado (luz vindo da esquerda)
    px = (xx - mid) / (UV_X[1] - UV_X[0]) * w
    ridge_dark = np.clip(1 - np.abs(px) / 1.4, 0, 1)
    ridge_light = np.clip(1 - np.abs(px + 2.2) / 1.2, 0, 1)
    color *= (1 - 0.6 * ridge_dark)[:, :, None]
    color += np.array([0.12, 0.13, 0.16])[None, None, :] * ridge_light[:, :, None]

    # arranhões finos
    for _ in range(60):
        r0 = rng.integers(0, h)
        c0 = rng.integers(0, w)
        length = rng.integers(8, 40)
        slope = rng.uniform(-0.6, 0.6)
        for t in range(length):
            r = r0 + t
            c = int(c0 + slope * t)
            if 0 <= r < h and 0 <= c < w:
                color[r, c] = color[r, c] * 0.75 + np.array([0.42, 0.45, 0.52]) * 0.25

    color = np.clip(color, 0, 1)
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[:, :, :3] = color
    img = bpy.data.images.new("asta_blade", w, h, alpha=True)
    # o Blender guarda a imagem de baixo para cima
    img.pixels.foreach_set(rgba[::-1].reshape(-1))
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    print("textura", path)
    return img


def snapshot(path, eye, target, lens=35, size=(1100, 800)):
    """Imagem Workbench com a textura da lâmina (o kit.snapshot só mostra a cor do material)."""
    scene = bpy.context.scene
    cam = bpy.data.objects.new("Snap", bpy.data.cameras.new("Snap"))
    cam.data.lens = lens
    scene.collection.objects.link(cam)
    cam.location = Vector(eye)
    cam.rotation_euler = (Vector(target) - Vector(eye)).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "TEXTURE"
    shading.show_cavity = True
    shading.background_type = "VIEWPORT"
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.filepath = path
    scene.render.image_settings.file_format = "PNG"
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)


# ---------------------------------------------------------------------------------------------
def main():
    kit.clean_scene()
    os.makedirs(SHOTS, exist_ok=True)
    os.makedirs(os.path.dirname(BLEND), exist_ok=True)

    k = kit.Kit("asta_sword")
    blade(k)
    guard(k)
    grip(k)
    k.box("Tip", (0.05, 0.05, 0.05), (APEX[0], 0, APEX[1]))
    k.box("Base", (0.05, 0.05, 0.05), (0, 0, BLADE_Z0))
    objects = k.build({
        "Blade": (0.2, 0.22, 0.27, 1),
        "Guard": (0.28, 0.24, 0.17, 1),
        "Grip": (0.17, 0.11, 0.08, 1),
        "Tip": (1, 0, 0, 1), "Base": (1, 0, 0, 1),
        "Pivot": (1, 0, 0, 1), "MarkX": (1, 0, 0, 1), "MarkY": (1, 0, 0, 1),
    })
    k.export(MODELS)

    img = blade_texture(os.path.join(TEXTURES, "asta_blade.png"))
    blade_ob = next(o for o in objects if o.name.startswith("Blade_"))
    mat = blade_ob.data.materials[0]
    nodes = mat.node_tree.nodes
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = img
    bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nodes.active = tex

    # marcadores longe da câmera nas imagens
    for o in objects:
        if o.name.split("_")[0] in ("Pivot", "MarkX", "MarkY", "Tip", "Base"):
            o.hide_render = True
    snapshot(os.path.join(SHOTS, "sword_front.png"), (0, -9, 2.0), (0, 0, 1.9), lens=40, size=(700, 1100))
    snapshot(os.path.join(SHOTS, "sword_side.png"), (9, 0, 2.0), (0, 0, 1.9), lens=40, size=(700, 1100))
    snapshot(os.path.join(SHOTS, "sword_persp.png"), (4.5, -6, 4.5), (0, 0, 1.6), lens=40, size=(900, 1100))
    snapshot(os.path.join(SHOTS, "sword_hilt.png"), (1.2, -2.0, 0.6), (0, 0, 0.0), lens=40, size=(900, 900))

    img.pack()
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)
    print("blend", BLEND)


main()
