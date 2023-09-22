-module(twitterws_app).
-behaviour(application).
-import(twitter, [startServer/0]).
-import(client, []).
-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    Id = twitter:startServer(),
    {ok, Fd} = file:open("server.txt", [write]),
    file:write(Fd, pid_to_list(Id)),
    file:close(Fd),
    Dispatch =
        cowboy_router:compile([{'_',[
			{"/",cowboy_static,{file,"/Users/shriyansnidhish/Rahul/UF/Fall22/DOSP/Project4/part2/twitterws/static/new/register.html"}},
            {"/register", register_handler, []},
			{"/:name/main",cowboy_static,{file,"/Users/shriyansnidhish/Rahul/UF/Fall22/DOSP/Project4/part2/twitterws/static/new/main.html"}}
		]}]),

    DispatchWebSocket = cowboy_router:compile([{'_', [{"/", main_handler, []}]}]),
    {ok, _} =
        cowboy:start_clear(my_http_listener, [{port, 8083}], #{env => #{dispatch => Dispatch}}),
    {ok, _} = cowboy:start_clear(ws, [{port, 8889}], #{env => #{dispatch => DispatchWebSocket}}),
    twitterws_sup:start_link().

stop(_State) ->
    ok.
