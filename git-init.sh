#!/bin/bash 
PROJ=$1
presdir=$PWD





if [ $(echo $@|wc -w) -ge 2 ];then
    echo "$0  <PROJECT> ; Takes one argument your GIT repository name";
    exit;
fi;


cd $presdir
git_refl=.elem_git_reflectors
git_host=inkiru-ds-prod1.us-central1.us.walmart.net
git_path=/app/user-data/DEV/USERS


if [ $(id|awk -F'(' '{print $2}' |awk -F')' '{print $1}') == 'jupyter' ] && [ -d /home/jupyter ]; then 
    REPO_PROJ=$HOME
    cd $REPO_PROJ
    
    if [ ! -f /home/jupyter/.git/FETCH_HEAD ];then
        if [ ! -f $HOME/.ssh/id_rsa ];then
           < /dev/zero ssh-keygen -q -N "";
        fi;
        pkey=`cat $HOME/.ssh/id_rsa.pub |awk -F'@' '{print $1}'`
        echo -e "$USERID login:"\\n
        ssh -l $USERID $git_host "echo $pkey >> .ssh/authorized_keys"
        nick=$(ssh -l $USERID $git_host ls -l /app/user-data/DEV/USERS/ |grep $USERID |awk '{print $NF}')
        git_dir=$(ssh -l $USERID $git_host grep -w GITDEV_${PROJ} .bashrc |awk -F'=' '{print $NF}')
        git_cfg_mail=$(ssh -l $USERID $git_host grep To $git_dir/git-pull.ipynb |tr '\n' ' '|awk -F"'" '{print $4}')
        REP=$USERID@$git_host:$git_path/$nick/$git_refl/$PROJ
        
        mkdir -p $HOME/.repos/.repo-$PROJ/
        
        git init
       
        git remote add origin $REP
        git config pull.rebase false
        git config --global user.name $nick
        git config --global user.email $git_cfg_mail
        git pull $REP
        DINIT=" `date +%Y-%m-%d,%H:%M:%S`"
        echo -e "##  DATE: $DINIT    UPDATE git-README.md " > git-README.md.tmp ; cat git-README.md >> git-README.md.tmp ; mv git-README.md.tmp git-README.md; 
    else
	echo "GIT already initialized";
	cat .git/FETCH_HEAD |awk '{print $NF}';
    fi;
fi;

