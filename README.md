# px

## 配置 Squid

执行脚本会安装并配置 Squid，监听 `0.0.0.0:18889`，并自动备份已有配置：

```bash
./setup-squid.sh
```

脚本会在配置校验通过后重启服务；已有配置备份保存为 `/etc/squid/squid.conf.bak.*`。