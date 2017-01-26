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
        ruby:
        javascript:
```

This will tell the duplication engine to analyze Ruby and JavaScript files.

### Mass Threshold

We set useful threshold defaults for the languages we support but you may want
to adjust these settings based on your project guidelines.

The mass threshold configuration represents the minimum "mass" a code block must
have to be analyzed for duplication. If the engine is too easily reporting
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

### Count Threshold

By default, the duplication engine will report code that has been duplicated in just two locations. You can be less strict by only raising a warning if code is duplicated in three or more locations only. To adjust this setting, add a `count_threshold` key to your config. For instance, to use the default `mass_threshold` for ruby, but to enforce the [Rule of Three][rule-of-three], you could use this configuration:

```yaml
engines:
  duplication:
    enabled: true
    config:
      languages:
        ruby:
          count_threshold: 3
```

You can also change the default count_threshold for all languages:

```yaml
engines:
  duplication:
    enabled: true
    count_threshold: 3
```

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

### Custom file name patterns

All engines check only appropriate files but you can override default set of
patterns. Patterns are ran aginast the project root direcory so you have to use
`**` to match files in nested directories. Also note that you have to specify
all patterns, not only the one you want to add.

```yml
engines:
  duplication:
    enabled: true
    config:
      languages:
        ruby:
          patterns:
            - "**/*.rb
            - "**/*.rake"
            - "Rakefile"
            - "**/*.ruby"
```



[codeclimate]: https://codeclimate.com/dashboard
[what-is-duplication]: https://docs.codeclimate.com/docs/duplication-concept
[flay]: https://github.com/seattlerb/flay
[cli]: https://github.com/codeclimate/codeclimate
[rule-of-three]: https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming)
[exclude-files-engine]: https://docs.codeclimate.com/docs/excluding-files-and-folders#section-exclude-paths-for-specific-engines
