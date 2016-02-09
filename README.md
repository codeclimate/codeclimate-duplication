# codeclimate-duplication

[![Code Climate](https://codeclimate.com/github/codeclimate/codeclimate-duplication/badges/gpa.svg)](https://codeclimate.com/github/codeclimate/codeclimate-duplication) [![codebeat badge](https://codebeat.co/badges/05f080b5-e2b1-4ca4-a734-6019c53cc491)](https://codebeat.co/projects/github-com-codeclimate-codeclimate-duplication)

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

To adjust this setting, add a `mass_threshold` key with your preferred value for
an enabled language:

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
        ruby:
          mass_threshold: 20
        javascript:
```

Note that you have the update the YAML structure under the `languages` key to
the Hash type to support extra configuration.

[codeclimate]: https://codeclimate.com/dashboard
[flay]: https://github.com/seattlerb/flay
[cli]: https://github.com/codeclimate/codeclimate
