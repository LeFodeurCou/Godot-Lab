extends CanvasLayer

class_name UiBase

var previousMouseMode: int
var pauseAllowed: bool

signal closeRequest

func open():
	push_warning("UiBase.open() not implemented in " + name)
func close() -> Signal: 
	push_warning("UiBase.close() not implemented in " + name)
	return get_tree().create_timer(0.0).timeout
func requestClose(): closeRequest.emit()
func refreshLocalization() -> void:
	pass
