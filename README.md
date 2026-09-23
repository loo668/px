# px

## 配置 Squid

执行脚本会安装并配置 Squid，监听 `0.0.0.0:18889`，并自动备份已有配置：

```bash
./setup-squid.sh
```

脚本会先校验配置，再启动 Squid。检测到 systemd 时使用 systemd 管理服务；在当前容器等无 systemd 环境中直接启动 Squid，并确认端口已监听。已有配置备份保存为 `/etc/squid/squid.conf.bak.*`。