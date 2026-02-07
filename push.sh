git add .
echo 'commit-msg: '
read commitMsg
git commit -m "$commitMsg"
git push -u origin main
