class_name SaveFileStore
extends RefCounted
## Solo datos JSON. tmp verificado → respaldo anterior → archivo definitivo.
var directory := "user://saves"
const MAX_BYTES := 2097152
func path_for(slot: int) -> String:
	return directory.path_join("autosave.json" if slot == 0 else "slot_%d.json" % slot)
func occupied(slot: int) -> bool:
	return FileAccess.file_exists(path_for(slot)) or FileAccess.file_exists(path_for(slot) + ".bak")
func _read(path: String, slot: int) -> Dictionary:
	if not FileAccess.file_exists(path): return {"error": "Ranura vacía."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"error": "No se pudo abrir el archivo (%s)." % error_string(FileAccess.get_open_error())}
	if file.get_length() > MAX_BYTES:
		file.close()
		return {"error": "El archivo supera el tamaño permitido."}
	var raw := file.get_as_text()
	var read_error := file.get_error()
	file.close()
	if read_error not in [OK, ERR_FILE_EOF]: return {"error": "No se pudo leer la partida."}
	var parser := JSON.new()
	if parser.parse(raw) != OK: return {"error": "Archivo dañado: JSON inválido."}
	var problem := SaveSchema.validate(parser.data, slot)
	return {"data": parser.data, "recovered": false} if problem.is_empty() else {"error": problem}
func read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot > 3: return {"error": "Ranura inválida."}
	var primary := _read(path_for(slot), slot)
	if primary.has("data"): return primary
	var backup := _read(path_for(slot) + ".bak", slot)
	if backup.has("data"):
		backup.recovered = true
		return backup
	if not FileAccess.file_exists(path_for(slot)) and FileAccess.file_exists(path_for(slot) + ".bak"): return backup
	return primary
func write_slot(slot: int, data: Dictionary, confirmed := false) -> Dictionary:
	if slot < 0 or slot > 3: return {"error": "Ranura inválida."}
	var problem := SaveSchema.validate(data, slot)
	if not problem.is_empty(): return {"error": problem}
	if occupied(slot) and not confirmed: return {"error": "Confirma antes de sobrescribir.", "confirmation_required": true}
	var absolute := ProjectSettings.globalize_path(directory)
	var result := DirAccess.make_dir_recursive_absolute(absolute)
	if result != OK: return {"error": "No se pudo crear la carpeta de guardado (%s)." % error_string(result)}
	var path := path_for(slot)
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return {"error": "No se pudo escribir el guardado (%s)." % error_string(FileAccess.get_open_error())}
	file.store_string(JSON.stringify(data, "\t", true, true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK: return {"error": "Escritura incompleta; la partida anterior se conserva."}
	if not _read(temporary, slot).has("data"): return {"error": "No se pudo verificar el archivo temporal."}
	if FileAccess.file_exists(path):
		if _read(path, slot).has("data"):
			if FileAccess.file_exists(backup):
				result = DirAccess.remove_absolute(backup)
				if result != OK: return {"error": "No se pudo renovar el respaldo."}
			result = DirAccess.rename_absolute(path, backup)
		else:
			# Un primario dañado nunca sustituye un respaldo válido.
			result = DirAccess.remove_absolute(path)
		if result != OK: return {"error": "No se pudo preparar el reemplazo; se conserva la partida anterior."}
	result = DirAccess.rename_absolute(temporary, path)
	if result != OK:
		if FileAccess.file_exists(backup) and not FileAccess.file_exists(path): DirAccess.copy_absolute(backup, path)
		return {"error": "No se pudo finalizar el guardado; hay un respaldo recuperable."}
	return {"ok": true}
