var babylon = require("babylon");

process.stdin.resume();

var source = "";
var toScrub = [
  'leadingComments',
  'trailingComments',
  'innerComments',
  'shadow',
  'start',
  'end',
  'raw',
  'rawValue'
];

process.stdin.on('data', function(chunk) {
  source += chunk;
});

process.stdin.on('end', function() {
  var ast = babylon.parse(source, { plugins: ["jsx", "objectRestSpread"], strictMode: false, sourceType: "module" });
  var program = ast.program;
  console.log(
    JSON.stringify(format(program))
  );
});

var format = function(node) {
  var result = {};

  for(var prop in node) {
    if (node.hasOwnProperty(prop) && !prop.startsWith("_") && toScrub.indexOf(prop) === -1) {
      var value = node[prop];

      if (value) {
        if (value.constructor === Array) {
          result[prop] = value.map(function(p) {
            return format(p)
          });
        } else if (prop === "loc") {
          result["start"] = value.start.line;
          result["end"] = value.end.line;
        } else if (typeof(value) === "object") {
          result[prop] = format(value);
        } else  {
          result[prop] = node[prop];
        }
      }
    }
  }

  return result;
}
