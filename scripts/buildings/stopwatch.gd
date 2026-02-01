extends Label

var _started = false
var _time = 0.0

func _process(delta: float) -> void:
	if _started:
		_time += delta
		
		var m = floori(_time / 60)
		var s = floori(_time) % 60
		var ms = floori(_time * 1000) % 1000
		text = "%d:%02d.%03d" % [m, s, ms]

func start():
	_started = true

func stop():
	_started = false
