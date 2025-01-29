# route53 ddns update script

Amazon Route53 を DDNSサーバーとし、動的IPを更新するスクリプト

# 前提条件

1. aws cliがインストールされていること
2. aws cliを利用するために最小限の権限を持ったユーザが作成されていること（後述）
3. aws cli に [2.]のキーにてアクセスが可能であること
4. AWS の Route53にホストゾーンが登録されていること

# ロール

ホストゾーンのARNを指定して権限を縛るとよい。

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
```

