FROM golang:1.23.6 AS zigchain-base

# Install dependencies
RUN apt-get update && apt-get install -y wget jq && rm -rf /var/lib/apt/lists/*

RUN go install github.com/MinseokOh/toml-cli@latest

# this version doesn't work:
# RUN wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v2.2.3/libwasmvm.x86_64.so
# Use previous version
RUN wget -O /usr/lib/libwasmvm.x86_64.so https://github.com/CosmWasm/wasmvm/releases/download/v2.2.2/libwasmvm.x86_64.so

# Workdir
WORKDIR /workspace

# Copy new script provided by Zignaly. The one that is included in the tar.gz doesn't work
COPY ./.docker/new-setup-script.sh /usr/local/bin/zigchain_local_setup2.sh

# Download tar.gz from zigchain repository
RUN LATEST_VERSION=$(curl -s https://raw.githubusercontent.com/ZIGChain/networks/refs/heads/main/zig-test-1/version.txt) && \
    wget "https://raw.githubusercontent.com/ZIGChain/networks/refs/heads/main/zig-test-1/binaries/zigchaind-${LATEST_VERSION}-linux-amd64.tar.gz" && \
    tar -zxvf "zigchaind-${LATEST_VERSION}-linux-amd64.tar.gz" -C /usr/local/bin zigchaind zigchain_local_setup.sh && \
    ls /usr/local/bin && \
    chmod +x /usr/local/bin/zigchaind /usr/local/bin/zigchain_local_setup.sh && \
    rm "zigchaind-${LATEST_VERSION}-linux-amd64.tar.gz"

# The setup script included in tar.gz doesn't work
# RUN /usr/local/bin/zigchain_local_setup.sh

# Run the script provided by Zignaly
RUN chmod +x /usr/local/bin/zigchain_local_setup2.sh && /usr/local/bin/zigchain_local_setup2.sh

# ENTRYPOINT ["/bin/sh", "-c", "while true; do sleep 1000; done"]
ENTRYPOINT ["/bin/sh", "-c", "/usr/local/bin/zigchaind start"]


FROM zigchain-base AS zigchain-dev
# Install Rust toolchain + wasm target
RUN apt-get update && apt-get install -y curl build-essential git && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    . "/root/.cargo/env" && \
    rustup install stable && \
    rustup install 1.81 && \
    rustup default stable && \
    rustup target add wasm32-unknown-unknown && \
    cargo install cargo-generate --features vendored-openssl && \
    cargo install cosmwasm-check && \
    cargo install wasm-pack && \
    cargo install cargo-tarpaulin && \
    cargo install cargo-nextest && \
    rustc --version && \
    cargo --version && \
    wasm-pack --version && \
    cosmwasm-check --version

ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]


ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /workspace

CMD ["/bin/bash"]