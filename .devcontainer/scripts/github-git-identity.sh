#!/usr/bin/env bash
# Sets git's global user.name and user.email from the GitHub account behind GITHUB_TOKEN.
#
# Runs on every attach (dc-postAttachCommand): VS Code copies the host's .gitconfig into the
# container when it attaches, which can bring a wrong identity with it, so this has to run after.
#
# The email is the account's public email if it has one, otherwise its GitHub noreply address,
# so a private address never ends up in commits. If GitHub can't be reached, the existing
# identity is left as it is.
set -u

account=$(gh api user 2>/dev/null) || { echo "git identity: GitHub not reachable; left as it is"; exit 0; }
login=$(jq -r '.login' <<<"$account")
name=$(jq -r '.name // .login' <<<"$account")
email=$(jq -r '.email // empty' <<<"$account")
if [ -z "$email" ]; then
  email=$(gh api user/emails --jq '[.[] | select(.verified and (.email | endswith("@users.noreply.github.com")))][0].email // empty' 2>/dev/null)
fi
[ -n "$email" ] || email="$(jq -r '.id' <<<"$account")+${login}@users.noreply.github.com"

git config --global user.name "$name"
git config --global user.email "$email"
echo "git identity: $name <$email>"
