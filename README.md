# px

## 配置 Squid

执行脚本会打开 Squid 管理菜单：

```bash
./setup-squid.sh
```

菜单功能：

1. 安装与配置部署
2. 启动
3. 重启
4. 查看服务状态
0. 退出

检测到 systemd 时使用 systemd 管理服务；在当前容器等无 systemd 环境中直接管理 Squid。配置部署前会校验配置，并将已有配置备份到 `/etc/squid/squid.conf.bak.*`。