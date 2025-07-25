#!/bin/bash
FILE=$1
PROJ=$2
nan=vim
devranch="dev-ut-stage-`date +%Y_wk%V`"

if [[ ! -d $HOME/$PROJ/ ]];then REPO_PROJ=$HOME; else REPO_PROJ=$HOME/$PROJ;fi

if [ -n `pgrep -a -fl FinderSync|awk '{print $1}'` ] && [ -d /System/Volumes/Data/Users/$USER/OneDrive\ -\ Walmart\ Inc/$PROJ/ ];then REPO_PROJ="/Users/$USER/OneDrive - Walmart Inc/$PROJ";fi
HOME_PROJ=$REPO_PROJ

if [[ (-d $HOME/.repos/.repo-$PROJ/) ]];then ls -l $HOME/.repos/.repo-$PROJ/; else mkdir -p $HOME/.repos/.repo-$PROJ/;fi

FILE1=`echo "$FILE"|awk -F'/' '{print $NF}'`
PATHSLASH=`echo "$FILE" |awk -F'/' '{$NF=""}1'|sed -e "s/ /\//g"`

if [[ ("$REPO_PROJ"/ == $PATHSLASH)  ||  ($PATHSLASH == "") ]];then FILE="$FILE"; else cp -p "$FILE" "$REPO_PROJ"/; fi

grep -swl "" $HOME/.repos/.repo-$PROJ/*$FILE,v*
if [ $? == 0 ];then
   lastfile=`ls -1tr $HOME/.repos/.repo-$PROJ/*$FILE,v*|tail -1`
   stamp=`ls -lr --time-style=full-iso $lastfile|awk '{print $6","$7,$9}'`
   which md5sum > /dev/null
   if [ $? == 0 ];then precheck=`md5sum $lastfile |awk '{print $1}'`;else precheck=`md5 $lastfile |awk '{print $NF}'`;fi
else
   precheck=0;
   stamp=0;
fi

which md5sum > /dev/null
if [ $? == 0 ];then check=`md5sum $FILE |awk '{print $1}'`;else check=`md5 $FILE |awk '{print $NF}'`;fi


presdir=`pwd`

if [[ ${check} != ${precheck} ]];then
   cp -p "$REPO_PROJ"/$FILE $HOME/.repos/.repo-$PROJ/`date +%Ywk%V%a`.$FILE,v`ls $HOME/.repos/.repo-$PROJ/*$FILE,v*|wc -l|awk '{print $1}'`
   cd "$REPO_PROJ"
   zip $HOME/.repos/repo-$PROJ.zip $FILE
   cp -p $HOME/.repos/repo-$PROJ.zip "$REPO_PROJ"/;
fi

cd "$REPO_PROJ"
REP=`git remote -v |grep push |awk '{print $2}'`
cat README.md

git archive --format zip --output $HOME/run_${PROJ}_master.zip master
git archive --remote $USER@$REP master --format zip --output $HOME/run_${PROJ}_remote.zip
echo -e \\n\\n
unzip -l $HOME/run_${PROJ}_master.zip 
echo -e \\n\\n
unzip -l $HOME/run_${PROJ}_remote.zip
echo -e \\n\\n
md5sum $HOME/run_${PROJ}_master.zip $HOME/run_${PROJ}_remote.zip


git checkout -B $devranch

$nan $FILE
check=`md5sum $FILE |awk '{print $1}'`
git add $FILE
git commit -m "dev feature change for $FILE, ref: $check"

echo -e \\n"New feature branch committed locally"\\n\\n

git log --all --decorate --oneline --graph
git push $REP

echo -e \\n"New feature branch pushed to remote repository"\\n\\n

git log --all --decorate --oneline --graph

git checkout master
echo -e \\n"Returning back to master local branch"
git status
cd "$presdir"

