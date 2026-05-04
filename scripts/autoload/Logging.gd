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
			print_stack()
			push_warning("[WARNING: %s] %s" % [origin, message])
		LogType.ERROR:
			print_stack()
			push_error("[ERROR: %s] %s" % [origin, message])
		LogType.FATAL:
			print_stack()
			push_error("[FATAL: %s] %s" % [origin, message])
