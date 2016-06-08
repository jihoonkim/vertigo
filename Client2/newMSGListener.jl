function newMSGListener(TIMEOUT, NETWORK, USER, LOCALDATA)
#  println("MSG try to connect to the server");
  println("Connecting to the server");
  sock_newMSGListener = connect(NETWORK["server_IP"],NETWORK["msgPort"]); # connect to newMSGListener
  if isopen(sock_newMSGListener)
    isMsgConnected = true;
#    println("Msg Listener is ready");
  else
    isMsgConnected = false;
  end
  isJobConnected = remotecall_fetch(2,newJobListener,NETWORK);
  if isMsgConnected && isJobConnected
#    println("ready to receive the MSG_CODEBOOK from Server via msg port!!:")
    MSG_CODEBOOK = deserialize(sock_newMSGListener); # get acknowledgments from newMSGListener;
#    println("Finished!!!")
#    println("ready to receive the CODEBOOK from Server via data port!!:")
    CODEBOOK = remotecall_fetch(2,receiveData);
#    println("Finished!!!")
    if !isempty(MSG_CODEBOOK) && !isempty(CODEBOOK)
      num_samples = size(LOCALDATA["X"],1);
      KernelData = LOCALDATA["X"]*LOCALDATA["X"]';
      Para=Dict{Any,Any}("tag"=>MSG_CODEBOOK["confirm_new_client"],
                         "datatime"=>now(),
                         "username"=>USER["username"],
                         "password"=>USER["password"],
                         "taskID"=>USER["taskID"],
                         "KernelData"=>KernelData,
                         "Y"=>LOCALDATA["Y"],
                         "num_samples"=>num_samples);
      serialize(sock_newMSGListener, Para);
      remotecall(2,sendData,Para);
#      println("connection between server @newJobListener has been established");
#      println("waiting for authorization from server");

      msg = deserialize(sock_newMSGListener);
      if msg["tag"] != -1
#        println("connection between server@newMSGListener has been established");
        println("connection to server has been established");
      else
        error(msg["msg"]);
      end
    else
      error("connection lost from newMSGListener\n");
      error("connection lost from newJobListener\n");
    end
  else
    error("Cannot connect to server@newMSGListener\n");
    error("Cannot connect to server@newJobListener\n");
  end

  closeClientFlag = false;
  result=Dict{Any,Any}("error"=>false, "iter"=>0);
  h = now();
  server_timeStamp = now();

  while !closeClientFlag
#    println("Receive msg from Msg Server: ", NETWORK["server_IP"], ":", NETWORK["msgPort"]);
    try
      msg = deserialize(sock_newMSGListener)
    catch
      break;
    end
#    msg = remotecall_fetch(2,receiveData);
#    println("msg is ", msg);
    if !isempty(msg)
      if msg["tag"] == MSG_CODEBOOK["break"]
        println("Get shutdown signal");
        msgdata = remotecall_fetch(2,receiveData);
        #break;
      elseif  msg["tag"] ==  MSG_CODEBOOK["getNewData"]
#        println("remote server requested to send data to here");
        result=remotecall_fetch(2, updateResults, CODEBOOK, result, LOCALDATA, NETWORK);
      elseif  msg["tag"] ==  MSG_CODEBOOK["confirm_online_client"]
        server_timeStamp = now();
      else
        println("Unknown message type received from server sock_newMSGListener");
        println("Unknown message type received from server sock_newJobListener");
      end
    end

    # report status to server.
    if TIMEOUT["ONLINE_REPORT_TIMER"] < Int64((now()-h))/1000########
      println("send confirm_online_client flag to ClientListener");
      msg=Dict{Any,Any}("tag"=>MSG_CODEBOOK["confirm_online_client"]);
      res = serialize(sock_newMSGListener, msg);
      if res == -1 || (TIMEOUT["OFFLINE_THRESHOLD"] < Int64((now()-server_timeStamp))/1000)  ########
        println("cannot connect to server");
        msg["tag"] = MSG_CODEBOOK["break"]
        println("close connection in Job");
        break
      end
      h = now();
    end
  end

  println("Coefficient is ", result["Wglobal"]);
  println("Difference between centralized modeling is ", result["Wglobal"]-LOCALDATA["W"]);
  close(sock_newMSGListener);
#  println("    >>>>newMSGListener has been distroyed");
  remotecall(2,closeJobListener);
#  println("    >>>>newJobListener has been distroyed");
  return result
end
