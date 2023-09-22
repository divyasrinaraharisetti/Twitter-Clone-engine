-module(twitter).
-export([server/3, startServer/0]).

startServer() ->
    spawn(twitter, server, [#{}, #{}, #{}]).

server(MapUsernameProfile, MapHashtag, MapMentions) ->
    receive
        {update, Username, Profile} ->
            server(maps:put(Username, Profile, MapUsernameProfile),
                   MapHashtag,
                   MapMentions);
        {update_mention_mapping, String, Tweet} ->
            Boolean = maps:is_key(String, MapMentions),
            if Boolean ->
                   List = maps:get(String, MapMentions),
                   Map = maps:put(String, lists:append(List, [Tweet]), MapMentions),
                   server(MapUsernameProfile, MapHashtag, Map);
               true ->
                   Map = maps:put(String, [Tweet], MapMentions),
                   server(MapUsernameProfile, MapHashtag, Map)
            end;
        {update_hashtag_mapping, String, Tweet} ->
            Boolean = maps:is_key(String, MapHashtag),
            if Boolean ->
                   List = maps:get(String, MapHashtag),
                   Map = maps:put(String, lists:append(List, [Tweet]), MapHashtag),
                   server(MapUsernameProfile, Map, MapMentions);
               true ->
                   Map = maps:put(String, [Tweet], MapHashtag),
                   server(MapUsernameProfile, Map, MapMentions)
            end;
        {add_profile, Username, Profile,UserId} ->
            Map = maps:put(Username, Profile, MapUsernameProfile),
            io:fwrite("fmdslfds ~n"),
            UserId ! {ok, "Profile Added"},
            server(Map, MapHashtag, MapMentions);
        {add_profile, Username, Profile} ->
                Map = maps:put(Username, Profile, MapUsernameProfile),
                server(Map, MapHashtag, MapMentions);
        {subscribe, FirstUsername, SecondUsername,UserId} ->
            Profile1 = maps:get(FirstUsername, MapUsernameProfile),
            Profile2 = maps:get(SecondUsername, MapUsernameProfile),
            ProcessId1 = maps:get("id", Profile1),
            ProcessId2 = maps:get("id", Profile2),
            ProcessId1 ! {subscribed_to, SecondUsername,UserId},
            ProcessId2 ! {subscribe, FirstUsername,UserId},
            server(MapUsernameProfile, MapHashtag, MapMentions);

        {search_by_subscribe,FirstUsername,SecondUsername,UserId}->
            Profile1 = maps:get(FirstUsername, MapUsernameProfile),
            Profile2 = maps:get(SecondUsername, MapUsernameProfile),
            Boolean = lists:any(fun(E)->E == SecondUsername end, maps:get("subscribed",Profile1)),
            if Boolean->
                UserId ! {ok,maps:get("tweets",Profile2)};
                true->
                    UserId ! {error}
            end,
            server(MapUsernameProfile, MapHashtag, MapMentions);

        {search_by_hashtag, Username, Hashtag,UserId} ->
            Profile = maps:get(Username, MapUsernameProfile),
            Pid = maps:get("id", Profile),
            Boolean = maps:is_key(Hashtag, MapHashtag),
            if Boolean ->
                   Pid ! {search_by_hashtag, Hashtag, maps:get(Hashtag, MapHashtag),UserId};
               true ->
                   Pid ! {search_by_hashtag, Hashtag, [],UserId}
            end,
            server(MapUsernameProfile, MapHashtag, MapMentions);
        {search_by_mention, Username, Mention,UserId} ->
            Profile = maps:get(Username, MapUsernameProfile),
            Pid = maps:get("id", Profile),
            Boolean = maps:is_key(Mention, MapMentions),
            if Boolean ->
                   Pid ! {search_by_mention, Mention, maps:get(Mention, MapMentions),UserId};
               true ->
                   Pid ! {search_by_mention, Mention, [],UserId}
            end,
            server(MapUsernameProfile, MapHashtag, MapMentions);
        {add_tweet_to_feed, Username, Tweet} ->
            Boolean = lists:any(fun(E) -> E == Username end, maps:keys(MapUsernameProfile)),
            if Boolean ->
                   Profile = maps:get(Username, MapUsernameProfile),
                   Pid = maps:get("id", Profile),
                   Pid ! {feed, Tweet},
                   server(MapUsernameProfile, MapHashtag, MapMentions);
               true ->
                   server(MapUsernameProfile, MapHashtag, MapMentions)
            end;
        {retweet, Username, Tweet, UserId} ->
            Profile = maps:get(Username, MapUsernameProfile),
            Pid = maps:get("id", Profile),
            Predicate = fun(E) -> E == Tweet end,
            A = lists:any(Predicate, maps:get("feed", Profile)),
            if A == true ->
                   Pid ! {tweet, Tweet, UserId};
               true ->
                   ok
            end,
            server(MapUsernameProfile, MapHashtag, MapMentions);
        {tweet, Username, Tweet, UserId} ->
            Profile = maps:get(Username, MapUsernameProfile),
            Pid = maps:get("id", Profile),
            Pid ! {tweet, Tweet,UserId},
            server(MapUsernameProfile, MapHashtag, MapMentions);

        {update_handler, Username,Id}->
            Profile = maps:get(Username, MapUsernameProfile),
            Pid = maps:get("id", Profile),
            Pid ! {update_handler,Id},
            server(MapUsernameProfile, MapHashtag, MapMentions);

        {get_feed,Username, UserId}->
            Profile = maps:get(Username, MapUsernameProfile),
            Feed = maps:get("feed",Profile),
            UserId ! {ok,Feed},
            server(MapUsernameProfile, MapHashtag, MapMentions)
    end.
