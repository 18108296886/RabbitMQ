## This Source Code Form is subject to the terms of the Mozilla Public
## License, v. 2.0. If a copy of the MPL was not distributed with this
## file, You can obtain one at https://mozilla.org/MPL/2.0/.
##
## Copyright (c) 2007-2020 VMware, Inc. or its affiliates.  All rights reserved.

defmodule UpdateVhostMetadataCommandTest do
  use ExUnit.Case, async: false
  import TestHelper

  @command RabbitMQ.CLI.Ctl.Commands.UpdateVhostMetadataCommand
  @vhost "update-metadata-test"

  setup_all do
    RabbitMQ.CLI.Core.Distribution.start()
    {:ok, opts: %{node: get_rabbit_hostname()}}
  end

  setup context do
    on_exit(context, fn -> delete_vhost(context[:vhost]) end)
    :ok
  end

  test "validate: no arguments fails validation" do
    assert @command.validate([], %{}) == {:validation_failure, :not_enough_args}
  end

  test "validate: too many arguments fails validation" do
    assert @command.validate(["test", "extra"], %{}) == {:validation_failure, :too_many_args}
  end

  test "validate: virtual host name without options fails validation" do
    assert @command.validate(["a-vhost"], %{}) == {:validation_failure, :not_enough_args}
  end

  test "validate: virtual host name and one or more metadata options succeeds" do
    assert @command.validate(["a-vhost"], %{description: "Used by team A"}) == :ok

    assert @command.validate(["a-vhost"], %{
             description: "Used by team A for QA purposes",
             tags: "qa,team-a"
           }) == :ok

    assert @command.validate(["a-vhost"], %{
             description: "Used by team A for QA purposes",
             tags: "qa,team-a",
             default_queue_type: "quorum"
           }) == :ok
  end

  test "validate: unknown default queue type fails validation" do
    assert @command.validate(["a-vhost"], %{
             description: "Used by team A for QA purposes",
             tags: "qa,team-a",
             default_queue_type: "unknown"
           }) == {:validation_failure, {:bad_argument, "Default queue type must be one of: quorum, stream, classic. Provided: unknown"}}
  end

  @tag vhost: @vhost
  test "run: passing a valid vhost name and description succeeds", context do
    add_vhost(context[:vhost])
    desc = "desc 2"

    assert @command.run([context[:vhost], %{desciption: desc}], context[:opts]) == :ok
    vh = list_vhosts() |> Enum.filter(fn record -> record[:name] == context[:vhost] end) |> List.first
    assert vh
    assert vh[:description] == desc
  end

  test "run: passing a valid vhost name and a set of tags succeeds", context do
    add_vhost(context[:vhost])
    tags = "a1,b2,c3"

    assert @command.run([context[:vhost], %{tags: tags}], context[:opts]) == :ok
    vh = list_vhosts() |> Enum.filter(fn record -> record[:name] == context[:vhost] end) |> List.first
    assert vh
    assert vh[:tags] == [:a1, :b2, :c3]
  end

  test "run: attempt to use a non-existent virtual host fails" do
    vh = "a-non-existent-3882-vhost"
    assert match?({:error, {:no_such_vhost, _}}, @command.run([vh], %{description: "irrelevant", context[:opts]}))
  end

  test "run: attempt to use an unreachable node returns a nodedown" do
    opts = %{node: :jake@thedog, timeout: 200, description: "does not matter"}
    assert match?({:badrpc, _}, @command.run(["na"], opts))
  end

  @tag vhost: @vhost
  test "run: adding the same host twice is idempotent", context do
    add_vhost(context[:vhost])

    assert @command.run([context[:vhost]], context[:opts]) == :ok
    assert list_vhosts() |> Enum.count(fn record -> record[:name] == context[:vhost] end) == 1
  end

  @tag vhost: @vhost
  test "banner", context do
    assert @command.banner([context[:vhost]], context[:opts]) =~
             ~r/Update metadata of vhost \"#{context[:vhost]}\" \.\.\./
  end

  @tag vhost: @vhost
  test "run: vhost tags are coerced to a list", context do
    add_vhost(context[:vhost])

    opts = Map.merge(context[:opts], %{description: "My vhost", tags: "my_tag"})
    assert @command.run([context[:vhost]], opts) == :ok
    record = list_vhosts() |> Enum.find(fn record -> record[:name] == context[:vhost] end)
    assert record[:tags] == [:my_tag]
  end
end
