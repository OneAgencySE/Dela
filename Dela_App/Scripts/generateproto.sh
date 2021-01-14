#!/bin/sh

echo "Generating GRPC client...."
find ../Proto -iname "*.proto" -exec protoc {} \
     --proto_path=./../Proto \
     --swift_out=Visibility=Public:./Shared/Lib/GenGrpcClient \
     --grpc-swift_out=Visibility=Public,Client=true,Server=false:./Shared/Lib/GenGrpcClient \
     --plugin=./protoc-gen-grpc-swift \
     --plugin=./protoc-gen-swift \;
echo "Generating GRPC client completed"