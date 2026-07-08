#!/usr/bin/env python3
import http.server
import socketserver
import os

ZH_FILE = '/var/www/enlyai.com/seo/crawler_home_zh.html'
EN_FILE = '/var/www/enlyai.com/seo/crawler_home.html'

# 已知爬虫 User-Agent 关键词
SPIDER_KEYWORDS = [
    'spider', 'bot', 'crawler', 'slurp', 'archiver',
    'feed', 'fetcher', 'monitor', 'scan', 'linkcheck',
    'preview', 'renderer'
]

class CrawlerHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        ua = self.headers.get('User-Agent', '').lower()
        accept_lang = self.headers.get('Accept-Language', '').lower()

        # 判断是否是爬虫
        is_spider = any(kw in ua for kw in SPIDER_KEYWORDS)
        # 判断是否明确请求英文
        is_en = accept_lang.startswith('en') and 'zh' not in accept_lang

        # 逻辑：爬虫→中文（搜索引擎显示中文）；浏览器：英文Accept→英文，其他→中文
        if is_spider:
            filepath = ZH_FILE
        elif is_en:
            filepath = EN_FILE
        else:
            filepath = ZH_FILE

        if not os.path.exists(filepath):
            filepath = EN_FILE if os.path.exists(EN_FILE) else ZH_FILE

        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Vary', 'Accept-Language')
        self.end_headers()
        with open(filepath, 'rb') as f:
            self.wfile.write(f.read())

    def log_message(self, format, *args):
        pass

server = socketserver.TCPServer(('127.0.0.1', 8902), CrawlerHandler)
server.serve_forever()