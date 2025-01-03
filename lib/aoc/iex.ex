defmodule AOC.IEx do
  @moduledoc """
  IEx helpers for advent of code.

  This module contains various helpers that make it easy to call procedures in your solution
  modules. It is intended to be used while testing solutions in iex, the elixir shell.

  In order to avoid prefixing all calls with `AOC.IEx`, we recommend adding `import AOC.IEx` to
  your [`.iex.exs` file](https://hexdocs.pm/iex/IEx.html#module-the-iex-exs-file).

  ## Requirements and `AOC.aoc/3`

  In order to find a module for a given day and year, this module expects the module to have the
  name `Y<year>.D<day>`. This is always the case if the `AOC.aoc/3` macro was used to build the
  solution module (and thus the case if the template generated by `mix aoc.gen` or `mix aoc` is
  used).

  Furthermore, it is expected that the solutions for part 1 and part 2 are defined in non-private
  functions named `p1` and `p2`. These functions must accept one argument: the puzzle input,
  represented as a string.

  ## Functions in this module

  This module provides the `p1e/1`, `p1i/1`, `p2e/1` and `p2i/1` functions, which call your part
  one or part two solution with an example (`p1e/1`, `p2e/1`) or with the puzzle input (`p1i/1`,
  `p2i/1`) from within iex.  You can also use `p1/2` and `p2/2` to call the `p1` and `p2`
  functions of your solution module directly.

  `mod/1` can be used to obtain the current solution module, which is useful if you wish to test
  other functions in your solution module. Moreover, `example_path/1`, `input_path/1`,
  `example_string/1`, and `input_string/1`, can be used to experiment with the puzzle input and
  example input retrieved by `mix aoc.get` or `mix aoc` inside iex.

  ## Specifying an example

  `mix aoc.get` fetches every code block on the puzzle input webpage and treats it as an example.
  These examples are stored on disk and can be accessed through the use of `p1e/1`, `p2e/1`,
  `example_path/1` and `example_string/1`. By default, these functions use or return the first
  code block found on the puzzle webpage. However, these functions accept an `n:` option, which
  can be used to specify which example to use. `list_examples/1` can be used to obtain an overview
  of all the available examples.

  Note that running `mix aoc.get` after finishing part 1 may retrieve additional examples.

  ## Specifying the puzzle date

  The functions in this module all select a puzzle (or more specifically, its solution module,
  input or example) based on the current time. For instance, the `p1/2` function calls the `p1`
  function of the solution module that corresponds to the current day. The current day (and year)
  is determined by `NaiveDateTime.local_now/0`, or by `DateTime.now/2` if a time zone was set, as
  described in the [README](readme.html#time-zones). If it is past midnight, or if you wish to
  solve an older challenge, there are a few options at your disposal:

  - Each function in this module accepts an optional keyword list through which the year and day
    can be specified. For instance, if you wish to run part 1 of of 8 december 1991, you could
    write the following code: `p1(<input>, year: 1991, day: 8)`. If you omit the day or year, the
    current day or year is used by default. `p1(<input>, day: 8)` would, for instance, call part 1
    of day 8 of the current year.

  - The year and day can be configured through the `:advent_of_code_utils` application
    environment. For instance, you can set the year to `1991` and the day to `8` by placing the
    following in your `config/config.exs`:

    ```elixir
    import Config

    config :advent_of_code_utils,
      day: 8,
      year: 1991
    ```

  Both of these options can be combined. You can, for instance, set the year in
  `config/config.exs` and select the day when calling `p1/2` or any other function in this module.

  To summarise, the day or year is determined according to the following rules:

  1. If year or day is passed as part of the keyword list argument, it is always used.
  2. If `:year` or `:day` is present in the `:advent_of_code_utils` application environment, it is
  used.
  3. The `year` or `day` returned by `NaiveDateTime.local_now/0` or `DateTime.now/2` is used.

  ## Automatic recompilation

  It is often necessary to recompile the current `mix` project before running code. To avoid
  repeatedly calling `IEx.Helpers.recompile/1`, the various `p*` functions in this module and
  `mod/1` will automatically recompile the current mix project (with `IEx.Helpers.recompile/1`)
  when `:auto_compile?` is set to `true` in the `:advent_of_code_utils` application environment:

  ```
  import Config

  config :advent_of_code_utils, auto_compile?: true
  ```

  ## Elapsed time

  Some developers are interested in the runtime of their solutions. When the `time_calls?` options
  is set in the `:advent_of_code_utils` application environment, the runtime of a solution will be
  shown when calling `p1/2`, `p2/2`, `p1i/1`, `p1e/1`, `p2i/1` and `p2e/1`. By default, this
  feature is disabled.

  ```
  import Config

  config :advent_of_code_utils, time_calls?: true
  ```

  This feature can also be enabled or disabled by passing `time: true` or `time: false` as an
  option to `p1/2`, `p2/2`, `p1i/1`, `p1e/1`, `p2i/1` or `p2e/1`.
  """
  alias AOC.Helpers

  defp mix_started? do
    Application.started_applications() |> Enum.find(false, fn {name, _, _} -> name == :mix end)
  end

  defp maybe_compile() do
    compile? = Helpers.app_env_val(:auto_compile?, false)
    if(compile? and mix_started?(), do: IEx.Helpers.recompile())
  end

  defp fetch_year_day(opts), do: {opts[:year] || Helpers.year(), opts[:day] || Helpers.day()}

  defp fetch_year_day_n(opts) do
    {y, d} = fetch_year_day(opts)
    {y, d, opts[:n] || 0}
  end

  defp call_p_fun(p, input, opts) do
    opts |> mod() |> Code.ensure_loaded!() |> maybe_timed_call(p, [input], opts)
  end

  defp maybe_timed_call(mod, fun, input, opts) do
    if Keyword.get(opts, :time, Helpers.app_env_val(:time_calls?, false)) do
      {time, res} = :timer.tc(mod, fun, input)
      IO.puts("⏱️ #{time / 1000} ms")
      res
    else
      apply(mod, fun, input)
    end
  end

  @doc """
  Get the module name for the currently configured puzzle.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  This function may cause recompilation if `auto_compile?` is enabled.

  ## Examples

      iex> mod(year: 1991, day: 8)
      Y1991.D8
      iex> Application.put_env(:advent_of_code_utils, :year, 1991)
      iex> Application.put_env(:advent_of_code_utils, :day, 8)
      iex> mod()
      Y1991.D8
      iex> mod(day: 9)
      Y1991.D9
      iex> mod(year: 2000)
      Y2000.D8
      iex> Application.put_env(:advent_of_code_utils, :year, 2000)
      iex> Application.put_env(:advent_of_code_utils, :day, 3)
      iex> mod()
      Y2000.D3
  """
  @spec mod(year: pos_integer(), day: pos_integer()) :: module()
  def mod(opts \\ []) do
    maybe_compile()
    {y, d} = fetch_year_day(opts)

    Helpers.module_name(y, d)
  end

  @doc """
  Call part 1 of the current puzzle with the given input.

  Calls, `Y<year>.D<day>.p1/1` with `input`.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  The `time:` option can be used to control if the execution of `p1` will be timed. If it is not
  present, the value of `:time_calls?` in the application environment (default: `false`) will be
  respected.

  This function may cause recompilation if `auto_compile?` is enabled.
  """
  @spec p1(String.t(), year: pos_integer(), day: pos_integer(), time: boolean()) :: any()
  def p1(input, opts \\ []), do: call_p_fun(:p1, input, opts)

  @doc """
  Call part 2 of the current puzzle with the given input.

  Calls, `Y<year>.D<day>.p2/1` with `input`.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  The `time:` option can be used to control if the execution of `p2` will be timed. If it is not
  present, the value of `:time_calls?` in the application environment (default: `false`) will be
  respected.

  This function may cause recompilation if `auto_compile?` is enabled.
  """
  @spec p2(String.t(), year: pos_integer(), day: pos_integer(), time: boolean()) :: any()
  def p2(input, opts \\ []), do: call_p_fun(:p2, input, opts)

  @doc """
  Call part 1 of the current puzzle with its example input.

  Uses `p1/2` and `example_string/1` to call `Y<year>.D<day>.p1/1` with the example input of
  `year` and `day`.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  The `time:` option can be used to control if the execution of `p1` will be timed. If it is not
  present, the value of `:time_calls?` in the application environment (default: `false`) will be
  respected.

  This function may cause recompilation if `auto_compile?` is enabled.
  """
  @spec p1e(year: pos_integer(), day: pos_integer(), time: boolean()) :: any()
  def p1e(opts \\ []), do: p1(example_string(opts), opts)

  @doc """
  Call part 1 of the current puzzle with its input.

  Uses `p1/2` and `input_string/1` to call `Y<year>.D<day>.p1/1` with the input of `year` and
  `day`.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  The `time:` option can be used to control if the execution of `p1` will be timed. If it is not
  present, the value of `:time_calls?` in the application environment (default: `false`) will be
  respected.

  This function may cause recompilation if `auto_compile?` is enabled.
  """
  @spec p1i(year: pos_integer(), day: pos_integer(), time: boolean()) :: any()
  def p1i(opts \\ []), do: p1(input_string(opts), opts)

  @doc """
  Call part 2 of the current puzzle with its example input.

  Uses `p2/2` and `example_string/1` to call `Y<year>.D<day>.p2/1` with the example input of
  `year` and `day`.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  The `time:` option can be used to control if the execution of `p2` will be timed. If it is not
  present, the value of `:time_calls?` in the application environment (default: `false`) will be
  respected.

  This function may cause recompilation if `auto_compile?` is enabled.
  """
  @spec p2e(year: pos_integer(), day: pos_integer(), time: boolean()) :: any()
  def p2e(opts \\ []), do: p2(example_string(opts), opts)

  @doc """
  Call part 2 of the current puzzle with its input.

  Uses `p2/2` and `input_string/1` to call `Y<year>.D<day>.p2/1` with the input of `year` and
  `day`.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.

  The `time:` option can be used to control if the execution of `p2` will be timed. If it is not
  present, the value of `:time_calls?` in the application environment (default: `false`) will be
  respected.

  This function may cause recompilation if `auto_compile?` is enabled.
  """
  @spec p2i(year: pos_integer(), day: pos_integer(), time: boolean()) :: any()
  def p2i(opts \\ []), do: p2(input_string(opts), opts)

  @doc """
  Obtain the path of the input for the current puzzle.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.
  """
  @spec input_path(year: pos_integer(), day: pos_integer()) :: Path.t()
  def input_path(opts \\ []) do
    {y, d} = fetch_year_day(opts)
    Helpers.input_path(y, d)
  end

  @doc """
  Obtain the path of the n-th example input of the current puzzle.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time, while `n` defaults to `0`. Refer to the module
  documentation for additional information.
  """
  @spec example_path(year: pos_integer(), day: pos_integer(), n: non_neg_integer()) :: Path.t()
  def example_path(opts \\ []) do
    {y, d, n} = fetch_year_day_n(opts)
    Helpers.example_path(y, d, n)
  end

  @doc """
  Obtain the puzzle input of the current puzzle as a string.

  Trailing newlines are stripped from the puzzle input string.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.
  """
  @spec input_string(year: pos_integer(), day: pos_integer()) :: String.t()
  def input_string(opts \\ []) do
    {y, d} = fetch_year_day(opts)
    Helpers.input_string(y, d)
  end

  @doc """
  Obtain the example input of the current puzzle as a string.

  Trailing newlines are stripped from the example input string.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time, while `n` defaults to `0`. Refer to the module
  documentation for additional information.
  """
  @spec example_string(year: pos_integer(), day: pos_integer(), n: non_neg_integer()) ::
          String.t()
  def example_string(opts \\ []) do
    {y, d, n} = fetch_year_day_n(opts)
    Helpers.example_string(y, d, n)
  end

  @doc """
  Show all available example strings.

  This is useful to determine which example corresponds with which index.

  If not present in the options list, `day` and `year` are fetched from the application
  environment or based on the local time. Refer to the module documentation for additional
  information.
  """
  def list_examples(opts \\ []) do
    {y, d} = fetch_year_day(opts)

    Stream.iterate(0, &(&1 + 1))
    |> Stream.map(&Helpers.example_path(y, d, &1))
    |> Enum.take_while(&File.exists?/1)
    |> Enum.map(&Helpers.path_to_string/1)
    |> Enum.with_index()
    |> Enum.each(fn {str, idx} ->
      [:blue, "Example #{idx}:"] |> IO.ANSI.format() |> IO.puts()
      IO.puts(str)
      IO.puts("")
    end)
  end
end
