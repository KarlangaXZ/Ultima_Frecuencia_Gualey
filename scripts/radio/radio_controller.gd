extends Node
## Secuencia textual reutilizable. La vista gestiona la modalidad y el cierre.
signal message_changed(sender: String, message: String, index: int, total: int)
signal finished
var transmission: RadioTransmission
var index := 0
var enabled := true

func play(value: RadioTransmission) -> bool:
	if not enabled or value == null or value.messages.is_empty(): return false
	transmission = value
	index = 0
	_emit_message()
	return true

func advance() -> void:
	if not enabled or transmission == null: return
	index += 1
	if index >= transmission.messages.size():
		transmission = null
		finished.emit()
	else: _emit_message()

func _emit_message() -> void:
	message_changed.emit(transmission.sender, transmission.messages[index], index + 1, transmission.messages.size())

func stop() -> void:
	enabled = false
	transmission = null
	finished.emit()
