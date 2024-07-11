#!/bin/bash
download_dir="$PWD"
repo_name="\""

trap clean_exit INT

responed_yes () {
    if [[ "$1" =~ ^(yes|y)$ ]]; then
        true
        return
    fi

    false
}


clean_exit () {
    echo

    read -rp "Do you want to keep the cloned repository? (y/n) " should_keep
    if responed_yes "$should_keep"; then exit "$1"; fi  # Exit immediately

    rm -rf "$download_dir/${repo_name:?}"*
    exit "$1";
}

clean_error () {
    echo
    echo "ERROR: $1"
    clean_exit 1
}


read -rp "Enter the URL of the GIT Repository: " repo_url
if [[ -z $repo_url ]]; then clean_error "Please enter a url!"; fi
echo

# Get the repo name
IFS='/' read -ra url_parts <<< "$repo_url"
repo_name="${url_parts[-1]}"

# create a tmp folder
mkdir -p "$download_dir"
cd "$download_dir" || clean_error "Could not Change Directory to \"$download_dir\"!"
if [[ $? -ne 0 ]]; then clean_exit $?; fi


# Download the bare repo
git clone --bare "$repo_url"
if [[ $? -ne 0 ]]; then clean_exit $?; fi
echo

# Enter the bare repo
cd "$download_dir/$repo_name"* || clean_error "Could not Change Directory to \"$download_dir/$repo_name\"!"
if [[ $? -ne 0 ]]; then clean_exit $?; fi

read -rp "What was the email for the old account? " old_email 
read -rp "What is the fixed email? " fixed_email
read -rp "What is the fixed username? " fixed_name
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

read -rp "Review new commit history? (y/n) " should_reveiw
echo
if responed_yes "$should_reveiw"; then
    git log
    echo
    echo
fi

read -rp "Do you want to push these changes? (y/n) " should_push
echo
if responed_yes "$should_push"; then
    git push --force --tags origin 'refs/heads/*'
    clean_exit 0
fi
