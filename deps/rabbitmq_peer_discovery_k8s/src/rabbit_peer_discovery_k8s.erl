%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2024 Broadcom. All Rights Reserved. The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries. All rights reserved.
%%

-module(rabbit_peer_discovery_k8s).
-behaviour(rabbit_peer_discovery_backend).

-export([init/0, list_nodes/0, supports_registration/0, register/0, unregister/0,
         post_registration/0, lock/1, unlock/1, node/0]).

-ifdef(TEST).
-compile(export_all).
-endif.

-spec list_nodes() -> {ok, {Nodes :: [node()] | node(), NodeType :: rabbit_types:node_type()}} | {error, Reason :: string()}.

list_nodes() ->
    Nodename = ?MODULE:node(),
    try
        Hostname = hostname(),
        [Prefix, Suffix] = string:split(atom_to_list(Nodename), Hostname),
        [StatefulSetName, MyPodId] = string:split(Hostname, "-", trailing),
        _ = list_to_integer(MyPodId),
        {ok, {list_to_atom(Prefix ++ StatefulSetName ++ "-0" ++ Suffix), disc}}
    catch error:_ ->
              rabbit_log:warning("Failed to generate node names based on my hostname. Perhaps you are trying to deploy RabbitMQ without a StatefulSet?"),
              {error, lists:flatten(io_lib:format("my nodename (~s) doesn't seem to be have an -ID suffix like StatefulSet pods should", [?MODULE:node()]))}
    end.

node() ->
    erlang:node().

% TODO can we (re)use somethnig from rabbit_peer_discovery_util?
hostname() ->
    {match, [Hostname0]} = re:run(atom_to_list(?MODULE:node()), "@(.*)",
                                 [{capture, [1], list}]),
    [Hostname, _Domain] = string:split(Hostname0, "."),
    Hostname.

supports_registration() -> false.
init() -> ok.
register() -> ok.
unregister() -> ok.
post_registration() -> ok.
lock(_) -> not_supported.
unlock(_) -> ok.
