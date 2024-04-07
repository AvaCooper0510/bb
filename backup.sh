
#!/bin/sh

. /data/.env

backup_file="/backup/backup_data_$(date +%Y%m%d%H%M%S)"
tar -czvfh "$backup_file.tar.gz" -C /data .

# 加密
openssl enc -aes-256-cbc -salt -in "$backup_file.tar.gz" -out "$backup_file.enc.tar.gz" -pass pass:ff@@123456

# 删除未加密的备份文件
rm "$backup_file.tar.gz"


#


cd /backup

# 清理，避免.git越来越大
if [ -d "./.git" ]; then
  git gc
fi

if ! git lfs 2>&1 > /dev/null; then
  echo "Git LFS not installed. Please ensure it is installed and try again."
  exit 1
fi

if [ ! -d "./.git" ]; then
  git init
  git lfs install
  git config user.name "$GIT_USERNAME"
  git config user.email "$GIT_EMAIL"
  git remote add origin "$GIT_REPO"

  # Github限制100m文件，文件用lfs传
  git config http.postBuffer 524288000
  git lfs track "*.tar.gz"
  echo "*.tar.gz filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
fi

git branch --show-current | grep -q '^main$' || git branch -m master main
git fetch --depth 1
git branch -u origin/main main 2>/dev/null || git push --set-upstream origin main
git reset --hard origin/main
echo "$(date)" > README.md
git add -A
git commit -m "Automated backup $(date)"
git push --force -u origin main
