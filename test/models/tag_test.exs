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

defmodule CaosTsdb.TagTest do
  use CaosTsdb.ModelCase

  alias CaosTsdb.Tag

  @a_tag %Tag{key: "a_valid/key", value: "a/valid.value",
              extra: %{
                "key1" => "value1",
                "key2" => "value2"
              }}

  describe "valid changeset" do
    @valid_key @a_tag.key
    @valid_value @a_tag.value
    @valid_extra Map.put(@a_tag.extra, "key3", "value3")

    test "creation" do
      changeset = Tag.changeset(%Tag{}, %{key: @valid_key, value: @valid_value, extra: @valid_extra})
      assert changeset.valid?
    end

    test "change" do
      changeset = Tag.changeset(@a_tag, %{})
      assert changeset.valid?

      changeset = Tag.changeset(@a_tag, %{extra: @valid_extra})
      assert changeset.valid?
    end
  end

  describe "invalid changeset" do
    @empty ""
    @invalid_key ".invalid"
    @invalid_value ".invalid"
    @valid_key "valid/key"
    @valid_value "valid/value.1"

    test "with empty key" do
      changeset = Tag.changeset(%Tag{}, %{key: @empty})
      refute changeset.valid?

      changeset = Tag.changeset(@a_tag, %{key: @empty})
      refute changeset.valid?
    end

    test "with empty value" do
      changeset = Tag.changeset(%Tag{}, %{value: @empty})
      refute changeset.valid?

      changeset = Tag.changeset(@a_tag, %{value: @empty})
      refute changeset.valid?
    end

    test "with invalid key" do
      changeset = Tag.changeset(%Tag{}, %{key: @invalid_key, value: @valid_value})
      refute changeset.valid?

      changeset = Tag.changeset(@a_tag, %{key: @invalid_key, value: @valid_value})
      refute changeset.valid?
    end

    test "with invalid value" do
      changeset = Tag.changeset(%Tag{}, %{key: @valid_key, value: @invalid_value})
      refute changeset.valid?

      changeset = Tag.changeset(@a_tag, %{key: @valid_key, value: @invalid_value})
      refute changeset.valid?
    end
  end
end
