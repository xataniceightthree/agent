# agent-client

```bash
curl -fsSL "https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/install.sh?x=$(date +%s%N)" | bash
```

Override alamat agent:

```bash
curl -fsSL "https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/install.sh?x=$(date +%s%N)" | bash -s -- --addr 1.2.3.4:3133
```

Cek status:

```bash
pgrep -af ./.fastingo/client
```

Uninstall:

```bash
pkill -f ./.fastingo/client; rm -rf ./.fastingo
```
