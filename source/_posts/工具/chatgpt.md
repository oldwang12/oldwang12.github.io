---
layout: 工具
title: chatgpt
date: 2023-07-28 11:00:52
tags: 工具
categories: 工具
---

#### 测试 key
```sh
curl https://api.openai.com/v1/chat/completions \
-H "Content-Type: application/json"  \
-H "Authorization: Bearer $1"  \
-d '{
    "model": "gpt-3.5-turbo", 
    "messages": [
        {
            "role": "user", 
            "content": "Hello!"
        }
    ]
}'
```