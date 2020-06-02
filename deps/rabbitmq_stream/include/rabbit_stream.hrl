-define(COMMAND_PUBLISH, 0).
-define(COMMAND_PUBLISH_CONFIRM, 1).
-define(COMMAND_SUBSCRIBE, 2).
-define(COMMAND_DELIVER, 3).
-define(COMMAND_CREDIT, 4).
-define(COMMAND_UNSUBSCRIBE, 5).
-define(COMMAND_PUBLISH_ERROR, 6).
-define(COMMAND_METADATA_UPDATE, 7).
-define(COMMAND_METADATA, 8).
-define(COMMAND_SASL_HANDSHAKE, 9).
-define(COMMAND_SASL_AUTHENTICATE, 10).
-define(COMMAND_TUNE, 11).
-define(COMMAND_OPEN, 12).
-define(COMMAND_CLOSE, 13).
-define(COMMAND_HEARTBEAT, 14).
-define(COMMAND_CREATE_STREAM, 998).
-define(COMMAND_DELETE_STREAM, 999).

-define(VERSION_0, 0).

-define(RESPONSE_CODE_OK, 0).
-define(RESPONSE_CODE_STREAM_DOES_NOT_EXIST, 1).
-define(RESPONSE_CODE_SUBSCRIPTION_ID_ALREADY_EXISTS, 2).
-define(RESPONSE_CODE_SUBSCRIPTION_ID_DOES_NOT_EXIST, 3).
-define(RESPONSE_CODE_STREAM_ALREADY_EXISTS, 4).
-define(RESPONSE_CODE_STREAM_DELETED, 5).
-define(RESPONSE_SASL_MECHANISM_NOT_SUPPORTED, 6).
-define(RESPONSE_AUTHENTICATION_FAILURE, 7).
-define(RESPONSE_SASL_ERROR, 8).
-define(RESPONSE_SASL_CHALLENGE, 9).
-define(RESPONSE_SASL_AUTHENTICATION_FAILURE_LOOPBACK, 10).
-define(RESPONSE_VHOST_ACCESS_FAILURE, 11).
-define(RESPONSE_CODE_UNKNOWN_FRAME, 12).
-define(RESPONSE_CODE_FRAME_TOO_LARGE, 13).
-define(RESPONSE_CODE_INTERNAL_ERROR, 14).

-define(OFFSET_TYPE_FIRST, 0).
-define(OFFSET_TYPE_LAST, 1).
-define(OFFSET_TYPE_NEXT, 2).
-define(OFFSET_TYPE_OFFSET, 3).
-define(OFFSET_TYPE_TIMESTAMP, 4).

-define(DEFAULT_INITIAL_CREDITS, 50000).
-define(DEFAULT_CREDITS_REQUIRED_FOR_UNBLOCKING, 12500).
-define(DEFAULT_FRAME_MAX, 1048576). %% 1 MB
-define(DEFAULT_HEARTBEAT, 600).