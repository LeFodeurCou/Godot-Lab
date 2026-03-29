extends CanvasLayer

class_name UiBase

var previousMouseMode: int
var pauseAllowed: bool

signal closeRequest

func open():
	push_warning("UiBase.open() not implemented in " + name)
func close(): 
	push_warning("UiBase.close() not implemented in " + name)
func requestClose(): closeRequest.emit()
