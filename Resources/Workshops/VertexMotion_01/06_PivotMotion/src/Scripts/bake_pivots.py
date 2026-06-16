import bpy
import random
from mathutils import Vector

# Bakes a per-leaf pivot into vertex color RGB and optionally creates one
# combined mesh whose object/local space matches TARGET_OBJECT_NAME.
#
# Contract with the Unity shader:
#   vertex color RGB = encoded pivot.xyz in shader object space
#   vertex color A   = random per-leaf phase  [0, 1]
#   Unity material _PivotMin/_PivotMax = bounds printed by this script

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

COLOR_ATTRIBUTE_NAME   = "Col"
COLOR_ATTRIBUTE_TYPE   = "FLOAT_COLOR"   
COLOR_ATTRIBUTE_DOMAIN = "CORNER"        

TARGET_OBJECT_NAME    = "TreeRoot"
COMBINED_OBJECT_NAME  = "TreeRoot_Leaves_Combined"
CREATE_COMBINED_OBJECT = True
HIDE_SOURCE_OBJECTS    = False

# Small padding around the pivot bounds so no encoded value sits exactly at
# 0 or 1 — gives headroom against floating-point drift on export.
PADDING_PERCENT = 0.05
MIN_AXIS_SIZE   = 0.001

RANDOM_SEED          = 12345
SORT_OBJECTS_BY_NAME = True

# ---------------------------------------------------------------------------
# ENCODE_SPACE_MODE
#
# Must match the space seen by the Unity shader's POSITION semantic after FBX
# import.  Two common cases:
#
#   "TARGET_LOCAL"  — Use when "Apply Transform" is OFF in the Blender FBX
#                     exporter.  Unity receives the mesh in Blender local space
#                     and compensates via a root transform on the GameObject.
#                     TreeRoot and all leaf objects must be exported together so
#                     their relative transforms are preserved.
#
#   "UNITY_XZY"     — Use when "Apply Transform" is ON.  Blender bakes the
#                     Z-up → Y-up conversion into mesh vertex positions, so
#                     Blender (X, Y, Z) becomes Unity (X, Z, Y).
#
#   "UNITY_XZ_NEGY" — Less common variant: Blender (X, Y, Z) → Unity (X, Z, -Y).
#
# How to verify: enable Debug Mode 3 (Pivot_Distance) in the Unity shader.
# Every vertex of a leaf should show a uniform radial gradient centred on its
# pivot.  Asymmetric or off-centre gradients mean the spaces do not match.
# ---------------------------------------------------------------------------
ENCODE_SPACE_MODE = "TARGET_LOCAL"  # TARGET_LOCAL | UNITY_XZY | UNITY_XZ_NEGY

# ---------------------------------------------------------------------------
# GAMMA / LINEAR EXPORT GUIDANCE  (read before exporting)
#
# The script writes linear FLOAT_COLOR data.  The FBX format stores vertex
# colours as 8-bit RGBA bytes internally, so Blender converts FLOAT_COLOR →
# BYTE_COLOR on write.  Unity's FBX importer then reads those bytes and — by
# default — treats them as sRGB, applying a gamma lift that corrupts the
# encoded pivot values.
#
# Recommended workflow (cleanest):
#   1. In Unity Model Import Settings → "Vertex Color Space" set to "Linear".
#      This is available in Unity 2022.1+.  The shader then reads raw values
#      with no correction needed.
#
# Alternative (if you cannot change import settings):
#   Set _VertexColorGamma = 2.2 in the Unity material.  The shader will call
#   pow(color.rgb, 2.2) before decoding.  Less accurate due to 8-bit quantisation
#   but workable.
#
# Verify with Debug Mode 1 (Raw_Vertex_Color): each leaf should show a flat,
# distinct solid colour.  Gradients across a leaf mean per-vertex (not per-loop)
# storage; all-black means the attribute was not exported.
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# Math helpers
# ---------------------------------------------------------------------------

def clamp01(value):
    return max(0.0, min(1.0, value))


def lerp(a, b, t):
    return a + (b - a) * t


def encode_01(value, min_value, max_value):
    size = max_value - min_value
    if abs(size) < 1e-8:
        return 0.5
    return clamp01((value - min_value) / size)


def decode_01(encoded_value, min_value, max_value):
    return lerp(min_value, max_value, encoded_value)


def convert_to_shader_object_space(v):
    """Remap a TreeRoot-local Vector into the space the Unity shader sees."""
    if ENCODE_SPACE_MODE == "TARGET_LOCAL":
        return v.copy()
    if ENCODE_SPACE_MODE == "UNITY_XZY":
        return Vector(( v.x,  v.z,  v.y))
    if ENCODE_SPACE_MODE == "UNITY_XZ_NEGY":
        return Vector(( v.x,  v.z, -v.y))
    raise RuntimeError(f"Unknown ENCODE_SPACE_MODE: {ENCODE_SPACE_MODE}")


def encode_pivot_to_color(pivot, bounds_min, bounds_max, phase):
    # RGB == XYZ in shader object space.  No channel swap, no inversion.
    # The Unity shader decodes as float3(color.r, color.g, color.b).
    return (
        encode_01(pivot.x, bounds_min.x, bounds_max.x),
        encode_01(pivot.y, bounds_min.y, bounds_max.y),
        encode_01(pivot.z, bounds_min.z, bounds_max.z),
        clamp01(phase),
    )


def decode_color_to_pivot(color, bounds_min, bounds_max):
    return Vector((
        decode_01(color[0], bounds_min.x, bounds_max.x),
        decode_01(color[1], bounds_min.y, bounds_max.y),
        decode_01(color[2], bounds_min.z, bounds_max.z),
    ))


# ---------------------------------------------------------------------------
# Mesh / attribute helpers
# ---------------------------------------------------------------------------

def get_or_create_color_attribute(mesh, name):
    attr = mesh.color_attributes.get(name)
    if attr is not None:
        data_type = getattr(attr, "data_type", None)
        if attr.domain == COLOR_ATTRIBUTE_DOMAIN and data_type == COLOR_ATTRIBUTE_TYPE:
            return attr
        mesh.color_attributes.remove(attr)
    return mesh.color_attributes.new(
        name=name,
        type=COLOR_ATTRIBUTE_TYPE,
        domain=COLOR_ATTRIBUTE_DOMAIN,
    )


def get_first_uv(mesh):
    return mesh.uv_layers[0] if mesh.uv_layers else None


def set_active_color(mesh, attr):
    try:
        mesh.color_attributes.active_color = attr
        mesh.color_attributes.active = attr
    except Exception:
        pass


def ensure_object_mode():
    if bpy.ops.object.mode_set.poll():
        bpy.ops.object.mode_set(mode='OBJECT')


def make_unique_mesh_data(objects):
    for obj in objects:
        obj.data = obj.data.copy()


# ---------------------------------------------------------------------------
# Bounds
# ---------------------------------------------------------------------------

def compute_pivot_bounds(pivot_data):
    """Compute bounds over all shader-space pivots with padding."""
    bounds_min = Vector((
        min(p.x for _, p, _ in pivot_data),
        min(p.y for _, p, _ in pivot_data),
        min(p.z for _, p, _ in pivot_data),
    ))
    bounds_max = Vector((
        max(p.x for _, p, _ in pivot_data),
        max(p.y for _, p, _ in pivot_data),
        max(p.z for _, p, _ in pivot_data),
    ))

    bounds_size = bounds_max - bounds_min
    for i in range(3):
        if bounds_size[i] < MIN_AXIS_SIZE:
            center = (bounds_min[i] + bounds_max[i]) * 0.5
            bounds_min[i] = center - MIN_AXIS_SIZE * 0.5
            bounds_max[i] = center + MIN_AXIS_SIZE * 0.5
        else:
            padding = bounds_size[i] * PADDING_PERCENT
            bounds_min[i] -= padding
            bounds_max[i] += padding

    return bounds_min, bounds_max


# ---------------------------------------------------------------------------
# Bake to source meshes
# ---------------------------------------------------------------------------

def bake_source_mesh_colors(pivot_data, bounds_min, bounds_max):
    for obj, pivot_shader_os, phase in pivot_data:
        mesh = obj.data
        color = encode_pivot_to_color(pivot_shader_os, bounds_min, bounds_max, phase)
        color_attr = get_or_create_color_attribute(mesh, COLOR_ATTRIBUTE_NAME)
        set_active_color(mesh, color_attr)
        for poly in mesh.polygons:
            for loop_index in poly.loop_indices:
                color_attr.data[loop_index].color = color
        mesh.update()


# ---------------------------------------------------------------------------
# Combined mesh
# ---------------------------------------------------------------------------

def get_combined_material_index(material, material_to_index, combined_mesh):
    if material is None:
        return 0
    existing = material_to_index.get(material.name)
    if existing is not None:
        return existing
    combined_mesh.materials.append(material)
    index = len(combined_mesh.materials) - 1
    material_to_index[material.name] = index
    return index


def create_combined_mesh(target, target_inv, pivot_data, bounds_min, bounds_max):
    """
    Build one combined mesh in shader object space.

    """
    verts = []
    faces = []
    loop_uvs = []
    loop_colors = []
    source_polygon_materials = []
    polygon_smooth_flags = []

    for obj, pivot_shader_os, phase in pivot_data:
        mesh = obj.data
        uv_layer = get_first_uv(mesh)
        color = encode_pivot_to_color(pivot_shader_os, bounds_min, bounds_max, phase)
        vertex_offset = len(verts)

        for v in mesh.vertices:
            world_pos = obj.matrix_world @ v.co
            # Step 1: bring into TreeRoot local space
            target_local_pos = target_inv @ world_pos
            # Step 2: apply the same axis remap used for pivots so that
            #         positionOS and pivotOS are in the same shader space.
            shader_pos = convert_to_shader_object_space(target_local_pos)
            verts.append(tuple(shader_pos))

        for poly in mesh.polygons:
            face = []
            for loop_index in poly.loop_indices:
                vi = mesh.loops[loop_index].vertex_index
                face.append(vertex_offset + vi)
                loop_uvs.append(tuple(uv_layer.data[loop_index].uv) if uv_layer else (0.0, 0.0))
                loop_colors.append(color)
            faces.append(face)
            polygon_smooth_flags.append(poly.use_smooth)

            material = None
            if obj.material_slots and poly.material_index < len(obj.material_slots):
                material = obj.material_slots[poly.material_index].material
            source_polygon_materials.append(material)

    combined_mesh = bpy.data.meshes.new(COMBINED_OBJECT_NAME + "Mesh")
    combined_mesh.from_pydata(verts, [], faces)
    combined_mesh.update(calc_edges=True)

    uv_attr = combined_mesh.uv_layers.new(name="UVMap")
    color_attr = get_or_create_color_attribute(combined_mesh, COLOR_ATTRIBUTE_NAME)
    set_active_color(combined_mesh, color_attr)

    for i, uv in enumerate(loop_uvs):
        uv_attr.data[i].uv = uv
    for i, color in enumerate(loop_colors):
        color_attr.data[i].color = color

    material_to_index = {}
    for i, material in enumerate(source_polygon_materials):
        combined_mesh.polygons[i].material_index = get_combined_material_index(
            material, material_to_index, combined_mesh
        )
    for i, use_smooth in enumerate(polygon_smooth_flags):
        combined_mesh.polygons[i].use_smooth = use_smooth

    combined_mesh.update()

    old = bpy.data.objects.get(COMBINED_OBJECT_NAME)
    if old:
        bpy.data.objects.remove(old, do_unlink=True)

    combined_obj = bpy.data.objects.new(COMBINED_OBJECT_NAME, combined_mesh)
    bpy.context.collection.objects.link(combined_obj)

    # The combined object's world transform must match the target so Unity sees
    # the mesh in the same local space we encoded into vertex colors.
    combined_obj.matrix_world = target.matrix_world.copy()

    # Store bake metadata as custom properties for reference in Unity.
    combined_obj["PivotBoundsMinOS"]    = (bounds_min.x, bounds_min.y, bounds_min.z)
    combined_obj["PivotBoundsMaxOS"]    = (bounds_max.x, bounds_max.y, bounds_max.z)
    combined_obj["PivotColorPacking"]   = "RGB = shader object-space XYZ, A = random phase [0,1]"
    combined_obj["PivotEncodeSpaceMode"] = ENCODE_SPACE_MODE
    combined_obj["PivotTargetObject"]   = TARGET_OBJECT_NAME

    return combined_obj


# ---------------------------------------------------------------------------
# Round-trip validation
# ---------------------------------------------------------------------------

def validate_round_trip(pivot_data, bounds_min, bounds_max):
    max_error = 0.0
    worst_name = ""
    for obj, pivot_shader_os, phase in pivot_data:
        color = encode_pivot_to_color(pivot_shader_os, bounds_min, bounds_max, phase)
        decoded = decode_color_to_pivot(color, bounds_min, bounds_max)
        error = (decoded - pivot_shader_os).length
        if error > max_error:
            max_error = error
            worst_name = obj.name
    return max_error, worst_name


# ---------------------------------------------------------------------------
# UI helper
# ---------------------------------------------------------------------------

def show_message_box(message, title="Pivot Bake Complete", icon='INFO'):
    def draw(self, context):
        for line in message.split("\n"):
            self.layout.label(text=line)
    bpy.context.window_manager.popup_menu(draw, title=title, icon=icon)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

ensure_object_mode()
random.seed(RANDOM_SEED)

target = bpy.data.objects.get(TARGET_OBJECT_NAME)
if target is None:
    raise RuntimeError(
        f"Target object '{TARGET_OBJECT_NAME}' not found. "
        "Create an Empty or mesh named TreeRoot at the desired tree origin."
    )

selected_meshes = [
    obj for obj in bpy.context.selected_objects
    if obj.type == "MESH"
    and obj.name != TARGET_OBJECT_NAME
    and obj.name != COMBINED_OBJECT_NAME
]

if SORT_OBJECTS_BY_NAME:
    selected_meshes.sort(key=lambda obj: obj.name)

if not selected_meshes:
    raise RuntimeError("No mesh objects selected. Select the leaf mesh objects before running.")

# Always copy mesh data to isolate linked/instanced datablocks.
make_unique_mesh_data(selected_meshes)

target_inv = target.matrix_world.inverted()
pivot_data = []

for obj in selected_meshes:
    # The per-leaf pivot is the object origin.
    # Move each leaf object's origin to the desired hinge point before running.
    pivot_world        = obj.matrix_world.translation.copy()
    pivot_target_local = target_inv @ pivot_world
    
    # Convert to shader space
    pivot_shader_os    = convert_to_shader_object_space(pivot_target_local)
    phase              = random.random()
    pivot_data.append((obj, pivot_shader_os, phase))

bounds_min, bounds_max = compute_pivot_bounds(pivot_data)
bake_source_mesh_colors(pivot_data, bounds_min, bounds_max)
max_error, worst_name = validate_round_trip(pivot_data, bounds_min, bounds_max)

combined_obj = None
if CREATE_COMBINED_OBJECT:
    combined_obj = create_combined_mesh(target, target_inv, pivot_data, bounds_min, bounds_max)
    if HIDE_SOURCE_OBJECTS:
        for obj, _, _ in pivot_data:
            obj.hide_viewport = True
            obj.hide_render   = True

message = (
    f"Baked pivot data to '{COLOR_ATTRIBUTE_NAME}' on {len(selected_meshes)} source objects.\n\n"
    f"Encode space : {ENCODE_SPACE_MODE}  (must match Unity shader object space)\n"
    f"Packing      : RGB = pivot XYZ, A = random phase.  No channel swap, no inversion.\n"
    f"Attribute    : {COLOR_ATTRIBUTE_TYPE}, {COLOR_ATTRIBUTE_DOMAIN}\n"
    f"Combined obj : {combined_obj.name if combined_obj else 'not created'}\n"
    f"Round-trip error (pre-export): {max_error:.9f}  worst: {worst_name or 'n/a'}\n\n"
    f"Unity material properties to set:\n"
    f"  _PivotMin        = ({bounds_min.x:.6f}, {bounds_min.y:.6f}, {bounds_min.z:.6f}, 0)\n"
    f"  _PivotMax        = ({bounds_max.x:.6f}, {bounds_max.y:.6f}, {bounds_max.z:.6f}, 0)\n"
    f"  _VertexColorGamma = 1.0  (set to 2.2 if Unity imports vertex colors as sRGB)\n\n"
    f"GAMMA NOTE: In Unity Model Import Settings set Vertex Color Space = Linear\n"
    f"(Unity 2022.1+) to avoid sRGB lift on the encoded pivot data.\n"
    f"If that option is unavailable, set _VertexColorGamma = 2.2 in the material.\n\n"
    f"AXIS NOTE: Use Debug Mode 3 (Pivot_Distance) to confirm ENCODE_SPACE_MODE.\n"
    f"Each leaf should show a uniform radial gradient centred on its pivot.\n\n"
    "Export the combined object as FBX. Do not use Blender Join after this bake\n"
    "unless the join target shares the same transform as TreeRoot."
)

print(message)
show_message_box(message)
