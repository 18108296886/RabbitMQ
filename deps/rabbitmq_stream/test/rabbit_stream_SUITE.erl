%% The contents of this file are subject to the Mozilla Public License
%% Version 2.0 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at https://www.mozilla.org/en-US/MPL/2.0/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is Pivotal Software, Inc.
%% Copyright (c) 2020-2021 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(rabbit_stream_SUITE).

% -include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("rabbit_common/include/rabbit.hrl").

-include("rabbit_stream.hrl").
-include("rabbit_stream_metrics.hrl").

-compile(nowarn_export_all).
-compile(export_all).

all() ->
    [{group, single_node}, {group, cluster}].

groups() ->
    [{single_node, [],
      [test_stream, test_stream_tls, test_gc_consumers, test_gc_publishers]},
     {cluster, [], [test_stream, test_stream_tls, java]}].

init_per_suite(Config) ->
    rabbit_ct_helpers:log_environment(),
    Config.

end_per_suite(Config) ->
    Config.

init_per_group(single_node, Config) ->
    Config1 =
        rabbit_ct_helpers:set_config(Config, [{rmq_nodes_clustered, false}]),
    Config2 = rabbit_ct_helpers:set_config(Config1, {rabbitmq_ct_tls_verify, verify_none}),
    rabbit_ct_helpers:run_setup_steps(Config2,
                                      [fun(StepConfig) ->
                                          rabbit_ct_helpers:merge_app_env(StepConfig,
                                                                          {rabbit,
                                                                           [{core_metrics_gc_interval,
                                                                             1000}]})
                                       end]
                                      ++ rabbit_ct_broker_helpers:setup_steps());
init_per_group(cluster = Group, Config) ->
    Config1 =
        rabbit_ct_helpers:set_config(Config, [{rmq_nodes_clustered, true}]),
    Config2 =
        rabbit_ct_helpers:set_config(Config1,
                                     [{rmq_nodes_count, 3},
                                      {rmq_nodename_suffix, Group},
                                      {tcp_ports_base}]),
    Config3 = rabbit_ct_helpers:set_config(Config2, {rabbitmq_ct_tls_verify, verify_none}),
    rabbit_ct_helpers:run_setup_steps(Config3,
                                      [fun(StepConfig) ->
                                          rabbit_ct_helpers:merge_app_env(StepConfig,
                                                                          {aten,
                                                                           [{poll_interval,
                                                                             1000}]})
                                       end]
                                      ++ rabbit_ct_broker_helpers:setup_steps());
init_per_group(_, Config) ->
    rabbit_ct_helpers:run_setup_steps(Config).

end_per_group(java, Config) ->
    rabbit_ct_helpers:run_teardown_steps(Config);
end_per_group(_, Config) ->
    rabbit_ct_helpers:run_steps(Config,
                                rabbit_ct_broker_helpers:teardown_steps()).

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_Test, _Config) ->
    ok.

test_stream(Config) ->
    Port = get_stream_port(Config),
    test_server(gen_tcp, Port),
    ok.

test_stream_tls(Config) ->
    Port = get_stream_port_tls(Config),
    application:ensure_all_started(ssl),
    test_server(ssl, Port),
    ok.

test_gc_consumers(Config) ->
    Pid = spawn(fun() -> ok end),
    rabbit_ct_broker_helpers:rpc(Config,
                                 0,
                                 rabbit_stream_metrics,
                                 consumer_created,
                                 [Pid,
                                  #resource{name = <<"test">>,
                                            kind = queue,
                                            virtual_host = <<"/">>},
                                  0,
                                  10,
                                  0,
                                  0,
                                  0,
                                  #{}]),
    ok = test_utils:wait_until(fun() -> consumer_count(Config) == 0 end),
    ok.

test_gc_publishers(Config) ->
    Pid = spawn(fun() -> ok end),
    rabbit_ct_broker_helpers:rpc(Config,
                                 0,
                                 rabbit_stream_metrics,
                                 publisher_created,
                                 [Pid,
                                  #resource{name = <<"test">>,
                                            kind = queue,
                                            virtual_host = <<"/">>},
                                  0,
                                  <<"ref">>]),
    ok = test_utils:wait_until(fun() -> publisher_count(Config) == 0 end),
    ok.

consumer_count(Config) ->
    ets_count(Config, ?TABLE_CONSUMER).

publisher_count(Config) ->
    ets_count(Config, ?TABLE_PUBLISHER).

ets_count(Config, Table) ->
    Info = rabbit_ct_broker_helpers:rpc(Config, 0, ets, info, [Table]),
    rabbit_misc:pget(size, Info).

java(Config) ->
    StreamPortNode1 = get_stream_port(Config, 0),
    StreamPortNode2 = get_stream_port(Config, 1),
    StreamPortTlsNode1 = get_stream_port_tls(Config, 0),
    StreamPortTlsNode2 = get_stream_port_tls(Config, 1),
    Node1Name = get_node_name(Config, 0),
    Node2Name = get_node_name(Config, 1),
    RabbitMqCtl = get_rabbitmqctl(Config),
    DataDir = rabbit_ct_helpers:get_config(Config, data_dir),
    MakeResult =
        rabbit_ct_helpers:make(Config, DataDir,
                               ["tests",
                                {"NODE1_STREAM_PORT=~b", [StreamPortNode1]},
                                {"NODE1_STREAM_PORT_TLS=~b", [StreamPortTlsNode1]},
                                {"NODE1_NAME=~p", [Node1Name]},
                                {"NODE2_NAME=~p", [Node2Name]},
                                {"NODE2_STREAM_PORT=~b", [StreamPortNode2]},
                                {"NODE2_STREAM_PORT_TLS=~b", [StreamPortTlsNode2]},
                                {"RABBITMQCTL=~p", [RabbitMqCtl]}]),
    {ok, _} = MakeResult.

get_rabbitmqctl(Config) ->
    rabbit_ct_helpers:get_config(Config, rabbitmqctl_cmd).

get_stream_port(Config) ->
    get_stream_port(Config, 0).

get_stream_port(Config, Node) ->
    rabbit_ct_broker_helpers:get_node_config(Config, Node,
                                             tcp_port_stream).

get_stream_port_tls(Config) ->
    get_stream_port_tls(Config, 0).

get_stream_port_tls(Config, Node) ->
    rabbit_ct_broker_helpers:get_node_config(Config, Node,
                                             tcp_port_stream_tls).

get_node_name(Config) ->
    get_node_name(Config, 0).

get_node_name(Config, Node) ->
    rabbit_ct_broker_helpers:get_node_config(Config, Node, nodename).

test_server(Transport, Port) ->
    {ok, S} =
        Transport:connect("localhost", Port, [{active, false}, {mode, binary}]),
    C0 = rabbit_stream_core:init(0),
    C1 = test_peer_properties(Transport, S, C0),
    C2 = test_authenticate(Transport, S, C1),
    Stream = <<"stream1">>,
    C3 = test_create_stream(Transport, S, Stream, C2),
    PublisherId = 42,
    C4 = test_declare_publisher(Transport, S, PublisherId, Stream, C3),
    Body = <<"hello">>,
    C5 = test_publish_confirm(Transport, S, PublisherId, Body, C4),
    SubscriptionId = 42,
    C6 = test_subscribe(Transport, S, SubscriptionId, Stream, C5),
    C7 = test_deliver(Transport, S, SubscriptionId, Body, C6),
    C8 = test_delete_stream(Transport, S, Stream, C7),
    _C9 = test_close(Transport, S, C8),
    closed = wait_for_socket_close(Transport, S, 10),
    ok.

test_peer_properties(Transport, S, C0) ->
    PeerPropertiesFrame =
        rabbit_stream_core:frame({request, 1, {peer_properties, #{}}}),
    ok = Transport:send(S, PeerPropertiesFrame),
    {C, [Cmd]} = receive_commands(Transport, S, C0),
    ?assertMatch({response, 1, {peer_properties, ?RESPONSE_CODE_OK, _}},
                 Cmd),
    C.

test_authenticate(Transport, S, C0) ->
    SaslHandshakeFrame =
        rabbit_stream_core:frame({request, 1, sasl_handshake}),
    ok = Transport:send(S, SaslHandshakeFrame),
    Plain = <<"PLAIN">>,
    AmqPlain = <<"AMQPLAIN">>,
    {C1, [Cmd]} = receive_commands(Transport, S, C0),
    case Cmd of
        {response, _, {sasl_handshake, ?RESPONSE_CODE_OK, Mechanisms}} ->
            ?assertEqual([AmqPlain, Plain], lists:sort(Mechanisms));
        _ ->
            ct:fail("invalid cmd ~p", [Cmd])
    end,

    Username = <<"guest">>,
    Password = <<"guest">>,
    Null = 0,
    PlainSasl = <<Null:8, Username/binary, Null:8, Password/binary>>,

    SaslAuthenticateFrame =
        rabbit_stream_core:frame({request, 2,
                                  {sasl_authenticate, Plain, PlainSasl}}),
    ok = Transport:send(S, SaslAuthenticateFrame),
    {C2, [SaslAuth | Cmds2]} = receive_commands(Transport, S, C1),
    {response, 2, {sasl_authenticate, ?RESPONSE_CODE_OK}} = SaslAuth,
    {C3, Tune} =
        case Cmds2 of
            [] ->
                {C2b, [X]} = receive_commands(Transport, S, C2),
                {C2b, X};
            [T] ->
                {C2, T}
        end,

    {tune, ?DEFAULT_FRAME_MAX, ?DEFAULT_HEARTBEAT} = Tune,

    TuneFrame =
        rabbit_stream_core:frame({response, 0,
                                  {tune, ?DEFAULT_FRAME_MAX, 0}}),
    ok = Transport:send(S, TuneFrame),

    VirtualHost = <<"/">>,
    OpenFrame =
        rabbit_stream_core:frame({request, 3, {open, VirtualHost}}),
    ok = Transport:send(S, OpenFrame),
    {C4,
     [{response, 3, {open, ?RESPONSE_CODE_OK, _ConnectionProperties}}]} =
        receive_commands(Transport, S, C3),
    C4.

test_create_stream(Transport, S, Stream, C0) ->
    CreateStreamFrame =
        rabbit_stream_core:frame({request, 1, {create_stream, Stream, #{}}}),
    ok = Transport:send(S, CreateStreamFrame),
    {C, [Cmd]} = receive_commands(Transport, S, C0),
    ?assertMatch({response, 1, {create_stream, ?RESPONSE_CODE_OK}}, Cmd),
    C.

test_delete_stream(Transport, S, Stream, C0) ->
    DeleteStreamFrame =
        rabbit_stream_core:frame({request, 1, {delete_stream, Stream}}),
    ok = Transport:send(S, DeleteStreamFrame),
    {C1, [Cmd | MaybeMetaData]} = receive_commands(Transport, S, C0),
    ?assertMatch({response, 1, {delete_stream, ?RESPONSE_CODE_OK}}, Cmd),
    case MaybeMetaData of
        [] ->
            test_metadata_update_stream_deleted(Transport, S, Stream, C1);
        [Meta] ->
            {metadata_update, Stream, ?RESPONSE_CODE_STREAM_NOT_AVAILABLE} =
                Meta,
            C1
    end.

test_metadata_update_stream_deleted(Transport, S, Stream, C0) ->
    {C1, [Meta]} = receive_commands(Transport, S, C0),
    {metadata_update, Stream, ?RESPONSE_CODE_STREAM_NOT_AVAILABLE} = Meta,
    C1.

test_declare_publisher(Transport, S, PublisherId, Stream, C0) ->
    DeclarePublisherFrame =
        rabbit_stream_core:frame({request, 1,
                                  {declare_publisher,
                                   PublisherId,
                                   <<>>,
                                   Stream}}),
    ok = Transport:send(S, DeclarePublisherFrame),
    {C, [Cmd]} = receive_commands(Transport, S, C0),
    ?assertMatch({response, 1, {declare_publisher, ?RESPONSE_CODE_OK}},
                 Cmd),
    C.

test_publish_confirm(Transport, S, PublisherId, Body, C0) ->
    BodySize = byte_size(Body),
    Messages = [<<1:64, 0:1, BodySize:31, Body:BodySize/binary>>],
    PublishFrame =
        rabbit_stream_core:frame({publish, PublisherId, 1, Messages}),
    ok = Transport:send(S, PublishFrame),
    {C, [Cmd]} = receive_commands(Transport, S, C0),
    ?assertMatch({publish_confirm, PublisherId, [1]}, Cmd),
    C.

test_subscribe(Transport, S, SubscriptionId, Stream, C0) ->
    SubCmd = {request, 1, {subscribe, SubscriptionId, Stream, 0, 10}},
    SubscribeFrame = rabbit_stream_core:frame(SubCmd),
    ok = Transport:send(S, SubscribeFrame),
    {C, [Cmd]} = receive_commands(Transport, S, C0),
    ?assertMatch({response, 1, {subscribe, ?RESPONSE_CODE_OK}}, Cmd),
    C.

test_deliver(Transport, S, SubscriptionId, Body, C0) ->
    {C, [{deliver, SubscriptionId, Chunk}]} = receive_commands(Transport, S, C0),
    <<5:4/unsigned,
      0:4/unsigned,
      0:8,
      1:16,
      1:32,
      _Timestamp:64,
      _Epoch:64,
      0:64,
      _Crc:32,
      _DataLength:32,
      _TrailerLength:32,
      _ReservedBytes:32,
      0:1,
      BodySize:31/unsigned,
      Body:BodySize/binary>> =
        Chunk,
    C.

test_close(Transport, S, C0) ->
    CloseReason = <<"OK">>,
    CloseFrame =
        rabbit_stream_core:frame({request, 1,
                                  {close, ?RESPONSE_CODE_OK, CloseReason}}),
    ok = Transport:send(S, CloseFrame),
    {C, [{response, 1, {close, ?RESPONSE_CODE_OK}}]} =
        receive_commands(Transport, S, C0),
    C.

wait_for_socket_close(_Transport, _S, 0) ->
    not_closed;
wait_for_socket_close(Transport, S, Attempt) ->
    case Transport:recv(S, 0, 1000) of
        {error, timeout} ->
            wait_for_socket_close(Transport, S, Attempt - 1);
        {error, closed} ->
            closed
    end.

receive_commands(Transport, S, C0) ->
    case Transport:recv(S, 0, 5000) of
        {ok, Data} ->
            case rabbit_stream_core:incoming_data(Data, C0) of
                {C1, []} ->
                    %% no command received, try once more
                    {ok, Data2} = Transport:recv(S, 0, 5000),
                    rabbit_stream_core:incoming_data(Data2, C1);
                {_C, _Cmds} = Ret ->
                    Ret
            end;
        {error, Err} ->
            ct:pal("error receiving data ~w", [Err]),
            {C0, []}
    end.
