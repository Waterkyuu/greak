-module(greak_cli_runtime_ffi).
-export([arguments/0, get_env/1]).

arguments() ->
    [unicode:characters_to_binary(Arg) || Arg <- init:get_plain_arguments()].

get_env(Name) ->
    case os:getenv(binary_to_list(Name)) of
        false -> none;
        Value -> {some, unicode:characters_to_binary(Value)}
    end.
