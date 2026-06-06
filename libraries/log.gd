extends Object
class_name Log

static func print(tag: String, ...args):
	print("[" + tag + "] ", "".join(args.map(func(x): return str(x))))

static func push_error(tag: String, ...args):
	push_error("[" + tag + "] ", "".join(args.map(func(x): return str(x))))

static func push_warning(tag: String, ...args):
	push_warning("[" + tag + "] ", "".join(args.map(func(x): return str(x))))
