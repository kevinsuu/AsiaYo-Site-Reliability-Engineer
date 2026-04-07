# 情境二：API 集群單台機器回應逾時

只有一台異常，代表問題在這台機器本身，不是程式版本或架構的問題。

## 先止血

如果這台已經影響用戶，先從 Load Balancer 移除（Drain），讓其他機器接流量再慢慢查。這步很重要，不要急著重啟，重啟之後 log 和 metrics 就不好追了。

## 系統資源檢查

登入機器，從淺到深逐一確認：

```bash
top -bn1 | head -20        # CPU 被打滿了嗎
free -m                     # 記憶體不足在 swap 嗎
df -h                       # 磁碟寫滿了嗎（log、tmp 最常見）
iostat -x 1 5               # 磁碟 I/O 有異常等待嗎
ss -s                       # 大量 TIME_WAIT 或連線堆積
dmesg | tail -50            # OOM killer 有沒有出手過
```

再看應用層的 log，有沒有大量 timeout 或 exception，確認 DB / Redis connection pool 有沒有耗盡。

## 跟正常機器做差異比較

只有一台異常，一定有某個地方不一樣，這步通常能直接找到根因：

- 部署版本是否一致（image tag / commit hash）
- 設定檔是否有差異
- 這台在哪個 AZ，該 AZ 是否有問題
- Instance 規格是否一致（換機器時有時候用了不同 type）
- 有沒有 Noisy Neighbor 問題（AWS 層面 CPU credit 或 bandwidth throttling）

## 進階排查

如果上面都沒找到，用 `tcpdump` 抓包看有沒有異常的 TCP Retransmission，或是用 `strace` 追 system call 的延遲在哪。Go 服務可以接 pprof 看 goroutine 狀態。

## 根因修復後

修完之後把機器加回 Load Balancer，持續觀察幾分鐘確認恢復正常。事後補對應的監控告警，並設定健康檢查讓 Load Balancer 能自動移除不健康的節點，下次就不用等人發現再手動處理了。
