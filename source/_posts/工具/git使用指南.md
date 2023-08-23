---
layout: 工具
title: git使用指南
date: 2023-08-16 10:36:30
tags: [工具,git]
categories: 工具
---

{% note primary%}

git 不仅仅是 pull 和 push。

{% endnote %}


<!-- more -->

## 1. 一键提交当前分支
```sh
git add .;git commit -m "test";git push origin $(git symbolic-ref --short HEAD)
```

## 2. 删除分支

```sh
# 删除本地分支
git branch -D xxx

# 删除远程分支
git push origin --delete xxx
```

## 3. 开发分支落后时，如何同步 master 分支。
```sh
# 1. 获取master分支的最新变更。可以使用以下命令来更新您本地的master分支
git checkout master
git pull origin master

# 2. 切换回开发分支，并将master分支的变更合并到开发分支上：
git checkout feature/test
git merge master

# 3. 如果有冲突出现，您需要解决这些冲突后再提交变更。

# 4. 推送开发分支到远程仓库
git push origin feature/test
```

## 4. git reset

放弃所有更改并回到上一次提交的状态：
```sh
git reset --hard HEAD^
```
{% note warning%}
这将删除所有的未提交更改，将HEAD指向父提交，并将工作区和暂存区恢复到上一次提交的状态。
{% endnote %}

保留更改但将其从暂存区中移除：
```sh
git reset HEAD
```

这将将所有已暂存的更改重置，但保留在工作区中，这样你就可以重新提交或进行进一步的更改。


{% note warning%}
请注意，git reset 是一个潜在的危险操作，因为它会从版本历史中移除提交。在执行这些命令之前，请确保你理解这些操作的副作用，并且在对你的代码产生重大影响之前，最好进行备份或咨询团队中的其他成员。
{% endnote %}


curl 'https://api.ucloud.cn/?Action=GetUK8SAvailablePHostList' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: zh-CN,zh;q=0.9' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'Cookie: das_session=adfd8fd1-b606-4585-98c3-5c9750e47a4d; gr_user_id=c1482fd8-2d70-41d3-ae84-2a09ba4a0e5d; Feedback_ID=98; SurveyCookieTest=1; c_project_lee_wang_ucloud_cn=%7B%22ProjectId%22%3A%22org-f4ncln%22%2C%22ProjectName%22%3A%22%E7%8E%8B%E9%9B%84%22%7D; _ga=GA1.1.101168770.1690783229; _ga_DZSMXQ3P9N=GS1.1.1690783228.1.1.1690783294.0.0.0; Hm_lvt_413fdc5943040809ed0703eabd01f173=1691809812,1692065605,1692502931,1692584368; U_CHANNEL_ID=1; c_region_806459794_qq_com=%7B%22Zone%22%3A%22cn-sh2-01%22%2C%22Region%22%3A%22cn-sh2%22%7D; c_last_region_806459794_qq_com=%7B%22region%22%3A%22cn-sh2%22%2C%22zone%22%3A%22cn-sh2-01%22%7D; U_USER_EMAIL=lee.wang%40ucloud.cn; U_COMPANY_ID=65906048; U_USER_ID=150829537; U_MANAGER=janey.deng%40ucloud.cn; hb_MA-B701-2FC93ACD9328_source=mail.qiye.163.com; U_JWT_TOKEN=eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTI3MTkzNjgsImp0aSI6IkF1NTNOMkpya2xYRU5mZ2ZKSFR6UTQiLCJpYXQiOjE2OTI2NzYxNjgsInN1YiI6InVjczppYW06OjY1OTA2MDQ4OnVzZXIvMTUwODI5NTM3In0.ZRlNLSnGw3tNae6PRdvuiDE6HKWHaANKrnrf1TqrVadMh2ERkALvGwJaXJR0lG_IrjGYSi0cDopOYHv0brmllQ; U_CSRF_TOKEN=227126c8c8ef8ebe49a383472a03cc65; gr_session_id_6b767e7fa13640a48f97e18e8045c9dc=4e5035dc-b5fe-454c-8fc8-d50642a4acbe; gr_cs1_4e5035dc-b5fe-454c-8fc8-d50642a4acbe=U_USER_ID%3A150829537; gr_session_id_6b767e7fa13640a48f97e18e8045c9dc_4e5035dc-b5fe-454c-8fc8-d50642a4acbe=true; Hm_lpvt_413fdc5943040809ed0703eabd01f173=1692693583; c_last_region_lee_wang_ucloud_cn=%7B%22region%22%3A%22cn-sh2%22%2C%22zone%22%3A%22cn-sh2-01%22%7D; c_region_lee_wang_ucloud_cn=%7B%22Zone%22%3A%22%24%22%2C%22Region%22%3A%22cn-sh2%22%7D' \
  -H 'Origin: https://console.ucloud.cn' \
  -H 'Referer: https://console.ucloud.cn/uk8s/detail/Node/uk8s-mr5q77pbzbg?clusterName=UKubernetes' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-site' \
  -H 'U-CSRF-Token: 227126c8c8ef8ebe49a383472a03cc65' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36' \
  -H 'sec-ch-ua: "Not/A)Brand";v="99", "Google Chrome";v="115", "Chromium";v="115"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  --data-raw 'Action=GetUK8SAvailablePHostList&Region=cn-sh2&Zone=cn-sh2-01&ProjectId=org-f4ncln&ClusterId=uk8s-mr5q77pbzbg&Offset=0&Limit=100&user_email=lee.wang@ucloud.cn' \
  --compressed