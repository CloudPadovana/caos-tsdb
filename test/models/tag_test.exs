################################################################################
#
# caos-tsdb - CAOS Time-Series DB
#
# Copyright © 2016 INFN - Istituto Nazionale di Fisica Nucleare (Italy)
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

defmodule CaosTsdb.TagTest do
  use CaosTsdb.ModelCase

  alias CaosTsdb.Tag

  @a_tag %Tag{key: "a tag",
              value: "a value",
              extra: %{
                "key1" => "value1",
                "key2" => "value2"
              }}

  test "changeset with valid creation" do
    changeset = Tag.changeset(%Tag{}, %{key: "a tag",
                                        value: "a value",
                                        extra: %{"key1" => "a new value"}})
    assert changeset.valid?
  end

  test "changeset with invalid creation" do
    changeset = Tag.changeset(%Tag{}, %{key: ""})
    refute changeset.valid?

    changeset = Tag.changeset(%Tag{}, %{value: ""})
    refute changeset.valid?

    changeset = Tag.changeset(%Tag{}, %{key: "", value: "a value"})
    refute changeset.valid?

    changeset = Tag.changeset(%Tag{}, %{key: "a key", value: ""})
    refute changeset.valid?
  end

  test "changeset with valid change" do
    changeset = Tag.changeset(@a_tag, %{})
    assert changeset.valid?

    changeset = Tag.changeset(@a_tag, %{extra: %{"key1" => "a new value1",
                                                 "key3" => "value3"}})
    assert changeset.valid?
  end

  test "changeset with invalid change" do
    changeset = Tag.changeset(@a_tag, %{key: "a new tag"})
    refute changeset.valid?

    changeset = Tag.changeset(@a_tag, %{key: ""})
    refute changeset.valid?

    changeset = Tag.changeset(@a_tag, %{key: "", value: "a new value"})
    refute changeset.valid?

    changeset = Tag.changeset(@a_tag, %{value: "a new value"})
    refute changeset.valid?
  end

end
