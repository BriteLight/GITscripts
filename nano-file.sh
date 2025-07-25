#!/bin/bash 
ins=$@
presdir=$PWD
function timestamp(){ /usr/bin/ls -lr --time-style=full-iso $1 |awk '{print $6","$7}'; }
function cksum { /usr/bin/md5sum $1 |awk '{print $1}'; }
function cksumipynb() { cat $1  |jq '.cells[] | select(.cell_type == "code") .source[] '  |tr '\n' '~'  |rev |sed -e 's/"n\\//' |rev |sed -e 's/"//' -e 's/\\n"~"/\n/g' -e 's/\\n"~/\n/g'  -e 's/\\\\/\\/g' -e 's/\\"/"/g' |tr '~' '\n'  |/usr/bin/md5sum |awk '{print $1}'; }
homer=`echo $HOME/.repos/.repo-|tr '/' '#'`
nano=/usr/bin/vim
file_list=`echo $ins|awk '{$NF=""}1'`
PROJ=`echo $ins|awk '{print $NF}' |sed -e 's/\// /g'|awk '{print $NF}'`
RAWPROJ=`echo $ins|awk '{print $NF}'`
if [[ ($PROJ == '.') || ($PROJ == '..') || ($RAWPROJ == '.') || ($RAWPROJ == '..') ]];then
    PROJ=`echo $ins|awk '{print $NF}' |awk -F'/' '{$NF=""}1'|awk '{print $NF}'`;
elif [[ ( -z $PROJ ) || ("$PROJ" != "`echo $PROJ`") || ("$file_list" == "") ]];then
    echo "$0  <file> [<file-2> <file-3> .. <file-n>] <PROJECT> ; Takes minimum of two arguments, file(s) and PROJECT name as the last argument. PROJECT can be a path to the project folder";
    exit;
fi;


if [ -z `env|grep -w GITDEV_$PROJ|awk -F'=' '{print $2}'` ];then
    LEDPROJ=`echo $RAWPROJ|awk -F'/' '{print $1}'`;
    if [[ ($LEDPROJ == '') ]];then
        PARPROJ=`echo $RAWPROJ|awk -F"/$PROJ" '{$NF=""}1'|sed -e "s/ /\/$PROJ/g" |awk -F'/' '{$NF=""}1'|sed -e "s/ /\//g"`;
    else
        PARPROJ=`echo $presdir/$RAWPROJ|awk -F"/$PROJ" '{$NF=""}1'|sed -e "s/ /\/$PROJ/g" |awk -F'/' '{$NF=""}1'|sed -e "s/ /\//g"`;
    fi;
    REPO_PROJ=$PARPROJ$PROJ
else
    REPO_PROJ=`env|grep -w GITDEV_$PROJ|awk -F'=' '{print $2}'`
fi;

REPO_PROJ=$(echo $REPO_PROJ/$PROJ |sed -e "s/$PROJ\/$PROJ/$PROJ/")

. $HOME/.bashrc
cd $presdir
unalias -a

if [ $HOME == /home/jupyter ];then
    if [ -f $HOME/git-add.sh ];then
        $HOME/git-add.sh $file_list
        exit;
    elif [ -f /data/git-add.sh ];then
        /data/git-add.sh
        exit;
    else
        echo "No available git-add.sh script. Exiting"
        exit;
    fi;
fi;


if [ ! -d $GITREF/$PROJ ] && [ $HOSTNAME == inkiru-ds-prod1 ];then
  GITDEV=$PARPROJ
  if [ -e $PROJ ];then
     mkdir $GITDEV/$PROJ
     exit;
  fi;
  mkdir $GITDEV/$PROJ
  mkdir $GITREF/$PROJ
  cd $GITREF/$PROJ
  git init --bare
  REPO_PROJ=$GITDEV$PROJ
  repoj=`echo $REPO_PROJ |tr '/' '#'`
  GITDEVPROJ=`echo $REPO_PROJ |sed -e 's/\//%/g'`
  REF=`echo $USER@$CDC_LOCALHOST:$GITREF/$PROJ |sed -e 's/\//%/g'`
  cd $REPO_PROJ
  git clone git@inkiru-ds-prod1.us-central1.us.walmart.net:/app/user-data/home/GIT-REPOs/git-scripts/git.git GITscripts
  cp -p GITscripts/git-add.sh .
  sed -e "s/PROJ/$PROJ/" -e "s/GITDEV/$GITDEVPROJ/" -e "s/GITREF/$REF/" -e 's/%/\//g' GITscripts/git-README.md > git-README.md
  sed -e "s/UUUUUUU/$USER/g" -e "s/NNNNNNN/$NAME/g" -e "s/FFF.LLL/$EMAIL/g" -e "s/RRRRR/$repoj/g" -e "s/#/\//g" -e "s/PPPP/$PROJ/g" GITscripts/git-pull.ipynb > git-pull.ipynb
  git init
  git remote add origin $USER@$CDC_LOCALHOST:$GITREF/$PROJ
  echo -e "export GITREF_$PROJ=$GITREF/$PROJ" >> $HOME/.bashrc
  echo -e "export GITDEV_$PROJ=$REPO_PROJ"    >> $HOME/.bashrc;
  proj_hub=`echo $PROJ|tr '[:upper:]'  '[:lower:]'`
  ssh-keygen -q -N "" -f $HOME/.ssh/id_${proj_hub}_rsa
  echo -e "Copy-n-Paste public into gecgithub01.walmart.com/$USER/$PROJ\\n\\n`cat $HOME/.ssh/id_${proj_hub}_rsa.pub`\\n\\n"
  echo -n "<return>"
  read holdup 
  echo -e \\n"Host $proj_hub\\n  Hostname gecgithub01.walmart.com\\n  User git\\n  IdentityFile ~/.ssh/id_${proj_hub}_rsa" >> $HOME/.ssh/config
  git remote add --mirror=push $proj_hub-hub $proj_hub:$USER/$PROJ.git > /dev/null 2>&1
  if [ $? != 0 ];then
     git remote remove $proj_hub-hub;
  else
     echo -e "Next time...."\\n"And your public key (~/.ssh/id_rsa.pub) to your Walmart GitHub repository:"\\n"Settings : Deploy keys : Add deploy key. Just copy-n-paste your public SSH key"
  fi;
  echo -n -e \\n\\n\\n"Enter Walmart GitHub owner of secondary public repository:  "
  read collab
  if [ ! -z $collab ]; then 
     dsUSER=`grep -w $collab /app/user-data/DEV/Test_Code/ds-team-map |awk '{print $1}'`
     git remote add --mirror=push $proj_hub-$collab-hub $proj_hub-$collab:$dsUSER/$PROJ.git
     for n in * ;do echo $n >> .gitignore;done
     git pull $proj_hub-$collab-$hub
  else
     git add git-pull.ipynb
     git add git-add.sh
     git add git-README.md
     git commit -m "Initializtion GIT repository for $PROJ project in Element."
     git push origin master
  fi;
  cd $presdir;
  . $HOME/.bashrc
  git remote -v
fi;

if [ -n "`pgrep -a -fl /Applications/OneDrive.app/Contents/MacOS/OneDrive|tail -1|awk '{print $1}'`" ] && [ -d /System/Volumes/Data/Users/$USER/OneDrive\ -\ Walmart\ Inc/$PROJ/ ];then
   function timestamp(){ /bin/ls -lT $1 |awk '{print $9"-"$6"-"$7","$8}'; }
   function cksum { /sbin/md5 "$1" |awk -F'=' '{print $NF}'; }
   function cksumipynb() { cat $1  |jq '.cells[] | select(.cell_type == "code") .source[] '  |tr '\n' '~'  |rev |sed -e 's/"n\\//' |rev |sed -e 's/"//' -e 's/\\n"~"/\n/g' -e 's/\\n"~/\n/g'  -e 's/\\\\/\\/g' -e 's/\\"/"/g' |tr '~' '\n'  |/usr/bin/md5 |awk '{print $1}'; }
   REPO_PROJ="/Users/$USER/OneDrive - Walmart Inc/$PROJ";
fi;
SVCREPO=achoban@inkiru-ds-prod1:/app/user-data/DEV/users/achoban/DSOpsWorkflows
proj_hub=`echo $PROJ|tr '[:upper:]'  '[:lower:]'`
comment_list=""
function git_svc_scp() {
            ssh achoban@inkiru-ds-prod1 "if [ ! -d DSOpsWorkflows/workflows/$proj_hub ];then mkdir DSOpsWorkflows/workflows/$proj_hub ;fi ;cd DSOpsWorkflows ; git pull inkiru_git_hub"
            scp -p $1 $SVCREPO/workflows/$proj_hub/
            ssh achoban@inkiru-ds-prod1 "cd DSOpsWorkflows ; git add workflows/$proj_hub/$2"
}
function git_add_arc() {
            cd $REPO_PROJ/
            if [ ! -f $REPO_PROJ/$2 ]; then cp -p $1 $REPO_PROJ/; $nano $REPO_PROJ/$2;fi
            if [ ! -f $HOME/.repos/.repo-$3/*.$2,v0 ];then cp -p $REPO_PROJ/$2 $HOME/.repos/.repo-$3/`date +%Ywk%V%a`.$2,v0;fi
            firsfile=`ls -1tr $HOME/.repos/.repo-$PROJ/*$file1,v*|head -1`
            lastfile=`ls -1tr $HOME/.repos/.repo-$PROJ/*$file1,v*|tail -1`
            if [ ! $( md5sum $1 |awk '{print $1}' ) == $( md5sum $REPO_PROJ/$2 |awk '{print $1}' ) ];then
                    cp -p $1 $REPO_PROJ/$2;$nano $REPO_PROJ/$2;
            fi;
            if [ $(file $2 |awk -F':' '{print $1}' |awk -F'.' '{print $NF}') == 'ipynb' ];then
                    check=`cksumipynb $REPO_PROJ/$2`
                    ckver=`cksumipynb $lastfile`;
                    ckfir=`cksumipynb $firsfile`;
            else    
                    check=`cksum $REPO_PROJ/$2`
                    ckver=`cksum $lastfile`;
                    ckfir=`cksum $firsfile`;
            fi;
            if [ ! $check == $ckver ] || [ $check == $ckfir ];then
                    if [ ! $ckver == $ckfir ];then
                            cp -p $REPO_PROJ/$2 $HOME/.repos/.repo-$3/`date +%Ywk%V%a`.$2,v`ls $HOME/.repos/.repo-$PROJ/*$2,v*|wc -l|awk '{print $1}'`
                            lastfile=`ls -1tr $HOME/.repos/.repo-$3/*$file1,v*|tail -1`;
                    fi;
                    lastf="$(echo $lastfile |tr '/' '#' |sed -e s/$homer//g |tr '#' '/')"
                    stamp=`timestamp $lastfile`
                    comment_list="    added "$REPO_PROJ"/$2 and ZIP, ref:$lastf \ $stamp \ $check # $comment_list"
                    zip $HOME/.repos/repo-$3.zip $2
                    ls -ltr $HOME/.repos/.repo-$3/*$2,v*
                    git add $2
                    git_svc_scp $2;
            fi;
}

if [[ (-d $HOME/.repos/.repo-$PROJ/) ]];then ls -ld $HOME/.repos/.repo-$PROJ/; else mkdir -p $HOME/.repos/.repo-$PROJ/;fi

for dir in $file_list;do
        file1=`echo $dir |awk -F'/' '{print $NF}'`
        if [ -f $dir ];then
            cp -p $dir "$REPO_PROJ";
            $nano "$REPO_PROJ/$file1"
            git_add_arc $dir $file1 $PROJ
            cd "$presdir";
        elif [[ -d $dir ]];then
            for file2 in `ls $dir`;do
                if [ -f $dir/$file2 ];then
                    cp -p $dir/$file2 "$REPO_PROJ"
                    $nano "$REPO_PROJ/$file2"
                    git_add_arc $dir/file2 $file2 $PROJ
                    cd "$presdir";
                fi;
            done;
        else
            echo -e \\n\\n\\t\\t"No such file or directory"\\n\\n
            sleep 2
            vim "$REPO_PROJ"/$file1;
            git_add_arc "$REPO_PROJ" $file1 $PROJ
            cd "$presdir";
        fi;
done;

cp -p $HOME/.repos/repo-$PROJ.zip "$REPO_PROJ"/
scp -p $HOME/.repos/repo-$PROJ.zip $SVCREPO/workflows/$proj_hub/
#
cd "$REPO_PROJ"
REP=`git remote -v |grep inkiru.*elem.*push |awk '{print $2}'`
git pull $REP master
git pull $proj_hub-hub > /dev/null 2>&1
git pull $proj_hub-$collab-hub > /dev/null 2>&1
git add repo-$PROJ.zip
ssh achoban@inkiru-ds-prod1 "cd DSOpsWorkflows ; git add workflows/$proj_hub/repo-$PROJ.zip"
git status
comment_svc=`echo $comment_list |tr ' ' '_'`
echo " $comment_list" |tr '#' '\n' |git commit -F -
ssh achoban@inkiru-ds-prod1 "cd DSOpsWorkflows ; git commit --message=$comment_svc"
ssh achoban@inkiru-ds-prod1 "cd DSOpsWorkflows ; git pull inkiru_git_hub"
ssh achoban@inkiru-ds-prod1 "cd DSOpsWorkflows ; git push inkiru_git_hub"
git push $REP master
git push -u $proj_hub-hub > /dev/null 2>&1
git push -u $proj_hub-$collab-hub > /dev/null 2>&1
git status
git log -n 1 |cat
echo -e \\n$file_list |tr ' ' '\n'
cd "$presdir"

