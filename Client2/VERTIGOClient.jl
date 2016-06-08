@everywhere function VERTIGOSolverClient(result, LOCALDATA)
  m = size(LOCALDATA["X"],1);
  n = size(LOCALDATA["X"],2);
  E = zeros(1,m);
  w1 = zeros(1,n);
  for i = 1:m
    w1 = w1+result["new_mw"][i,1]*LOCALDATA["Y"][i]*LOCALDATA["X"][i,:];
  end
  w1 = w1/result["lambda"];
#   for i = 1:m
#     X1 = LOCALDATA["X"][i,:];
#     E[1,i] = LOCALDATA["Y"][i]*w1*X1';
#   end
  E = LOCALDATA["Y"]'.*(w1*LOCALDATA["X"]');

  result["E"] = E;
  result["n"] = n;
  if haskey(result,"Wglobal")
    result["Wglobal_old"] = result["Wglobal"];
  else
    result["Wglobal_old"] = zeros(1,n);
  end
  Wglobal=zeros(1,n);
  for i = 1:m
    Wglobal = Wglobal+result["new_mw"][i,1]*LOCALDATA["Y"][i]*LOCALDATA["X"][i,:];
  end
  Wglobal = Wglobal/result["lambda"];
  result["Wglobal"] = Wglobal;
 # println("Coefficient for current iteration is ", result["Wglobal"]);
 # println("Difference between the previous iteration is ", result["Wglobal"]-result["Wglobal_old"], "; MSE is ", norm(result["Wglobal"]-result["Wglobal_old"],2));
 # println("Difference between the coefficients led by centralized modeling is ", result["Wglobal"]-LOCALDATA["W"], "; MSE is ", norm(result["Wglobal"]-LOCALDATA["W"],2));
  @printf("Coefficient for current iteration is [ ");
  for i = 1:n
    @printf("%7.3e  ",result["Wglobal"][1,i]);
  end
  @printf("]\n");
  @printf("Difference between the previous iteration is [ ");
  for i = 1:n
    @printf("%7.3e  ",result["Wglobal"][1,i]-result["Wglobal_old"][1,i]);
  end
  @printf("]; MSE is %7.3e \n", norm(result["Wglobal"]-result["Wglobal_old"],2));
  @printf("Difference between the coefficients led by centralized modeling is [ ");
  for i = 1:n
    @printf("%7.3e  ", result["Wglobal"][1,i]-LOCALDATA["W"][i]);
  end
  @printf("]; MSE is %7.3e \n", norm(result["Wglobal"]-LOCALDATA["W"],2));
  return result;
end
