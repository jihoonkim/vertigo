# update dependant packages
apt-get update -y

# install dependent packages 
apt-get install -y git iputils-ping netcat net-tools \
                   software-properties-common vim wget zip

# update the repository source list before instaling Julia
add-apt-repository -y ppa:staticfloat/juliareleases
add-apt-repository -y ppa:staticfloat/julia-deps

# update dependant packages
apt-get update -y

# install Julia 
apt-get install -y julia
