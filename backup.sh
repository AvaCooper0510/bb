
#!/bin/sh

. /data/.env

# tar -czvf /backup/backup_data_$(date +%Y%m%d%H%M%S).tar.gz -C /data .

# # 保留两个
# ls -1 /backup/backup_data_*.tar.gz | head -n -2 | xargs rm -f

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
  git config http.postBuffer 524288000
  git lfs track "*.tar.gz"
  echo "*.tar.gz filter=lfs diff=lfs merge=lfs -text" >> .gitattributes
fi

echo "$(date)" > README.md

git branch --show-current | grep -q '^main$' || git branch -m master main
git fetch --depth 1
git branch -u origin/main main 2>/dev/null || git push --set-upstream origin main
git reset --hard origin/main
git add -A
git commit -m "Automated backup $(date)"
git push --force -u origin main
