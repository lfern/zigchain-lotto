#!/bin/bash

rm -rf ~/.zigchain

CHAINID="zigchain-1"
MONIKER="mynode"
PASSPHRASE="12345678"

# Set moniker and chain-id for (Moniker can be anything)
echo "Init ZIGChain"
zigchaind init $MONIKER --chain-id $CHAINID

# Update "constant_fee" denom
jq '.app_state.crisis.constant_fee.denom = "uzig"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

# Update "min_deposit" denom
jq '.app_state.gov.params.min_deposit[0].denom = "uzig"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

# Update "min_deposit" amount
jq '.app_state.gov.params.min_deposit[0].amount = "100"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

# Update "expedited_min_deposit" denom
jq '.app_state.gov.params.expedited_min_deposit[0].denom = "uzig"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

# Update "expedited_min_deposit" amount
jq '.app_state.gov.params.expedited_min_deposit[0].amount = "500"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

# Update "mint_denom"
jq '.app_state.mint.params.mint_denom = "uzig"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config.genesis.json

# Update "bond_denom"
jq '.app_state.staking.params.bond_denom = "uzig"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

# Set Governance Voting Period (2 minutes)
echo "NOTE: Setting Governance Voting Period to 2 minutes and 1 minute for expedited requests for easy testing"
jq '.app_state.gov.params.voting_period = "300s"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json

jq '.app_state.gov.params.expedited_voting_period = "150s"' $HOME/.zigchain/config/genesis.json > $HOME/.zigchain/config/tmp_genesis.json \
&& mv $HOME/.zigchain/config/tmp_genesis.json $HOME/.zigchain/config/genesis.json
# Add minimum fee for transactions to app.toml
# As it is .toml file we need to use awk to replace the value instead of jq
perl -pi -e 's/^minimum-gas-prices.*/minimum-gas-prices = "0.00025uzig"/' $HOME/.zigchain/config/app.toml

VAL_KEY="valuser1"
VAL_MNEMONIC="debate pottery prize tag lottery lounge protect fancy keep orbit person stage ten possible expect spend utility estate hope people attack input oval bird"

ZUSER1_KEY="zuser1"
ZUSER1_MNEMONIC="horse elite dog fix slide moon rely wife convince pear visa woman make rent giraffe under lawn impulse visit improve together above mixed what"

ZUSER2_KEY="zuser2"
ZUSER2_MNEMONIC="motion toddler sad surge present spot destroy clarify lyrics drastic cactus rhythm cupboard govern space soft fan accuse source spend artwork state smart motor"

ZUSER3_KEY="zuser3"
ZUSER3_MNEMONIC="design coral crawl aerobic airport engine spice impulse hobby limit twelve budget praise dog usage comic rain icon miss custom worth upper blade path"

ZUSER4_KEY="zuser4"
ZUSER4_MNEMONIC="blue define teach split satisfy mention food loop economy gravity lobster keep card milk smile unable barely attack shoot bulk vapor hybrid board drift"

ZUSER5_KEY="zuser5"
ZUSER5_MNEMONIC="net impact drift popular debris coast wrong iron amazing patient poet forward occur any private chunk tonight final clump general video bracket abstract fade"

NEWLINE=$'\n'

# Import keys from mnemonics
echo "Importing Keys from Mnemonics"

import_key() {
    local mnemonic=$1
    local key_name=$2

    if [[ "$(uname)" == "Darwin" ]]; then
        echo -e "$mnemonic\n$PASSPHRASE\n$PASSPHRASE" | zigchaind keys add "$key_name" --recover
    else
        yes "$mnemonic$NEWLINE$PASSPHRASE$NEWLINE$PASSPHRASE" | zigchaind keys add "$key_name" --recover
    fi
}

import_key "$VAL_MNEMONIC" "$VAL_KEY"
import_key "$ZUSER1_MNEMONIC" "$ZUSER1_KEY"
import_key "$ZUSER2_MNEMONIC" "$ZUSER2_KEY"
import_key "$ZUSER3_MNEMONIC" "$ZUSER3_KEY"
import_key "$ZUSER4_MNEMONIC" "$ZUSER4_KEY"
import_key "$ZUSER5_MNEMONIC" "$ZUSER5_KEY" 


# Allocate genesis accounts (cosmos formatted addresses)
echo "Allocate funds to genesis accounts"
yes $PASSPHRASE | zigchaind genesis add-genesis-account $(zigchaind keys show $VAL_KEY -a) 1000000000000000000000uzig
yes $PASSPHRASE | zigchaind genesis add-genesis-account $(zigchaind keys show $ZUSER1_KEY -a) 1000000000000000000000uzig
yes $PASSPHRASE | zigchaind genesis add-genesis-account $(zigchaind keys show $ZUSER2_KEY -a) 1000000000000000000000uzig
yes $PASSPHRASE | zigchaind genesis add-genesis-account $(zigchaind keys show $ZUSER3_KEY -a) 1000000000000000000000uzig
yes $PASSPHRASE | zigchaind genesis add-genesis-account $(zigchaind keys show $ZUSER4_KEY -a) 1000000000000000000000uzig

# Sign genesis transaction
echo "Signing genesis transaction"
yes $PASSPHRASE | zigchaind genesis gentx $VAL_KEY 100000000000000000uzig --chain-id $CHAINID

# Collect genesis tx
echo "Collecting genesis transaction"
yes $PASSPHRASE | zigchaind genesis collect-gentxs

echo "Validating genesis"

# Run this to ensure everything worked and that the genesis file is set up correctly
zigchaind genesis validate

cp $HOME/.zigchain/config/config.toml $HOME/.zigchain/config/config-bak.toml
sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' $HOME/.zigchain/config/config.toml
sed -i 's|laddr = "tcp://127.0.0.1:26656"|laddr = "tcp://0.0.0.0:26656"|' $HOME/.zigchain/config/config.toml
# these don't preserve comments
# toml-cli set $HOME/.zigchain/config/config.toml rpc.laddr "tcp://0.0.0.0:26657"
# toml-cli set $HOME/.zigchain/config/config.toml p2p.laddr "tcp://0.0.0.0:26656"

echo "🎉 Setup done!"