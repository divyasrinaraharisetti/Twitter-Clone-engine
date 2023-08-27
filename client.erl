-module(client).
-export[start/0, get_and_parse_user_input/2, loop/1].

start() ->
    io:fwrite("\nHello, New Client!\n"),
    PortNumber = 1204,
    IPAddress = "localhost",
    {ok, Sock} = gen_tcp:connect(IPAddress, PortNumber, [binary, {packet, 0}]),
    io:fwrite("\n Request sent to the Server\n"),
    spawn(client, get_and_parse_user_input, [Sock, "_"]),
    loop(Sock).

loop(Sock) ->
    receive
        {tcp, Sock, Data} ->
            io:fwrite("Received message from server\n"),
            io:fwrite(Data),
            loop(Sock);
        {tcp, closed, Sock} ->  
            io:fwrite("Client Cant connect anymore - TCP Closed")
        end.

get_and_parse_user_input(Sock, UserName) ->
    {ok, [CommandType]} = io:fread("\nEnter the command: ", "~s\n"),
    io:fwrite(CommandType),
    if 
        CommandType == "register" ->
            UserName1 = register_account(Sock);
        CommandType == "tweet" ->
            if
                UserName == "_" ->
                    io:fwrite("Register first!\n"),
                    UserName1 = get_and_parse_user_input(Sock, UserName);
                true ->
                    send_tweet(Sock,UserName),
                    UserName1 = UserName
            end;
        CommandType == "retweet" ->
            if
                UserName == "_" ->
                    io:fwrite("Register first!\n"),
                    UserName1 = get_and_parse_user_input(Sock, UserName);
                true ->
                    re_tweet(Sock, UserName),
                    UserName1 = UserName
            end;
        CommandType == "subscribe" ->
            if
                UserName == "_" ->
                    io:fwrite("Register first!\n"),
                    UserName1 = get_and_parse_user_input(Sock, UserName);
                true ->
                    subscribe_to_user(Sock, UserName),
                    UserName1 = UserName
            end;
        CommandType == "query" ->
            if
                UserName == "_" ->
                    io:fwrite("Register first!\n"),
                    UserName1 = get_and_parse_user_input(Sock, UserName);
                true ->
                    query_tweet(Sock, UserName),
                    UserName1 = UserName
            end;
        CommandType == "logout" ->
            if
                UserName == "_" ->
                    io:fwrite("Register first!\n"),
                    UserName1 = get_and_parse_user_input(Sock, UserName);
                true ->
                    UserName1 = "_"
            end;
        CommandType == "login" ->
            UserName1 = signin_account();
        true ->
            io:fwrite("Please try a different command!\n"),
            UserName1 = get_and_parse_user_input(Sock, UserName)
    end,
    get_and_parse_user_input(Sock, UserName1).


register_account(Sock) ->
    % Input user-name
    {ok, [UserName]} = io:fread("\nPlease Enter the User Name: ", "~s\n"),
    % send the server request
    io:format("SELF: ~p\n", [self()]),
    ok = gen_tcp:send(Sock, [["register", ",", UserName, ",", pid_to_list(self())]]),
    io:fwrite("\n Hi, Your Account has been Successfully Registered! \n"),
    UserName.

signin_account() ->
    % Input user-name
    {ok, [UserName]} = io:fread("\nPlease Enter the User Name: ", "~s\n"),
    io:format("SELF: ~p\n", [self()]),
    io:fwrite("\n Signed in with an Account!\n"),
    UserName.

send_tweet(Sock,UserName) ->
    Tweet = io:get_line("\nLet's Tweet?:"),
    ok = gen_tcp:send(Sock, ["tweet", "," ,UserName, ",", Tweet]),
    io:fwrite("\nSuccess, Tweet has been Sent!\n").`

re_tweet(Socket, UserName) ->
    {ok, [Person_UserName]} = io:fread("\nEnter the User Name whose tweet you want to re-post: ", "~s\n"),
    ok = gen_tcp:send(Socket, ["query", "," ,UserName, ",",  "3", ",", Person_UserName]),
    Tweet = io:get_line("\nNow, Enter the Tweet you want to re-post: "),
    ok = gen_tcp:send(Socket, ["retweet", "," ,Person_UserName, ",", UserName,",",Tweet]),
    io:fwrite("\nRetweeted Successfully!\n").

subscribe_to_user(Sock, UserName) ->
    SubscribeUserName = io:get_line("\nTo which user you want to subscribe?:"),
    ok = gen_tcp:send(Sock, ["subscribe", "," ,UserName, ",", SubscribeUserName]),
    io:fwrite("\nHey you've Subscribed Successfully!\n").

query_tweet(Sock, UserName) ->
    io:fwrite("\n These are the Querying Options below:\n"),
    io:fwrite("\n 1. Mentions\n"),
    io:fwrite("\n 2. Searchs of Hashtag\n"),
    io:fwrite("\n 3. User Tweets that are Subscribed\n"),
    {ok, [Option]} = io:fread("\nSpecify the task number you want to perform: ", "~s\n"),
    if
        Option == "1" ->
            ok = gen_tcp:send(Sock, ["query", "," ,UserName, ",", "1", ",", UserName]);
        Option == "2" ->
            {ok, [Hashtag]} = io:fread("\nSEnter the hahstag you want to search: ", "~s\n"),
            % Hashtag = io:get_line("\nEnter the hahstag you want to search: "),
            ok = gen_tcp:send(Sock, ["query", "," ,UserName, ",","2",",", Hashtag]);
        true ->
            {ok, [Sub_UserName]} = io:fread("\nWhose tweets do you want? ", "~s\n"),
            % Sub_UserName = io:get_line("\nWhose tweets do you want? "),
            ok = gen_tcp:send(Sock, ["query", "," ,UserName, ",", "3",",",Sub_UserName])
    end.

% subscribe <user_name>
% INPUT