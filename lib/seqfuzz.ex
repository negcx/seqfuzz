defmodule Seqfuzz do
  @moduledoc """
  Seqfuzz is an implementation of a sequential fuzzy string matching algorithm, similar to those used in code editors like Sublime Text. It is based on Forrest Smith's work on [lib_ftps](https://github.com/forrestthewoods/lib_fts/) and his blog post [Reverse Engineering Sublime Text's Fuzzy Match](https://www.forrestthewoods.com/blog/reverse_engineering_sublime_texts_fuzzy_match/).

  There is an alternate implementation by [@WolfDan](https://github.com/WolfDan) which can be found here: [Fuzzy Match v0.2.0 Elixir](https://github.com/tajmone/fuzzy-search/tree/master/fts_fuzzy_match/0.2.0/elixir).

  ## Examples

      iex> Seqfuzz.match("Hello, world!", "hellw")
      %{match?: true, matches: [0, 1, 2, 3, 7], score: 187}

      iex> items = [{1, "Hello Goodbye"}, {2, "Hell on Wheels"}, {3, "Hello, world!"}]
      iex> Seqfuzz.filter(items, "hellw", &(elem(&1, 1)))
      [{3, "Hello, world!"}, {2, "Hell on Wheels"}]

  ## Scoring

  Scores can be configured in your mix configuration. I have added additional separators as a default as well as two additional scoring features: case match bonus and string match bonus. Case match bonus provides a small bonus for matching case. String match bonus provides a large bonus when the pattern and the string match exactly (although with different cases) to make sure that those results are always highest.

  The default scores and available settings are:

      config :seqfuzz,
        sequential_bonus: 15,
        separator_bonus: 30,
        camel_bonus: 30,
        first_letter_bonus: 15,
        leading_letter_penalty: -3,
        max_leading_letter_penalty: -25,
        unmatched_letter_penalty: -1,
        case_match_bonus: 1,
        string_match_bonus: 20,
        separators: ["_", " ", ".", "/", ","],
        initial_score: 100

  ## Changelog

  * `0.1.0` - Initial version. Supports basic algorithm but does not search recursively for better matches.

  ## Roadmap

  * Add support for recursive search for better matches.
  * Add support for asynchronous stream search.
  """

  @type match_metadata :: %{match?: boolean, matches: [integer], score: integer}

  @doc """
  Determines whether `pattern` is a sequential fuzzy match with `string` and provides a matching score. `matches` is a list of indices within `string` where a match was found.

  ## Examples

      iex> Seqfuzz.match("Hello, world!", "hellw")
      %{match?: true, matches: [0, 1, 2, 3, 7], score: 187}

  """
  @spec match(String.t(), String.t()) :: match_metadata()
  def match(string, pattern) do
    match(string, pattern, 0, 0, [])
  end

  @doc """
  Applies the `match` algorithm to the entire `enumerable` with options to sort and filter.

  ## Options

  * `:sort` - Sort the enumerable by score, defaults to `false`.
  * `:filter` - Filter out elements that don't match, defaults to `false`.
  * `:metadata` - Include the match metadata map in the result, defaults to `true`. When `true` the return value is a tuple `{element, %{...}}`. When `false`, the return value is a list of `element`.

  ## Examples

      iex> strings = ["Hello Goodbye", "Hell on Wheels", "Hello, world!"]
      iex> Seqfuzz.matches(strings, "hellw", & &1)
      [
        {"Hello Goodbye", %{match?: false, matches: [0, 1, 2, 3], score: 155}},
        {"Hell on Wheels", %{match?: true, matches: [0, 1, 2, 3, 8], score: 185}},
        {"Hello, world!", %{match?: true, matches: [0, 1, 2, 3, 7], score: 187}}
      ]

      iex> strings = ["Hello Goodbye", "Hell on Wheels", "Hello, world!"]
      iex> Seqfuzz.matches(
      iex>   strings,
      iex>   "hellw",
      iex>   & &1,
      iex>   metadata: false,
      iex>   filter: true,
      iex>   sort: true
      iex> )
      ["Hello, world!", "Hell on Wheels"]

  """
  @spec matches(Enumerable.t(), String.t(), (any -> String.t()), keyword) ::
          Enumerable.t() | [{any, match_metadata}]
  def matches(enumerable, pattern, string_callback, opts \\ []) do
    opts = [sort: false, filter: false, metadata: true] |> Keyword.merge(opts)

    enumerable
    |> Enum.map(fn item ->
      {item, match(string_callback.(item), pattern)}
    end)
    |> matches_filter(opts[:filter])
    |> matches_sort(opts[:sort])
    |> matches_metadata(opts[:metadata])
  end

  @doc """
  Matches against a list of strings and returns the list of matches sorted by highest score first.

  ## Examples

      iex> strings = ["Hello Goodbye", "Hell on Wheels", "Hello, world!"]
      iex> Seqfuzz.filter(strings, "hellw")
      ["Hello, world!", "Hell on Wheels"]
  """
  @spec filter(Enumerable.t(), String.t()) :: Enumerable.t()
  def filter(enumerable, pattern) do
    enumerable
    |> matches(pattern, & &1, sort: true, filter: true, metadata: false)
  end

  @doc """
  Matches against an enumerable using a callback to access the string to match and returns the list of matches sorted by highest score first.

  ## Examples

      iex> items = [{1, "Hello Goodbye"}, {2, "Hell on Wheels"}, {3, "Hello, world!"}]
      iex> Seqfuzz.filter(items, "hellw", &(elem(&1, 1)))
      [{3, "Hello, world!"}, {2, "Hell on Wheels"}]
  """
  @spec filter(Enumerable.t(), String.t(), (any -> String.t())) :: Enumerable.t()
  def filter(enumerable, pattern, string_callback) do
    enumerable
    |> matches(pattern, string_callback, sort: true, filter: true, metadata: false)
  end

  defp matches_metadata(enumerable, true = _metadata?) do
    enumerable
  end

  defp matches_metadata(enumerable, false = _metadata?) do
    enumerable
    |> Enum.map(fn {item, _} ->
      item
    end)
  end

  defp matches_filter(enumerable, true = _filter?) do
    enumerable
    |> Enum.filter(fn {_, %{match?: match?}} ->
      match?
    end)
  end

  defp matches_filter(enumerable, false = _filter?) do
    enumerable
  end

  defp matches_sort(enumerable, true = _sort?) do
    enumerable
    |> Enum.sort_by(
      fn {_, %{score: score}} ->
        score
      end,
      :desc
    )
  end

  defp matches_sort(enumerable, false = _sort?) do
    enumerable
  end

  defp match(string, pattern, string_idx, pattern_idx, matches) do
    # We must use String.length and a case statement because
    # byte_size does not properly capture the length of UTF-8 strings.
    string_len = String.length(string)
    pattern_len = String.length(pattern)

    initial_score = Application.get_env(:seqfuzz, :initial_score)

    case {string_len, string_idx, pattern_len, pattern_idx} do
      # Pattern length is 0
      {_, _, 0, _} ->
        score =
          initial_score
          |> score_leading_letter(matches)
          |> score_sequential_bonus(matches)
          |> score_unmatched_letter_penalty(matches, string)
          |> score_neighbor(matches, string)
          |> score_first_letter_bonus(matches)
          |> score_case_match_bonus(matches, string, pattern)
          |> score_string_match_bonus(string, pattern)

        %{match?: false, score: score, matches: matches}

      # String length is 0
      {0, _, _, _} ->
        score =
          initial_score
          |> score_leading_letter(matches)
          |> score_sequential_bonus(matches)
          |> score_unmatched_letter_penalty(matches, string)
          |> score_neighbor(matches, string)
          |> score_first_letter_bonus(matches)
          |> score_case_match_bonus(matches, string, pattern)
          |> score_string_match_bonus(string, pattern)

        %{match?: false, score: score, matches: matches}

      # There is more pattern left than string
      {string_len, string_idx, pattern_len, pattern_idx}
      when pattern_len - pattern_idx > string_len - string_idx ->
        score =
          initial_score
          |> score_leading_letter(matches)
          |> score_sequential_bonus(matches)
          |> score_unmatched_letter_penalty(matches, string)
          |> score_neighbor(matches, string)
          |> score_first_letter_bonus(matches)
          |> score_case_match_bonus(matches, string, pattern)
          |> score_string_match_bonus(string, pattern)

        %{match?: false, score: score, matches: matches}

      # No more pattern left - this is a match. Go to score.
      {_, _, pattern_len, pattern_idx} when pattern_len - pattern_idx == 0 ->
        score =
          initial_score
          |> score_leading_letter(matches)
          |> score_sequential_bonus(matches)
          |> score_unmatched_letter_penalty(matches, string)
          |> score_neighbor(matches, string)
          |> score_first_letter_bonus(matches)
          |> score_case_match_bonus(matches, string, pattern)
          |> score_string_match_bonus(string, pattern)

        %{match?: true, score: score, matches: matches}

      # If none of the terminating clauses match above, continue
      # walking the pattern and string.
      {string_len, string_idx, pattern_len, pattern_idx}
      when pattern_len > pattern_idx and string_len > string_idx ->
        if pattern
           |> String.at(pattern_idx)
           |> String.downcase() ==
             string
             |> String.at(string_idx)
             |> String.downcase() do
          match(string, pattern, string_idx + 1, pattern_idx + 1, matches ++ [string_idx])
        else
          match(string, pattern, string_idx + 1, pattern_idx, matches)
        end
    end
  end

  defp score_leading_letter(score, matches) do
    leading_letter_penalty = Application.get_env(:seqfuzz, :leading_letter_penalty)
    max_leading_letter_penalty = Application.get_env(:seqfuzz, :max_leading_letter_penalty)
    score + max(leading_letter_penalty * Enum.fetch!(matches, 0), max_leading_letter_penalty)
  end

  defp score_sequential_bonus(score, matches) do
    sequential_bonus = Application.get_env(:seqfuzz, :sequential_bonus)

    [_head | tail] = matches

    (matches
     |> Enum.zip(tail)
     |> Enum.count(fn {curr, next} ->
       next - curr == 1
     end)) * sequential_bonus + score
  end

  defp score_unmatched_letter_penalty(score, matches, string) do
    unmatched_letter_penalty = Application.get_env(:seqfuzz, :unmatched_letter_penalty)

    [_head | tail] = matches

    tail = tail ++ [String.length(string) - 1]

    (matches
     |> Enum.zip(tail)
     |> Enum.filter(fn {curr, next} ->
       next - curr != 1
     end)
     |> Enum.map(fn {curr, next} ->
       next - curr - 1
     end)
     |> Enum.sum()) * unmatched_letter_penalty + score
  end

  defp score_neighbor(score, matches, string) do
    separator_bonus = Application.get_env(:seqfuzz, :separator_bonus)
    separators = Application.get_env(:seqfuzz, :separators)
    camel_bonus = Application.get_env(:seqfuzz, :camel_bonus)

    (matches
     |> Enum.filter(&(&1 > 0))
     |> Enum.map(fn index ->
       curr = String.at(string, index)
       neighbor = String.at(string, index - 1)

       cond do
         neighbor in separators -> separator_bonus
         curr == String.upcase(curr) and neighbor == String.downcase(neighbor) -> camel_bonus
         true -> 0
       end
     end)
     |> Enum.sum()) + score
  end

  defp score_first_letter_bonus(score, matches) do
    first_letter_bonus = Application.get_env(:seqfuzz, :first_letter_bonus)

    if matches |> hd == 0 do
      first_letter_bonus + score
    else
      score
    end
  end

  defp score_case_match_bonus(score, matches, string, pattern) do
    case_match_bonus = Application.get_env(:seqfuzz, :case_match_bonus)

    (0..(length(matches) - 1)
     |> Enum.count(fn match_idx ->
       String.at(pattern, match_idx) == String.at(string, Enum.fetch!(matches, match_idx))
     end)) * case_match_bonus + score
  end

  defp score_string_match_bonus(score, string, pattern) do
    string_match_bonus = Application.get_env(:seqfuzz, :string_match_bonus)

    if String.downcase(string) == String.downcase(pattern) do
      score + string_match_bonus
    else
      score
    end
  end
end
