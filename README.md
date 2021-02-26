# Dela

Dela - Swedish word for 'to split' or "to Share", and that's what is is. Let's share!

## Our goal

A iOS application written in `Swift` and `SwiftUI` that talks to a `Rust` based `gRPC` server with all the normal shenanigans!

What is it then?

It's a Instagram/Pintrest/Blog/Reddit app with A simple focus: To tell a story.

[Todo: Images, more text, links etc]

## Requirements:

### 😎 Be awsome! 🤓

No but seriously, you might need a Mac, `xcode` installed with `'Location -> Command line tools'` set.
You need `Homebrew` for the setup script, check it out if you want to opt-out of it. You'll need [Rust](https://www.rust-lang.org/tools/install) too.

### Setup - Do run it

Run the setup script to prepare xcode for running the backend project
It'll download and generate needed binaries that are not distrobuted by brew

Things it adds: protobuf + grpc-swift and it generates the client for initial setup

```bash
# chmod +x setup.sh
./setup
```

After running the setup, double check your `Dela_App -> local.xcconfig`

### Dev

After installing the requirements and you've run the setup script.

This is how you run the server from terminal:

```bash
cd Dela_Backend
docker-compose -f stack.yml up -d
cargo run
```

Docker is not needed, however it is convenient!
the stack.yml file sets up the backend dependencies. Have a look a t http://localhost:8081/ for the DB viewer.

If you want to develop the server, you'll know how 🥸

To run the app, use `xcode` and ... 🥸

#### Tips

Use `rust-analyzers` that you can find for vscode and other editors, it's awesome
