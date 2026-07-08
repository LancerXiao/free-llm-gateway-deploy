# EnlyAI 服务器配置文件

本目录包含 EnlyAI 生产服务器上的关键配置文件，用于版本控制和部署同步。

## 目录结构

```
server-configs/
├── nginx/
│   └── enlyai.com.conf          # Nginx 配置（含 sub_filter 注入、SEO 优化）
├── seo/
│   ├── crawler_home_zh.html     # 中文版爬虫预渲染页面（2026年7月最新模型）
│   ├── crawler_home.html        # 英文版爬虫预渲染页面
│   ├── lang.js                  # 浏览器语言检测脚本
│   └── robots.txt               # 爬虫规则
├── scripts/
│   ├── crawler_server.py        # 爬虫预渲染服务（端口8902，根据UA返回中英文）
│   └── auto_submit_urls.sh      # URL自动提交到搜索引擎
├── systemd/
│   └── enlyai-crawler-server.service  # crawler 服务 systemd 配置
└── cron/
    └── crontab.txt              # 定时任务配置
```

## 部署路径

服务器上的对应路径：

| 本地文件 | 服务器路径 |
|---------|-----------|
| `nginx/enlyai.com.conf` | `/etc/nginx/conf.d/enlyai.com.conf` |
| `seo/crawler_home_zh.html` | `/var/www/enlyai.com/seo/crawler_home_zh.html` |
| `seo/crawler_home.html` | `/var/www/enlyai.com/seo/crawler_home.html` |
| `seo/lang.js` | `/var/www/enlyai-assets/lang.js` |
| `seo/robots.txt` | `/var/www/enlyai.com/robots.txt` |
| `scripts/crawler_server.py` | `/opt/enlyai/crawler_server.py` |
| `scripts/auto_submit_urls.sh` | `/opt/enlyai/auto_submit_urls.sh` |

## 关键功能

### 爬虫语言自适应
`crawler_server.py` 根据 User-Agent 判断是否为爬虫：
- **爬虫**（Baiduspider、Bingbot、Googlebot 等）→ 返回中文版，确保搜索引擎显示中文
- **浏览器** → 根据 Accept-Language 返回对应语言

### SEO 优化
- 中文版包含 2026 年 7 月最新顶级模型（Claude Sonnet 5、GPT-5.6、GLM 5.2、DeepSeek V4 等）
- og:image 完整标签（width/height/alt）
- 结构化数据（ld+json）
- 百度自动推送 JS

### URL 自动提交
`auto_submit_urls.sh` 每天 3:00 自动提交 URL 到：
- Bing IndexNow API
- Google ping sitemap
- 百度 ping RPC

## 更新模型列表

修改 `seo/crawler_home_zh.html` 和 `seo/crawler_home.html` 中的模型列表后，上传到服务器并重启 crawler 服务：

```bash
# 上传到服务器
scp seo/crawler_home_zh.html root@server:/var/www/enlyai.com/seo/
scp seo/crawler_home.html root@server:/var/www/enlyai.com/seo/

# 重启服务
systemctl restart enlyai-crawler-server
```
