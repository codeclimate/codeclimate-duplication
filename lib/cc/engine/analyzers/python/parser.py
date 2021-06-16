import json, sys, ast

PY3 = sys.version_info[0] == 3

def string_type():
    return str if PY3 else basestring

def num_types():
    if PY3:
        return (int, float)
    else:
        return (int, float, long)

def to_json(node):
    json_ast = {'attributes': {}}
    json_ast['_type'] = node.__class__.__name__
    for key, value in ast.iter_fields(node):
        json_ast[key] = cast_value(value)
    for attr in node._attributes:
        json_ast['attributes'][attr] = cast_value(getattr(node, attr))
    return json_ast

def cast_infinity(value):
    if value > 0:
        return "Infinity"
    else:
        return "-Infinity"

def cast_value(value):
    if value is None or isinstance(value, (bool, string_type())):
        return value
    elif PY3 and isinstance(value, bytes):
        return value.decode()
    elif isinstance(value, complex):
        # Complex numbers cannot be serialised directly.  Ruby's to_json
        # handles this by string-ifying the numbers, so we do similarly here.
        return str(complex)
    elif isinstance(value, num_types()):
        if abs(value) == 1e3000:
            return cast_infinity(value)
        return value
    elif isinstance(value, list):
        return [cast_value(v) for v in value]
    else:
        return to_json(value)

if __name__ == '__main__':
    source = ""
    for line in sys.stdin.readlines():
        source += line
    print(json.dumps(to_json(ast.parse(source))))
