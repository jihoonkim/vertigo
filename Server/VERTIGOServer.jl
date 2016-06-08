@everywhere function initVERTIGO(result, msg)
  num_features = msg["DB"]["currentTask"][1,4]+1;
  num_samples=result["m"];
  result["kernel"]=zeros(num_samples,num_samples);

  for i = 1: length(socks_list_data["username"])
    # YYYY compute kernel gram matrix
    result["kernel"]=result["kernel"]+socks_list_data["KernelData"][i];
    # YYYY socks_list_data.KernelData{i}
  end

  result["posterior_new_mw"] = ones(num_samples, 1) * 1e-4;
  result["incoming_mw_old"] = ones(num_samples, 1);
#  result["posterior_new_mw"] = ones(num_samples) * 1e-4;
#  result["incoming_mw_old"] = ones(num_samples);
  # YYYY Compute the first part of Hessian matrix for just one time at server
  result["HessianFirsterm"]=repmat(result["Y"],1,num_samples).*result["kernel"];
  result["HessianFirsterm"]=repmat(result["Y"]',num_samples,1).*result["HessianFirsterm"]/result["lambda"];
#  println("Initialization finished");
  return result;
end

@everywhere function VERTIGOServer(result,socks_list_data)
#  index=1: result["m"]+1 : result["m"]^2;

#  result["hessian"] = Hessian(result["posterior_new_mw"],result["HessianFirsterm"],index);
  result["hessian"] = result["HessianFirsterm"] + diagm(1./(result["posterior_new_mw"][:,1].*(1-result["posterior_new_mw"][:,1])));
  # save test result
  E1 = zeros(1,result["m"]);
  for i = 1:length(socks_list_data["username"])
    E1 = E1+socks_list_data["E"][i];
  end
  # compute in the server term2 of Eq.(10): log(a_i/(1-a_i))
#  p = zeros(1,result["m"]);
#  for i=1:result["m"]
#    p[1,i]=log(result["posterior_new_mw"][i,1]/(1-result["posterior_new_mw"][i,1]));
#  end
  p = log(result["posterior_new_mw"]./(1-result["posterior_new_mw"]));
  J1 = E1'+p;

  a2 = result["posterior_new_mw"]-result["hessian"]\J1;
  println("The absolute maximum of alpha-alpha_old (dual coefficients) is : ", maximum(abs(result["posterior_new_mw"]-a2)));
  # modify value in alpha to [0,1]
  a2[a2.<0]=1/(3^(result["iter"])+100);
  a2[a2.>1]=1-1/(3^(result["iter"])+100);

  result["incoming_mw_old"] = result["posterior_new_mw"];
  result["posterior_new_mw"] = a2;

  # check Wglobal with primal problem
  result["Wglobal"] = [];
  for i = 1: length(socks_list_data["username"])
    result["Wglobal"]=vcat(result["Wglobal"], socks_list_data["Wglobal"][i]');
  end
  Wglobal=result["Wglobal"];

  return result;
end
