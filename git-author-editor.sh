#!/bin/bash
tmp_dir="/$PWD/git-tmp"
function clean_exit() { rm -rf $tmp_dir; exit $1; }


read -p "Enter the URL of the GIT Repository: " repo_url
if [[ -z $repo_url ]]; then echo "ERROR: Please enter a url!"; clean_exit 1; fi
echo

# Get the repo name
IFS='/' read -ra url_parts <<< "$repo_url"
repo_name="${url_parts[-1]}"

# create a tmp folder
mkdir -p "/$PWD/git-tmp"
cd "/$PWD/git-tmp"

# Download the bare repo
git clone --bare $repo_url
if [[ $? -ne 0 ]]; then clean_exit $?; fi
echo

# Enter the bare repo
cd $tmp_dir/$repo_name*

read -p "What was the email for the old account? " old_email 
read -p "What is the fixed email? " fixed_email
read -p "What is the fixed username? " fixed_name
echo

git filter-branch --env-filter "
OLD_EMAIL=\"$old_email\"
CORRECT_NAME=\"$fixed_name\"
CORRECT_EMAIL=\"$fixed_email\"
if [ \"\$GIT_COMMITTER_EMAIL\" = \"\$OLD_EMAIL\" ]
then
    export GIT_COMMITTER_NAME=\"\$CORRECT_NAME\"
    export GIT_COMMITTER_EMAIL=\"\$CORRECT_EMAIL\"
fi
if [ \"\$GIT_AUTHOR_EMAIL\" = \"\$OLD_EMAIL\" ]
then
    export GIT_AUTHOR_NAME=\"\$CORRECT_NAME\"
    export GIT_AUTHOR_EMAIL=\"\$CORRECT_EMAIL\"
fi
" --tag-name-filter cat -- --branches --tags
if [[ $? -ne 0 ]]; then clean_exit $?; fi
echo

clean_exit 0