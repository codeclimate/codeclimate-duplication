<?php

require dirname(__FILE__)."/vendor/autoload.php";
require dirname(__FILE__)."/lib/PhpParser/Serializer/JSON.php";

ini_set('xdebug.max_nesting_level', 2000);

try {

  $parser = (new PhpParser\ParserFactory)->create(PhpParser\ParserFactory::PREFER_PHP7);
  $code = file_get_contents("php://stdin");
  $stmts = $parser->parse($code);

  $serializer = new PhpParser\Serializer\JSON;
  $nodes = $serializer->serialize($stmts);
  $json = json_encode($nodes);
  if (false === $json) {
    fwrite(STDERR, "Parse Error: JSON encoding failed: ".json_last_error_msg()."\n");
    exit(1);
  } else {
    echo $json;
  }
} catch (PHPParser\Error $e) {
  fwrite(STDERR, "Parse Error: ".$e->getMessage()."\n");
  exit(1);
}
