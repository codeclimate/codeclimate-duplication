# Developer notes

## Upgrading php parser

* install php
* `cd vendor/php-parser`
* edit composer.json to use the newer version
* install composer: `curl "https://getcomposer.org/installer" | php`
* update `composer.lock`: `php composer.phar update`
* `rm composer.phar`

## QA

There is an automated [QA tool](https://github.com/codeclimate/qm_qa) that can
be used to run the engine against a popular set of OSS repos across supported
languages. If you are adding a new language here, please add that language to
the list of languages scanned by the QA tool, and run it!
