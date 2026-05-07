-module(greak_openai_stream_ffi).
-export([post_sse/4]).

post_sse(Url, Headers, Body, OnLine) ->
    application:ensure_all_started(ssl),
    application:ensure_all_started(inets),
    Request = {
        post,
        {
            binary_to_list(Url),
            normalise_headers(Headers),
            "application/json",
            Body
        },
        [{timeout, 30000}],
        [{sync, false}, {stream, self()}, {body_format, binary}]
    },
    case httpc:request(Request) of
        {ok, RequestId} ->
            receive_stream(RequestId, <<>>, [], OnLine);
        {error, Reason} ->
            {error, format_reason(Reason)}
    end.

normalise_headers(Headers) ->
    lists:map(
      fun({Key, Value}) ->
          {binary_to_list(Key), binary_to_list(Value)}
      end,
      Headers
    ).

receive_stream(RequestId, Buffer, Lines, OnLine) ->
    receive
        {http, {RequestId, stream_start, _Headers}} ->
            receive_stream(RequestId, Buffer, Lines, OnLine);
        {http, {RequestId, stream, Chunk}} ->
            {Rest, NextLines} = flush_lines(<<Buffer/binary, Chunk/binary>>, Lines, OnLine),
            receive_stream(RequestId, Rest, NextLines, OnLine);
        {http, {RequestId, stream_end, _Headers}} ->
            FinalLines = flush_tail(Buffer, Lines, OnLine),
            {ok, join_lines(lists:reverse(FinalLines))};
        {http, {RequestId, {error, Reason}}} ->
            {error, format_reason(Reason)}
    after 30000 ->
        {error, <<"stream_timeout">>}
    end.

flush_lines(Buffer, Lines, OnLine) ->
    Parts = binary:split(Buffer, <<"\n">>, [global]),
    case Parts of
        [] ->
            {<<>>, Lines};
        [_Only] ->
            {Buffer, Lines};
        _ ->
            Rest = lists:last(Parts),
            Completed = lists:sublist(Parts, length(Parts) - 1),
            NextLines =
                lists:foldl(
                  fun(Line, Acc) ->
                      Clean = trim_cr(Line),
                      OnLine(Clean),
                      [Clean | Acc]
                  end,
                  Lines,
                  Completed
                ),
            {Rest, NextLines}
    end.

flush_tail(<<>>, Lines, _OnLine) ->
    Lines;
flush_tail(Buffer, Lines, OnLine) ->
    Clean = trim_cr(Buffer),
    OnLine(Clean),
    [Clean | Lines].

trim_cr(Line) ->
    Size = byte_size(Line),
    case Size > 0 andalso binary:at(Line, Size - 1) =:= $\r of
        true -> binary:part(Line, 0, Size - 1);
        false -> Line
    end.

join_lines(Lines) ->
    lists:foldl(
      fun(Line, <<>>) -> Line;
         (Line, Acc) -> <<Acc/binary, "\n", Line/binary>>
      end,
      <<>>,
      Lines
    ).

format_reason(Reason) ->
    unicode:characters_to_binary(io_lib:format("~p", [Reason])).
