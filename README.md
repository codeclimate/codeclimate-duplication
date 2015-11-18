# codeclimate-duplication

`codeclimate-duplication` is an engine that wraps [flay] and supports Ruby,
Python, JavaScript, and PHP. You can run it on the command line using the Code
Climate CLI or on our [hosted analysis platform][codeclimate].

## Installation

1. Install the [Code Climate CLI][cli], if you haven't already.
2. Run `codeclimate engines:enable duplication`. This command installs the
   engine and enables it in your `.codeclimate.yml` file.
3. You're ready to analyze! `cd` into your project's folder and run `codeclimate
   analyze`.

## Configuring

### Languages

By enabling the duplication engine with the Code Climate CLI, all supported
languages are configured by default, but we recommend adjusting this
configuration to enable only the languages you care about. If you have a project
with Ruby and JavaScript files, you might want the following configuration:

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
      - ruby
      - javascript
```

This will tell the duplication engine to analyze Ruby and JavaScript files.

### Threshold

We set useful threshold defaults for the languages we support but you may want
to adjust these settings based on your project guidelines.

The threshold configuration represents the minimum "mass" a code block must have
to be analyzed for duplication. If the engine is too easily reporting
duplication, try raising the threshold. If you suspect that the engine isn't
catching enough duplication, try lowering the threshold. The best setting tends
to differ from language to language.

You can set thresholds for the two different types of duplication this engine
reports: blocks that are identical to each other, and blocks that are
structurally similar but differ in content.

To adjust these thresholds, you can add `identical_mass_threshold` and
`similar_mass_threshold` keys with your preferred value for
an enabled language:

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
        ruby:
          identical_mass_threshold: 20
          similar_mass_threshold: 30
        javascript:
```

If you would like to use the same threshold for both identical & similar issues,
you can just set the `mass_threshold` key.

Note that you have to update the YAML structure under the `langauges` key to
the Hash type to support extra configuration.

[codeclimate]: https://codeclimate.com/dashboard
[flay]: https://github.com/seattlerb/flay
[cli]: https://github.com/codeclimate/codeclimate
