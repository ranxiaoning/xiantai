extends SceneTree

func _init():
	var out_file = FileAccess.open("res://check_output.txt", FileAccess.WRITE)
	out_file.store_line("Starting check...")
	
	var packed_scene = load("res://scenes/GameMap.tscn")
	if not packed_scene:
		out_file.store_line("ERROR: Failed to load res://scenes/GameMap.tscn")
		out_file.close()
		quit(1)
		return
	
	var scene = packed_scene.instantiate()
	if not scene:
		out_file.store_line("ERROR: Failed to instantiate res://scenes/GameMap.tscn")
		out_file.close()
		quit(1)
		return
		
	out_file.store_line("SUCCESS: Scene loaded and instantiated.")
	
	var header = scene.get_node("Header")
	if header:
		out_file.store_line("Children of Header:")
		for child in header.get_children():
			out_file.store_line(" - " + child.name)
	
	out_file.close()
	quit()
