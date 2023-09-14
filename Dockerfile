FROM rust:1.67.0  AS  builder

RUN apt update && apt install lld clang -y

WORKDIR /app/zero2prod

COPY Cargo.* .

RUN cargo vendor

COPY . .

ENV SQLX_OFFLINE true

RUN cargo build --release

FROM debian:bullseye-slim AS runtime

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
