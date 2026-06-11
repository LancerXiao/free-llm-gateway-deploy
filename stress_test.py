#!/usr/bin/env python3
"""enlyai-chat 压力测试脚本 (基于 requests + ThreadPoolExecutor)"""
import requests
import time
import json
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

API_URL = "https://api.enlyai.com/v1/chat/completions"
API_KEY = "sk-scz5ymhelfKbuckZK04znfZmtrjKrOtIMDT6j8NLcL3rq1qM"
TOTAL_REQUESTS = int(sys.argv[1]) if len(sys.argv) > 1 else 50
CONCURRENT = int(sys.argv[2]) if len(sys.argv) > 2 else 10

def send_request(req_id):
    """发送单个请求"""
    payload = {
        "model": "enlyai-chat",
        "messages": [{"role": "user", "content": f"Say hello and tell me a fun fact. Request #{req_id}"}],
        "max_tokens": 50
    }
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    start = time.time()
    try:
        r = requests.post(API_URL, json=payload, headers=headers, timeout=60)
        elapsed = time.time() - start
        data = r.json()
        if r.status_code != 200:
            error = json.dumps(data, ensure_ascii=False)[:150]
            return {"id": req_id, "status": "FAIL", "time": elapsed, "error": f"HTTP {r.status_code}: {error}"}
        choices = data.get("choices")
        try:
            if choices and isinstance(choices, list) and len(choices) > 0:
                msg = choices[0].get("message") if isinstance(choices[0], dict) else None
                content = (msg.get("content", "") or "")[:60] if msg else ""
                model = data.get("model", "?")
                if content:
                    return {"id": req_id, "status": "OK", "time": elapsed, "model": model, "content": content}
                else:
                    return {"id": req_id, "status": "OK", "time": elapsed, "model": model, "content": "(empty)"}
        except (TypeError, KeyError, IndexError):
            pass
        error = json.dumps(data, ensure_ascii=False)[:200]
        return {"id": req_id, "status": "FAIL", "time": elapsed, "error": f"Bad response: {error}"}
    except requests.Timeout:
        elapsed = time.time() - start
        return {"id": req_id, "status": "TIMEOUT", "time": elapsed, "error": "requests.Timeout"}
    except Exception as e:
        elapsed = time.time() - start
        import traceback
        return {"id": req_id, "status": "ERROR", "time": elapsed, "error": f"{type(e).__name__}: {str(e)[:120]}", "traceback": traceback.format_exc()[:200]}

def run_stress_test():
    """执行压力测试"""
    print(f"=== enlyai-chat 压力测试 ===")
    print(f"总请求: {TOTAL_REQUESTS}, 并发数: {CONCURRENT}")
    print(f"API URL: {API_URL}")
    print()

    results = []
    start_time = time.time()

    with ThreadPoolExecutor(max_workers=CONCURRENT) as executor:
        futures = {executor.submit(send_request, i): i for i in range(TOTAL_REQUESTS)}
        for future in as_completed(futures):
            r = future.result()
            results.append(r)
            if r["status"] == "OK":
                print(f"  #{r['id']:3d} OK  {r['time']:.2f}s  model={r['model'][:30]}  content={r['content'][:40]}")
            else:
                print(f"  #{r['id']:3d} {r['status']}  {r['time']:.2f}s  error={r.get('error','')[:80]}")
                if r.get('traceback'):
                    print(f"         TB: {r['traceback'][:150]}")

    total_time = time.time() - start_time

    # 按 ID 排序
    results.sort(key=lambda x: x["id"])

    # 统计
    ok_count = sum(1 for r in results if r["status"] == "OK")
    fail_count = sum(1 for r in results if r["status"] == "FAIL")
    timeout_count = sum(1 for r in results if r["status"] == "TIMEOUT")
    error_count = sum(1 for r in results if r["status"] == "ERROR")
    ok_times = [r["time"] for r in results if r["status"] == "OK"]

    print()
    print("=" * 60)
    print(f"总耗时: {total_time:.2f}s")
    print(f"成功率: {ok_count}/{TOTAL_REQUESTS} ({ok_count/TOTAL_REQUESTS*100:.1f}%)")
    print(f"失败: {fail_count}, 超时: {timeout_count}, 错误: {error_count}")

    if ok_times:
        ok_times.sort()
        p50 = ok_times[len(ok_times)//2]
        p90 = ok_times[int(len(ok_times)*0.9)]
        print(f"响应时间 - 平均: {sum(ok_times)/len(ok_times):.2f}s, P50: {p50:.2f}s, P90: {p90:.2f}s, 最小: {min(ok_times):.2f}s, 最大: {max(ok_times):.2f}s")

    # 模型分布
    model_counts = {}
    for r in results:
        if r["status"] == "OK":
            m = r.get("model", "unknown")
            model_counts[m] = model_counts.get(m, 0) + 1
    if model_counts:
        print(f"\n模型路由分布:")
        for m, c in sorted(model_counts.items(), key=lambda x: -x[1]):
            print(f"  {m}: {c} 次 ({c/ok_count*100:.1f}%)")

    # 失败详情
    if fail_count + timeout_count + error_count > 0:
        print(f"\n失败详情:")
        for r in results:
            if r["status"] != "OK":
                print(f"  #{r['id']} {r['status']}: {r.get('error','')[:120]}")

if __name__ == "__main__":
    run_stress_test()
