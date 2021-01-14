#!/bin/sh

if brew ls --versions protobuf > /dev/null; then
     echo "protobuf is installed"
else
     echo "Installing needed depencencies..."
     brew install protobuf
fi

if [[ -f ./Dela_App/protoc-gen-grpc-swift ]] && [[ -f ./Dela_App/protoc-gen-swift ]]; then 
     echo "protoc generator files exists"
else
     echo "Installing protoc generator files..."
     git clone https://github.com/grpc/grpc-swift.git temp-swift-grpc
     cd temp-swift-grpc
     make plugins
     cp protoc-gen-swift protoc-gen-grpc-swift ../Dela_App
     cd ..
     rm -rf temp-swift-grpc
fi

mkdir -p ./Dela_App/Shared/GenGrpcClient

cd ./Dela_App
sh ./Scripts/generateproto.sh
cd ..

if [[ -f ./Dela_App/local.xcconfig ]]; then 
     echo "local.xcconfig exists"
else    
     echo 'API_URL = <ADDRESS>' > ./Dela_App/local.xcconfig
     echo "Be sure to check out the local.xcconfig file"
fi 

if [[ -f ./Dela_Backend/.env ]]; then 
     echo "backend .env exists"
else
     echo "Be sure to check out the .env file"
     echo 'TEST_JPEG=test_img.jpeg\nUPLOAD_PATH=Upload\nSERVER_ADDR=0.0.0.0:50051' > ./Dela_Backend/.env
fi

