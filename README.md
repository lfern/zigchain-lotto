# Zigchain Lotto Example
## 📌 TO-DO List

- [x] Generate intial version of a contract  ✅
- [ ] Generate Lotto Contract
- [ ] Publish in local network
- [ ] Publish in testnet network
- [ ] Optimize
- [ ] Create DAPP application

## Local network
* Default HTTP port 26657
* Default P2P port 26656

## Code coverage
cargo install cargo-tarpaulin

## Running tests
cargo install cargo-nextest

## Optimize
On linux:
```bash
docker run --rm -v "$(pwd)":/code \\
  --mount type=volume,source="$(basename "$(pwd)")_cache",target=/target \\
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry \\
  cosmwasm/optimizer:0.16.0
```

On Windows, you can use the following command instead.
```cmd
docker run --rm -v ${pwd}:/code `
  --mount type=volume,source="$("$(Split-Path -Path $pwd -Leaf)")_cache",target=/target `
  --mount type=volume,source=registry_cache,target=/usr/local/cargo/registry `
  cosmwasm/optimizer:0.16.0
```
The binary will be under the folder artifacts and its size will be 138 kB.

## Contracts examples
* Mantra chain: https://metaschool.so/articles/build-on-mantra-chain-developer-guide
* Metaschool: https://github.com/0xmetaschool/building-on-MANTRA-chain
* InterWasm: https://github.com/InterWasm/cw-contracts


## Some code examples
```bash
# See the list of codes that was uploaded to the network previously.
zigchaind query wasm list-code $NODE

# Here is an alternative if you haven't set up the environment variables to interact with the network previously:
zigchaind query wasm list-code --node https://rpc.dukong.mantrachain.io:443

# Add wallets for testing...
zigchaind keys add wallet
zigchaind keys add wallet2

# check contract
cosmwasm-check ./target/wasm32-unknown-unknown/release/contract.wasm

# 1️⃣ Subir el código:
zigchaind tx wasm store zigchain_lottery.wasm --from wallet --chain-id ...

# 2️⃣ Instanciar el contrato:
zigchaind tx wasm instantiate <code_id> '{"draw_interval":3600,"max_entry_amount":"1000000"}' --from wallet --label "lottery" --chain-id ...

# 3️⃣ Ejecutar comandos:
zigchaind tx wasm execute <contract_addr> '{"enter_lottery":{}}' --amount 500000uatom --from player
```

-------------------------



