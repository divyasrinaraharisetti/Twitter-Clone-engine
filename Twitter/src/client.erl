-module(client).
-export([tweet/3, registerUser/4, sendRetweet/3, subscribeOtherUser/3, hashtagSearch/3,
         mentionSearch/3, messageHandler/1, feedRetrieve/2, subscribeSearch/3, updateHandler/3]).

tweet(Username, Tweet, ServerId) ->
    ServerId ! {tweet, Username, Tweet, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

subscribeOtherUser(FistUsername, SecondUsername, ServerId) ->
    ServerId ! {subscribe, FistUsername, SecondUsername, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

sendRetweet(Username, Tweet, ServerId) ->
    ServerId ! {retweet, Username, Tweet, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

subscribeSearch(FirstUsername, SecondUsername, ServerId) ->
    ServerId ! {search_by_subscribe, FirstUsername, SecondUsername, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

messageHandler(CurrentProfile) ->
    ProfileMapSize = maps:size(CurrentProfile),
    if ProfileMapSize > 0 ->
           maps:get("server", CurrentProfile)
           ! {add_profile, maps:get("username", CurrentProfile), CurrentProfile};
       true ->
           ok
    end,
    receive
        {subscribe, OtherUserProfile, UserId} ->
            CurrentProfileSubscription = maps:get("subscriptions", CurrentProfile),
            NewProfileSubscription = lists:append([OtherUserProfile], CurrentProfileSubscription),
            UpdatedProfile = maps:put("subscriptions", NewProfileSubscription, CurrentProfile),
            UserId ! {ok, ""},
            messageHandler(UpdatedProfile);
        {subscribed_to, SecondUsername2, UserId} ->
            CurrentProfileSubscription = maps:get("subscribed", CurrentProfile),
            NewProfileSubscription = lists:append([SecondUsername2], CurrentProfileSubscription),
            UpdatedProfile = maps:put("subscribed", NewProfileSubscription, CurrentProfile),
            UserId ! {ok, ""},
            messageHandler(UpdatedProfile);
        {feed, TweetList} ->
            HandlerId = maps:get("handler", CurrentProfile),
            HandlerId ! {ok, TweetList},
            Feed = maps:get("feed", CurrentProfile),
            NewlyAddedTweets = lists:append(Feed, [TweetList]),
            UpdatedProfile = maps:put("feed", NewlyAddedTweets, CurrentProfile),
            messageHandler(UpdatedProfile);
        {search_by_hashtag, _Hashtag, ListOfTweets, UserId} ->
            UserId ! {ok, ListOfTweets},
            messageHandler(CurrentProfile);
        {search_by_mention, _Mention, ListOfTweets, UserId} ->
            UserId ! {ok, ListOfTweets},
            messageHandler(CurrentProfile);
        {tweet, TweetList, UserId} ->
            SplitedTweet = string:split(TweetList, " ", all),
            helper:extractHashtagsFromTweet(SplitedTweet,
                                               1,
                                               maps:get("server", CurrentProfile),
                                               TweetList),
            Mentions =
                helper:extractMentionsFromTweet(SplitedTweet,
                                                   1,
                                                   maps:get("server", CurrentProfile),
                                                   [],
                                                   TweetList),
            ListOfTweets = maps:get("tweets", CurrentProfile),
            NewlyAddedTweets = lists:append(ListOfTweets, [TweetList]),
            UpdatedProfile = maps:put("tweets", NewlyAddedTweets, CurrentProfile),
            ListOfMentionsAndSubscriptions =
                lists:append(Mentions, maps:get("subscriptions", CurrentProfile)),
            CurrentUsernameAndListofMentionsSubscriptions =
                ListOfMentionsAndSubscriptions ++ [maps:get("username", CurrentProfile)],
            helper:tweetToSubscribers(CurrentUsernameAndListofMentionsSubscriptions,
                                                      1,
                                                      TweetList,
                                                      maps:get("server", CurrentProfile)),
            UserId ! {ok, ""},
            messageHandler(UpdatedProfile);
        {update_handler, Id} ->
            NewProfile = maps:put("handler", Id, CurrentProfile),
            messageHandler(NewProfile);
        {start, Profile} ->
            messageHandler(Profile)
    end.

hashtagSearch(Username, Hashtag, ServerId) ->
    ServerId ! {search_by_hashtag, Username, Hashtag, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

mentionSearch(Username, Hashtag, ServerId) ->
    ServerId ! {search_by_mention, Username, Hashtag, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

feedRetrieve(Username, ServerId) ->
    ServerId ! {get_feed, Username, self()},
    receive
        {ok, ReplyString} ->
            ReplyString
    end.

updateHandler(Username, ProfileId, ServerId) ->
    ServerId ! {update_handler, Username, ProfileId}.

registerUser(Username, Password, Email, ServerId) ->
    Pid = spawn(client, messageHandler, [#{}]),
    Profile = #{"server" => ServerId},
    CurrentProfileUsername = maps:put("username", Username, Profile),
    CurrentProfilePassword = maps:put("password", Password, CurrentProfileUsername),
    CurrentProfileEmail = maps:put("email", Email, CurrentProfilePassword),
    CurrentProfileTweetList = maps:put("tweets", [], CurrentProfileEmail),
    CurrentProfileSubscription = maps:put("subscriptions", [], CurrentProfileTweetList),
    CurrentProfileFeed = maps:put("feed", [], CurrentProfileSubscription),
    CurrentProfileHandler = maps:put("handler", "", CurrentProfileFeed),
    CurrentProfileSub = maps:put("subscribed", [], CurrentProfileHandler),
    CurrentProfileId = maps:put("id", Pid, CurrentProfileSub),
    Pid ! {start, CurrentProfileId},
    ServerId ! {add_profile, Username, CurrentProfileId, self()},
    receive
        {ok, ReplyString} ->
            ReplyString;
        {error} ->
            []
    end.
