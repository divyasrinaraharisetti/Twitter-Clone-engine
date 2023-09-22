-module(helper).
-export([extractHashtagsFromTweet/4, extractMentionsFromTweet/5,
         tweetToSubscribers/4,getTimestamp/0,getProfileId/0]).
extractHashtagsFromTweet(SplitedTweet, Index, ServerId, Tweet) ->
    if Index > length(SplitedTweet) ->
           ok;
       true ->
           ExtractedString = lists:nth(Index, SplitedTweet),
           HashSymbol = string:equal("#", string:sub_string(ExtractedString, 1, 1)),
           if HashSymbol ->
                  ServerId ! {update_hashtag_mapping, ExtractedString, Tweet},
                  extractHashtagsFromTweet(SplitedTweet, Index + 1, ServerId, Tweet);
              true ->
                  extractHashtagsFromTweet(SplitedTweet, Index + 1, ServerId, Tweet)
           end
    end.
tweetToSubscribers(SubscriptionsList, Index, Tweet, ServerId) ->
    if Index > length(SubscriptionsList) ->
           ok;
       true ->
           ServerId ! {add_tweet_to_feed, lists:nth(Index, SubscriptionsList), Tweet},
           tweetToSubscribers(SubscriptionsList,Index+1,Tweet,ServerId)
    end.
extractMentionsFromTweet(SplitedTweet, Index, ServerId, List, TweetList) ->
    if Index > length(SplitedTweet) ->
           List;
       true ->
           ExtractedString = lists:nth(Index, SplitedTweet),
           AtSymbol = string:equal("@", string:sub_string(ExtractedString, 1, 1)),
           if AtSymbol ->
                  ServerId ! {update_mention_mapping, ExtractedString, TweetList},
                  NewList = lists:append(List, [string:sub_string(ExtractedString, 2)]),
                  extractMentionsFromTweet(SplitedTweet, Index + 1, ServerId, NewList, TweetList);
              true ->
                  extractMentionsFromTweet(SplitedTweet, Index + 1, ServerId, List, TweetList)
           end
    end.
getTimestamp() ->
  {MegaSecond, Second, MicroSecond} = os:timestamp(),
  (MegaSecond*1000000 + Second)*1000 + (MicroSecond/1000).

getProfileId()->
	{ok, Fd} = file:open("server.txt", [read]), 
	{ok,A} = file:read(Fd, 1024),
	file:close(Fd),
	list_to_pid(A).