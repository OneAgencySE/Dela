# Build

During build there's a bash script running that generates the content of `/Dela_App/Shared/GenGrpcClient/[name].swift`, this is the gRPC dependencies that comes from the `/Proto` files. 

The script can be found in in xCode `Dela -> Build Phases -> Run Script`.