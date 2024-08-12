#!/usr/bin/env fish

mkdir -p $HOME/git/private

cd $HOME/git/private

git config user.name "Lucas"
git config user.email "keyruu@web.de"

privateRepos = (
  "nexcalimat"
  "traversetown"
  "traversetown-htmx"
  "oblivion"
  "buymeaspezi"
)

for repo in $privateRepos
  git clone git@github.com:keyruu/$repo.git
end

