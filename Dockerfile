FROM rust:1.96.0-bookworm AS kujo-builder

ARG KUJO_RUNTIME_REF=

RUN apt-get update && apt-get install -y --no-install-recommends git pkg-config ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/kujo-runtime
COPY RUNTIME_VERSION /tmp/RUNTIME_VERSION

RUN if [ -z "$KUJO_RUNTIME_REF" ]; then KUJO_RUNTIME_REF="$(cat /tmp/RUNTIME_VERSION)"; fi \
	&& git init . \
	&& git remote add origin https://github.com/kujolang/kujo.git \
	&& git fetch --depth 1 origin "$KUJO_RUNTIME_REF" \
	&& git checkout --detach "$KUJO_RUNTIME_REF" \
	&& cargo build --release --locked --manifest-path Cargo.toml

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates bash libgcc-s1 libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/kujo-eval
COPY --from=kujo-builder /tmp/kujo-runtime/target/release/kujo /usr/local/bin/kujo
COPY . /opt/kujo-eval/

ENTRYPOINT ["kujo", "run", "main.kujo"]
CMD ["run"]
