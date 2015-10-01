import json, sys, ast

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
    if value is None or isinstance(value, (bool, basestring)):
        return value
    elif isinstance(value, (int, float, long, complex)):
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
    print json.dumps(to_json(ast.parse(source)))
