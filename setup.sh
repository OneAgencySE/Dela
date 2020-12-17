#!/bin/sh

brew install protobuf
git clone https://github.com/grpc/grpc-swift.git temp-swift-grpc
cd temp-swift-grpc
make plugins
cp protoc-gen-swift protoc-gen-grpc-swift ../Dela.App
cd ..
rm -rf temp-swift-grpc

mkdir 
protoc helloworld.proto \
     --proto_path=./Proto \
     --swift_out=Visibility=Public:./Dela.App/Shared/GenGrpcClient \
     --grpc-swift_out=Visibility=Public,Client=true,Server=false:./Dela.App/Shared/GenGrpcClient \
     --plugin=./Dela.App/protoc-gen-grpc-swift