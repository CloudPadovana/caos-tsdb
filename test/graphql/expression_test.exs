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

defmodule CaosTsdb.Graphql.ExpressionTest do
  use CaosTsdb.ConnCase

  import CaosTsdb.DateTime.Helpers

  setup %{conn: conn} do
    conn = conn
    |> put_req_header("accept", "application/json")
    |> put_valid_token()

    {:ok, conn: conn}
  end

  @query """
  query($from: Datetime!, $to: Datetime!, $granularity: Int, $expression: String!, $terms: [ExpressionTerm]) {
    expression(from: $from, to: $to, granularity: $granularity, expression: $expression, terms: $terms) {
      timestamp
      value
    }
  }
  """

  @query_params %{granularity: nil, from: nil, to: nil, expression: nil, terms: []}

  def my_fixture do
    tags = %{
      t11: fixture(:tag, key: "key1", value: "value1"),
      t12: fixture(:tag, key: "key1", value: "value2"),
      t21: fixture(:tag, key: "key2", value: "value1"),
      t22: fixture(:tag, key: "key2", value: "value2")
    }

    metrics = %{
      m1: fixture(:metric, name: "metric1"),
      m2: fixture(:metric, name: "metric2")
    }

    series = %{
      s1_11_h: fixture(:series, tags: [tags.t11], metric: metrics.m1, period: 3600),
      s1_12_h: fixture(:series, tags: [tags.t12], metric: metrics.m1, period: 3600),
      s1_21_h: fixture(:series, tags: [tags.t21], metric: metrics.m1, period: 3600),
      s1_22_h: fixture(:series, tags: [tags.t22], metric: metrics.m1, period: 3600),
      s2_11_h: fixture(:series, tags: [tags.t11], metric: metrics.m2, period: 3600),
      s2_12_h: fixture(:series, tags: [tags.t12], metric: metrics.m2, period: 3600),
      s2_21_h: fixture(:series, tags: [tags.t21], metric: metrics.m2, period: 3600),
      s2_22_h: fixture(:series, tags: [tags.t22], metric: metrics.m2, period: 3600),

      s1_11_d: fixture(:series, tags: [tags.t11], metric: metrics.m1, period: 86400),
      s1_12_d: fixture(:series, tags: [tags.t12], metric: metrics.m1, period: 86400),
      s1_21_d: fixture(:series, tags: [tags.t21], metric: metrics.m1, period: 86400),
      s1_22_d: fixture(:series, tags: [tags.t22], metric: metrics.m1, period: 86400),
      s2_11_d: fixture(:series, tags: [tags.t11], metric: metrics.m2, period: 86400),
      s2_12_d: fixture(:series, tags: [tags.t12], metric: metrics.m2, period: 86400),
      s2_21_d: fixture(:series, tags: [tags.t21], metric: metrics.m2, period: 86400),
      s2_22_d: fixture(:series, tags: [tags.t22], metric: metrics.m2, period: 86400)
    }

    t0 = "2016-08-08T16:00:00Z" |> parse_date!

    samples_args = %{from: t0, start_value: 0, repeat: 100, series: nil, values: :linear}
    samples = %{
      s1_11_h: fixture(:samples, %{ samples_args | start_value: 0,    series: series.s1_11_h }),
      s1_12_h: fixture(:samples, %{ samples_args | start_value: 5,    series: series.s1_12_h }),
      s1_21_h: fixture(:samples, %{ samples_args | start_value: 10,   series: series.s1_21_h }),
      s1_22_h: fixture(:samples, %{ samples_args | start_value: 0,    series: series.s1_22_h }),
      s2_11_h: fixture(:samples, %{ samples_args | start_value: 700,  series: series.s2_11_h }),
      s2_12_h: fixture(:samples, %{ samples_args | start_value: 1000, series: series.s2_12_h }),
      s2_21_h: fixture(:samples, %{ samples_args | start_value: 27,   series: series.s2_21_h }),
      s2_22_h: fixture(:samples, %{ samples_args | start_value: 80,   series: series.s2_22_h }),

      s1_11_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s1_11_d }),
      s1_12_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s1_12_d }),
      s1_21_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s1_21_d }),
      s1_22_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s1_22_d }),
      s2_11_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s2_11_d }),
      s2_12_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s2_12_d }),
      s2_21_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s2_21_d }),
      s2_22_d: fixture(:samples, %{ samples_args | start_value: 0, series: series.s2_22_d })
    }

    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0}
  end

  test "identity operation on a series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "expression with invalid term", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "_x + y",
                      terms: [
                        %{name: "_x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"},
                        %{name: "y/z",
                          series: %{metric: %{name: metrics.m2.name}, period: 3600, tags: [%{id: tags.t21.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    assert json_response(new_conn, 200)["errors"] |> List.first |> Map.get("message") == "In field \"expression\": Term name `y/z` has invalid format."
  end

  test "expression with unknown term", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "_x + y",
                      terms: [
                        %{name: "_x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"},
                        %{name: "z",
                          series: %{metric: %{name: metrics.m2.name}, period: 3600, tags: [%{id: tags.t21.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    assert json_response(new_conn, 200)["errors"] |> List.first |> Map.get("message") == "In field \"expression\": Unknown term name `y`"
  end

  test "constant addition on a series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x+5",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "use special constant", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x + GRANULARITY",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" =>
                       fixture(:expression, %{ "x" => [samples.s1_11_h]}, put_in(query_params, [:expression], "x"))
                       |> Enum.map(fn s -> %{s | value: s.value + 60*60*2} end)
                       |> samples_to_json([:timestamp, :value])
    }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "sum of two series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x+y",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"},
                        %{name: "y",
                          series: %{metric: %{name: metrics.m2.name}, period: 3600, tags: [%{id: tags.t21.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h], "y" => [samples.s2_21_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "ratio of two series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x/y",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"},
                        %{name: "y",
                          series: %{metric: %{name: metrics.m2.name}, period: 3600, tags: [%{id: tags.t21.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h], "y" => [samples.s2_21_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json
  end

  test "ratio of same series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x/y",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"},
                        %{name: "y",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h], "y" => [samples.s1_11_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json

    value = json_response(new_conn, 200)["data"]["expression"]
    |> Enum.map(fn s -> s["value"] end)
    |> Enum.uniq

    assert value == [1]
  end

  test "difference of same series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    t1 = Timex.shift(t0, hours: 5)
    t2 = Timex.shift(t0, hours: 35)

    query_params = %{ @query_params |
                      from: t1 |> format_date!,
                      to: t2 |> format_date!,
                      granularity: 60*60*2,
                      expression: "x - y",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "NONE",
                          downsample: "SUM"},
                        %{name: "y",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "NONE",
                          downsample: "SUM"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h], "y" => [samples.s1_11_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json

    value = json_response(new_conn, 200)["data"]["expression"]
    |> Enum.map(fn s -> s["value"] end)
    |> Enum.uniq

    assert value == [0]
  end

  test "sum of same series", %{conn: conn} do
    %{tags: tags, metrics: metrics, series: series, samples: samples, t0: t0} = my_fixture()

    query_params = %{ @query_params |
                      granularity: 3600,
                      expression: "x+y",
                      terms: [
                        %{name: "x",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "NONE",
                          downsample: "NONE"},
                        %{name: "y",
                          series: %{metric: %{name: metrics.m1.name}, period: 3600, tags: [%{id: tags.t11.id}]},
                          function: "SUM",
                          downsample: "NONE"}
                      ]
                    }

    new_conn = graphql_query conn, @query, query_params

    expected_json = %{ "expression" => fixture(:expression, %{"x" => [samples.s1_11_h], "y" => [samples.s1_11_h]}, query_params) |> samples_to_json([:timestamp, :value]) }

    assert json_response(new_conn, 200)["data"] == expected_json

    values = json_response(new_conn, 200)["data"]["expression"]
    |> Enum.map(fn s -> s["value"] end)

    exp_values = samples.s1_11_h
    |> Enum.map(fn s -> 2*s.value end)

    assert values == exp_values
  end
end
