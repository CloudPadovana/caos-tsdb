################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Author: Fabrizio Chiarello <fabrizio.chiarello@pd.infn.it>
#
################################################################################

defmodule CaosTsdb.Graphql.Resolver.ExpressionResolver do
  use CaosTsdb.Web, :resolver

  defmodule MultipleSamplesError do
    defexception message: "Multiple samples for timestamp"
  end

  defmodule TermNameError do
    defexception [:message]

    def exception(term) do
      msg = "Term name `#{term.name}` has invalid format."
      %TermNameError{message: msg}
    end
  end

  # From https://github.com/narrowtux/abacus/blob/master/src/math_term.xrl#L9: [a-zA-Z_][a-zA-Z0-9_\-]*
  @term_name_regex ~r|^[[:alpha:]_][[:alnum:]_\-]*$|

  defp check_term_name(term) do
    unless term.name =~ @term_name_regex do
      raise TermNameError, term
    end
  end

  defp check_chunks(mapped_samples) do
    do_raise = mapped_samples
    |> Enum.map(fn {_unix_ts, samples} -> length(samples) end)
    |> Enum.any?(fn count -> count > 1 end)

    if do_raise do
      raise MultipleSamplesError
    end
  end

  defp resolve_term(term, args, context) do
    check_term_name(term)

    term_args = args
    |> Map.take([:from, :to, :granularity])
    |> Map.merge(term)

    with {:ok, samples} <- AggregateResolver.aggregate_term(term_args, context) do
      mapped_samples = samples
      |> Enum.group_by(fn s -> Timex.to_unix(s.timestamp) end)

      mapped_samples
    else
      {:error, error} -> raise error
    end
  end

  defp resolve_terms(args = %{terms: terms}, context) do
    try do
      mapped_terms = terms
      |> Enum.map(fn term ->
        mapped_samples = resolve_term(term, args, context)

        if length(terms) > 1 do
          check_chunks(mapped_samples)
        end

        {term.name, mapped_samples}
      end)
      |> Map.new()

      {:ok, mapped_terms}
    rescue
      e in MultipleSamplesError -> {:error, e.message}
      e in TermNameError -> {:error, e.message}
    end
  end

  defp timebase_interval(_args = %{from: from, to: to, granularity: granularity}, bounds) do
    real_from = bounds
    |> Enum.map(fn {x, _y} -> x end)
    |> (&Enum.concat([Timex.to_unix(from)], &1)).()
    |> Enum.max
    |> Timex.from_unix

    real_to = bounds
    |> Enum.map(fn {_x, y} -> y end)
    |> (&Enum.concat([Timex.to_unix(to)], &1)).()
    |> Enum.min
    |> Timex.from_unix

    Timex.Interval.new(from: real_from, until: real_to,
      step: [seconds: granularity], right_open: false, left_open: false)
  end

  defp timebase(args, mapped_terms) do
    bounds = mapped_terms
    |> Enum.map(fn
      {_name, mapped_samples} when map_size(mapped_samples) == 0 -> []

      {_name, mapped_samples} ->
        mapped_samples
        |> Map.keys()
        |> Enum.min_max
    end)

    if Enum.empty?(List.flatten(bounds)) do
      []
    else
      timebase_interval(args, bounds)
    end
  end

  defp check_expression(expression, mapped_terms) do
    with {:ok, expr} <- Abacus.parse(expression),
         known_names <- Map.keys(mapped_terms),
         {:ok, expr_vars} <- Abacus.variables(expr) do

      s = expr_vars
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(known_names))

      case MapSet.size(s) do
        0 -> {:ok, expr}
        _ ->
          name = s
          |> MapSet.to_list()
          |> List.first()

          {:error, "Unknown term name `#{name}`"}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  defp eval_expression(_expression, vars) when map_size(vars) == 0 do nil end

  defp eval_expression(expression, vars) do
    case Abacus.eval(expression, vars) do
      {:ok, value} -> value
      {:error, _} -> nil
    end
  end

  defp vars_for_timestamp(unix_ts, mapped_terms) when map_size(mapped_terms) == 1 do
    {name, mapped_samples} = mapped_terms
    |> Map.to_list()
    |> List.first()

    mapped_samples
    |> Map.get(unix_ts, [])
    |> Enum.map(fn s -> %{name => s.value} end)
  end

  defp vars_for_timestamp(unix_ts, mapped_terms) do
    mapped_terms
    |> Enum.flat_map(fn {name, mapped_samples} ->
      mapped_samples
      |> Map.get(unix_ts, [])
      |> Enum.map(fn s -> {name, s.value} end)
    end)
    |> Map.new
    |> List.wrap
  end

  def expression(args = %{expression: expression}, context) do
    with {:ok, mapped_terms} <- resolve_terms(args, context),
         {:ok, expr} <- check_expression(expression, mapped_terms),
         timebase <- timebase(args, mapped_terms) do

      samples = timebase
      |> Enum.map(&Timex.to_unix/1)
      |> Enum.flat_map(fn unix_ts ->
        vars_for_timestamp(unix_ts, mapped_terms)
        |> Enum.map(fn vars ->
          v = eval_expression(expr, vars)
          %Sample{timestamp: Timex.from_unix(unix_ts), value: v}
        end)
      end)

      {:ok, samples}
    else
      {:error, error} -> {:error, error}
    end
  end
end
