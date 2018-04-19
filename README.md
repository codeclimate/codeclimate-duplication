# codeclimate-duplication

[![Maintainability](https://api.codeclimate.com/v1/badges/fab9d005758da2acd1b2/maintainability)](https://codeclimate.com/github/codeclimate/codeclimate-duplication/maintainability)

`codeclimate-duplication` is an engine that wraps [flay] and supports Java, Ruby,
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

### Mass Threshold

We set useful threshold defaults for the languages we support but you may want
to adjust these settings based on your project guidelines.

The mass threshold configuration represents the minimum "mass" a code block must
have to be analyzed for duplication. If the engine is too easily reporting
duplication, try raising the threshold. If you suspect that the engine isn't
catching enough duplication, try lowering the threshold. The best setting tends
to differ from language to language.

To adjust this setting, use the top-level `checks` key in your config file:

```yaml
checks:
  identical-code:
    config:
      threshold: 25
  similar-code:
    config:
      threshold: 50
```

Note that you have the update the YAML structure under the `languages` key to
the Hash type to support extra configuration.

### Count Threshold

By default, the duplication engine will report code that has been duplicated in just two locations. You can be less strict by only raising a warning if code is duplicated in three or more locations only. To adjust this setting, add a `count_threshold` key to your config. For instance, to use the default `mass_threshold` for ruby, but to enforce the [Rule of Three][rule-of-three], you could use this configuration:

```yaml
plugins:
  duplication:
    enabled: true
    config:
      languages:
        ruby:
          count_threshold: 3
```

You can also change the default `count_threshold` for all languages:

```yaml
plugins:
  duplication:
    enabled: true
    config:
      count_threshold: 3
```

### Custom file name patterns

All engines check only appropriate files but you can override default set of
patterns. Patterns are ran against the project root direcory so you have to use
`**` to match files in nested directories. Also note that you have to specify
all patterns, not only the one you want to add.

```yml
plugins:
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

### Node Filtering

Sometimes structural similarities are reported that you just don't
care about. For example, the contents of arrays or hashes might have
similar structures and there's little you can do to refactor them. You
can specify language specific filters to ignore any issues that match
the pattern. Here is an example that filters simple hashes and arrays:

```yaml
plugins:
  duplication:
    enabled: true
    config:
      languages:
        ruby:
          filters:
            - "(hash (lit _) (str _) ___)"
            - "(array (str _) ___)"
```

The syntax for patterns are pretty simple. In the first pattern:
`"(hash (lit _) (str _) ___)"` specifies "A hash with a literal key, a
string value, followed by anything else (including nothing)". You
could also specify `"(hash ___)"` to ignore all hashes altogether.

#### Visualizing the Parse Tree

Figuring out what to filter is tricky. codeclimate-duplication comes
with a configuration option to help with the discovery. Instead of
scanning your code and printing out issues for codeclimate, it prints
out the parse-trees instead! Just add `dump_ast: true` and `debug: true` to your
.codeclimate.yml file:

```
---
plugins:
  duplication:
    enabled: true
    config:
      dump_ast: true
      debug: true
      ... rest of config ...
```

Then run `codeclimate analyze` while using the debug flag to output stderr:

```
% CODECLIMATE_DEBUG=1 codeclimate analyze
```

Running that command might output something like:

```
Sexps for issues:

# 1) ExpressionStatement#4261258897 mass=128:

# 1.1) bogus-examples.js:5

s(:ExpressionStatement,
 :expression,
 s(:AssignmentExpression,
  :"=",
  :left,
  s(:MemberExpression,
   :object,
   s(:Identifier, :EventBlock),
   :property,
   s(:Identifier, :propTypes)),
   ... LOTS more...)
   ... even more LOTS more...)
```

This is the internal representation of the actual code. Assuming
you've looked at those issues and have determined them not to be an
issue you want to address, you can filter it by writing a pattern
string that would match that tree.

Looking at the tree output again, this time flattening it out:

```
s(:ExpressionStatement, :expression, s(:AssignmentExpression, :"=",:left, ...) ...)
```

The internal representation (which is ruby) is different from the
pattern language (which is lisp-like), so first we need to convert
`s(:` to `(` and remove all commas and colons:

```
(ExpressionStatement expression (AssignmentExpression "=" left ...) ...)
```

Next, we don't care bout `expression` so let's get rid of that by
replacing it with the matcher for any single element `_`:

```
(ExpressionStatement _ (AssignmentExpression "=" left ...) ...)
```

The same goes for `"="` and `left`, but we actually don't care about
the rest of the AssignmentExpression node, so let's use the matcher
that'll ignore the remainder of the tree `___`:

```
(ExpressionStatement _ (AssignmentExpression ___) ...)
```

And finally, we don't care about what follows in the
`ExpressionStatement` so let's ignore the rest too:

```
(ExpressionStatement _ (AssignmentExpression ___) ___)
```

This reads: "Any ExpressionStatement node, with any value and an
AssignmentExpression node with anything in it, followed by anything
else". There are other ways to write a pattern to match this tree, but
this is pretty clear.

Then you can add that filter to your config:

```
---
plugins:
  duplication:
    enabled: true
    config:
      dump_ast: true
      languages:
        javascript:
          filters:
          - "(ExpressionStatement _ (AssignmentExpression ___) ___)"
```

Then rerun the analyzer and figure out what the next filter should be.
When you are happy with the results, remove the `dump_ast` config (or
set it to false) to go back to normal analysis.

For more information on pattern matching,
see [sexp_processor][sexp_processor], especially [sexp.rb][sexp.rb]

[codeclimate]: https://codeclimate.com/dashboard
[what-is-duplication]: https://docs.codeclimate.com/docs/duplication-concept
[flay]: https://github.com/seattlerb/flay
[cli]: https://github.com/codeclimate/codeclimate
[rule-of-three]: https://en.wikipedia.org/wiki/Rule_of_three_(computer_programming)
[exclude-files-engine]: https://docs.codeclimate.com/docs/excluding-files-and-folders#section-exclude-paths-for-specific-engines
[sexp_processor]: https://github.com/seattlerb/sexp_processor/
[sexp.rb]: https://github.com/seattlerb/sexp_processor/blob/master/lib/sexp.rb
