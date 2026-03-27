@tool
extends PanelContainer

const PREVIEW_PADDING := 16.0
const PREVIEW_GAP := 20.0
const PREVIEW_LABEL_HEIGHT := 24.0
const PREVIEW_BORDER_COLOR := Color(0.45, 0.45, 0.45, 0.1)

var texture: Texture2D
var rows: Array[Dictionary] = []
var export_file_dialog: FileDialog

@onready var hframes_spinbox: SpinBox = $MarginContainer/VBoxContainer/GridContainer/HFrames
@onready var vframes_spinbox: SpinBox = $MarginContainer/VBoxContainer/GridContainer/VFrames
@onready var fps_spinbox: SpinBox = $MarginContainer/VBoxContainer/GridContainer/FPS
@onready var file_dialog: FileDialog = $MarginContainer/VBoxContainer/FileDialog
@onready var subviewport: SubViewport = $MarginContainer/VBoxContainer/PreviewTabs/AnimationPreview/ScrollContainer/SubViewportContainer/SubViewport
@onready var subviewport_container: SubViewportContainer = $MarginContainer/VBoxContainer/PreviewTabs/AnimationPreview/ScrollContainer/SubViewportContainer
@onready var texture_grid: GridContainer = $MarginContainer/VBoxContainer/PreviewTabs/TexturePreview/ScrollContainer/GridContainer
@onready var generate_all_button: Button = $MarginContainer/VBoxContainer/GenerateButton
@onready var export_button: Button = $MarginContainer/VBoxContainer/ExportButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    hframes_spinbox.value = 13
    vframes_spinbox.value = 54
    fps_spinbox.value = 5
    subviewport_container.stretch = false
    hframes_spinbox.value_changed.connect(_on_frames_changed)
    vframes_spinbox.value_changed.connect(_on_frames_changed)
    generate_all_button.pressed.connect(_generate_all_animations)
    _setup_export_file_dialog()
    _clear_preview_sprites()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass


func _on_pick_button_pressed() -> void:
    file_dialog.popup_centered()


func _on_file_dialog_file_selected(path: String) -> void:
    texture = load(path) as Texture2D
    _create_preview_grid()
    
    
func _create_preview_grid() -> void:
    var cw = texture.get_width() / hframes_spinbox.value
    var ch = texture.get_height() / vframes_spinbox.value
    subviewport.size = Vector2(cw, ch)
    _clear_preview_sprites()

    texture_grid.columns = hframes_spinbox.value + 1
    for child in texture_grid.get_children():
        child.queue_free()
    # Build the per-row preview grid.
    var image = texture.get_image()
    rows.clear()
    for iy in range(vframes_spinbox.value):
        var vbox = VBoxContainer.new()
        var name_edit = LineEdit.new()
        var name_button = Button.new()
        name_edit.text = "Anim%d" % iy
        name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
        name_button.text = "Generate"
        name_button.pressed.connect(func():
            _generate_animation(name_edit.text, iy)
        )
        vbox.add_child(name_edit)
        vbox.add_child(name_button)
        texture_grid.add_child(vbox)
        var row_frames_count = 0
        for ix in range(hframes_spinbox.value):
            var rect = Rect2(
                ix * cw,
                iy * ch,
                cw,
                ch
            )
            if not _has_visible_pixel(image, rect):
                texture_grid.add_child(Control.new())
            else:
                var atlas = AtlasTexture.new()
                atlas.atlas = texture
                atlas.region = rect
                var texture_rect = TextureRect.new()
                texture_rect.texture = atlas
                texture_grid.add_child(texture_rect)
                row_frames_count += 1
        rows.append({
            "count": row_frames_count,
            "name_edit": name_edit
        })


func _generate_sprite_frames(anim_name: String, row: int, count: int) -> SpriteFrames:
    var frames = SpriteFrames.new()
    frames.add_animation(anim_name)
    frames.set_animation_speed(anim_name, fps_spinbox.value)
    var cw = texture.get_width() / hframes_spinbox.value
    var ch = texture.get_height() / vframes_spinbox.value
    for i in range(count):
        var atlas = AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = Rect2(
            cw * i,
            row * ch,
            cw,
            ch
        )
        frames.add_frame(anim_name, atlas)
    return frames

func _has_visible_pixel(image: Image, rect: Rect2) -> bool:
    for y in range(rect.position.y, rect.position.y + rect.size.y):
        for x in range(rect.position.x, rect.position.x + rect.size.x):
            var color = image.get_pixel(x, y)
            if color.a > 0.0:
                return true
    return false


func _on_frames_changed(value):
    var h = hframes_spinbox.value
    var v = vframes_spinbox.value
    _create_preview_grid()


func _generate_all_animations():
    var has_default_anim = false
    for i in range(rows.size()):
        if _get_row_anim_name(i).to_lower() == "default":
            has_default_anim = true
            break

    if not has_default_anim:
        push_warning("Set one animation name to 'default' before exporting.")
        return

    for i in range(rows.size()):
        var anim_name = _get_row_anim_name(i)
        _generate_animation(anim_name, i)


func _clear_preview_sprites() -> void:
    for child in subviewport.get_children():
        if child is AnimatedSprite2D and not child.has_meta("preview_item"):
            child.queue_free()
        elif child.has_meta("preview_item") and child.get_meta("preview_item"):
            child.queue_free()


func _layout_preview_sprites() -> void:
    var preview_sprites: Array[AnimatedSprite2D] = []
    var preview_names: Array[String] = []
    for child in subviewport.get_children():
        if child is AnimatedSprite2D and child.has_meta("preview_item") and child.get_meta("preview_item"):
            preview_sprites.append(child)
            preview_names.append(str(child.get_meta("anim_name", "")))

    if preview_sprites.is_empty() or texture == null:
        return

    for child in subviewport.get_children():
        if child is ColorRect:
            child.queue_free()
        elif child is Label:
            child.queue_free()

    var cell_width = float(texture.get_width()) / hframes_spinbox.value
    var cell_height = float(texture.get_height()) / vframes_spinbox.value
    var sprite_count = preview_sprites.size()
    var column_count = max(1, int(ceil(sqrt(float(sprite_count)))))
    var row_count = int(ceil(float(sprite_count) / column_count))
    var item_width = cell_width + PREVIEW_GAP
    var item_height = cell_height + PREVIEW_LABEL_HEIGHT + PREVIEW_GAP

    for index in range(sprite_count):
        var column = index % column_count
        var row_index = index / column_count
        var origin = Vector2(
            PREVIEW_PADDING + item_width * column,
            PREVIEW_PADDING + item_height * row_index
        )
        var border = ColorRect.new()
        border.color = PREVIEW_BORDER_COLOR
        border.position = origin
        border.size = Vector2(cell_width + PREVIEW_GAP, cell_height + PREVIEW_LABEL_HEIGHT)
        border.set_meta("preview_item", true)
        subviewport.add_child(border)

        var label = Label.new()
        label.text = preview_names[index]
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.position = origin + Vector2(0, cell_height + 2)
        label.size = Vector2(cell_width + PREVIEW_GAP, PREVIEW_LABEL_HEIGHT)
        label.clip_text = true
        label.set_meta("preview_item", true)
        subviewport.add_child(label)

        var sprite_position = Vector2(
            origin.x + (cell_width + PREVIEW_GAP) * 0.5,
            origin.y + cell_height * 0.5
        )
        preview_sprites[index].set_meta("preview_item", true)
        preview_sprites[index].centered = true
        preview_sprites[index].position = sprite_position

    var preview_size = Vector2(
        PREVIEW_PADDING * 2 + item_width * column_count,
        PREVIEW_PADDING * 2 + item_height * row_count
    )
    subviewport.size = preview_size
    subviewport_container.custom_minimum_size = preview_size


func _generate_animation(anim_name: String, row: int):
    var animated_sprite = AnimatedSprite2D.new()
    var frames = _generate_sprite_frames(anim_name, row, _get_row_count(row))
    animated_sprite.set_meta("preview_item", true)
    animated_sprite.set_meta("anim_name", anim_name)
    animated_sprite.frames = frames
    animated_sprite.play(anim_name)
    subviewport.add_child(animated_sprite)
    _layout_preview_sprites()

func _setup_export_file_dialog() -> void:
    export_file_dialog = FileDialog.new()
    export_file_dialog.title = "Save SpriteFrames"
    export_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
    export_file_dialog.access = FileDialog.ACCESS_RESOURCES
    export_file_dialog.filters = PackedStringArray(["*.tres ; SpriteFrames Resource", "*.res ; Binary Resource"])
    export_file_dialog.file_selected.connect(_on_export_file_selected)
    add_child(export_file_dialog)


func _get_row_anim_name(row: int) -> String:
    var row_name = "Anim%d" % row
    if row < 0 or row >= rows.size():
        return row_name

    var input = rows[row].get("name_edit", null) as LineEdit
    if input != null:
        var custom_name = input.text.strip_edges()
        if not custom_name.is_empty():
            return custom_name
    return row_name


func _get_row_count(row: int) -> int:
    if row < 0 or row >= rows.size():
        return 0
    return int(rows[row].get("count", 0))


func _build_export_frames() -> SpriteFrames:
    var export_frames = SpriteFrames.new()
    for row in range(rows.size()):
        var frame_count = _get_row_count(row)
        if frame_count <= 0:
            continue

        var anim_name = _get_row_anim_name(row)
        export_frames.add_animation(anim_name)
        export_frames.set_animation_speed(anim_name, fps_spinbox.value)
        var cw = texture.get_width() / hframes_spinbox.value
        var ch = texture.get_height() / vframes_spinbox.value
        for i in range(frame_count):
            var atlas = AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(
                cw * i,
                row * ch,
                cw,
                ch
            )
            export_frames.add_frame(anim_name, atlas)
    return export_frames


func _on_export_button_pressed() -> void:
    if texture == null:
        push_warning("Please select a texture before exporting SpriteFrames.")
        return

    if rows.is_empty():
        push_warning("No frame data to export. Please load texture and generate preview first.")
        return

    export_file_dialog.current_file = "sprite_frames.tres"
    export_file_dialog.popup_centered_ratio(0.6)


func _on_export_file_selected(path: String) -> void:
    var export_frames = _build_export_frames()
    var has_animation = false
    for anim_name in export_frames.get_animation_names():
        if export_frames.get_frame_count(anim_name) > 0:
            has_animation = true
            break

    if not has_animation:
        push_warning("No valid animations to export.")
        return

    var result = ResourceSaver.save(export_frames, path)
    if result != OK:
        push_warning("Failed to export SpriteFrames. Error code: %d" % result)
        return

    print("SpriteFrames exported to: %s" % path)
