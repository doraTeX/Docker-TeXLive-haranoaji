FROM ubuntu:19.10

LABEL maintainer="doraTeX <taylorkgb [at] gmail.com>"

ENV TL_VERSION      2019
ENV TL_PATH         /usr/local/texlive
ENV FONT_PATH       ${TL_PATH}/texmf-local/fonts
ENV TEXMF_DIST_PATH ${TL_PATH}/texmf-dist
ENV PATH            ${TL_PATH}/bin/x86_64-linux:/bin:${PATH}

WORKDIR /tmp

# Install required packages
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    # Basic tools
    wget unzip git ghostscript \
    # for tlmgr
    perl-modules-5.28 \
    # for XeTeX
    fontconfig && \
    # Clean caches
    apt clean && \
    apt autoclean && \
    apt autoremove -y && \
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
    # Install HaranoAji fonts
      git clone https://github.com/trueroad/HaranoAjiFonts.git && \
      mkdir -p "${FONT_PATH}/opentype/haranoaji" && \
      cp -p ./HaranoAjiFonts/*.otf "${FONT_PATH}/opentype/haranoaji/" && \
      rm -rf ./HaranoAjiFonts && \
    # Update ptex-fontmaps
      git clone https://github.com/texjporg/jfontmaps.git && \
      cp -p ./jfontmaps/database/ptex-fontmaps-data.dat "${TEXMF_DIST_PATH}/fonts/misc/ptex-fontmaps/" && \
      cp -pr ./jfontmaps/maps/haranoaji "${TEXMF_DIST_PATH}/fonts/map/dvipdfmx/ptex-fontmaps/" && \
      cp -p ./jfontmaps/script/*.pl "${TEXMF_DIST_PATH}/scripts/ptex-fontmaps/" && \
      rm -rf ./jfontmaps && \
    # Update cjk-gs-integrate
      git clone https://github.com/texjporg/cjk-gs-support.git && \
      cp -p ./cjk-gs-support/cjk-gs-integrate.pl "${TEXMF_DIST_PATH}/scripts/cjk-gs-integrate/" && \
      cp -p ./cjk-gs-support/database/cjkgs-haranoaji.dat "${TEXMF_DIST_PATH}/fonts/misc/cjk-gs-integrate/" && \
      rm -rf ./cjk-gs-support && \
    # Update zxjafont
      wget -q -O "${TEXMF_DIST_PATH}/tex/latex/zxjafont/zxjafont.sty" https://raw.githubusercontent.com/doraTeX/ZXjafont/master/zxjafont.sty && \
    # Apply new font settings
      mktexlsr && \
      cjk-gs-integrate --cleanup --force && \
      cjk-gs-integrate --force && \
      kanji-config-updmap-sys --jis2004 haranoaji && \
    # Re-index LuaTeX font database
      luaotfload-tool -u -f && \
    # Enable XeTeX to find fonts in TEXMFDIST and TEXMFLOCAL using fontconfig
      printf "%s\n" \
        "<?xml version=\"1.0\"?>" \
        "<!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">" \
        "<fontconfig>" \
          "<dir>${TEXMF_DIST_PATH}/fonts/opentype</dir>" \
          "<dir>${TEXMF_DIST_PATH}/fonts/truetype</dir>" \
          "<dir>${FONT_PATH}/opentype</dir>" \
          "<dir>${FONT_PATH}/truetype</dir>" \
        "</fontconfig>" \
        > /etc/fonts/local.conf && \
      fc-cache -r && \
    # Install llmk
      wget -q -O /usr/local/bin/llmk https://raw.githubusercontent.com/wtsnjp/llmk/master/llmk.lua && \
      chmod +x /usr/local/bin/llmk

VOLUME ["/usr/local/texlive/${TL_VERSION}/texmf-var/luatex-cache/generic/fonts/otl"]

WORKDIR /workdir

CMD ["llmk"]