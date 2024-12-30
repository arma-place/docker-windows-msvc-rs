FROM ubuntu:22.04 AS ubuntu_wine

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --install-recommends curl build-essential wine-stable \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN wine --version

####################################################################################################

FROM ubuntu_wine AS ubuntu_linker

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y git msitools p7zip-full wget unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /output

ARG MSVC_WINE_COMMIT='4244f960cb20a8e1c7b8d11bcb6cd1e6f6ab28c9'

RUN git clone https://github.com/est31/msvc-wine-rust.git .
RUN git reset --hard $MSVC_WINE_COMMIT

RUN chmod +x get.sh
RUN ./get.sh  licenses-accepted
RUN rm -r dl
RUN rm -rf .git

####################################################################################################

FROM ubuntu_wine

ARG RUST_VERSION='1.83.0'

# Install Linker scripts
COPY --from=ubuntu_linker /output/ /usr/local/lib/msvc/
RUN echo "#!/usr/bin/env bash\n/usr/local/lib/msvc/linker-scripts/linkx64.sh \$@" > /usr/local/bin/ld-x86_64-pc-windows-msvc
RUN echo "#!/usr/bin/env bash\n/usr/local/lib/msvc/linker-scripts/linkx86.sh \$@" > /usr/local/bin/ld-i686-pc-windows-msvc
RUN chmod +x /usr/local/bin/ld-x86_64-pc-windows-msvc
RUN chmod +x /usr/local/bin/ld-i686-pc-windows-msvc

# Install Rust
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain $RUST_VERSION --target x86_64-pc-windows-msvc --target i686-pc-windows-msvc
ENV PATH="/root/.cargo/bin:${PATH}"
ENV CARGO_HOME="/root/.cargo"
ENV RUSTUP_HOME="/root/.rustup"

WORKDIR /usr/local/src
ENTRYPOINT ["cargo"]
CMD ["build", "--target=x86_64-pc-windows-msvc", "--config=target.x86_64-pc-windows-msvc.linker=\"/usr/local/lib/msvc/linker-scripts/linkx64.sh\"", "--config=target.i686-pc-windows-msvc.linker=\"/usr/local/lib/msvc/linker-scripts/linkx86.sh\""]