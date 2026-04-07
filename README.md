# AsiaYo SRE 前測作答

蘇銘凱 / Mid-Senior Site Reliability Engineer

## 專案結構

```
question1/          Python 腳本找最高頻單字
question2/
  terraform/        EKS cluster (Terraform)
  k8s-manifests/    K8s 應用程式 manifest
question3/          SQL 查詢
scenario/           情境實戰 (Markdown)
```

## 題目一

```bash
cd question1 && python3 find_most_frequent.py
# 輸出: 4 twinkle
```

用 regex 去除標點、Counter 統計頻率，忽略大小寫。有處理多個單字同頻的情況。

## 題目二

**Terraform** — VPC 跨 3 AZ + EKS managed node group + IRSA + gp3 StorageClass

**K8s Manifest** — 對應架構圖的所有元件：
- MySQL StatefulSet (讀寫分離，GTID replication)
- App Deployment (3 副本, Anti-Affinity, HPA)
- Ingress (TLS + cert-manager)
- PDB, ServiceAccount (IRSA), PVC

高可用考量：multi-AZ、Pod 分散節點、HPA 自動擴縮、PDB 保障 drain 時可用數。
App 走 stateless 設計 (檔案存取用 S3)，PVC 保留但不掛載 (EBS RWO 限制，詳見 app-pvc.yaml 註解)。

## 題目三

提供 DENSE_RANK 和 LIMIT OFFSET 兩種解法。用 DENSE_RANK 處理並列不跳號，第二名 John 在 A 班。

## 情境題

- `scenario1.md` — 百倍流量：事前壓測 + 預擴容 + CDN + Redis + SQS 削峰
- `scenario2.md` — 單台逾時：先 drain 再查，和正常機器做差異比較
- `scenario3.md` — SSH 掛掉：SSM Session Manager 優先，最後手段 EBS detach
- `scenario4.md` — ELK 串接：DaemonSet collector + JSON 結構化日誌 + trace_id
