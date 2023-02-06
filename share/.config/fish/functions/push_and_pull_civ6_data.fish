function push_and_pull_civ6_data -d "Synchronise Civ6 saved game data between this and a remote machine"
    set -g REMOTE_MACHINE 'bagumbayan'
    set -g REMOTE_CIV_6_USER_DIR 'C:\\Users\\ginolatorilla\\Documents\\My Games\\Sid Meier\'s Civilization VI'
    set -g LOCAL_CIV_6_USER_DIR "/mnt/x/Documents/My Games/Sid Meier's Civilization VI"

    set -g STAGING_DIR (mktemp -d civ6syncXXX -u -p /tmp)
    scp -pr $REMOTE_MACHINE':"'$REMOTE_CIV_6_USER_DIR'"' $STAGING_DIR
    echo 'Downloaded their Civ6 files at' $STAGING_DIR

    set -g their_modify_time (stat -c '%Y' $STAGING_DIR)
    set -g our_modify_time (stat -c '%Y' $LOCAL_CIV_6_USER_DIR)

    if [ $their_modify_time -gt $our_modify_time ]
        echo 'Theirs is newer'
        rm -rf "/mnt/x/Documents/My Games/Sid Meier's Civilization VI - Backup"
        cp -rf $LOCAL_CIV_6_USER_DIR "/mnt/x/Documents/My Games/Sid Meier's Civilization VI - Backup"
        echo 'Created local backup in "/mnt/x/Documents/My Games/Sid Meier\'s Civilization VI - Backup"'
    else
        echo 'Ours is newer'
        ssh $REMOTE_MACHINE rmdir /s /q '"''C:\\Users\\ginolatorilla\\Documents\\My Games\\Sid Meier\'s Civilization VI - Backup''"'
        ssh $REMOTE_MACHINE xcopy /s /i '"'$REMOTE_CIV_6_USER_DIR'"' '"C:\\Users\\ginolatorilla\\Documents\\My Games\\Sid Meier\'s Civilization VI - Backup"'
        echo 'Created remote backup in "C:\\Users\\ginolatorilla\\Documents\\My Games\\Sid Meier\'s Civilization VI - Backup".'
        set -g STAGING_DIR (mktemp -d civ6syncXXX -u -p /tmp)
        cp -rf $LOCAL_CIV_6_USER_DIR $STAGING_DIR
    end

    rm -f $STAGING_DIR/InputSettings.json
    rm -f $STAGING_DIR/EOSOptions.txt
    rm -f $STAGING_DIR/Mods.sqlite
    rm -f $STAGING_DIR/SoundOpts.txt
    rm -f $STAGING_DIR/AppOptions.txt
    rm -f $STAGING_DIR/UserOptions.txt
    rm -f $STAGING_DIR/GraphicsOptions.txt
    rm -f $STAGING_DIR/GraphicsOptions.txt
    rm -rf $STAGING_DIR/Mods
    rm -rf $STAGING_DIR/Cache
    rm -rf $STAGING_DIR/ModUserData

    if [ $their_modify_time -gt $our_modify_time ]
        /usr/bin/cp -rf $STAGING_DIR/* -t $LOCAL_CIV_6_USER_DIR
        echo 'Installed their Civ6 saves to ours.'
    else
        scp -pr $STAGING_DIR/* $REMOTE_MACHINE':"'$REMOTE_CIV_6_USER_DIR'"'
        echo 'Uploaded our Civ6 saves to theirs.'
    end
end
