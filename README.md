# codeclimate-duplication

`codeclimate-duplication` is an engine that wraps [flay] and supports Ruby,
Python, JavaScript, and PHP. You can run it in the command line using the Code
Climate CLI, or on our [hosted analysis platform][codeclimate].

[codeclimate]: https://codeclimate.com/dashboard

## Installation

1. If you haven't already, [install the Code Climate CLI][cli]
2. Run `codeclimate engines:enable duplication`. This command both installs the
  engine and enables it in your `.codeclimate.yml` file.
3. You're ready to analyze! Browse into your project's folder and run
  `codeclimate analyze`.

[cli]: https://github.com/codeclimate/codeclimate

## Configuring

You can add the following to your `.codeclimate.yml` to get started with the
duplication engine.

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
        YOUR_LANGUAGE:
```

This will tell Code Climate to run the duplication engine with `YOUR_LANGUAGE`.
You can also specify a `paths` array under `YOUR_LANGUAGE` which use Ruby's
[`Dir.glob`][glob] format.

For example, all JavaScript and JSX files:

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
        javascript:
          paths:
            - "**/*.js"
            - "**/*.jsx"
```

[glob]: http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob

You can also specify the mass threshold which is what determines how much "mass"
a block of code needs before it's checked for duplication. This varies from
language to language with higher numbers needing more mass to trigger a check
and lower numbers needing less mass.

For example you could tell the engine to check only very large blocks of code:

```
engines:
  duplication:
    enabled: true
    config:
      languages:
        javascript:
          mass_threshold: 300
```
