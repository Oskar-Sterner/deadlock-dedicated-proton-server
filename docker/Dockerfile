FROM cm2network/steamcmd:root

RUN apt-get update && apt-get install -y --no-install-recommends \
    gosu wget unzip python3 xvfb procps libfreetype6 \
    mesa-vulkan-drivers libvulkan1 libgl1-mesa-dri \
    && rm -rf /var/lib/apt/lists/*

ARG APPID=1422450
ARG PROTON_VERSION=GE-Proton10-34
ARG DEADWORKS_VERSION=v0.4.7
ARG DOTNET_VERSION=10.0.0

ENV STEAM_HOME="/home/steam" \
    STEAM_PATH="/home/steam/.steam/steam" \
    APPID=${APPID} \
    DEADWORKS_DIR="/opt/deadworks"

RUN mkdir -p ${STEAM_PATH}
WORKDIR ${STEAM_PATH}

# Install GE-Proton (latest version with SteamClient023 support)
RUN mkdir -p compatibilitytools.d/ && \
    wget -qO- https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz \
    | tar -xz -C compatibilitytools.d/

# Set up Wine prefix with default settings
RUN mkdir -p steamapps/compatdata/${APPID} && \
    cp -r compatibilitytools.d/${PROTON_VERSION}/files/share/default_pfx steamapps/compatdata/${APPID}

# Install steamclient64.dll into prefix for Steam API
RUN mkdir -p "steamapps/compatdata/${APPID}/pfx/drive_c/Program Files (x86)/Steam" && \
    wget -qO "steamapps/compatdata/${APPID}/pfx/drive_c/Program Files (x86)/Steam/steamclient64.dll" \
    https://buczek.ru/steamclient64.dll

# Bundle Deadworks framework — overlaid onto the game directory at container start
RUN mkdir -p ${DEADWORKS_DIR} && \
    wget -qO /tmp/deadworks.zip \
    https://github.com/Deadworks-net/deadworks/releases/download/${DEADWORKS_VERSION}/deadworks-${DEADWORKS_VERSION}.zip && \
    unzip -q /tmp/deadworks.zip -d ${DEADWORKS_DIR} && \
    rm /tmp/deadworks.zip

# Bundle Windows .NET runtime directly inside the Wine prefix at the
# canonical Windows path. Wine's nethost requires the runtime to be
# discoverable by hostfxr; placing it at "C:\Program Files\dotnet"
# matches the layout produced by the official Microsoft installer and
# is what deadworks.exe (built with EnableDynamicLoading) expects.
# Mounting it elsewhere with DOTNET_ROOT pointing at a Z:\ path was
# silently failing for plugin DLL loads.
RUN mkdir -p "steamapps/compatdata/${APPID}/pfx/drive_c/Program Files/dotnet" && \
    wget -qO /tmp/dotnet.zip \
    https://builds.dotnet.microsoft.com/dotnet/Runtime/${DOTNET_VERSION}/dotnet-runtime-${DOTNET_VERSION}-win-x64.zip && \
    unzip -q /tmp/dotnet.zip -d "steamapps/compatdata/${APPID}/pfx/drive_c/Program Files/dotnet" && \
    rm /tmp/dotnet.zip

RUN chown -R steam:steam ${STEAM_HOME} ${DEADWORKS_DIR}

# Proton environment
ENV STEAM_COMPAT_CLIENT_INSTALL_PATH=${STEAM_PATH} \
    STEAM_COMPAT_DATA_PATH=${STEAM_PATH}/steamapps/compatdata/${APPID} \
    PROTON=${STEAM_PATH}/compatibilitytools.d/${PROTON_VERSION}/proton \
    DISPLAY=:99

# .NET runtime path as seen by the Windows process inside the Wine prefix.
ENV DOTNET_ROOT='C:\Program Files\dotnet'

# --- Headless rendering optimizations ---
# These dramatically reduce CPU/memory usage on servers without a GPU
# by minimizing the work done by DXVK, Mesa llvmpipe, and Wine.

# Wine: suppress all debug output (major CPU saver)
ENV WINEDEBUG="-all" \
    WINE_LARGE_ADDRESS_AWARE=1

# DXVK: disable logging and shader cache (saves CPU + disk I/O)
ENV DXVK_LOG_LEVEL="none" \
    DXVK_STATE_CACHE=0

# Mesa llvmpipe: minimize software rendering overhead
ENV MESA_NO_ERROR=1 \
    MESA_SHADER_CACHE_DISABLE="true" \
    GALLIUM_DRIVER="llvmpipe" \
    LP_NUM_THREADS=2

# Proton: disable logging, reduce memory overhead
ENV PROTON_LOG=0 \
    PROTON_NO_WRITE_WATCH=1 \
    PROTON_NO_ESYNC=1 \
    PROTON_NO_FSYNC=1

# Disable Wine crash dialogs and debugger
ENV WINEDLLOVERRIDES="winedbg.exe=d"

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
