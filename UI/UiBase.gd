extends CanvasLayer

class_name UiBase

var previousMouseMode: int
var pauseAllowed: bool

signal closeRequest

func open(): pass
func close(): pass
func requestClose(): closeRequest.emit()
