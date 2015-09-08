var fs = require('fs');
var esprima = require('esprima');
var source = "";

process.stdin.resume();
process.stdin.setEncoding('utf8');

process.stdin.on('data', function(chunk) {
  source += chunk;
});

process.stdin.on('end', function() {
  var result = esprima.parse(source, { loc: true });
  process.stdout.write(JSON.stringify(result));
});
