FROM ubuntu:19.10

LABEL maintainer="doraTeX <taylorkgb [at] gmail.com>"

ENV TL_VERSION      2019
ENV TL_PATH         /usr/local/texlive
ENV PATH            ${TL_PATH}/bin/x86_64-linux:/bin:${PATH}

WORKDIR /tmp

# Install required packages
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    # Basic tools
    wget unzip ghostscript \
    # for tlmgr
    perl-modules-5.28 \
    # for XeTeX
    fontconfig && \
    # Clean caches
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install TeX Live
RUN mkdir install-tl-unx && \
    wget -qO- http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | \
      tar -xz -C ./install-tl-unx --strip-components=1 && \
    printf "%s\n" \
      "TEXDIR ${TL_PATH}" \
      "selected_scheme scheme-full" \
      "option_doc 0" \
      "option_src 0" \
      > ./install-tl-unx/texlive.profile && \
    ./install-tl-unx/install-tl \
      -profile ./install-tl-unx/texlive.profile && \
    rm -rf *

# Set up fonts and llmk
RUN \
    # Run cjk-gs-integrate
      cjk-gs-integrate --cleanup --force && \
      cjk-gs-integrate --force && \
    # Copy CMap: 2004-{H,V}
      cp ${TL_PATH}/texmf-dist/fonts/cmap/ptex-fontmaps/2004-* /var/lib/ghostscript/CMap/ && \
      kanji-config-updmap-sys --jis2004 haranoaji && \
    # Re-index LuaTeX font database
      luaotfload-tool -u -f && \
    # Install llmk
      wget -q -O /usr/local/bin/llmk https://raw.githubusercontent.com/wtsnjp/llmk/master/llmk.lua && \
      chmod +x /usr/local/bin/llmk

VOLUME ["/usr/local/texlive/${TL_VERSION}/texmf-var/luatex-cache"]

WORKDIR /workdir

CMD ["llmk"]