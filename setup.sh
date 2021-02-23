#!/bin/sh

echo "To run mongoDB we use docker, this is however not needed if you want your own setup"
if brew ls --versions openssl > /dev/null; then 
     echo "Brew is used to install apps. Check out the setup.sh if you want to do it manually"
     return 1;
fi

if brew ls --versions openssl > /dev/null; then
     echo "Openssl is installed!"
else
     echo "Installing Openssl..."
     brew install openssl
fi

if brew ls --versions swiftlint > /dev/null; then
     echo "Swiftlint is installed!"
else
     echo "Installing Swiftlint..."
     brew install swiftlint
fi

if brew ls --versions protobuf > /dev/null; then
     echo "Protobuf is installed!"
else
     echo "Installing Protobuf..."
     brew install protobuf
fi

if [[ -f ./Dela_App/protoc-gen-grpc-swift ]] && [[ -f ./Dela_App/protoc-gen-swift ]]; then 
     echo "Protoc generator files exists"
else
     echo "Building Protoc generator files..."
     git clone https://github.com/grpc/grpc-swift.git temp-swift-grpc
     cd temp-swift-grpc
     make plugins
     cp protoc-gen-swift protoc-gen-grpc-swift ../Dela_App
     cd ..
     rm -rf temp-swift-grpc
fi

mkdir -p ./Dela_App/Shared/GenGrpcClient

cd ./Dela_App
mkdir -p Shared/Lib/GenGrpcClient
sh ./Scripts/generateproto.sh
cd ..

if [[ -f ./Dela_App/local.xcconfig ]]; then 
     echo "Settings file local.xcconfig exists"
else    
     echo 'API_URL = <ADDRESS>\nAPI_PORT = 50051' > ./Dela_App/local.xcconfig
     echo "Be sure to check out the local.xcconfig file"
fi 

if [[ -f ./Dela_Backend/.env ]]; then 
     echo "The backend .env exists"
else
     echo "Be sure to check out the backend .env file"
     mkdir -p ./Dela_Backend/Upload
     echo 'TEST_JPEG=test_img.jpeg\nUPLOAD_PATH=Upload\nSERVER_ADDR=0.0.0.0:50051' > ./Dela_Backend/.env
fi

if [ ! -d "./Dela_Backend/certs" ]; then
    echo "Setting up self signed certificates"
    mkdir ./Dela_Backend/certs
    openssl req -x509 -newkey rsa:4096 -nodes -keyout ./Dela_Backend/certs/key.pem -out ./Dela_Backend/certs/cert.pem -days 365 -subj '/CN=localhost'
    openssl rsa -in ./Dela_Backend/certs/key.pem -out ./Dela_Backend/certs/nopass.pem
fi
