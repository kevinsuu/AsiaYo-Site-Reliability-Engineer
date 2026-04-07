# 找出 words.txt 中出現最多次的單字，忽略大小寫、標點符號
import re
from collections import Counter

with open("words.txt", "r") as f:
    text = f.read().lower()

# re.findall 只抓字母，標點自動被排除
words = re.findall(r'[a-z]+', text)
counter = Counter(words)
max_count = counter.most_common(1)[0][1]

# 處理並列同頻的情況，全部輸出
for word, count in counter.most_common():
    if count < max_count:
        break
    print(f"{count} {word}")
