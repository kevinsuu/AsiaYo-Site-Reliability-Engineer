# 情境四：新服務串接 ELK/EFK

在 K8s（EKS）環境下推薦用 **DaemonSet** 架構，每台 Node 跑一個 collector（Fluentd 或 Filebeat）。K8s 會自動把所有 Pod 的 stdout 存到 Node 的固定路徑，collector 統一讀取。這樣新服務上線根本不需要動 collector 設定，直接就能收到 log。

## 串接步驟

**最重要的是統一 log 格式**，應用程式輸出 JSON 到 stdout：

```json
{"timestamp": "...", "level": "error", "service": "payment", "message": "...", "trace_id": "abc123"}
```

`trace_id` 一定要帶，跨服務追問題全靠這個串起來。格式統一是後面能有效搜尋的基礎，這步沒做好後面都是白費。

確認 collector 有設定 JSON parse，不然 `level`、`trace_id` 不會被拆成獨立欄位，在 Kibana 就沒辦法用欄位過濾，只能全文搜，很難用。

接著在 Kibana 建 Index Pattern，新服務的 log 才會出現在搜尋介面。建幾個常用的 Dashboard（Error Rate、慢請求），讓開發者不用每次都從頭寫 query，降低使用門檻。

## 幾個要注意的細節

**不能丟 log**：collector 要設 buffer，Elasticsearch 暫時掛掉時 log 先暫存，恢復後再送。

**log 裡不能有敏感資訊**，密碼、token 在 collector 這層過濾掉，不要等進了 ES 才發現。

**儲存成本**：設 Index Lifecycle Policy，舊 log 自動壓縮，超過 30 天自動刪除，不然 ES 存量會無限長大，帳單也會一起長大。

**Kibana 要設 RBAC**，開發者只能看自己服務的 log，不然大家查詢互相干擾，log 量一多很難用。
