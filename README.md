# Deadlock Dedicated Proton Server

Run Valve's Deadlock dedicated server on Linux using Docker and GE-Proton. A temporary solution until Valve publishes a native Linux server binary.

> Based on the original [deadlock-proton-server](https://github.com/8ucz3k/deadlock-proton-server) by 8ucz3k, updated with critical fixes for current Deadlock versions.

## What's different from the original?

| Issue | Original repo | This repo |
|-------|--------------|-----------|
| Proton version | GE-Proton9-5 (missing `SteamClient023`) | **GE-Proton10-34** (supports `SteamClient023`) |
| Executable name | `project8.exe` (renamed by Valve) | **`deadlock.exe`** |
| Virtual display | None | **Xvfb** included (required by Proton/Wine) |
| Vulkan support | None (crashes on headless) | **Mesa llvmpipe** software Vulkan |
| Default map | `street_test` (doesn't exist) | **`dl_streets`** |
| Skip updates | Not supported | **`SKIP_UPDATE=1`** to skip SteamCMD on restart |

## Requirements

- Linux server with **8 GB+ RAM** and **40 GB+ free disk space**
- Docker and Docker Compose
- A Steam account that owns Deadlock

## Quick start

```bash
# 1. Clone this repo
git clone https://github.com/Oskar-Sterner/deadlock-dedicated-proton-server.git
cd deadlock-dedicated-proton-server

# 2. Build the Docker image (~1.5 GB download)
docker build -t deadlock-server -f docker/Dockerfile docker/

# 3. Configure your server
cp env.sample .env
nano .env  # Add your Steam credentials and server settings

# 4. Start the server (~36 GB game download on first run)
docker compose up -d

# 5. Watch the logs
docker compose logs -f
```

## Configuration

Edit `.env` to configure the server:

```ini
# Server settings
PORT=27015
SERVER_PASSWORD=            # Leave empty for no password
MAP=dl_streets              # Available: dl_streets, dl_midtown, dl_hideout

# Steam credentials (required for downloading game files)
STEAM_LOGIN=your_username
STEAM_PASSWORD=your_password
STEAM_2FA_CODE=XXXXX        # From Steam Guard mobile app

# Set to 1 after initial download to skip SteamCMD on restarts
SKIP_UPDATE=0
```

### Available maps

| Map | File size |
|-----|-----------|
| `dl_streets` | 892 MB |
| `dl_midtown` | 1008 MB |
| `dl_hideout` | 370 MB |

## System tuning

Raise `vm.max_map_count` (required for Wine/Proton games):

```bash
# Apply immediately
sudo sysctl -w vm.max_map_count=2147483642

# Persist across reboots
echo 'vm.max_map_count=2147483642' | sudo tee -a /etc/sysctl.conf
```

## Managing the server

```bash
# View logs
docker compose logs -f

# Stop the server
docker compose down

# Restart the server
docker compose restart

# Update game files (requires fresh 2FA code in .env)
# Edit .env with new STEAM_2FA_CODE, then:
docker compose down && docker compose up -d
```

### RCON

There is no interactive console. Use RCON to manage the server:

- RCON is available on the same port as the game server (default 27015)
- Use any Source engine RCON client to connect

### Server config

Place a `server.cfg` file in `server/Deadlock/game/citadel/cfg/` to configure server convars.

## Updating

### Game updates

When Deadlock receives an update:

1. Get a fresh Steam Guard 2FA code
2. Update `STEAM_2FA_CODE` in `.env`
3. Set `SKIP_UPDATE=0` in `.env`
4. Restart: `docker compose down && docker compose up -d`

### Proton updates

If a newer GE-Proton is needed, edit the `PROTON_VERSION` build arg in `docker/Dockerfile` and rebuild:

```bash
docker build --no-cache -t deadlock-server -f docker/Dockerfile docker/
docker compose down && docker compose up -d
```

## Troubleshooting

### Server crashes immediately on map load

The most common cause is an outdated Proton version missing the `SteamClient023` interface. Make sure you're using **GE-Proton10-34 or newer**.

Check which interfaces your Proton supports:

```bash
docker run --rm --entrypoint bash deadlock-server -c \
  'cat /home/steam/.steam/steam/compatibilitytools.d/GE-Proton*/files/lib/wine/x86_64-unix/lsteamclient.so \
   | tr -d "\0" | grep -oP "SteamClient0[0-9]+" | sort -u'
```

You need `SteamClient023` in the output.

### Server hangs on "hanging forever..."

Check the logs above that message for the actual error. Common causes:
- Wrong Steam credentials or expired 2FA code
- Permissions issue on the `server/Deadlock` directory
- Game executable not found (check if Valve renamed it again)

### "Two-factor code mismatch" error

Steam Guard codes expire quickly. Get a fresh code, update `.env`, and restart.

After the initial download, set `SKIP_UPDATE=1` in `.env` so restarts don't need a fresh 2FA code.

### High CPU during startup

Normal. The server uses significant CPU while loading the map (especially with software Vulkan rendering via llvmpipe). It settles down after initialization.

## How it works

1. **SteamCMD** downloads the Windows Deadlock server files (App ID 1422450)
2. **GE-Proton** (a Wine-based compatibility layer) runs the Windows `.exe` on Linux
3. **Xvfb** provides a virtual display that Proton requires
4. **Mesa llvmpipe** provides software Vulkan rendering for the headless server
5. **Docker** wraps everything for portability and isolation

## Credits

- Original concept: [8ucz3k/deadlock-proton-server](https://github.com/8ucz3k/deadlock-proton-server)
- [GE-Proton](https://github.com/GloriousEggroll/proton-ge-custom) by GloriousEggroll
- [SteamCMD Docker image](https://hub.docker.com/r/cm2network/steamcmd) by CM2.Network

## License

MIT
