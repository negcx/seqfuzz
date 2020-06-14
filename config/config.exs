use Mix.Config

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
