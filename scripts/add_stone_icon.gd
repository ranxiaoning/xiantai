extends SceneTree

func _init():
    var packed_scene = load("res://scenes/GameMap.tscn")
    if not packed_scene:
        print("Failed to load GameMap.tscn")
        quit(1)
        return
        
    var scene = packed_scene.instantiate()
    var header = scene.get_node("Header")
    var stone_label = header.get_node("SpiritStoneLabel")
    
    if header and stone_label:
        # Create a container for alignment
        var hbox = HBoxContainer.new()
        hbox.name = "StoneContainer"
        hbox.alignment = BoxContainer.ALIGNMENT_END
        hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
        hbox.anchor_left = 0.8
        hbox.offset_right = -20
        hbox.theme_override_constants_separation = 8
        
        # Create icon
        var icon = TextureRect.new()
        icon.name = "StoneIcon"
        icon.texture = load("res://assets/ui/spirit_stone.png")
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.custom_minimum_size = Vector2(24, 24)
        icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        
        # Adjust label
        stone_label.get_parent().remove_child(stone_label)
        stone_label.anchor_left = 0
        stone_label.anchor_right = 0
        stone_label.offset_left = 0
        stone_label.offset_right = 0
        stone_label.text = str(100) # Placeholder
        stone_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        stone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        stone_label.theme_override_colors_set("font_color", Color(0.9, 0.85, 0.4, 1.0)) # Golden
        
        # Assemble
        header.add_child(hbox)
        hbox.add_child(icon)
        hbox.add_child(stone_label)
        
        hbox.owner = scene
        icon.owner = scene
        stone_label.owner = scene
        
        # Save
        var new_packed = PackedScene.new()
        new_packed.pack(scene)
        ResourceSaver.save(new_packed, "res://scenes/GameMap.tscn")
        print("GameMap.tscn updated with spirit stone icon.")
    else:
        print("Header or SpiritStoneLabel not found")
        
    quit()
