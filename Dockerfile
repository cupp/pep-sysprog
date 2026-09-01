# Containerfile — RISC-V systems courses (build/run with docker OR podman)
FROM debian:bookworm-slim

# --- Base build + debugging tools ---
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      gdb \
      make \
      git \
      curl \
      ca-certificates \
      gnupg \
      python3 \
      default-jre-headless \
    # --- Native toolchain + Python dev (Data Structures course) ---
    #   gcc here is the NATIVE compiler (no riscv64- prefix)
      gcc \
      python3-dev \
      python3-pip \
      valgrind \
    # --- RISC-V cross-toolchains (GNU) ---
      gcc-riscv64-linux-gnu \
      g++-riscv64-linux-gnu \
      gcc-riscv64-unknown-elf \
    # --- QEMU ---
      qemu-user \
      qemu-system-misc \
# --- GitHub CLI (gh) from GitHub's official apt repository ---
# gh is not in Debian's default repos, so add GitHub's repo + signing key first.
    && mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
         -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
         > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*


# Toolchain smoke test: fail the image build loudly if the bare-metal RISC-V
# compiler is broken or missing. Replaces the incidental build-time check that
# the old pre-baked xv6 clone used to provide, without carrying a kernel clone.
RUN printf 'int main(void){return 0;}\n' > /tmp/smoke.c \
    && riscv64-unknown-elf-gcc -march=rv64g -mabi=lp64 -nostdlib -e main \
         /tmp/smoke.c -o /tmp/smoke.elf \
    && test -f /tmp/smoke.elf \
    && rm -f /tmp/smoke.c /tmp/smoke.elf \
    && echo "RISC-V bare-metal toolchain OK"

# --- ISA simulators for Computer Systems (assembly + assembler project) ---
# RARS — BSD-licensed, self-contained GUI/CLI jar.
RUN curl -L -o /opt/rars.jar \
      https://github.com/TheThirdOne/rars/releases/download/v1.6/rars1_6.jar
# --- Non-root user (matches Podman's rootless model; good hygiene under Docker) ---
RUN useradd -ms /bin/bash student
USER student
WORKDIR /home/student/work

CMD ["/bin/bash"]
