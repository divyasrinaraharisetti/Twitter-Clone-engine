-module(main_handler).
-behavior(cowboy_websocket).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2,tweet/2]).

init(Request, ProtocolState) ->
	{cowboy_websocket, Request, ProtocolState,#{idle_timeout => 30000}}.

websocket_init(ProtocolState) ->
	{[], ProtocolState}.
	
websocket_handle({text, Data}, ProtocolState) ->
	SplitString = string:split(binary_to_list(Data), "-",all),
	Event = lists:nth(1, SplitString),
	if
		Event == "update_handler"->
			ProfileId = helper:getProfileId(),
			client:updateHandler(lists:nth(2, SplitString),self(),ProfileId),
			String = list_to_binary(""),
			{[{text, <<String/binary>>}], ProtocolState};
		Event == "tweet"->
			tweet(lists:nth(2, SplitString), lists:nth(3, SplitString)),
			String = list_to_binary(""),
			{reply,{text,<<String/binary>>},ProtocolState};
		Event == "subscribe"->
			subscribe(lists:nth(2, SplitString), lists:nth(3, SplitString)),
			String = list_to_binary("update-Subscribed to "++lists:nth(3, SplitString)),
			{reply,{text,<<String/binary>>},ProtocolState};
		Event == "hashtag"->
			ResponseString = hashtag(lists:nth(2, SplitString), lists:nth(3, SplitString)),
			String = list_to_binary("search-"++ResponseString),
			{reply,{text,<<String/binary>>},ProtocolState};
		Event == "mention"->
			ResponseString = mention(lists:nth(2, SplitString), lists:nth(3, SplitString)),
			String = list_to_binary("search-"++ResponseString),
			{reply,{text,<<String/binary>>},ProtocolState};
		Event == "search"->
			ResponseString = searchTweet(lists:nth(2, SplitString), lists:nth(3, SplitString)),
			String = list_to_binary("search-"++ResponseString),
			{reply,{text,<<String/binary>>},ProtocolState};
		Event == "retweet"->
			retweet(lists:nth(2, SplitString), lists:nth(3, SplitString)),
			String = list_to_binary(""),
			{reply,{text,<<String/binary>>},ProtocolState};
		true->
			String = list_to_binary(""),
			{[{text, <<String/binary>>}], ProtocolState}
	end;

websocket_handle({binary, Data}, ProtocolState) ->
	{[{binary, Data}], ProtocolState};
websocket_handle(_Frame, ProtocolState) ->
	{[], ProtocolState}.

websocket_info(String, ProtocolState) ->
	Tweet = lists:nth(2, tuple_to_list(String)),
	NewString = list_to_binary(Tweet),
	{reply, {text, <<NewString/binary>>}, ProtocolState}.

convertListTweetToString(String,[])->
	String;
convertListTweetToString(String,List)->
	[H|T] = List,
	convertListTweetToString(String ++ H ++  "\n", T).
searchTweet(Username,Mention)->
	ProfileId = helper:getProfileId(),
	ResponseString = client:subscribeSearch(Username, Mention, ProfileId),
	UpdatedString = convertListTweetToString("", ResponseString),
	UpdatedString.
mention(Username,Mention)->
	ProfileId = helper:getProfileId(),
	ResponseString = client:mentionSearch(Username, Mention, ProfileId),
	UpdatedString = convertListTweetToString("", ResponseString),
	UpdatedString.
hashtag(Username,Hashtag)->
	ProfileId = helper:getProfileId(),
	ResponseString = client:hashtagSearch(Username, Hashtag, ProfileId),
	UpdatedString = convertListTweetToString("", ResponseString),
	UpdatedString.
tweet(Username,Tweet)->
	ProfileId = helper:getProfileId(),
	ResponseString = client:tweet(Username, Tweet, ProfileId),
	ResponseString.
retweet(Username,Tweet)->
	ProfileId = helper:getProfileId(),
	ResponseString = client:sendRetweet(Username, Tweet, ProfileId),
	ResponseString.
subscribe(FirstUsername,SecondUsername)->
	ProfileId = helper:getProfileId(),
	client:subscribeOtherUser(FirstUsername,SecondUsername, ProfileId),
	ok.
