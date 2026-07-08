#!/bin/bash
# 每天自动提交URL到搜索引擎
LOG="/var/log/url-submit.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
KEY_FILE=$(ls /var/www/enlyai.com/seo/*.txt 2>/dev/null | head -1)
KEY=$(basename "$KEY_FILE" .txt 2>/dev/null)

echo "[$TIMESTAMP] 开始自动提交URL..." >> $LOG

if [ -n "$KEY" ]; then
    # IndexNow 提交 (Bing/Yandex)
    RESULT=$(curl -s --max-time 15 -X POST "https://api.indexnow.org/IndexNow" \
      -H "Content-Type: application/json" \
      -d "{
        \"host\": \"enlyai.com\",
        \"key\": \"$KEY\",
        \"keyLocation\": \"https://enlyai.com/$KEY.txt\",
        \"urlList\": [\"https://enlyai.com/\", \"https://enlyai.com/blog/\"]
      }")
    echo "[$TIMESTAMP] IndexNow: $RESULT" >> $LOG
fi

# Google ping sitemap
curl -s --max-time 15 "https://www.google.com/ping?sitemap=https://enlyai.com/sitemap.xml" >> $LOG 2>&1

# 百度 ping
curl -s --max-time 10 "http://ping.baidu.com/ping/RPC2" \
  -H "Content-Type: text/xml" \
  -d '<?xml version="1.0" encoding="UTF-8"?>
<methodCall><methodName>weblogUpdates.extendedPing</methodName>
<params><param><value><string>EnlyAI</string></value></param>
<param><value><string>https://enlyai.com/</string></value></param>
<param><value><string>https://enlyai.com/</string></value></param>
<param><value><string>https://enlyai.com/blog/feed.xml</string></value></param>
</params></methodCall>' >> $LOG 2>&1

echo "[$TIMESTAMP] 自动提交完成" >> $LOG