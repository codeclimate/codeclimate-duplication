import json, sys, ast, _ast

PY3 = sys.version_info[0] == 3

try:
    from _ast import AsyncFunctionDef
    additional_docstring_types = [AsyncFunctionDef]
except ImportError:
    additional_docstring_types = []

possible_docstring_types = [_ast.FunctionDef, _ast.ClassDef, _ast.Module]
possible_docstring_types.extend(additional_docstring_types)

def string_type():
    return str if PY3 else basestring

def num_types():
    if PY3:
        return (int, float, complex)
    else:
        return (int, float, long, complex)

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
    elif isinstance(value, num_types()):
        if abs(value) == 1e3000:
            return cast_infinity(value)
        return value
    elif isinstance(value, list):
        return [cast_value(v) for v in value]
    else:
        return to_json(value)

def remove_docstring_from_ast(tree):
    for node in ast.walk(tree):
        if (type(node) in possible_docstring_types and node.body and isinstance(node.body[0], _ast.Expr)
                    and isinstance(node.body[0].value, _ast.Str)):
                node.body.pop(0)

if __name__ == '__main__':
    source = ""
    for line in sys.stdin.readlines():
        source += line
    tree = ast.parse(source)
    remove_docstring_from_ast(tree)
    print(json.dumps(to_json(tree)))
