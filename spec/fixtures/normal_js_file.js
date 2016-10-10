/* This is a JS file that should not be minified */
function foo() {
  var i = 1;
  for (var j = 0; j < 500; j++) {
    i += j % 3;
  }
  return i;
}

function bar() {
  var i = 1;
  for (var j = 0; j < 500; j++) {
    i += j % 3;
  }
  console.log("This one very long line should not result in the file being considered minified because it is not minified, it is, as they say, unminified. You could call it maxified. If you wanted to. Maybe you don't. I don't know your life, man.");
  return i;
}
