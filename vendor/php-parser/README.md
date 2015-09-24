# parser.php

Simple I/O wrapper over the [PHP-Parser](https://github.com/nikic/PHP-Parser) library.

## Installation

PHP Parser relies on composer:

```
composer install
```

## Usage

Pass a string of PHP on `stdin`, get a JSON AST on `stdout`.

```
$ cat test/test.php | php parser.php
```

## Running Tests

There is a simple smoke test which asserts that the above example works
as expected.

```
$ ./test/run
PASS
```

