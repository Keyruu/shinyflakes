#!/usr/bin/env fish

mkdir -p $HOME/git/private

cd $HOME/git/private

set privateRepos "nexcalimat" "traversetown" "traversetown-htmx" "oblivion" "buymeaspezi" "tabula"

for repo in $privateRepos
  git clone git@github.com:keyruu/$repo.git
end

