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

USER=Dict{Any,Any}("username"=>"UCSD001",
                   "password"=> "123456",
                   "taskID"=>"t001");

# get local data
# vars = matread("/home/wenrui/Downloads/data1.mat");
# beta1b = vars["beta1b"];
# X = vars["XTR"];
# Y = vars["YTR"];
# X = [1.53007251442410	-0.261163645776479	-0.457014640871583;
# -0.249024742513714	0.443421912904091	1.24244840639074;
# -1.06421341288933	0.391894209432449	-1.06670139898475;
# 1.60345729812004	-1.25067890682641	0.933728162671239;
# 1.23467914689078	-0.947960922331432	0.350321001356112;
# -0.229626450963181	-0.741106093940412	-0.0290057637087263;
# -1.50615970397972	-0.507817550278174	0.182452167505983;
# -0.444627816446985	-0.320575506600239	-1.56505601415073;
# -0.155941035724769	0.0124690413616180	-0.0845394798177242;
# 0.276068253931536	-3.02917734140415	1.60394635060288];
# Y = [-1;1;-1;1;1;1;-1;-1;1;-1];
# W = [0.331551473758145 0.115932730166927 0.850722357175564];

# X = [ER status (0 = ER-, 1= ER+), age at diagnosis, tumor size (mm)]
X = [0	40	12;
     1	51	26;
     1	80	24;
     1	74	20;
     1	41	33;
     1	57	22;
     0	68	6;
     0	93	29;
     1	40	21;
     0	71	24];
Y = [1;1;1;1;-1;-1;1;1;1;1];
W = [-0.345416402338104 0.161562655536072 -0.505713041110335];
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
