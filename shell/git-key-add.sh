eval "$(ssh-agent -s)"
ssh-add ~/.ssh/$KEYFILENAME
ssh -Tv git@github.com
