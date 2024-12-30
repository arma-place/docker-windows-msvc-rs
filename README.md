# Docker image for cross compiling Rust to Windows MSVC

This docker image can be used to cross compile Rust programs to `x86_64-pc-windows-msvc` or `i686-pc-windows-msvc`. The MSVC build tools and Windows SDK are installed with [this project](https://github.com/est31/msvc-wine-rust).

## Usage

You can either use the [public docker image](https://github.com/arma-place/docker-windows-msvc-rs/pkgs/container/windows-msvc-rs) (`ghcr.io/arma-place/windows-msvc-rs`) or build the image with the provided Dockerfile yourself, if you need other versions of MSVC or Rust than specified [in the table below](#configuration).

The public docker image is available for multiple different rust version (see [here](https://github.com/arma-place/docker-windows-msvc-rs/pkgs/container/windows-msvc-rs/versions?filters%5Bversion_type%5D=tagged)).

When running the image, `cargo` is the default entry point, so if you just want to use `cargo`, you only need to pass the cargo-command (i.e. `build`) and options. The working directory is `/usr/local/src`, therefore you need to bind a volume from you rust project to that directory.

### Building a Rust project via `cargo build`
The default command in the docker container already specifies the target (`x86_64-pc-windows-msvc`) and the linker (`ld-x86_64-pc-windows-msvc`), therefore if you just want to build (debug) without passing any extra options, you can do it like this:
```sh
docker run --rm -v .:/usr/local/src ghcr.io/arma-place/windows-msvc-rs
```
_(This example assumes that your working directory is located in your Rust project. `--rm` is theoretically not needed, but ensures the container is removed once done)_

### Passing extra options to `cargo build`
If you need to pass options to `cargo build` (other than the default target and linker). You need make sure that you set the correct build target (`x86_64-pc-windows-msvc` or  `i686-pc-windows-msvc`) and configured the correct linker  (`ld-x86_64-pc-windows-msvc` or `ld-i686-pc-windows-msvc` resp.). This can be done by either placing a `config.toml` in the `.cargo` directory in your rust project or passing both options as flags to `cargo build`.
```toml
# File .cargo/config.toml
[build]
target="x86_64-pc-windows-msvc" # or "i686-pc-windows-msvc" for x32 build

[target.x86_64-pc-windows-msvc]
linker = "ld-x86_64-pc-windows-msvc"

[target.i686-pc-windows-msvc]
linker = "ld-i686-pc-windows-msvc"
```
or
```sh
# flags to pass to cargo build
--target=x86_64-pc-windows-msvc --config=target.x86_64-pc-windows-msvc.linker=\"ld-x86_64-pc-windows-msvc\"
```

Therefore actually running `cargo build` in the container (i.e. with the `--release` flag) would look something like this:
```sh
# When .cargo/config.toml includes target and linker
docker run --rm -v .:/usr/local/src ghcr.io/arma-place/windows-msvc-rs build --release

# Passing target and linker as flags
docker run --rm -v .:/usr/local/src ghcr.io/arma-place/windows-msvc-rs build --release --target=x86_64-pc-windows-msvc --config=target.x86_64-pc-windows-msvc.linker=\"ld-x86_64-pc-windows-msvc\"
```
_(This example assumes that your working directory is located in your Rust project. `--rm` is theoretically not needed, but ensures the container is removed once done)_

### Using your local crates.io cache
To speed up the build process you can map your local crates.io cache into the container, by specifying an extra volume when executing `docker run`:

```sh
docker run -v ~/.cargo/registry:/root/.cargo/registry [...]
```

### `docker-compose.yml`

The following `docker-compose.yml` contains an exemplary configuration that you can use in your project provided you want to compile to the x64 target: 

```yml
# docker-compose.yml

version: '3.9'

services:
  debug:
    image: ghcr.io/arma-place/windows-msvc-rs
    volumes:
      # map project directory to container's working directory (required)
      - .:/usr/local/src
      # use local crates.io cache in container (optional; speeds up the build for local development)
      - ~/.cargo/registry:/root/.cargo/registry

  release:
    image: ghcr.io/arma-place/windows-msvc-rs
    volumes: # see debug service for explanation of volumes
      - .:/usr/local/src
      - ~/.cargo/registry:/root/.cargo/registry

    command: [
      "build",
      "--release",
      # target & linker either have to passed as flags here or be
      # configured in your .cargo/config.toml file (see README)
      "--target=x86_64-pc-windows-msvc",
      "--config=target.x86_64-pc-windows-msvc.linker=\"ld-x86_64-pc-windows-msvc\""
    ]
```

## Configuration

There are a couple of docker build-time variables available to configure the build. These can be passed to the `docker build` command using the `--build-arg <varname>=<value>` flag.

| Name               | Default Value                               | Description                                                                                                                    |
| :------------------| :------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------- |
| `RUST_VERSION`     | `1.83.0`                                    | Rust version to install                                                                                                        |
| `MSVC_WINE_COMMIT` | `4244f960cb20a8e1c7b8d11bcb6cd1e6f6ab28c9`  | Commit SHA from [this project](https://github.com/est31/msvc-wine-rust) to use to install the MSVC build tools and Windows SDK |
