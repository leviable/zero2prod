FROM rust:1.68.0 AS builder

RUN apt update && apt install lld clang -y

WORKDIR /app/zero2prod

# Prebuild dependencies and cache layer
RUN cargo init --vcs none --lib
RUN echo "fn main() {}" > src/main.rs

COPY Cargo.toml .

RUN cargo build 
RUN cargo build --release

# Copy in actual code and build binary
COPY . .

ENV SQLX_OFFLINE true
RUN cargo build --release

FROM debian:bullseye-slim AS app

WORKDIR /app

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/zero2prod/target/release/zero2prod zero2prod
COPY configuration configuration

ENV APP_ENVIRONMENT production

ENTRYPOINT ["./zero2prod"]
