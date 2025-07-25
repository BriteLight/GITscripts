#!/bin/bash 
file_list=$@
presdir=$PWD
function timestamp(){ /usr/bin/ls -lr --time-style=+%Y%m%d%H%M.%S $1 |awk '{print $6","$7}'; }
function cksum { /usr/bin/md5sum $1 |awk '{print $1}'; }
function cksumipynb() { cat $1  |jq '.cells[] | select(.cell_type == "code") .source[] '  |tr '\n' '~'  |rev |sed -e 's/"n\\//' |rev |sed -e 's/"//' -e 's/\\n"~"/\n/g' -e 's/\\n"~/\n/g'  -e 's/\\\\/\\/g' -e 's/\\"/"/g' |tr '~' '\n'  |/usr/bin/md5sum |awk '{print $1}'; }
HOME=/home/jupyter
homer=`echo $HOME/.repos/.repo-|tr '/' '#'`

PROJ=$(cat $HOME/.git/FETCH_HEAD |awk -F'/' '{print $NF}')
if [ -z $PROJ ];then
    PROJ=$(git remote -v |grep -w fetch |awk -F'/' '{print $NF}' |awk '{print $1}');
    if [ -z $PROJ ] && [ -f $HOME/git-README.md ];then
        PROJ=$(grep inkiru-ds-prod1 $HOME/git-README.md |awk -F '/' '{print $NF}');
        if [ ! -z $PROJ ] &&  [ -f /data/git-init.sh ];then
            echo -e "No GIT Repository has been set. Please have GIT Repository name and credentials preopared for $PROJ GIT initialization."\\n\\n;
            /data/git-init.sh $PROJ;
        else
            echo -e \\n"FATAL:  No GIT init preset available";
            echo -e -n \\n\\n\\n"GIT repo name: "
            read PROJ;
            /data/git-init.sh $PROJ;
        fi;
    fi;
fi;

if [ $0 == 1 ];then
    echo -e "$0  <file> [<file-2> <file-3> .. <file-n>] ; Takes minimum of one argument. file(s) will be added to or modifications commited to your GIT repository"\\n$USERID@$(cat .git/FETCH_HEAD |awk '{print $NF}');
    exit;
fi;


git_refl=.elem_git_reflectors
git_host=inkiru-ds-prod1.us-central1.us.walmart.net
git_path=/app/user-data/DEV/USERS
git_user=`git remote -v |grep inkiru.*elem.*push |awk '{print $2}' |awk -F'@' '{print $1}'`


if [ $(id|awk -F'(' '{print $2}' |awk -F')' '{print $1}') == 'jupyter' ] && [ -d /home/jupyter ]; then
    REPO_PROJ=$HOME
    cd $REPO_PROJ
    GITDEVPROJ=`grep /$git_user/ git-README.md |grep "$PROJ" |awk '{print $2}'`
    REP=`git remote -v |grep inkiru.*elem.*push |awk '{print $2}'`;
    chmod 600 $HOME/.ssh/id_rsa
    LOGI=`echo $REP|awk -F':' '{print $1}'`
    files=" "
    for file in `ssh $git_user@$git_host "cd $GITDEVPROJ; git status |grep modified " |awk '{print $NF}'`;do files="$files `echo $file`";done
    if [ ! "$files" == " " ];then ssh $git_user@$git_host "cd $GITDEVPROJ; git add $files; git commit -m 'sync from jupter'; git push"; fi
    DPREV=`head -1 git-README.md |awk '{print $NF}'`
    DNEW=`date +%Y-%m-%d,%H:%M:%S`
    sed -e "s/$DPREV/$DNEW/" git-README.md > git-README.md.tmp 
    mv git-README.md.tmp git-README.md
    mod_to_restore=`git status |egrep -v "$(echo $file_list|tr ' ' '|')|git-README.md" |grep modified|awk '{print "/home/jupyter/"$NF}'`
    if [ ! -z "$mod_to_restore" ];then
        git restore $(echo $mod_to_restore |tr '\n' ' ');
    fi;
    
    comment_list=""
    
    function git_add_arc() {
	    cd $HOME/
	    if [ ! -f $HOME/$2 ]; then cp -p $1 $HOME/;fi
	    if [ ! -f $HOME/.repos/.repo-$3/*.$2,v0 ];then cp -p $HOME/$2 $HOME/.repos/.repo-$3/`date +%Ywk%V%a`.$2,v0;fi
            firsfile=`ls -1tr $HOME/.repos/.repo-$PROJ/*$file1,v*|head -1`
            lastfile=`ls -1tr $HOME/.repos/.repo-$PROJ/*$file1,v*|tail -1`
	    if [ ! $( md5sum $1 |awk '{print $1}' ) == $( md5sum $HOME/$2 |awk '{print $1}' ) ];then
		    cp -p $1 $HOME/$2;
            fi;
            if [ "$(grep mimetype $HOME/$2 |awk -F'"mimetype": "' '{print $2}' |awk -F'"' '{print $1}')" == "text/x-python" ];then
		    check=`cksumipynb $HOME/$2`
		    ckver=`cksumipynb $lastfile`;
		    ckfir=`cksumipynb $firsfile`;
	    else
		    check=`cksum $HOME/$2`
		    ckver=`cksum $lastfile`;
		    ckfir=`cksum $firsfile`;
	    fi;
	    if [ ! $check == $ckver ] || [ $check == $chfir ];then 
		    if [ ! $ckver == $ckfir ];then
		            cp -p $HOME/$2 $HOME/.repos/.repo-$3/`date +%Ywk%V%a`.$2,v`ls $HOME/.repos/.repo-$PROJ/*$2,v*|wc -l|awk '{print $1}'`
			    lastfile=`ls -1tr $HOME/.repos/.repo-$3/*$file1,v*|tail -1`;
		    fi;
                    lastf="$(echo $lastfile |tr '/' '#' |sed -e s/$homer//g |tr '#' '/')"
                    stamp=`timestamp $lastfile`
                    comment_list="    added from Element $HOME/$2 and ZIP, ref:$lastf \ $stamp \ $check # $comment_list"
                    $(which zip) $HOME/.repos/repo-$3.zip $2
                    ls -ltr $HOME/.repos/.repo-$3/*$2,v*
                    git add $2
	    fi
    }
    
    
    for dir in $file_list;do
            file1=`echo $dir |awk -F'/' '{print $NF}'`
            if [ -f $dir ];then
                git_add_arc $dir $file1 $PROJ
                cd "$presdir";
            elif [[ -d $dir ]];then
                for file2 in `ls $dir`;do
                    if [ -f $dir/$file2 ];then
                        git_add_arc $dir/file2 $file2 $PROJ
                        cd "$presdir";
                    fi;
                done;
            fi;
    done;
    
    cp -p $HOME/.repos/repo-$PROJ.zip "$REPO_PROJ"/
    #
    cd "$REPO_PROJ"
    git stash    
    git pull $REP master --no-rebase
    git add repo-$PROJ.zip
    git add git-README.md
    git status
    echo " $comment_list" |tr '#' '\n' |git commit -F -
    git push $REP master
    git status
    git log -n 1 |cat
    echo -e \\n$file_list |tr ' ' '\n'
    cd "$presdir"

    for file in $file_list;do scp -p $file $git_user@$git_host:$GITDEVPROJ/;done
    
    ssh $git_user@$git_host "cd $GITDEVPROJ; GITscripts/add-a-file.sh '$file_list $PROJ'"
    
    for repo_file in $(git ls-tree -l -r HEAD |egrep -v $(echo repo-$PROJ.zip git-README.md $file_list|tr ' ' '|') |awk '{print $NF}');do
        ts_file=$(ssh $git_user@$git_host ls -lr --time-style=+%Y%m%d%H%M.%S $GITDEVPROJ/$repo_file|awk '{print $6}')
        touch -t $ts_file $repo_file;
        
    done;
fi;
exit;
