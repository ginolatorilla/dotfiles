if status --is-interactive
    set --global fish_user_abbreviations

    abbr --add gs git status
    abbr --add gss git status --short --branch

    abbr --add gl git log
    abbr --add glo git log --graph --oneline
    abbr --add glop git log --graph --oneline --patch

    abbr --add ga git add
    abbr --add gaa git add --all
    abbr --add gap git add --patch
    abbr --add gau git add --update

    abbr --add gr git reset
    abbr --add grp git reset --patch
    abbr --add grc git reset --soft HEAD~1
    abbr --add grch git reset --hard HEAD~1

    abbr --add gci git commit
    abbr --add gcm git commit --message
    abbr --add gca git commit --amend
    abbr --add gcaa git commit --amend --no-edit

    abbr --add gco git checkout
    abbr --add gcof git checkout --force

    abbr --add gcl git clone
    abbr --add gclr git clone --recursive

    abbr --add gb git branch
    abbr --add gba git branch --all
    abbr --add gbd git branch --delete
    abbr --add gbm git branch --move

    abbr --add grb git rebase
    abbr --add grba git rebase --abort
    abbr --add grbc git rebase --continue
    abbr --add grbs git rebase --skip
    abbr --add grbi git rebase --interactive

    abbr --add gm git merge --no-ff
    abbr --add gf git fetch
    abbr --add gpu git pull --ff-only
    abbr --add gpr git pull --rebase
    abbr --add gps git push
    abbr --add gpsf git push --force

    abbr --add gcp git cherry-pick
    abbr --add gcpc git cherry-pick --continue
    abbr --add gcpa git cherry-pick --abort
    abbr --add gcpq git cherry-pick --quit
end