# path: scripts/data/DataFolder.gd
class_name DataFolder
extends RefCounted
## Lists resource files in a folder. Works in editor and exported builds (.remap aware).


static func list_resource_paths(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("DataFolder: cannot open %s" % dir_path)
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var clean := file_name.trim_suffix(".remap")
			if clean.ends_with(".tres") or clean.ends_with(".res"):
				var full_path := dir_path.path_join(clean)
				if not result.has(full_path):
					result.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result
