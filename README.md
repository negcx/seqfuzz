Seqfuzz is an implementation of a sequential fuzzy string matching algorithm, similar to those used in code editors like Sublime Text. It is based on Forrest Smith's work on [lib_ftps](https://github.com/forrestthewoods/lib_fts/) and his blog post [Reverse Engineering Sublime Text's Fuzzy Match](https://www.forrestthewoods.com/blog/reverse_engineering_sublime_texts_fuzzy_match/).

There is an alternate implementation by [@WolfDan](https://github.com/WolfDan) which can be found here: [Fuzzy Match v0.2.0 Elixir](https://github.com/tajmone/fuzzy-search/tree/master/fts_fuzzy_match/0.2.0/elixir).

### Documentation

- **GitHub**: [https://github.com/negcx/seqfuzz](https://github.com/negcx/seqfuzz)
- **Hexdocs**: [https://hexdocs.pm/seqfuzz](https://hexdocs.pm/seqfuzz)

## Installation

The package can be installed by adding `seqfuzz` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:seqfuzz, "~> 0.2.0"}
  ]
end
```

## Examples

      iex> Seqfuzz.match("Hello, world!", "hellw")
      %{match?: true, matches: [0, 1, 2, 3, 7], score: 202}

      iex> items = [{1, "Hello Goodbye"}, {2, "Hell on Wheels"}, {3, "Hello, world!"}]
      iex> Seqfuzz.filter(items, "hellw", &(elem(&1, 1)))
      [{3, "Hello, world!"}, {2, "Hell on Wheels"}]

## Scoring

Scores can be passed as options if you want to override the defaults. I have added additional separators as a default as well as two additional scoring features: case match bonus and string match bonus. Case match bonus provides a small bonus for matching case. String match bonus provides a large bonus when the pattern and the string match exactly (although with different cases) to make sure that those results are always highest.

## Changelog

- `0.2.0` - Change scoring to be via options instead of configuration.
- `0.1.0` - Initial version. Supports basic algorithm but does not search recursively for better matches.

## Roadmap

- Add support for recursive search for better matches.
- Add support for asynchronous stream search.
