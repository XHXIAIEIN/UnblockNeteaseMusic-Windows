# UnblockNeteaseMusic-Windows

解锁网易云音乐客户端灰色歌曲的 Windows 一键工具。

基于 [UnblockNeteaseMusic/server](https://github.com/UnblockNeteaseMusic/server) 项目。

## 下载

[![下载](https://img.shields.io/github/v/release/XHXIAIEIN/UnblockNeteaseMusic-Windows?label=下载&style=for-the-badge)](https://github.com/XHXIAIEIN/UnblockNeteaseMusic-Windows/releases/latest/download/UnblockNeteaseMusic-Windows.zip)

或前往 [Releases](https://github.com/XHXIAIEIN/UnblockNeteaseMusic-Windows/releases) 页面下载。

## 安装

1. 下载并解压 `UnblockNeteaseMusic-Windows.zip`
2. 双击 `gui/start.vbs`
3. 首次运行会自动下载核心程序

## 使用

1. 点击「启动」
2. 网易云客户端设置代理：设置 → 工具 → 自定义代理
   - 类型：`HTTP`
   - 服务器：`127.0.0.1`
   - 端口：`3610`
3. 点击确定，重启网易云音乐

## 配置

编辑 `gui/res/config.json`：

```json
{
  "sources": ["kuwo", "kugou", "migu", "bilibili"],
  "port": 3610,
  "enableFlac": false,
  "enableLocalVip": false,
  "blockAds": false
}
```

### 基本参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `sources` | array | 音源优先级，可选：`kuwo` `kugou` `migu` `bilibili` `qq` `youtube` `ytdlp` `bodian` `pyncmd` `joox` |
| `port` | int | HTTP 代理端口，HTTPS 端口自动为 port+363 |

### 音质参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `enableFlac` | bool | 启用无损 FLAC 音质 |
| `selectMaxBr` | bool | 从所有音源中选择最高码率 |
| `minBr` | int | 最低可接受码率，如 `128000` `192000` `320000` |

### 功能参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `enableLocalVip` | string | 本地 VIP 模式：`true` / `cvip` / `svip` |
| `blockAds` | bool | 屏蔽应用内广告 |
| `searchAlbum` | bool | 搜索时包含专辑名以提高匹配度 |
| `followSourceOrder` | bool | 严格按音源顺序查询（而非并行） |
| `noCache` | bool | 禁用缓存 |

### 网络参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `strict` | bool | 严格模式，仅代理必要请求 |
| `proxyUrl` | string | 上游代理，如 `http://127.0.0.1:7890` |
| `forceHost` | string | 强制使用的网易云服务器 IP |
| `endpoint` | string | 公开端点地址（用于反向代理） |
| `cnrelay` | string | 大陆中继服务器 `host:port` |

### 认证参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `neteaseCookie` | string | 网易云 Cookie，包含 `MUSIC_U` |
| `qqCookie` | string | QQ 音乐 Cookie：`uin=xxx; qm_keyst=xxx` |
| `miguCookie` | string | 咪咕音乐认证 Token |
| `jooxCookie` | string | JOOX Cookie：`wmid=xxx; session_key=xxx` |
| `youtubeKey` | string | YouTube Data API v3 密钥 |


> 完整参数说明请参考 [UnblockNeteaseMusic/server](https://github.com/UnblockNeteaseMusic/server)

## 卸载

1. 删除下载的文件夹
2. (可选) 删除证书：`certmgr.msc` → 受信任的根证书颁发机构 → 删除 "UnblockNeteaseMusic Root CA"

## 文件

```
gui/
├── start.vbs        # 启动器
└── res/
    ├── ca.crt       # 证书
    ├── config.json  # 配置
    └── UnblockNeteaseMusic.ps1
```

首次启动会自动从 [GitHub Releases](https://github.com/UnblockNeteaseMusic/server/releases/latest) 下载最新版 `unblockneteasemusic.exe` (~37MB) 到 res 文件夹。

## 致谢

- [UnblockNeteaseMusic/server](https://github.com/UnblockNeteaseMusic/server)
