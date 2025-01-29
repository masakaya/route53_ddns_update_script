#!/bin/bash

# 設定
ZONE_NAME="yourdomain.com."  # ゾーン名を指定（末尾にドットを付ける）

# 現在のIPアドレスを取得
CURRENT_IP=$(curl -s http://checkip.amazonaws.com)

# ゾーン名からホストゾーンIDを取得
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name == '$ZONE_NAME'].Id" --output text | cut -d'/' -f3)

# ゾーン名からAレコードを取得
RECORD_NAME="$ZONE_NAME"  # Aレコード名はゾーン名と同じ
EXISTING_IP=$(aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --query "ResourceRecordSets[?Name == '$RECORD_NAME'].ResourceRecords[0].Value" --output text | awk '{print $1}')

# Aレコードが存在しない場合、新規作成
if [ -z "$EXISTING_IP" ]; then
    # Aレコードを新規作成
    CHANGE_BATCH=$(jq -n --arg name "$RECORD_NAME" --arg ip "$CURRENT_IP" '{
      Comment: "Create A record with current IP",
      Changes: [
        {
          Action: "CREATE",
          ResourceRecordSet: {
            Name: $name,
            Type: "A",
            TTL: 300,
            ResourceRecords: [{ Value: $ip }]
          }
        }
      ]
    }')

    # Aレコードを作成
    aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch "$CHANGE_BATCH"

    # ログ出力
    echo "$(date): Aレコードを新規作成しました。IP: $CURRENT_IP" >> update.log

# IPアドレスが変わった場合のみ更新
elif [ "$CURRENT_IP" != "$EXISTING_IP" ]; then
    # Aレコードを更新
    CHANGE_BATCH=$(jq -n --arg name "$RECORD_NAME" --arg ip "$CURRENT_IP" '{
      Comment: "Update A record to new IP",
      Changes: [
        {
          Action: "UPSERT",
          ResourceRecordSet: {
            Name: $name,
            Type: "A",
            TTL: 300,
            ResourceRecords: [{ Value: $ip }]
          }
        }
      ]
    }')

    # Aレコードを変更
    aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch "$CHANGE_BATCH"

    # ログ出力
    echo "$(date): Aレコードを更新しました。新しいIP: $CURRENT_IP" >> update.log
else
    echo "IPアドレスは変更されていません。"
fi
