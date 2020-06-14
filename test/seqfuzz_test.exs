defmodule SeqfuzzTest do
  use ExUnit.Case
  doctest Seqfuzz

  test "One letter match" do
    assert ["Snack Food", "Food"]
           |> Seqfuzz.filter("f") ==
             ["Food", "Snack Food"]
  end

  test "Empty pattern" do
    assert ["Snack Food", "Food"]
           |> Seqfuzz.filter("") ==
             ["Snack Food", "Food"]
  end

  test "Empty string" do
    assert ["", "Food"]
           |> Seqfuzz.filter("f") == ["Food"]
  end

  test "Empty pattern and string" do
    assert [""] |> Seqfuzz.filter("") == []
  end

  test "No matches" do
    assert ["XYZ", "zzz"] |> Seqfuzz.filter("f") == []
  end
end
