# agent-client

Dua mode install. Pilih salah satu.

## 1. Hold mode (foreground)

Client menempel ke proses panel/container — tetap hidup selama panel menjalankan prosesnya.

```bash
curl -fsSL "https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/installhold.sh?x=$(date +%s%N)" | bash
```

## 2. PID mode (background / detached)

Client dilepas ke background, PID disimpan di `.fastingo/client.pid`, log di `.fastingo/client.log`.

```bash
curl -fsSL "https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/installpid.sh?x=$(date +%s%N)" | bash
```

---

## Override alamat agent

Tambahkan `-s -- --addr IP:PORT`:

```bash
# hold
curl -fsSL "https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/installhold.sh?x=$(date +%s%N)" | bash -s -- --addr 1.2.3.4:3133

# pid
curl -fsSL "https://raw.githubusercontent.com/xataniceightthree/agent/main/setup/installpid.sh?x=$(date +%s%N)" | bash -s -- --addr 1.2.3.4:3133
```

## Cek status

```bash
# hold
pgrep -af ./.fastingo/client

# pid
cat ./.fastingo/client.pid
tail -f ./.fastingo/client.log
```

## Stop

```bash
# hold / pid
pkill -f ./.fastingo/client
```

## Uninstall

```bash
pkill -f ./.fastingo/client; rm -rf ./.fastingo
```
