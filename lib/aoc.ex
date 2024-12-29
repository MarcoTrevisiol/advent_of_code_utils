defmodule AOC do
  @moduledoc """
  Advent of Code solution module macro and helpers.

  This module contains the `aoc/3` macro, which should be used to write a solution module for a
  given advent of code challenge. The intended use is to write your solution for day `<day>`, year
  `<year>` as follows:

  ```
  import AOC

  aoc <year>, <day> do
    def p1(input) do
      # Part 1 solution goes here
    end

    def p2(input) do
      # Part 1 solution goes here
    end
  end
  ```

  Writing a solution module with the `aoc/3` macro enables you to use the functions defined in the
  `AOC.IEx` module to test your solutions with ease. For instance, you can use `AOC.IEx.p1e/1` to
  call `p1` with the first example input of the current day and `AOC.IEx.p1i/1` to call `p1` with
  the puzzle input of the current day. Similar functions are available for `p2`.

  Note that the code skeleton shown above can be generated by running `mix aoc.gen` or `mix aoc`.
  """
  alias AOC.Helpers

  @doc """
  Part 1 solution.

  Must accept a string which represents the puzzle or example input.
  """
  @callback p1(String.t()) :: any()

  @doc """
  Part 2 solution.

  Must accept a string which represents the puzzle or example input. This callback is marked as
  optional as day 25 does not have a second part; this also prevents warnings while working on
  part 1.
  """
  @callback p2(String.t()) :: any()

  @optional_callbacks p2: 1

  @doc """
  Generate an advent of code solution module for a given year and day.

  The generated module will be named `Y<year>.D<day>`. The helpers in `AOC.IEx` rely on this
  convention to find your solution module.

  ## Examples

  ```
  import AOC

  aoc 2020, 1 do
    def some_function do
      :foo
    end
  end
  ```

  is equivalent to:

  ```
  defmodule Y2020.D1 do
    @behaviour AOC

    def some_function do
      :foo
    end
  end
  ```
  """
  defmacro aoc(year, day, do: body) do
    quote do
      defmodule unquote(Helpers.module_name(year, day)) do
        @behaviour AOC

        unquote(body)
      end
    end
  end

  @doc """
  Generate an advent of code test module for a given year and day.

  The generated module will be named `Y<year>.D<day>.AOCTest`. It will be tagged with the year,
  day and date of the puzzle, and will contain helper functions, `input_path/0`, `example_path/1`,
  `input_string/0` and `example_string/1` which can be used to access the example and puzzle
  input, as described in `AOC.Case`.

  The generated module will import the solution module of the same date (unless `import?: false`
  is provided as an option) and automatically calls `ExUnit.DocTest.doctest/1` on the solution
  module, unless `doctest?: false` is provided as an option. Any other options (such as `async:
  true`) are passed to ExUnit.

  ## Examples

  ```
  import AOC

  aoc_test 2020,1, async: true do
    test "does my helper work?" do
      assert some_helper(:foo) == 42
    end
  end
  ```

  Is equivalent to:

  ```
  defmodule Y2020.D1.AOCTest do
    use AOC.Case, year: 2020, day: 1, async: true

    import Y2020.D1

    test "does my helper work?" do
      assert some_helper(:foo) == 42
    end

    doctest Y2020.D1
  end
  ```
  """
  defmacro aoc_test(year, day, opts \\ [], do: body) do
    target = Helpers.module_name(year, day)
    opts = opts ++ [year: year, day: day]

    maybe_import =
      if Keyword.get(opts, :import?, true) do
        quote(do: import(unquote(target)))
      end

    maybe_doctest =
      if Keyword.get(opts, :doctest?, true) do
        quote(do: doctest(unquote(target)))
      end

    quote do
      defmodule unquote(Helpers.test_module_name(year, day)) do
        use AOC.Case, unquote(opts)
        unquote(maybe_import)
        unquote(body)
        unquote(maybe_doctest)
      end
    end
  end
end
