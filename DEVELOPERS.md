# Developer notes

## Upgrading php parser

* install php
* `cd vendor/php-parser`
* edit composer.json to use the newer version
* install composer: `curl "https://getcomposer.org/installer" | php`
* update `composer.lock`: `php composer.phar update`
* `rm composer.phar`
