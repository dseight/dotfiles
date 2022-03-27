# Git abbreviations (mostly from Oh-My-Zsh git plugin)

if status is-interactive
    abbr -a -g g git

    abbr -a -g ga git add
    abbr -a -g gap git add -p

    abbr -a -g gc git commit -v
    abbr -a -g gca git commit -v --amend

    abbr -a -g gco git checkout

    abbr -a -g gd git diff
    abbr -a -g gds git diff --staged
    abbr -a -g gdw git diff --word-diff

    abbr -a -g gf git fetch
    abbr -a -g gfa git fetch --all --prune
    abbr -a -g gfo git fetch origin

    abbr -a -g glp git log --patch-with-stat
    abbr -a -g glg git log --graph
    abbr -a -g glo git log --oneline --decorate
    abbr -a -g glog git log --oneline --decorate --graph
    abbr -a -g gloga git log --oneline --decorate --graph --all

    abbr -a -g gm git merge
    abbr -a -g gma git merge --abort

    abbr -a -g gp git push
    abbr -a -g gpd git push --dry-run
    abbr -a -g gpf git push --force-with-lease
    abbr -a -g gpff git push --force

    abbr -a -g gr git remote
    abbr -a -g gra git remote add
    abbr -a -g grmv git remote rename
    abbr -a -g grrm git remote remove
    abbr -a -g grset git remote set-url

    abbr -a -g grb git rebase
    abbr -a -g grba git rebase --abort
    abbr -a -g grbc git rebase --continue
    abbr -a -g grbi git rebase -i
    abbr -a -g grbs git rebase --skip

    abbr -a -g grm git rm
    abbr -a -g grmc git rm --cached

    abbr -a -g gre git reset
    abbr -a -g greh git reset --hard

    abbr -a -g gss git status --short
end
