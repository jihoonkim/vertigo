# Pkg.update();
# Pkg.add("MAT");
# using MAT;

TIMEOUT= Dict{Any,Any}("ACCEPT"=>0.1,
                       "ACCEPT_data"=>1,
                       "RECEIVE"=>0.01,
                       "RECEIVE_data"=>1,
                       "OFFLINE_CHECKPOINT"=>5,
                       "OFFLINE_THRESHOLD"=>30000,
                       "pending_Calc_Threshold"=>30,
                       "ONLINE_REPORT_TIMER"=>10000);

NETWORK=Dict{Any,Any}("server_IP"=>"132.239.245.154",
                      "msgPort"=>4001,
                      "dataPort"=>4002);

USER=Dict{Any,Any}("username"=>"UCSD002",
                   "password"=> "123456",
                   "taskID"=>"t001");

# get local data
# vars = matread("/Users/dbmi/Downloads/data2.mat");
# beta1b = vars["beta1b"];
# X = vars["XTR"];
# Y = vars["YTR"];
# X = [0.0983477746401080; 0.0413736134896147; -0.734169112696739; -0.0308137300123200; 0.232347012624477;0.426387557408945; -0.372808741723504; -0.236454583757186; 2.02369088660305;-2.25835397049619];
# Y = [-1;1;-1;1;1;1;-1;-1;1;-1];
# W = 1.104506931658992;

# X = [Lymph node status(0=LN-,1=LN+), DSS TIME (Disease-Specific Survival Time in years)]
X = [0	11.833;
     0	11.833;
     0	3.583;
     0	11.667;
     0	7.167;
     0	4.667;
     0	11.500;
     0	2.167;
     0	11.500;
     1	5.083];
Y = [1;1;1;1;-1;-1;1;1;1;1];
W = [0.0784144520632770 0.600400689036173];

LOCALDATA=Dict{Any,Any}("X"=>X,
                        "Y"=>Y,
                        "W"=>W);
# LOCALDATA["CovX"] = LOCALDATA["X"]'*LOCALDATA["X"];

## create matlab pool
if nprocs()<2
  addprocs(1)
end

include("newMSGListener.jl")
include("newJobListener.jl")

## start calculation
tic()
output = newMSGListener(TIMEOUT, NETWORK, USER, LOCALDATA);
toc()
println("The task is done!!!!!!");
