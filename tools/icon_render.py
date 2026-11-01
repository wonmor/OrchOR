# App icon render (Blender 3.6, Eevee). Usage: blender -b -P tools/icon_render.py -- c out.png 1024 [lensmul] [alpha]
# Variant c is the shipped icon; lensmul 0.6667 gives the Android adaptive background, "alpha" its monochrome mask.

import bpy, math, random, sys
from mathutils import Vector
argv = sys.argv[sys.argv.index('--') + 1:]
variant, out = argv[0], argv[1]
size = int(argv[2]) if len(argv) > 2 else 1024
lensmul = float(argv[3]) if len(argv) > 3 else 1.0
alpha_pass = len(argv) > 4 and argv[4] == 'alpha'
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = 'BLENDER_EEVEE'
ee = sc.eevee
ee.taa_render_samples = 128
ee.use_bloom = True; ee.bloom_intensity = 0.09; ee.bloom_threshold = 0.9; ee.bloom_radius = 6.5; ee.bloom_color = (1.0, 0.85, 0.8)
ee.use_gtao = True; ee.gtao_distance = 1.2
ee.use_ssr = True
ee.use_soft_shadows = True
ee.volumetric_start = 2; ee.volumetric_end = 60; ee.volumetric_tile_size = '4'
sc.render.resolution_x = sc.render.resolution_y = size
import os
if os.environ.get('WIDE'): sc.render.resolution_x = int(size * 2.048); cam_d_sensor_fit = 'HORIZONTAL'
sc.render.film_transparent = False
sc.view_settings.view_transform = 'Filmic'; sc.view_settings.look = 'Medium High Contrast'
sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGB'

# World: deep indigo, light haze
w = bpy.data.worlds.new('W'); sc.world = w; w.use_nodes = True
nt = w.node_tree; bg = nt.nodes['Background']; bg.inputs[0].default_value = (0.004, 0.006, 0.03, 1); bg.inputs[1].default_value = 1
vol = nt.nodes.new('ShaderNodeVolumePrincipled'); vol.inputs['Density'].default_value = 0.008
vol.inputs['Color'].default_value = (0.25, 0.4, 1.0, 1)
nt.links.new(vol.outputs[0], nt.nodes['World Output'].inputs['Volume'])

def mat(name, base, emit=None, estr=0.0, rough=0.35, alpha=1.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    p = m.node_tree.nodes['Principled BSDF']
    p.inputs['Base Color'].default_value = (*base, 1)
    p.inputs['Roughness'].default_value = rough
    p.inputs['Specular'].default_value = 0.6
    p.inputs['Sheen'].default_value = 0.6
    if emit:
        p.inputs['Emission'].default_value = (*emit, 1); p.inputs['Emission Strength'].default_value = estr
    if alpha < 1:
        p.inputs['Alpha'].default_value = alpha; m.blend_method = 'BLEND'; m.shadow_method = 'NONE'; m.show_transparent_back = True
    return m

A = mat('alpha', (0.04, 0.12, 0.60), rough=0.3)
B = mat('beta', (0.05, 0.35, 0.70), rough=0.3)
SUPY = mat('supY', (0.9, 0.7, 0.15), (1.0, 0.78, 0.25), 1.3)
SUPC = mat('supC', (0.2, 0.8, 0.9), (0.3, 0.9, 1.0), 1.1)
GHOST_Y = mat('ghY', (1, 0.8, 0.3), (1.0, 0.8, 0.3), 1.0, alpha=0.22)
GHOST_C = mat('ghC', (0.3, 0.9, 1), (0.35, 0.9, 1.0), 0.9, alpha=0.2)
RED = mat('red', (0.9, 0.08, 0.04), (1.0, 0.12, 0.05), 6.0)
CORE = mat('core', (1, 1, 1), (1.0, 0.85, 0.8), 40.0)

bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=1)
proto_mesh = bpy.context.object.data; bpy.ops.object.shade_smooth(); bpy.data.objects.remove(bpy.context.object)

P, N = 13, 46                 # protofilaments, monomers per protofilament
R = 2.15                      # lattice radius
dz = 0.98                     # monomer spacing
rise = 3 * dz / 13            # 3-start helix
cx, cz = 0.0, 0.0
flash_ring, flash_p = {'a': (21, 12), 'b': (13, 10), 'c': (22, 12)}[variant]   # collapse site
beads = []
for p in range(P):
    th = 2 * math.pi * p / P
    for n in range(N):
        z = n * dz + p * rise
        pos = Vector((R * math.cos(th), R * math.sin(th), z))
        o = bpy.data.objects.new(f'b{p}_{n}', proto_mesh)
        o.location = pos
        o.rotation_euler = (0, 0, th)
        o.scale = (0.40, 0.46, 0.50)   # radial x tangential x axial
        bpy.context.collection.objects.link(o)
        beads.append((o, p, n, pos))

fr = 0.55 if variant == 'b' else 1.18
flash = Vector((R * fr * math.cos(2 * math.pi * flash_p / P), R * fr * math.sin(2 * math.pi * flash_p / P), flash_ring * dz + flash_p * rise))
def dist_patch(p, n, cp, cn):
    dp = min((p - cp) % P, (cp - p) % P)
    return math.hypot(dp * 1.0, (n - cn) * 0.75)
for o, p, n, pos in beads:
    m = A if n % 2 == 0 else B
    d_flash = (pos - flash).length
    sup = dist_patch(p, n, (flash_p + 1) % P, flash_ring + 9) < 3.3 + random.uniform(-0.7, 0.7) or dist_patch(p, n, (flash_p + 11) % P, flash_ring - 9) < 1.7 + random.uniform(-0.5, 0.5)
    if d_flash < 1.6:
        m = RED
    elif sup:
        m = SUPY if random.random() < 0.6 else SUPC
        # ghosted second state: a translucent twin, slightly displaced
        g = bpy.data.objects.new(o.name + 'g', proto_mesh)
        g.location = pos + Vector((random.uniform(-.2, .2), random.uniform(-.2, .2), random.uniform(0.18, 0.3)))
        g.rotation_euler = o.rotation_euler; g.scale = o.scale * 1.08
        bpy.context.collection.objects.link(g)
        g.data = proto_mesh; g.material_slots  # noop
        g.active_material = None
        g.data.materials.clear() if False else None
        g.color = (1, 1, 1, 1)
        g_m = GHOST_Y if m is SUPY else GHOST_C
        if not g.material_slots: g.data.materials.append(None) if len(proto_mesh.materials) == 0 else None
        g.material_slots[0].link = 'OBJECT'; g.material_slots[0].material = g_m
    if not o.material_slots: proto_mesh.materials.append(None)
    o.material_slots[0].link = 'OBJECT'; o.material_slots[0].material = m

# Collapse flash: hot core + red light
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.38, location=flash); bpy.ops.object.shade_smooth()
bpy.context.object.data.materials.append(CORE)
ld = bpy.data.lights.new('flash', 'POINT'); ld.energy = 5000; ld.color = (1, 0.18, 0.10); ld.shadow_soft_size = 0.6
ld.volume_factor = 0.45
lo = bpy.data.objects.new('flash', ld); lo.location = flash; bpy.context.collection.objects.link(lo)

def light(name, kind, loc, energy, color, size=4, target=None):
    l = bpy.data.lights.new(name, kind); l.energy = energy; l.color = color
    if kind == 'AREA': l.size = size
    l.volume_factor = 0.15
    o = bpy.data.objects.new(name, l); o.location = loc; bpy.context.collection.objects.link(o)
    if target is not None:
        c = o.constraints.new('TRACK_TO'); c.target = target; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
    return o

tgt = bpy.data.objects.new('tgt', None); tgt.location = (0, 0, N * dz / 2); bpy.context.collection.objects.link(tgt)
focus = bpy.data.objects.new('focus', None); focus.location = flash; bpy.context.collection.objects.link(focus)

cam_d = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cam_d); bpy.context.collection.objects.link(cam); sc.camera = cam
cam_d.dof.use_dof = True; cam_d.dof.focus_object = focus
look = bpy.data.objects.new('look', None); bpy.context.collection.objects.link(look)
c = cam.constraints.new('TRACK_TO'); c.target = look; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'

if variant == 'a':      # dramatic low diagonal: tube rising across the frame, open mouth near
    cam.location = (10.5, -5.0, 9.0); look.location = (0, 0, 22); cam_d.lens = 34; cam_d.dof.aperture_fstop = 1.6
    cam.rotation_mode = 'XYZ'
elif variant == 'b':    # looking into the hollow mouth, tube receding into haze
    cam.location = (1.7, -1.3, -3.2); look.location = (0.0, 0.0, 14); cam_d.lens = 22; cam_d.dof.aperture_fstop = 1.4
else:                   # side-on diagonal close-up around the collapse
    cam.location = (11.0, -5.5, 20.0); look.location = (0, 0, 21); cam_d.lens = 30; cam_d.dof.aperture_fstop = 2.2

# Roll so the tube runs corner to corner
roll = bpy.data.objects.new('roll', None)
light('rim', 'AREA', (-9, 8, 30), 4000, (0.35, 0.65, 1.0), 10, tgt)
light('rim2', 'AREA', (-6, 10, 5), 1200, (0.3, 0.9, 1.0), 8, tgt)
light('key', 'AREA', (10, -10, 28), 900, (1.0, 0.85, 0.75), 6, tgt)
light('fill', 'AREA', (6, -8, -4), 160, (0.4, 0.45, 1.0), 8, tgt)

if variant == 'b':
    light('mouth', 'AREA', (3.5, -3.0, -3.0), 250, (0.45, 0.6, 1.0), 6, tgt)
    light('inner', 'POINT', (0, 0, 4), 80, (0.3, 0.8, 1.0))
bpy.context.view_layer.update()
# rotate camera around its view axis to put the tube on a diagonal
import mathutils
cam_world = cam.matrix_world.copy()
c_rot = cam.constraints[0]
mw = cam.matrix_world.copy()
cam.constraints.remove(c_rot)
cam.matrix_world = mw
cam.rotation_mode = 'QUATERNION'
axis = (mw.to_quaternion() @ Vector((0, 0, -1)))
roll_deg = {'a': -38, 'b': -30, 'c': -45}[variant]
cam.rotation_quaternion = mathutils.Quaternion(axis, math.radians(roll_deg)) @ mw.to_quaternion()

cam_d.lens *= lensmul
if os.environ.get('WIDE'): cam_d.shift_x = float(os.environ.get('SHIFT', '0'))
if alpha_pass:
    sc.render.film_transparent = True; sc.render.image_settings.color_mode = 'RGBA'; ee.use_bloom = False
    nt.links.remove(nt.nodes['World Output'].inputs['Volume'].links[0])
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
