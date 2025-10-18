FROM nvcr.io/nvidia/pytorch:24.10-py3

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1 \
    NANOCHAT_BASE_DIR=/workspace/.cache/nanochat \
    PATH="/root/.cargo/bin:/root/.local/bin:${PATH}"

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential curl git pkg-config libssl-dev \
        python3-dev python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    /root/.cargo/bin/rustup component add rustfmt

COPY pyproject.toml uv.lock ./
COPY rustbpe ./rustbpe

RUN uv venv && \
    . .venv/bin/activate && \
    uv sync --frozen

RUN . .venv/bin/activate && \
    uv pip install maturin && \
    maturin develop --manifest-path rustbpe/Cargo.toml --release

COPY . .

RUN . .venv/bin/activate && \
    uv sync --frozen && \
    maturin develop --manifest-path rustbpe/Cargo.toml --release

ENV PATH="/workspace/.venv/bin:${PATH}"

ENTRYPOINT ["/bin/bash"]
