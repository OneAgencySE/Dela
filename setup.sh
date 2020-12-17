#!/bin/sh

brew install protobuf
git clone https://github.com/grpc/grpc-swift.git temp-swift-grpc
cd temp-swift-grpc
make plugins
cp protoc-gen-swift protoc-gen-grpc-swift ../Dela_App
cd ..
rm -rf temp-swift-grpc

mkdir ./Dela_App/Shared/GenGrpcClient
protoc helloworld.proto \
     --proto_path=./Proto \
     --swift_out=Visibility=Public:./Dela_App/Shared/GenGrpcClient \
     --grpc-swift_out=Visibility=Public,Client=true,Server=false:./Dela_App/Shared/GenGrpcClient \
     --plugin=./Dela_App/protoc-gen-grpc-swift \
     --plugin=./Dela_App/protoc-gen-swift