################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016, 2017 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.AggregateController do
  use CaosTsdb.Web, :controller

  alias CaosTsdb.Sample
  alias CaosTsdb.Series

  plug :scrub_datetime, "from" when action in [:show]
  plug :scrub_datetime, "to" when action in [:show]
  plug :scrub_integer, "granularity" when action in [:show]
  plug :scrub_integer, "period" when action in [:show]

  @default_params %{"from" => epoch,
                    "to" => Timex.now,
                    "tags" => [],
                    "granularity" => 24*60*60}

  defp filter_by_tags(query, tags = []) do
    query
  end

  defp filter_by_tags(query, tags = _) do
    query
    |> where([_, _, tag], tag.id in ^tags)
  end

  defp group_by_tags(query, tags = []) do
    query
    |> group_by([_, _, _], [fragment("myfrom")])
    |> order_by([_, _, _], [fragment("myfrom")])
  end

  defp group_by_tags(query, tags = _) do
    query
    |> group_by([_, _, tag], [tag.id, fragment("myfrom")])
    |> order_by([_, _, tag], [tag.id, fragment("myfrom")])
  end

  defp my_select(query, args) do
    query
    |> select([s, series, tag], %{
                ### NOTE: do not change "myfrom": pay attention to not to use SQL reserved names like "timestamp, from"
                from: fragment("CAST(DATE_ADD(?, INTERVAL (?*((TO_SECONDS(?)-TO_SECONDS(?)) div ?)) SECOND) AS datetime) AS myfrom",
                  type(^args.from, :datetime),
                  type(^args.granularity, :integer),
                  datetime_add(s.timestamp, ^(-args.period), "second"),
                  type(^args.from, :datetime),
                  type(^args.granularity, :integer)),
                tag_id: tag.id,
                granularity: type(^args.granularity, :integer),
                # aggregates
                avg: avg(s.value),
                count: count(s.value),
                min: min(s.value),
                max: max(s.value),
                std: fragment("stddev_pop(?)", s.value),
                var: fragment("var_pop(?)", s.value),
                sum: sum(s.value)})
  end

  def show(conn, params = %{"metric" => metric_name, "period" => period}) do
    %{"from" => from,
      "to" => to,
      "tags" => tags,
      "granularity" => granularity
    } = Map.merge(@default_params, params)

    ### NOTE: where clauses have to be performed on raw fields, i.e. on the timestamp field
    where_from = from |> Timex.shift(seconds: period)
    where_to = to

    having_from = from
    having_to = to |> Timex.shift(seconds: -granularity)

    args = %{
      metric_name: metric_name,
      period: period,
      from: from,
      to: to,
      where_from: where_from,
      where_to: where_to,
      tags: tags,
      granularity: granularity
    }

    aggregates = Sample
    |> join(:inner, [sample], series in assoc(sample, :series))
    |> join(:inner, [_, series], tag in assoc(series, :tags))
    |> where([_, series], series.metric_name == ^args.metric_name)
    |> where([_, series], series.period == ^args.period)
    |> filter_by_tags(tags)
    |> where([sample], sample.timestamp >= ^args.where_from)
    |> where([sample], sample.timestamp <= ^args.where_to)
    |> my_select(args)
    |> group_by_tags(tags)
    |> having([sample], fragment("myfrom") >= ^having_from)
    |> having([sample], fragment("myfrom") <= ^having_to)
    |> Repo.all
    |> Enum.map(fn(x)
      -> case Timex.Ecto.DateTime.load(x.from) do
           {:ok, t} -> %{ x | from: t }
         end
    end)

    render(conn, "show.json", %{aggregates: aggregates, tags: tags})
  end
end
