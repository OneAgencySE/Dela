#!/bin/sh

echo "Installing needed depencencies..."
brew install protobuf
git clone https://github.com/grpc/grpc-swift.git temp-swift-grpc
cd temp-swift-grpc
make plugins
cp protoc-gen-swift protoc-gen-grpc-swift ../Dela_App
cd ..
rm -rf temp-swift-grpc

mkdir ./Dela_App/Shared/GenGrpcClient

echo "Genereating GRPC client...."
find ./Proto -iname "*.proto" -exec protoc {} \
     --proto_path=./Proto \
     --swift_out=Visibility=Public:./Dela_App/Shared/GenGrpcClient \
     --grpc-swift_out=Visibility=Public,Client=true,Server=false:./Dela_App/Shared/GenGrpcClient \
     --plugin=./Dela_App/protoc-gen-grpc-swift \
     --plugin=./Dela_App/protoc-gen-swift \;

echo "Be sure to check out the local.xcconfig file"
echo 'API_URL = <ADDRESS>' > ./Dela_App/local.xcconfig

echo "Be sure to check out the .env file"
echo 'TEST_JPEG=test_img.jpeg\nUPLOAD_PATH=Upload\SERVER_ADDR=0.0.0.0:50051' > ./Dela_Backend/.env
