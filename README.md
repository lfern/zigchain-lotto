# Contract example for mantra developer guide:
* https://metaschool.so/articles/build-on-mantra-chain-developer-guide
* https://github.com/0xmetaschool/building-on-MANTRA-chain

# More contracts
git clone <https://github.com/InterWasm/cw-contracts>
cd cw-contracts
git checkout main
cd contracts/nameservice

RUSTFLAGS='-C link-arg=-s' cargo wasm
This generates a file approximately 165kB in size. We can either use the command above or apply a different Rust optimizer—details of which will be covered in the optimized compilation section below—to produce the smallest possible wasm binary before uploading it to the blockchain.

Unit Tests
Let's try running the unit tests:
RUST_BACKTRACE=1 cargo unit-test


-> Optimize:
docker run --rm -v "$(pwd)":/code \\
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/target \\
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \\
  cosmwasm/optimizer:0.16.0

On Windows, you can use the following command instead.
docker run --rm -v ${pwd}:/code `
  --mount type=volume,source="$("$(Split-Path -Path $pwd -Leaf)")_cache",target=/target `
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry `
  cosmwasm/optimizer:0.16.0
The binary will be under the folder artifacts and its size will be 138 kB.


See the list of codes that was uploaded to the network previously.
zigchaind query wasm list-code $NODE
# Here is an alternative if you haven't set up the environment variables to interact with the network previously:
zigchaind query wasm list-code --node <https://rpc.dukong.mantrachain.io:443>


-------------------------


El puerto 26657 es para HTTP
El puerto 26656 es para el P2P


docker-compose --profile testnet up



# add wallets for testing
zigchaind keys add wallet
zigchaind keys add wallet2