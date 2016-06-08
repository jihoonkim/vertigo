include("VERTIGOClient.jl")

@everywhere global sock_newJobListener

@everywhere function newJobListener(NETWORK)
  global sock_newJobListener;
  sock_newJobListener = connect(NETWORK["server_IP"],NETWORK["dataPort"]);
  if isopen(sock_newJobListener)
#    println("Job Listener is ready");
    return true;
  else
    return false;
  end
end

@everywhere function closeJobListener()
  global sock_newJobListener;
  close(sock_newJobListener);
end

@everywhere function receiveData()
  global sock_newJobListener;
  data = deserialize(sock_newJobListener);
  return data;
end

@everywhere function sendData(data)
  global sock_newJobListener;
  serialize(sock_newJobListener,data);
end

@everywhere function updateResults(CODEBOOK, result, LOCALDATA, NETWORK)
  global sock_newJobListener;

  result["error"] = false;
  resultFromServer = deserialize(sock_newJobListener);
  if isempty(resultFromServer)
    result["error"] = true;
    println("Error: cannot get message from server");
    return result;
  else
    if resultFromServer["tag"] != CODEBOOK["getNewData"];
      result["error"] = true;
      println("get unkonwn message");
      return result;
    end
    result["iter"] = resultFromServer["iter"];
    result["lambda"] = resultFromServer["lambda"];
    result["new_mw"] = resultFromServer["mw"];
#    println("Receive data from Data Server: ", NETWORK["server_IP"], ":", NETWORK["dataPort"]);
    println("start updating at iter : ",result["iter"]);
    result = VERTIGOSolverClient(result, LOCALDATA);
    #final result
#    aaa = Dict{Any,Any}("tag"=>CODEBOOK["receiveClient2ServerData"], "mw"=>result["mw"], "vw"=>result["vw"], "iter"=>result["iter"], "E"=>result["E"], "Wglobal"=>result["Wglobal"], "n"=>result["n"]);
    aaa = Dict{Any,Any}("tag"=>CODEBOOK["receiveClient2ServerData"], "iter"=>result["iter"], "E"=>result["E"], "Wglobal"=>result["Wglobal"], "n"=>result["n"]);
    res = serialize(sock_newJobListener, aaa);

    if res == -1
      println("fail to upload results to server");
#    else
#      println("Finish updating at iter : ",result["iter"]," and send results to ", NETWORK["server_IP"], ":", NETWORK["dataPort"]);
    end
  end
  return result
end
