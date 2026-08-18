"""
Genere un personnage low-poly rigge (armature + skinning rigide + animations
idle/walk/death) et l'exporte en glTF binaire pour IA_Life.

Usage :
    blender --background --python tools/blender/build_character.py

Proportions calees sur scripts/main.gd (_spawn_character) : hauteur totale
1.4 (capsule de collision), torse 0.6x1.0x0.4 centre y=0.5, tete 0.4^3
centree y=1.2 (coordonnees Godot Y-up).
"""

import math
import os

import bpy

OUTPUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "assets", "models", "character.glb",
)

# Hauteurs en Z (Blender, Z-up) -> Y en Godot apres export gltf (+Y up).
HIPS_Z = 0.7
CHEST_Z = 1.0
HEAD_TOP_Z = 1.4
ELBOW_Z = 0.75
HAND_Z = 0.5
KNEE_Z = 0.35
FOOT_Z = 0.0
SHOULDER_X = 0.22
LEG_X = 0.15

FPS = 24


def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions, bpy.data.materials):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def build_armature():
    armature_data = bpy.data.armatures.new("CharacterArmature")
    armature_obj = bpy.data.objects.new("Character", armature_data)
    bpy.context.collection.objects.link(armature_obj)
    bpy.context.view_layer.objects.active = armature_obj
    armature_obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')

    eb = armature_data.edit_bones

    def add_bone(name, head, tail, parent=None):
        b = eb.new(name)
        b.head = head
        b.tail = tail
        b.use_connect = False
        if parent:
            b.parent = parent
        return b

    root = add_bone("Root", (0, 0, 0), (0, 0, 0.1))
    hips = add_bone("Hips", (0, 0, HIPS_Z), (0, 0, HIPS_Z + 0.1), root)
    spine = add_bone("Spine", (0, 0, HIPS_Z), (0, 0, CHEST_Z), hips)
    head = add_bone("Head", (0, 0, CHEST_Z), (0, 0, HEAD_TOP_Z), spine)

    for side, sign in (("L", 1.0), ("R", -1.0)):
        add_bone(f"UpperArm.{side}", (sign * SHOULDER_X, 0, CHEST_Z), (sign * SHOULDER_X, 0, ELBOW_Z), spine)
        add_bone(f"LowerArm.{side}", (sign * SHOULDER_X, 0, ELBOW_Z), (sign * SHOULDER_X, 0, HAND_Z),
                  eb[f"UpperArm.{side}"])
        add_bone(f"UpperLeg.{side}", (sign * LEG_X, 0, HIPS_Z), (sign * LEG_X, 0, KNEE_Z), hips)
        add_bone(f"LowerLeg.{side}", (sign * LEG_X, 0, KNEE_Z), (sign * LEG_X, 0, FOOT_Z),
                  eb[f"UpperLeg.{side}"])

    bpy.ops.object.mode_set(mode='OBJECT')
    return armature_obj


def add_box_part(name, size, center, bone_name, armature_obj, material):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=center)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    obj.data.materials.append(material)

    vg = obj.vertex_groups.new(name=bone_name)
    vg.add(range(len(obj.data.vertices)), 1.0, 'REPLACE')

    obj.parent = armature_obj
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = armature_obj
    return obj


def build_mesh_parts(armature_obj):
    material = bpy.data.materials.new("CharacterBody")
    material.diffuse_color = (0.75, 0.75, 0.75, 1.0)

    parts = [
        ("Torso", (0.5, 0.32, CHEST_Z - HIPS_Z), (0, 0, (HIPS_Z + CHEST_Z) / 2.0), "Spine"),
        ("Head", (0.36, 0.36, 0.36), (0, 0, (CHEST_Z + HEAD_TOP_Z) / 2.0), "Head"),
    ]
    for side, sign in (("L", 1.0), ("R", -1.0)):
        parts.append((f"UpperArm.{side}", (0.14, 0.14, CHEST_Z - ELBOW_Z),
                       (sign * SHOULDER_X, 0, (CHEST_Z + ELBOW_Z) / 2.0), f"UpperArm.{side}"))
        parts.append((f"LowerArm.{side}", (0.12, 0.12, ELBOW_Z - HAND_Z),
                       (sign * SHOULDER_X, 0, (ELBOW_Z + HAND_Z) / 2.0), f"LowerArm.{side}"))
        parts.append((f"UpperLeg.{side}", (0.17, 0.17, HIPS_Z - KNEE_Z),
                       (sign * LEG_X, 0, (HIPS_Z + KNEE_Z) / 2.0), f"UpperLeg.{side}"))
        parts.append((f"LowerLeg.{side}", (0.15, 0.15, KNEE_Z - FOOT_Z),
                       (sign * LEG_X, 0, (KNEE_Z + FOOT_Z) / 2.0), f"LowerLeg.{side}"))

    for name, size, center, bone_name in parts:
        add_box_part(name, size, center, bone_name, armature_obj, material)


def set_bone_rotation(armature_obj, bone_name, euler_deg, frame):
    pb = armature_obj.pose.bones[bone_name]
    pb.rotation_mode = 'XYZ'
    pb.rotation_euler = (math.radians(euler_deg[0]), math.radians(euler_deg[1]), math.radians(euler_deg[2]))
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)


def set_bone_location(armature_obj, bone_name, loc, frame):
    pb = armature_obj.pose.bones[bone_name]
    pb.location = loc
    pb.keyframe_insert(data_path="location", frame=frame)


def reset_pose(armature_obj):
    for pb in armature_obj.pose.bones:
        pb.rotation_mode = 'XYZ'
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)


def new_action(armature_obj, name):
    if armature_obj.animation_data is None:
        armature_obj.animation_data_create()
    action = bpy.data.actions.new(name)
    armature_obj.animation_data.action = action
    action.use_fake_user = True
    return action


def select_armature(armature_obj):
    bpy.ops.object.select_all(action='DESELECT')
    armature_obj.select_set(True)
    bpy.context.view_layer.objects.active = armature_obj


def build_idle_action(armature_obj):
    select_armature(armature_obj)
    bpy.ops.object.mode_set(mode='POSE')
    reset_pose(armature_obj)
    new_action(armature_obj, "Idle")

    frames = (1, 30, 60)
    breathe = (0.0, -1.5, 0.0)
    for f in frames:
        amount = breathe if f == 30 else (0.0, 0.0, 0.0)
        set_bone_rotation(armature_obj, "Spine", amount, f)
        set_bone_rotation(armature_obj, "Head", (amount[0] * 0.5, amount[1] * -0.5, 0.0), f)
    bpy.ops.object.mode_set(mode='OBJECT')


def build_walk_action(armature_obj):
    select_armature(armature_obj)
    bpy.ops.object.mode_set(mode='POSE')
    reset_pose(armature_obj)
    new_action(armature_obj, "Walk")

    swing = 28.0
    elbow_bend = 15.0
    knee_bend = -20.0

    def pose_at(frame, phase):
        set_bone_rotation(armature_obj, "UpperLeg.L", (phase * swing, 0, 0), frame)
        set_bone_rotation(armature_obj, "UpperLeg.R", (-phase * swing, 0, 0), frame)
        set_bone_rotation(armature_obj, "LowerLeg.L", (max(0.0, -phase) * -knee_bend, 0, 0), frame)
        set_bone_rotation(armature_obj, "LowerLeg.R", (max(0.0, phase) * -knee_bend, 0, 0), frame)
        set_bone_rotation(armature_obj, "UpperArm.L", (-phase * swing * 0.8, 0, 0), frame)
        set_bone_rotation(armature_obj, "UpperArm.R", (phase * swing * 0.8, 0, 0), frame)
        set_bone_rotation(armature_obj, "LowerArm.L", (elbow_bend, 0, 0), frame)
        set_bone_rotation(armature_obj, "LowerArm.R", (elbow_bend, 0, 0), frame)
        set_bone_rotation(armature_obj, "Spine", (0, 0, phase * 4.0), frame)

    pose_at(1, 1.0)
    pose_at(13, -1.0)
    pose_at(24, 1.0)
    bpy.ops.object.mode_set(mode='OBJECT')


def build_death_action(armature_obj):
    select_armature(armature_obj)
    bpy.ops.object.mode_set(mode='POSE')
    reset_pose(armature_obj)
    new_action(armature_obj, "Death")

    set_bone_rotation(armature_obj, "Hips", (0, 0, 0), 1)
    set_bone_rotation(armature_obj, "Spine", (0, 0, 0), 1)
    set_bone_rotation(armature_obj, "Head", (0, 0, 0), 1)
    set_bone_location(armature_obj, "Hips", (0, 0, 0), 1)

    set_bone_rotation(armature_obj, "Hips", (-85.0, 0, 0), 24)
    set_bone_location(armature_obj, "Hips", (0, -0.32, -0.38), 24)
    set_bone_rotation(armature_obj, "Spine", (10.0, 0, 0), 24)
    set_bone_rotation(armature_obj, "Head", (-15.0, 0, 0), 24)
    set_bone_rotation(armature_obj, "UpperLeg.L", (-10.0, 0, 0), 24)
    set_bone_rotation(armature_obj, "UpperLeg.R", (10.0, 0, 0), 24)

    bpy.ops.object.mode_set(mode='OBJECT')


def main():
    clear_scene()
    armature_obj = build_armature()
    build_mesh_parts(armature_obj)

    bpy.context.scene.render.fps = FPS

    build_idle_action(armature_obj)
    build_walk_action(armature_obj)
    build_death_action(armature_obj)

    armature_obj.animation_data.action = bpy.data.actions["Idle"]

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT_PATH,
        export_format='GLB',
        export_animations=True,
        export_animation_mode='ACTIONS',
        export_apply=False,
        use_selection=False,
    )
    print(f"Exporte : {OUTPUT_PATH}")


main()
