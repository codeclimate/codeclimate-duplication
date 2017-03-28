<?php
function hello($name) {
  if (empty($name)) {
    [$foo, $bar] = foo::bar($baz);
    echo "Hello World!";
  } else {
    echo "Hello $name!";
  }
}

function hi($name) {
  if (empty($name)) {
    [$foo, $bar] = foo::bar($baz);
    echo "Hi World!";
  } else {
    echo "Hi $name!";
  }
}
