<?php

require dirname(__FILE__)."/vendor/autoload.php";
require dirname(__FILE__)."/lib/PhpParser/Serializer/JSON.php";

ini_set('xdebug.max_nesting_level', 2000);

try {

  $parser = new PhpParser\Parser(new PhpParser\Lexer\Emulative);
  $code = file_get_contents("php://stdin");
  $stmts = $parser->parse($code);

  $serializer = new PhpParser\Serializer\JSON;
  $nodes = $serializer->serialize($stmts);
  echo json_encode($nodes);

} catch (PHPParser\Error $e) {
  fwrite(STDERR, "Parse Error: ".$e->getMessage()."\n");
  exit(1);
}
