include("VERTIGOServer.jl")
@everywhere global socks_list_data = Dict{Any,Any}("socks"=>[],
                                                   "client_iter"=>[],
                                                   "username"=>cell(0),
                                                   "numSample"=>[],
                                                   "KernelData"=>cell(0),
                                                   "E"=>cell(0),
                                                   "Wglobal"=>cell(0),
                                                   "isOffline"=>falses(0),
                                                   "isReceived"=>falses(0));
@everywhere global srvsock_data

@everywhere function newDataListener(NETWORK)
  global srvsock_data;

  srvsock_data = listen(NETWORK["dataPort"]);
#  println("New Data listener is ready..");
end

@everywhere function initSocks(DB)
  global socks_list_data;

  socks_list_data["KernelData"] = cell(size(DB["users"],1));
  socks_list_data["E"] = cell(size(DB["users"],1));
  socks_list_data["Wglobal"] = cell(size(DB["users"],1));
#  println("socks initialized");
end

@everywhere function handleIncomingMessageFromClient(result, MSG_CODEBOOK, TIMEOUT, DB)
  global socks_list_data;
  msg_res=[];
  msgout=[];

  isClientsReceived = (sum(socks_list_data["isReceived"])==result["num_sites"] && result["iter"]>0 && DB["isActive"]);
  for i = 1: length(socks_list_data["socks"])
    if (!socks_list_data["isReceived"][i]) || (isClientsReceived && !result["clientCount"][i])
#      println("ready for socks ", i);
      msg = deserialize(socks_list_data["socks"][i]);
      socks_list_data["isReceived"][i] = true;
    else
      msg = -1;
    end
    if msg != -1
      if msg["tag"] == MSG_CODEBOOK["confirm_new_client"]
        socks_list_data["username"][i] = msg["username"];
        if !(msg["username"] == "UCSD_SHUTDOWN")
          socks_list_data["KernelData"][i] = msg["KernelData"];
          m = size(msg["KernelData"],1);
          result["m"] = m;
          result["Y"] = msg["Y"];
        end
        println("    >>>>New user: ", msg["username"], " ( count: ", length(socks_list_data["username"]),", confirmed at ", msg["datatime"], " from socket: ", i);
        # modified from newDataListener
        msgout=Dict{Any,Any}("tag"=>MSG_CODEBOOK["confirm_online_clientFromDatalistener"],"username"=> msg["username"], "ID"=> i);
      elseif msg["tag"]== MSG_CODEBOOK["receiveClient2ServerData"]
        if result["iter"] == msg["iter"]
#          println("message received from client ", socks_list_data["username"][i]);
          result["clientCount"][i] = true;
          socks_list_data["E"][i] = msg["E"];
          socks_list_data["Wglobal"][i] = msg["Wglobal"];
        else
          println("Error: iter mismath sev: ", result["iter"], " <> clt: ",msg["iter"]," when message received from client ", socks_list_data["username"][i]);
        end
      else
        println("error: Unknown incoming message detected from user ", socks_list_data["username"][i]);
      end
    end
  end
  if !isempty(socks_list_data["username"]) && (sum(true .== result["clientCount"]) == length(socks_list_data["username"]))
    msg_res = Dict{Any,Any}("tag"=>MSG_CODEBOOK["updateCalculation"]);
    result["clientCount"] = falses(result["num_sites"]);
#    println("all incoming messages has been collected from clients");
  end

  return result, msg_res, msgout
end

@everywhere function add_socket_list(msg, old_socks_size, TIMEOUT, MSG_CODEBOOK)
  global srvsock_data;
  global socks_list_data;
  msgout = [];
  socks_list_length = msg["length"];

  if old_socks_size - socks_list_length != -1
    println(2, "There is an error between data and client listeners");
    msgout=Dict{Any,Any}("tag"=>MSG_CODEBOOK["confirm_online_clientFromDatalistener"], "username"=>[], "ID"=>socks_list_length);
  else
    tmp_sock = accept(srvsock_data);
    serialize(tmp_sock, MSG_CODEBOOK);
    println("    >>>>a new client (not confirmed) has been received by newDataListener: ", old_socks_size+1);
    old_socks_size = old_socks_size + 1;
    socks_list_data["socks"] = vcat(socks_list_data["socks"],tmp_sock);
    socks_list_data["username"] = vcat(socks_list_data["username"], cell(1));
    socks_list_data["isReceived"] = vcat(socks_list_data["isReceived"],false);
  end

  return old_socks_size, msgout;
end

@everywhere function  updateAllSites(msg, msgminus1, result, MSG_CODEBOOK, TIMEOUT, DB)
  global socks_list_data;

#  println("updateAllSites data username: ", socks_list_data["username"]);
  if haskey(msg,"DB") && !isvalidUsers(socks_list_data, msg, DB)
    println("error: One or more users are not ready for update");
    msgout = -1;
  else
    if result["iter"] == 0
      println("initialize for all sites");
      result = initVERTIGO(result, msg);
    else
      println("update all sites");
      result = VERTIGOServer(result,socks_list_data);
    end
    result["iter"] = result["iter"] + 1;
    result, msgout= sendoutMessage(msgminus1, result, socks_list_data, MSG_CODEBOOK, TIMEOUT);
  end

  return result, msgout
end

@everywhere function checkConverge(result)
  res = true;
  dist1 = maximum(abs(result["posterior_new_mw"]-result["incoming_mw_old"]));

  if(dist1 > 1e-7)
    res = false;
    return res;
  end

  return res;
end

@everywhere function  sendoutMessage(msgminus1, result, socks_list_data, MSG_CODEBOOK, TIMEOUT)
  msgout=Dict{Any,Any}("tag"=>MSG_CODEBOOK["sendNewData"]);

  if msgminus1 == -1
    println("client is not ready for accepting message");
    # send message to client listener.
    msgout["tag"]=MSG_CODEBOOK["updateCalculation_Fail"];
    return result, msgout;
  end
  for i = 1: length(socks_list_data["username"])
    # send updated result back to clients
    a = Dict{Any,Any}("tag"=>MSG_CODEBOOK["getNewData"],
                      "iter"=>result["iter"],
                      "mw"=>result["posterior_new_mw"],
                      "lambda"=>result["lambda"]);
    res = serialize(socks_list_data["socks"][i], a);
    if res == -1
      println("Cannot send message to user : ", socks_list_data["username"][i]);
#    else
#      println("Message has been sent to user : ", socks_list_data["username"][i]);
    end
  end
  println("Send results to clients");
  # send message to client listener.
  if checkConverge(result)
    result["jobDone"] = true;
    msgout=Dict{Any,Any}("tag"=>MSG_CODEBOOK["updateCalculation_Done"], "iter"=>result["iter"]);
  end

  return result, msgout
end

@everywhere function isvalidUsers(socks_list_data, msg, DB)
  res = false;

  if !DB["isActive"]
    println("Detect: DB is inActive");
    return res;
  end
  for i = 1: length(socks_list_data["socks"])
    aa = getUserIDByName(socks_list_data["username"][i], DB);
    pos = find((aa.== DB["jobs"][:,2]) .== true);
    if (length(pos) != 1) || (!DB["jobs"][pos,3][1])
      println("Detect: inActive user <$pos>");
      return res
    end
  end
  res = true;
  return res
end

@everywhere function getUserIDByName(username, DB)
  userID = cell(0);
  pos1 = find((username.== (DB["users"][:, 2])) .== true); # 2 is for username

  if !isempty(pos1)
        userID = DB["users"][pos1, 1];
    end
  return userID
end

@everywhere function  remove_socks_list(offline_idx, MSG_CODEBOOK)
  global socks_list_data;

  if !isempty(offline_idx) && max(offline_idx) <= length(socks_list_data["socks"]);
    println("The following clients have been offline: ", socks_list_data["socks"](offline_idx));
    for i = 1: length(offline_idx)
      closeRemoteSocket(socks_list_data["socks"][offline_idx[i]],  MSG_CODEBOOK);
    end
    socks_list_data["socks"][offline_idx] = [];
  end
  old_socks_size = length(socks_list_data["socks"]);

  return old_socks_size
end

@everywhere function closeServerData(ServerName, MSG_CODEBOOK)
  global srvsock_data;
  global socks_list_data;
  num_users = length(socks_list_data["socks"]);

  for i = 1:num_users
    closeRemoteSocket(socks_list_data["socks"][i],  MSG_CODEBOOK);
  end
  close(srvsock_data);
  println(ServerName, " Server socket data closed at ",now());
  println(num_users, " clients has been disconnected from ", ServerName);
end

@everywhere function closeRemoteSocketData(sock,  MSG_CODEBOOK)
  a=Dict{Any,Any}("tag"=> MSG_CODEBOOK["break"]);
  res = serialize(sock, a);

  if res != -1
    println("send shutdown signal to ", sock);
  else
    println("fail to send shutdown signal to ", sock);
  end
  close(sock);

  return res
end
