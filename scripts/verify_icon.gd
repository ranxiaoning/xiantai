extends SceneTree

func _init():
	print("Starting verification of GameMap.tscn UI changes...")
	var scene = load("res://scenes/GameMap.tscn")
	if not scene:
		print("FAILED: Could not load scenes/GameMap.tscn")
		quit(1)
		return
	
	var instance = scene.instantiate()
	if not instance:
		print("FAILED: Could not instantiate scenes/GameMap.tscn")
		quit(1)
		return
	
	var header = instance.get_node("Header")
	if not header:
		print("FAILED: Header node not found")
		quit(1)
		return
	
	var container = header.get_node_or_null("SpiritStoneContainer")
	if not container:
		print("FAILED: SpiritStoneContainer (HBoxContainer) not found in Header")
		# Try looking by unique name if needed, but it should be a direct child
		quit(1)
		return
	
	if not container is HBoxContainer:
		print("FAILED: SpiritStoneContainer is not an HBoxContainer")
		quit(1)
		return
	
	var icon = container.get_node_or_null("SpiritStoneIcon")
	if not icon:
		print("FAILED: SpiritStoneIcon not found in SpiritStoneContainer")
		quit(1)
		return
	
	if not icon is TextureRect:
		print("FAILED: SpiritStoneIcon is not a TextureRect")
		quit(1)
		return
	
	if icon.texture == null:
		print("FAILED: SpiritStoneIcon has no texture assigned")
		quit(1)
		return
	
	print("Icon path: ", icon.texture.resource_path)
	if icon.texture.resource_path != "res://assets/ui/spirit_stone.png":
		print("FAILED: SpiritStoneIcon has wrong texture path: ", icon.texture.resource_path)
		quit(1)
		return
	
	var label = container.get_node_or_null("SpiritStoneLabel")
	if not label:
		print("FAILED: SpiritStoneLabel not found in SpiritStoneContainer")
		quit(1)
		return
	
	if not label.unique_name_in_owner:
		print("FAILED: SpiritStoneLabel unique_name_in_owner is not true")
		quit(1)
		return

	print("SUCCESS: UI structure verified successfully!")
	quit(0)
