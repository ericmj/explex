%% Vendored from hex_core v0.5.0, do not edit manually

%% -*- coding: utf-8 -*-
%% Automatically generated, do not edit
%% Generated by gpb_compile version 4.3.1
-module(mix_hex_pb_signed).

-export([encode_msg/2, encode_msg/3]).
-export([decode_msg/2, decode_msg/3]).
-export([merge_msgs/3, merge_msgs/4]).
-export([verify_msg/2, verify_msg/3]).
-export([get_msg_defs/0]).
-export([get_msg_names/0]).
-export([get_group_names/0]).
-export([get_msg_or_group_names/0]).
-export([get_enum_names/0]).
-export([find_msg_def/1, fetch_msg_def/1]).
-export([find_enum_def/1, fetch_enum_def/1]).
-export([enum_symbol_by_value/2, enum_value_by_symbol/2]).
-export([get_service_names/0]).
-export([get_service_def/1]).
-export([get_rpc_names/1]).
-export([find_rpc_def/2, fetch_rpc_def/2]).
-export([get_package_name/0]).
-export([gpb_version_as_string/0, gpb_version_as_list/0]).


%% enumerated types

-export_type([]).

%% message types
-type 'Signed'() ::
      #{payload                 => iodata()         % = 1
        %% signature            => iodata()         % = 2
       }.

-export_type(['Signed'/0]).

-spec encode_msg('Signed'(), atom()) -> binary().
encode_msg(Msg, MsgName) when is_atom(MsgName) ->
    encode_msg(Msg, MsgName, []).

-spec encode_msg('Signed'(), atom(), list()) -> binary().
encode_msg(Msg, MsgName, Opts) ->
    verify_msg(Msg, MsgName, Opts),
    TrUserData = proplists:get_value(user_data, Opts),
    case MsgName of
      'Signed' ->
	  e_msg_Signed(id(Msg, TrUserData), TrUserData)
    end.


e_msg_Signed(Msg, TrUserData) ->
    e_msg_Signed(Msg, <<>>, TrUserData).


e_msg_Signed(#{payload := F1} = M, Bin, TrUserData) ->
    B1 = begin
	   TrF1 = id(F1, TrUserData),
	   e_type_bytes(TrF1, <<Bin/binary, 10>>, TrUserData)
	 end,
    case M of
      #{signature := F2} ->
	  begin
	    TrF2 = id(F2, TrUserData),
	    e_type_bytes(TrF2, <<B1/binary, 18>>, TrUserData)
	  end;
      _ -> B1
    end.

-compile({nowarn_unused_function,e_type_sint/3}).
e_type_sint(Value, Bin, _TrUserData) when Value >= 0 ->
    e_varint(Value * 2, Bin);
e_type_sint(Value, Bin, _TrUserData) ->
    e_varint(Value * -2 - 1, Bin).

-compile({nowarn_unused_function,e_type_int32/3}).
e_type_int32(Value, Bin, _TrUserData)
    when 0 =< Value, Value =< 127 ->
    <<Bin/binary, Value>>;
e_type_int32(Value, Bin, _TrUserData) ->
    <<N:64/unsigned-native>> = <<Value:64/signed-native>>,
    e_varint(N, Bin).

-compile({nowarn_unused_function,e_type_int64/3}).
e_type_int64(Value, Bin, _TrUserData)
    when 0 =< Value, Value =< 127 ->
    <<Bin/binary, Value>>;
e_type_int64(Value, Bin, _TrUserData) ->
    <<N:64/unsigned-native>> = <<Value:64/signed-native>>,
    e_varint(N, Bin).

-compile({nowarn_unused_function,e_type_bool/3}).
e_type_bool(true, Bin, _TrUserData) ->
    <<Bin/binary, 1>>;
e_type_bool(false, Bin, _TrUserData) ->
    <<Bin/binary, 0>>;
e_type_bool(1, Bin, _TrUserData) -> <<Bin/binary, 1>>;
e_type_bool(0, Bin, _TrUserData) -> <<Bin/binary, 0>>.

-compile({nowarn_unused_function,e_type_string/3}).
e_type_string(S, Bin, _TrUserData) ->
    Utf8 = unicode:characters_to_binary(S),
    Bin2 = e_varint(byte_size(Utf8), Bin),
    <<Bin2/binary, Utf8/binary>>.

-compile({nowarn_unused_function,e_type_bytes/3}).
e_type_bytes(Bytes, Bin, _TrUserData)
    when is_binary(Bytes) ->
    Bin2 = e_varint(byte_size(Bytes), Bin),
    <<Bin2/binary, Bytes/binary>>;
e_type_bytes(Bytes, Bin, _TrUserData)
    when is_list(Bytes) ->
    BytesBin = iolist_to_binary(Bytes),
    Bin2 = e_varint(byte_size(BytesBin), Bin),
    <<Bin2/binary, BytesBin/binary>>.

-compile({nowarn_unused_function,e_type_fixed32/3}).
e_type_fixed32(Value, Bin, _TrUserData) ->
    <<Bin/binary, Value:32/little>>.

-compile({nowarn_unused_function,e_type_sfixed32/3}).
e_type_sfixed32(Value, Bin, _TrUserData) ->
    <<Bin/binary, Value:32/little-signed>>.

-compile({nowarn_unused_function,e_type_fixed64/3}).
e_type_fixed64(Value, Bin, _TrUserData) ->
    <<Bin/binary, Value:64/little>>.

-compile({nowarn_unused_function,e_type_sfixed64/3}).
e_type_sfixed64(Value, Bin, _TrUserData) ->
    <<Bin/binary, Value:64/little-signed>>.

-compile({nowarn_unused_function,e_type_float/3}).
e_type_float(V, Bin, _) when is_number(V) ->
    <<Bin/binary, V:32/little-float>>;
e_type_float(infinity, Bin, _) ->
    <<Bin/binary, 0:16, 128, 127>>;
e_type_float('-infinity', Bin, _) ->
    <<Bin/binary, 0:16, 128, 255>>;
e_type_float(nan, Bin, _) ->
    <<Bin/binary, 0:16, 192, 127>>.

-compile({nowarn_unused_function,e_type_double/3}).
e_type_double(V, Bin, _) when is_number(V) ->
    <<Bin/binary, V:64/little-float>>;
e_type_double(infinity, Bin, _) ->
    <<Bin/binary, 0:48, 240, 127>>;
e_type_double('-infinity', Bin, _) ->
    <<Bin/binary, 0:48, 240, 255>>;
e_type_double(nan, Bin, _) ->
    <<Bin/binary, 0:48, 248, 127>>.

-compile({nowarn_unused_function,e_varint/3}).
e_varint(N, Bin, _TrUserData) -> e_varint(N, Bin).

-compile({nowarn_unused_function,e_varint/2}).
e_varint(N, Bin) when N =< 127 -> <<Bin/binary, N>>;
e_varint(N, Bin) ->
    Bin2 = <<Bin/binary, (N band 127 bor 128)>>,
    e_varint(N bsr 7, Bin2).


decode_msg(Bin, MsgName) when is_binary(Bin) ->
    decode_msg(Bin, MsgName, []).

decode_msg(Bin, MsgName, Opts) when is_binary(Bin) ->
    TrUserData = proplists:get_value(user_data, Opts),
    decode_msg_1_catch(Bin, MsgName, TrUserData).

-ifdef('OTP_RELEASE').
decode_msg_1_catch(Bin, MsgName, TrUserData) ->
    try decode_msg_2_doit(MsgName, Bin, TrUserData)
    catch Class:Reason:StackTrace -> error({gpb_error,{decoding_failure, {Bin, MsgName, {Class, Reason, StackTrace}}}})
    end.
-else.
-ifdef('GPB_PATTERN_STACK').
decode_msg_1_catch(Bin, MsgName, TrUserData) ->
    try decode_msg_2_doit(MsgName, Bin, TrUserData)
    catch Class:Reason:StackTrace -> error({gpb_error,{decoding_failure, {Bin, MsgName, {Class, Reason, StackTrace}}}})
    end.
-else.
decode_msg_1_catch(Bin, MsgName, TrUserData) ->
    try decode_msg_2_doit(MsgName, Bin, TrUserData)
    catch Class:Reason ->
        StackTrace = erlang:get_stacktrace(),
        error({gpb_error,{decoding_failure, {Bin, MsgName, {Class, Reason, StackTrace}}}})
    end.
-endif.

-endif.

decode_msg_2_doit('Signed', Bin, TrUserData) ->
    id(d_msg_Signed(Bin, TrUserData), TrUserData).



d_msg_Signed(Bin, TrUserData) ->
    dfp_read_field_def_Signed(Bin, 0, 0,
			      id('$undef', TrUserData),
			      id('$undef', TrUserData), TrUserData).

dfp_read_field_def_Signed(<<10, Rest/binary>>, Z1, Z2,
			  F@_1, F@_2, TrUserData) ->
    d_field_Signed_payload(Rest, Z1, Z2, F@_1, F@_2,
			   TrUserData);
dfp_read_field_def_Signed(<<18, Rest/binary>>, Z1, Z2,
			  F@_1, F@_2, TrUserData) ->
    d_field_Signed_signature(Rest, Z1, Z2, F@_1, F@_2,
			     TrUserData);
dfp_read_field_def_Signed(<<>>, 0, 0, F@_1, F@_2, _) ->
    S1 = #{payload => F@_1},
    if F@_2 == '$undef' -> S1;
       true -> S1#{signature => F@_2}
    end;
dfp_read_field_def_Signed(Other, Z1, Z2, F@_1, F@_2,
			  TrUserData) ->
    dg_read_field_def_Signed(Other, Z1, Z2, F@_1, F@_2,
			     TrUserData).

dg_read_field_def_Signed(<<1:1, X:7, Rest/binary>>, N,
			 Acc, F@_1, F@_2, TrUserData)
    when N < 32 - 7 ->
    dg_read_field_def_Signed(Rest, N + 7, X bsl N + Acc,
			     F@_1, F@_2, TrUserData);
dg_read_field_def_Signed(<<0:1, X:7, Rest/binary>>, N,
			 Acc, F@_1, F@_2, TrUserData) ->
    Key = X bsl N + Acc,
    case Key of
      10 ->
	  d_field_Signed_payload(Rest, 0, 0, F@_1, F@_2,
				 TrUserData);
      18 ->
	  d_field_Signed_signature(Rest, 0, 0, F@_1, F@_2,
				   TrUserData);
      _ ->
	  case Key band 7 of
	    0 ->
		skip_varint_Signed(Rest, 0, 0, F@_1, F@_2, TrUserData);
	    1 -> skip_64_Signed(Rest, 0, 0, F@_1, F@_2, TrUserData);
	    2 ->
		skip_length_delimited_Signed(Rest, 0, 0, F@_1, F@_2,
					     TrUserData);
	    3 ->
		skip_group_Signed(Rest, Key bsr 3, 0, F@_1, F@_2,
				  TrUserData);
	    5 -> skip_32_Signed(Rest, 0, 0, F@_1, F@_2, TrUserData)
	  end
    end;
dg_read_field_def_Signed(<<>>, 0, 0, F@_1, F@_2, _) ->
    S1 = #{payload => F@_1},
    if F@_2 == '$undef' -> S1;
       true -> S1#{signature => F@_2}
    end.

d_field_Signed_payload(<<1:1, X:7, Rest/binary>>, N,
		       Acc, F@_1, F@_2, TrUserData)
    when N < 57 ->
    d_field_Signed_payload(Rest, N + 7, X bsl N + Acc, F@_1,
			   F@_2, TrUserData);
d_field_Signed_payload(<<0:1, X:7, Rest/binary>>, N,
		       Acc, _, F@_2, TrUserData) ->
    {NewFValue, RestF} = begin
			   Len = X bsl N + Acc,
			   <<Bytes:Len/binary, Rest2/binary>> = Rest,
			   {id(binary:copy(Bytes), TrUserData), Rest2}
			 end,
    dfp_read_field_def_Signed(RestF, 0, 0, NewFValue, F@_2,
			      TrUserData).

d_field_Signed_signature(<<1:1, X:7, Rest/binary>>, N,
			 Acc, F@_1, F@_2, TrUserData)
    when N < 57 ->
    d_field_Signed_signature(Rest, N + 7, X bsl N + Acc,
			     F@_1, F@_2, TrUserData);
d_field_Signed_signature(<<0:1, X:7, Rest/binary>>, N,
			 Acc, F@_1, _, TrUserData) ->
    {NewFValue, RestF} = begin
			   Len = X bsl N + Acc,
			   <<Bytes:Len/binary, Rest2/binary>> = Rest,
			   {id(binary:copy(Bytes), TrUserData), Rest2}
			 end,
    dfp_read_field_def_Signed(RestF, 0, 0, F@_1, NewFValue,
			      TrUserData).

skip_varint_Signed(<<1:1, _:7, Rest/binary>>, Z1, Z2,
		   F@_1, F@_2, TrUserData) ->
    skip_varint_Signed(Rest, Z1, Z2, F@_1, F@_2,
		       TrUserData);
skip_varint_Signed(<<0:1, _:7, Rest/binary>>, Z1, Z2,
		   F@_1, F@_2, TrUserData) ->
    dfp_read_field_def_Signed(Rest, Z1, Z2, F@_1, F@_2,
			      TrUserData).

skip_length_delimited_Signed(<<1:1, X:7, Rest/binary>>,
			     N, Acc, F@_1, F@_2, TrUserData)
    when N < 57 ->
    skip_length_delimited_Signed(Rest, N + 7, X bsl N + Acc,
				 F@_1, F@_2, TrUserData);
skip_length_delimited_Signed(<<0:1, X:7, Rest/binary>>,
			     N, Acc, F@_1, F@_2, TrUserData) ->
    Length = X bsl N + Acc,
    <<_:Length/binary, Rest2/binary>> = Rest,
    dfp_read_field_def_Signed(Rest2, 0, 0, F@_1, F@_2,
			      TrUserData).

skip_group_Signed(Bin, FNum, Z2, F@_1, F@_2,
		  TrUserData) ->
    {_, Rest} = read_group(Bin, FNum),
    dfp_read_field_def_Signed(Rest, 0, Z2, F@_1, F@_2,
			      TrUserData).

skip_32_Signed(<<_:32, Rest/binary>>, Z1, Z2, F@_1,
	       F@_2, TrUserData) ->
    dfp_read_field_def_Signed(Rest, Z1, Z2, F@_1, F@_2,
			      TrUserData).

skip_64_Signed(<<_:64, Rest/binary>>, Z1, Z2, F@_1,
	       F@_2, TrUserData) ->
    dfp_read_field_def_Signed(Rest, Z1, Z2, F@_1, F@_2,
			      TrUserData).

read_group(Bin, FieldNum) ->
    {NumBytes, EndTagLen} = read_gr_b(Bin, 0, 0, 0, 0, FieldNum),
    <<Group:NumBytes/binary, _:EndTagLen/binary, Rest/binary>> = Bin,
    {Group, Rest}.

%% Like skipping over fields, but record the total length,
%% Each field is <(FieldNum bsl 3) bor FieldType> ++ <FieldValue>
%% Record the length because varints may be non-optimally encoded.
%%
%% Groups can be nested, but assume the same FieldNum cannot be nested
%% because group field numbers are shared with the rest of the fields
%% numbers. Thus we can search just for an group-end with the same
%% field number.
%%
%% (The only time the same group field number could occur would
%% be in a nested sub message, but then it would be inside a
%% length-delimited entry, which we skip-read by length.)
read_gr_b(<<1:1, X:7, Tl/binary>>, N, Acc, NumBytes, TagLen, FieldNum)
  when N < (32-7) ->
    read_gr_b(Tl, N+7, X bsl N + Acc, NumBytes, TagLen+1, FieldNum);
read_gr_b(<<0:1, X:7, Tl/binary>>, N, Acc, NumBytes, TagLen,
          FieldNum) ->
    Key = X bsl N + Acc,
    TagLen1 = TagLen + 1,
    case {Key bsr 3, Key band 7} of
        {FieldNum, 4} -> % 4 = group_end
            {NumBytes, TagLen1};
        {_, 0} -> % 0 = varint
            read_gr_vi(Tl, 0, NumBytes + TagLen1, FieldNum);
        {_, 1} -> % 1 = bits64
            <<_:64, Tl2/binary>> = Tl,
            read_gr_b(Tl2, 0, 0, NumBytes + TagLen1 + 8, 0, FieldNum);
        {_, 2} -> % 2 = length_delimited
            read_gr_ld(Tl, 0, 0, NumBytes + TagLen1, FieldNum);
        {_, 3} -> % 3 = group_start
            read_gr_b(Tl, 0, 0, NumBytes + TagLen1, 0, FieldNum);
        {_, 4} -> % 4 = group_end
            read_gr_b(Tl, 0, 0, NumBytes + TagLen1, 0, FieldNum);
        {_, 5} -> % 5 = bits32
            <<_:32, Tl2/binary>> = Tl,
            read_gr_b(Tl2, 0, 0, NumBytes + TagLen1 + 4, 0, FieldNum)
    end.

read_gr_vi(<<1:1, _:7, Tl/binary>>, N, NumBytes, FieldNum)
  when N < (64-7) ->
    read_gr_vi(Tl, N+7, NumBytes+1, FieldNum);
read_gr_vi(<<0:1, _:7, Tl/binary>>, _, NumBytes, FieldNum) ->
    read_gr_b(Tl, 0, 0, NumBytes+1, 0, FieldNum).

read_gr_ld(<<1:1, X:7, Tl/binary>>, N, Acc, NumBytes, FieldNum)
  when N < (64-7) ->
    read_gr_ld(Tl, N+7, X bsl N + Acc, NumBytes+1, FieldNum);
read_gr_ld(<<0:1, X:7, Tl/binary>>, N, Acc, NumBytes, FieldNum) ->
    Len = X bsl N + Acc,
    NumBytes1 = NumBytes + 1,
    <<_:Len/binary, Tl2/binary>> = Tl,
    read_gr_b(Tl2, 0, 0, NumBytes1 + Len, 0, FieldNum).

merge_msgs(Prev, New, MsgName) when is_atom(MsgName) ->
    merge_msgs(Prev, New, MsgName, []).

merge_msgs(Prev, New, MsgName, Opts) ->
    TrUserData = proplists:get_value(user_data, Opts),
    case MsgName of
      'Signed' -> merge_msg_Signed(Prev, New, TrUserData)
    end.

-compile({nowarn_unused_function,merge_msg_Signed/3}).
merge_msg_Signed(#{} = PMsg,
		 #{payload := NFpayload} = NMsg, _) ->
    S1 = #{payload => NFpayload},
    case {PMsg, NMsg} of
      {_, #{signature := NFsignature}} ->
	  S1#{signature => NFsignature};
      {#{signature := PFsignature}, _} ->
	  S1#{signature => PFsignature};
      _ -> S1
    end.


verify_msg(Msg, MsgName) when is_atom(MsgName) ->
    verify_msg(Msg, MsgName, []).

verify_msg(Msg, MsgName, Opts) ->
    TrUserData = proplists:get_value(user_data, Opts),
    case MsgName of
      'Signed' -> v_msg_Signed(Msg, [MsgName], TrUserData);
      _ -> mk_type_error(not_a_known_message, Msg, [])
    end.


-compile({nowarn_unused_function,v_msg_Signed/3}).
v_msg_Signed(#{payload := F1} = M, Path, TrUserData) ->
    v_type_bytes(F1, [payload | Path], TrUserData),
    case M of
      #{signature := F2} ->
	  v_type_bytes(F2, [signature | Path], TrUserData);
      _ -> ok
    end,
    lists:foreach(fun (payload) -> ok;
		      (signature) -> ok;
		      (OtherKey) ->
			  mk_type_error({extraneous_key, OtherKey}, M, Path)
		  end,
		  maps:keys(M)),
    ok;
v_msg_Signed(M, Path, _TrUserData) when is_map(M) ->
    mk_type_error({missing_fields,
		   [payload] -- maps:keys(M), 'Signed'},
		  M, Path);
v_msg_Signed(X, Path, _TrUserData) ->
    mk_type_error({expected_msg, 'Signed'}, X, Path).

-compile({nowarn_unused_function,v_type_bytes/3}).
v_type_bytes(B, _Path, _TrUserData) when is_binary(B) ->
    ok;
v_type_bytes(B, _Path, _TrUserData) when is_list(B) ->
    ok;
v_type_bytes(X, Path, _TrUserData) ->
    mk_type_error(bad_binary_value, X, Path).

-compile({nowarn_unused_function,mk_type_error/3}).
-spec mk_type_error(_, _, list()) -> no_return().
mk_type_error(Error, ValueSeen, Path) ->
    Path2 = prettify_path(Path),
    erlang:error({gpb_type_error,
		  {Error, [{value, ValueSeen}, {path, Path2}]}}).


-compile({nowarn_unused_function,prettify_path/1}).
prettify_path([]) -> top_level;
prettify_path(PathR) ->
    list_to_atom(string:join(lists:map(fun atom_to_list/1,
				       lists:reverse(PathR)),
			     ".")).


-compile({nowarn_unused_function,id/2}).
-compile({inline,id/2}).
id(X, _TrUserData) -> X.

-compile({nowarn_unused_function,v_ok/3}).
-compile({inline,v_ok/3}).
v_ok(_Value, _Path, _TrUserData) -> ok.

-compile({nowarn_unused_function,m_overwrite/3}).
-compile({inline,m_overwrite/3}).
m_overwrite(_Prev, New, _TrUserData) -> New.

-compile({nowarn_unused_function,cons/3}).
-compile({inline,cons/3}).
cons(Elem, Acc, _TrUserData) -> [Elem | Acc].

-compile({nowarn_unused_function,lists_reverse/2}).
-compile({inline,lists_reverse/2}).
'lists_reverse'(L, _TrUserData) -> lists:reverse(L).
-compile({nowarn_unused_function,'erlang_++'/3}).
-compile({inline,'erlang_++'/3}).
'erlang_++'(A, B, _TrUserData) -> A ++ B.

get_msg_defs() ->
    [{{msg, 'Signed'},
      [#{name => payload, fnum => 1, rnum => 2, type => bytes,
	 occurrence => required, opts => []},
       #{name => signature, fnum => 2, rnum => 3,
	 type => bytes, occurrence => optional, opts => []}]}].


get_msg_names() -> ['Signed'].


get_group_names() -> [].


get_msg_or_group_names() -> ['Signed'].


get_enum_names() -> [].


fetch_msg_def(MsgName) ->
    case find_msg_def(MsgName) of
      Fs when is_list(Fs) -> Fs;
      error -> erlang:error({no_such_msg, MsgName})
    end.


-spec fetch_enum_def(_) -> no_return().
fetch_enum_def(EnumName) ->
    erlang:error({no_such_enum, EnumName}).


find_msg_def('Signed') ->
    [#{name => payload, fnum => 1, rnum => 2, type => bytes,
       occurrence => required, opts => []},
     #{name => signature, fnum => 2, rnum => 3,
       type => bytes, occurrence => optional, opts => []}];
find_msg_def(_) -> error.


find_enum_def(_) -> error.


-spec enum_symbol_by_value(_, _) -> no_return().
enum_symbol_by_value(E, V) ->
    erlang:error({no_enum_defs, E, V}).


-spec enum_value_by_symbol(_, _) -> no_return().
enum_value_by_symbol(E, V) ->
    erlang:error({no_enum_defs, E, V}).



get_service_names() -> [].


get_service_def(_) -> error.


get_rpc_names(_) -> error.


find_rpc_def(_, _) -> error.



-spec fetch_rpc_def(_, _) -> no_return().
fetch_rpc_def(ServiceName, RpcName) ->
    erlang:error({no_such_rpc, ServiceName, RpcName}).


get_package_name() -> undefined.



gpb_version_as_string() ->
    "4.3.1".

gpb_version_as_list() ->
    [4,3,1].
