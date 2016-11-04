# codeclimate-duplication

[![Code Climate](https://codeclimate.com/github/codeclimate/codeclimate-duplication/badges/gpa.svg)](https://codeclimate.com/github/codeclimate/codeclimate-duplication)

`codeclimate-duplication` is an engine that wraps [flay] and supports Ruby,
Python, JavaScript, and PHP. You can run it on the command line using the Code
Climate CLI or on our [hosted analysis platform][codeclimate].

## What is duplication?

The duplication engine's algorithm can be surprising, but it's actually very
simple. We have a [docs page][what-is-duplication] explaining the algorithm.

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

#### JavaScript

The engine uses `babylon` to parse JS source code. Here's a configuration
example that enables both `flow` and `jsx`:

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
      - javascript
      javascript_plugins:
      - flow
      - jsx
```

For a full list of Babylon plugins: https://github.com/babel/babylon#plugins

**Note:** If no `config.javascript_plugins` is provided, the default includes
`jsx` and `objectRestSpread`.

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

### Excluding files and directories

As with any other Code Climate engine, you can exclude certain files or
directories from being analyzed. For more information, see
[*Exclude paths for specific engines*][exclude-files-engine] in our
documentation.

```yaml
engines:
  duplication:
    exclude_paths:
    - examples/
```

[codeclimate]: https://codeclimate.com/dashboard
[what-is-duplication]: https://docs.codeclimate.com/docs/duplication-concept
[flay]: https://github.com/seattlerb/flay
[cli]: https://github.com/codeclimate/codeclimate
[exclude-files-engine]: https://docs.codeclimate.com/docs/excluding-files-and-folders#section-exclude-paths-for-specific-engines
