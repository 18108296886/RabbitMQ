%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2023 Broadcom. All Rights Reserved. The term “Broadcom” refers to Broadcom Inc. and/or its subsidiaries.  All rights reserved.
%%
-module(uaa_jwt).

-export([add_signing_key/3,
         decode_and_verify/1,
         get_jwk/2,
         verify_signing_key/2]).

-export([client_id/1, sub/1, client_id/2, sub/2]).

-include_lib("jose/include/jose_jwk.hrl").

-define(APP, rabbitmq_auth_backend_oauth2).

-type key_type() :: json | pem | map.

-spec add_signing_key(binary(), key_type(), binary() | map()) -> {ok, map()} | {error, term()}.
add_signing_key(KeyId, Type, Value) ->
    case verify_signing_key(Type, Value) of
        ok ->
            {ok, rabbit_oauth2_config:add_signing_key(KeyId, {Type, Value})};
        {error, _} = Err ->
            Err
    end.

-spec update_jwks_signing_keys(term()) -> ok | {error, term()}.
update_jwks_signing_keys(ResourceServerId) ->
    case rabbit_oauth2_config:get_jwks_url(ResourceServerId) of
        undefined ->
            rabbit_log:debug("No JWKS URL for resource-server-id ~p ", [ResourceServerId]),
            {error, no_jwks_url};
        JwksUrl ->
            rabbit_log:debug("Downloading keys from ~p using ~p", [JwksUrl, rabbit_oauth2_config:get_key_config(ResourceServerId)]),
            case uaa_jwks:get(JwksUrl, rabbit_oauth2_config:get_key_config(ResourceServerId)) of
                {ok, {_, _, JwksBody}} ->
                    KeyList = maps:get(<<"keys">>, jose:decode(erlang:iolist_to_binary(JwksBody)), []),
                    Keys = maps:from_list(lists:map(fun(Key) -> {maps:get(<<"kid">>, Key, undefined), {json, Key}} end, KeyList)),
                    rabbit_log:debug("Downloaded keys ~p", [Keys]),
                    case rabbit_oauth2_config:replace_signing_keys(ResourceServerId, Keys) of
                      {error, _} = Err -> Err;
                      _ -> ok
                    end;
                {error, _} = Err ->
                    rabbit_log:error("Error Downloadings keys ~p", [Err]),
                    Err
            end
    end.

-spec decode_and_verify(binary()) -> {boolean(), binary(), map()} | {error, term()}.
decode_and_verify(Token) ->
  case uaa_jwt_jwt:resolve_resource_server_id(Token) of
    {error, _} = Err ->
        Err;
    ResourceServerId ->
      rabbit_log:debug("Resolved resource_server_id : ~p", [ResourceServerId]),
      case uaa_jwt_jwt:get_key_id(ResourceServerId, Token) of
        {ok, KeyId} ->
            rabbit_log:debug("Resolved signing_key_id : ~p", [KeyId]),
            case get_jwk(KeyId, ResourceServerId) of
              {ok, JWK} ->
                  case uaa_jwt_jwt:decode_and_verify(ResourceServerId, JWK, Token) of
                    {true, Payload} -> {true, ResourceServerId, Payload};
                    Other -> Other
                  end;
              {error, _} = Err ->
                  Err
            end;
        {error, _} = Err ->
          Err
      end
  end.

-spec get_jwk(binary(), binary()) -> {ok, map()} | {error, term()}.
get_jwk(KeyId, ResourceServerId) ->
    get_jwk(KeyId, ResourceServerId, true).

get_jwk(KeyId, ResourceServerId, AllowUpdateJwks) ->
    case rabbit_oauth2_config:get_signing_key(KeyId, ResourceServerId) of
        undefined ->
            if
                AllowUpdateJwks ->
                    rabbit_log:debug("Signing key ~p not found. Downloading it .. ", [KeyId]),
                    case update_jwks_signing_keys(ResourceServerId) of
                        ok ->
                            get_jwk(KeyId, ResourceServerId, false);
                        {error, no_jwks_url} ->
                            {error, key_not_found};
                        {error, _} = Err ->
                            Err
                    end;
                true            ->
                    rabbit_log:debug("Signing key ~p not found. Download not allowed ", [KeyId]),
                    {error, key_not_found}
            end;
        {Type, Value} ->
            rabbit_log:debug("Signing key found : ~p, ~p ", [Type, Value]),
            case Type of
                json     -> uaa_jwt_jwk:make_jwk(Value);
                pem      -> uaa_jwt_jwk:from_pem(Value);
                pem_file -> uaa_jwt_jwk:from_pem_file(Value);
                map      -> uaa_jwt_jwk:make_jwk(Value);
                _        -> {error, unknown_signing_key_type}
            end
    end.

verify_signing_key(Type, Value) ->
    Verified = case Type of
        json     -> uaa_jwt_jwk:make_jwk(Value);
        pem      -> uaa_jwt_jwk:from_pem(Value);
        pem_file -> uaa_jwt_jwk:from_pem_file(Value);
        map      -> uaa_jwt_jwk:make_jwk(Value);
        _         -> {error, unknown_signing_key_type}
    end,
    case Verified of
        {ok, Key} ->
            case jose_jwk:from(Key) of
                #jose_jwk{}     -> ok;
                {error, Reason} -> {error, Reason}
            end;
        Err -> Err
    end.


-spec client_id(map()) -> binary() | undefined.
client_id(DecodedToken) ->
    maps:get(<<"client_id">>, DecodedToken, undefined).

-spec client_id(map(), any()) -> binary() | undefined.
client_id(DecodedToken, Default) ->
    maps:get(<<"client_id">>, DecodedToken, Default).

-spec sub(map()) -> binary() | undefined.
sub(DecodedToken) ->
    maps:get(<<"sub">>, DecodedToken, undefined).

-spec sub(map(), any()) -> binary() | undefined.
sub(DecodedToken, Default) ->
    maps:get(<<"sub">>, DecodedToken, Default).
