# 情境三：EC2 無法 SSH 登入

服務還活著代表機器沒掛，問題是 SSH 這條路不通。思路是先換條路進去，再來查為什麼 SSH 不行。

## 先換條路進機器

**第一選擇是 SSM Session Manager**，不走 SSH port，只要機器有裝 SSM Agent 且 IAM Role 正確就能連：

```bash
aws ssm start-session --target i-xxxxxxxxxxxx
```

SSM 進不去的話，用 **EC2 Serial Console**（AWS Console 開），連系統快掛掉的狀態也能看到 login prompt 並互動。

進去之前先在 AWS Console 截 Instance Screenshot、看 System Log，保留現場，之後查根因用得到。

## 可能的原因

**最常見的是磁碟或 inode 滿了**，`/var/log` 沒設 rotation，sshd 建立 session 需要寫檔案，空間滿就失敗了：

```bash
df -h    # 磁碟空間
df -i    # inode 使用量（空間有餘但 inode 滿也會出問題）
```

其他常見原因：
- sshd 程序掛掉 → `systemctl status sshd`
- `authorized_keys` 權限被改掉（需 600，`.ssh` 目錄需 700）
- 記憶體耗盡，系統無法 fork 新 process
- `sshd_config` 被改過（Port、AllowUsers 等設定異動）
- `/etc/nologin` 存在，非 root 用戶無法登入

## 修復方式

進去之後確認根因，修復後確認 SSH 可以正常登入。

如果 SSM 也沒辦法互動（資源耗盡），用 **SSM Run Command** 直接對機器下指令，不需要互動式連線。

萬不得已才走 **EBS detach**：先從 Load Balancer 移除這台 → Stop instance（注意不是 Terminate）→ Detach root volume → Attach 到另一台正常機器 → 直接修設定或清空間 → 掛回去重啟 → 加回 Load Balancer。

如果不想停機，也可以從最新 AMI 直接開一台新的，設定確認正確後加入 Load Balancer，舊機器再移除，舊機器先保留一段時間供事後查因。

## 預防

所有 EC2 都要裝 SSM Agent，這次就靠它進去，SSH 掛掉才有備案。磁碟空間設 CloudWatch 告警（80% 就通知），Log Rotation 要設好，定期建 AMI 確保可以快速重建。
