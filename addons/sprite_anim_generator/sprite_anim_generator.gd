@tool
extends EditorPlugin

var editor = null

func _enable_plugin() -> void:
    print("Sprite Animation Generator plugin enabled.")


func _disable_plugin() -> void:
    print("Sprite Animation Generator plugin disabled.")


func _enter_tree() -> void:
    editor = preload("res://addons/sprite_anim_generator/editor.tscn").instantiate()
    editor.name = "SAG"
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, editor)


func _exit_tree() -> void:
    if editor:
        remove_control_from_docks(editor)
        editor.queue_free()
        editor = null

func _get_plugin_icon() -> Texture2D:
    return preload("res://addons/sprite_anim_generator/logo.svg")


func _get_plugin_name() -> String:
    return "Sprite Animation Generator (SAG)"