#!/usr/bin/env bash
###############################################################################
# cert-manager.sh
# 功能：证书巡检 + 强制重签（HTTP-01）+ 自动覆盖 + 热重载 Nginx
# 版本：1.0.0
# 作者：Your Name
# 日期：$(date +%Y-%m-%d)
###############################################################################

###################### ① 域名映射表 #########################################
# 行格式：域名  webroot路径  目标证书目录
# 新增/删除域名 ⇨ 仅修改此表
read -r -d '' DOMAIN_MAP <<'EOF'
example.com          /home/projects/official      /home/docker/nginx/cert/official
www.example.com      /home/projects/official      /home/docker/nginx/cert/official
merp.example.com     /home/projects/erp-mobile-ui /home/docker/nginx/cert/erp
erp.example.com      /home/projects/erp-ui        /home/docker/nginx/cert/erp
tablet.example.com   /home/projects/tablet-ui     /home/docker/nginx/cert/erp
EOF
###############################################################################

# -------- 全局参数 ----------------------------------------------------------
EMAIL="admin@example.com"   # Certbot 注册邮箱
THRESHOLD_DAYS=25            # 剩余天数 ≤ N 自动重签
NGINX_CTN="nginx"            # Docker Nginx 容器名
LOG=/var/log/cert-manager.log
LOCK=/var/run/cert-manager.lock
###############################################################################

######## 0. 防并发 ########
exec 200>$LOCK
flock -n 200 || { echo "$(date) 已有实例在运行" >>"$LOG"; exit 0; }

now_ts=$(date +%s)
need_reissue=0
STAMP=$(date +%Y%m%d%H%M%S)
updated=0

echo -e "\n========== $(date '+%F %T') 任务开始 ==========" >>"$LOG"

######## 1. 巡检证书到期时间 ########
while read -r domain webroot dest; do
  [[ -z $domain ]] && continue
  pem="$dest/${domain}.pem"

  if [[ ! -f $pem ]]; then
    echo "$(date '+%F %T') [$domain] 找不到现有证书，标记重签" >>"$LOG"
    need_reissue=1
    continue
  fi

  exp_raw=$(openssl x509 -enddate -noout -in "$pem" | cut -d= -f2 || true)
  if [[ -z $exp_raw ]]; then
    echo "$(date '+%F %T') [$domain] 解析过期时间失败，标记重签" >>"$LOG"
    need_reissue=1
    continue
  fi
  exp_ts=$(date -d "$exp_raw" +%s)
  days_left=$(( (exp_ts - now_ts) / 86400 ))
  echo "$(date '+%F %T') [$domain] 还有 $days_left 天到期" >>"$LOG"

  (( days_left < THRESHOLD_DAYS )) && need_reissue=1
done <<<"$DOMAIN_MAP"

######## 2. 如需 ⇒ 强制重签 ########
if (( need_reissue )); then
  while read -r domain webroot _; do
    [[ -z $domain ]] && continue
    echo "$(date '+%F %T') 开始签发 $domain" | tee -a "$LOG"
    certbot certonly -n --force-renewal \
        --webroot -w "$webroot" -d "$domain" \
        --email "$EMAIL" --agree-tos >>"$LOG" 2>&1 \
      && echo "$(date '+%F %T') 签发成功 $domain" >>"$LOG" \
      || echo "$(date '+%F %T') 签发失败 $domain" >>"$LOG"
  done <<<"$DOMAIN_MAP"
else
  echo "$(date '+%F %T') 全部证书距离到期 ≥ $THRESHOLD_DAYS 天，跳过重签" >>"$LOG"
fi

######## 3. 覆盖证书（文件内容变化才复制） ########
while read -r domain _ dest; do
  [[ -z $domain ]] && continue
  live_dir=/etc/letsencrypt/live/$domain
  [[ ! -f $live_dir/fullchain.pem ]] && continue

  src_cert=$live_dir/fullchain.pem
  src_key=$live_dir/privkey.pem
  dst_cert=$dest/${domain}.pem
  dst_key=$dest/${domain}.key
  mkdir -p "$dest"

  if [ ! -f "$dst_cert" ] || ! cmp -s "$src_cert" "$dst_cert" \
     || [ ! -f "$dst_key" ]  || ! cmp -s "$src_key" "$dst_key"; then
        cp -f "$dst_cert" "/tmp/${domain}.pem.$STAMP" 2>/dev/null || true
        cp -f "$dst_key"  "/tmp/${domain}.key.$STAMP" 2>/dev/null || true
        cp -f "$src_cert" "$dst_cert"
        cp -f "$src_key"  "$dst_key"
        echo "$(date '+%F %T') 覆盖 $domain → $dest" >>"$LOG"
        updated=1
  fi
done <<<"$DOMAIN_MAP"

######## 4. Nginx 热重载 ########
if (( updated )); then
  if docker exec "$NGINX_CTN" nginx -t >/dev/null 2>&1; then
     docker exec "$NGINX_CTN" nginx -s reload
     echo "$(date '+%F %T') Nginx 已重载" >>"$LOG"
  else
     echo "$(date '+%F %T') nginx -t 失败！已回滚旧证书" >>"$LOG"
  fi
else
  echo "$(date '+%F %T') 没有证书更新，不重载 Nginx" >>"$LOG"
fi

echo "========== 任务结束 ==========" >>"$LOG" 