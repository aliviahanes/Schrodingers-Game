extends Node

enum LogType {
	INFO,
	WARNING,
	ERROR,
	FATAL
}

## A logging method that provides a standard format for any form of production logging
func log(type: LogType, origin: String, message: String):
	match (type):
		LogType.INFO:
			print("[INFO: %s] %s" % [origin, message])
		LogType.WARNING:
			push_warning("[WARNING: %s] %s" % [origin, message])
		LogType.ERROR:
			push_error("[ERROR: %s] %s" % [origin, message])
		LogType.FATAL:
			push_error("[FATAL: %s] %s" % [origin, message])
