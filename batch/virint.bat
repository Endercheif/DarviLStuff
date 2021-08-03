
::Script to paint pixel arts with colors and different options. Written by DarviL (David Losantos)

@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

::::::Config::::::
set "temp1=%temp%\virint.tmp"
set "wip1=%temp%\virint_wip!random!.tmp"
set "cfg1=%~dp0vrnt.cfg" & rem '%~dp0' is a parameter extension, which acts here as the directory where VIRINT is located.

set ver=3.4.2-1
set /a build=55

::Setting default values.
set /a brush_X=5
set /a brush_Y=5
set "space=​"
set brush_color=[97m
set brush_color2=[97m
set brush_type=██& set brushErase_oldType=██
set /a canvas_X=32
set /a canvas_Y=24
set draw_filename_state=


call :mode_get


::Remove temporary files ONLY if there's no more than one instance of VIRINT running (including the current one)
for /f "usebackq" %%G in (`tasklist /fi "imagename eq cmd.exe" /v ^| find "cmd.exe"`) do set /a instanceCounter += 1
if !instanceCounter! LEQ 2 if exist "%temp%\virint*.tmp*" del /f /q "%temp%\virint*.tmp*" 2> nul


::Read the cfg file if it exists.
if exist "!cfg1!" (
    for /f "usebackq tokens=1-2 delims==" %%G in (`findstr /v /r /c:"^^#" "!cfg1!"`) do (
        if "%%H"=="0" (set "%%G=") else (set "%%G=%%H")
    )
)


::Check for parameters.
set "self_filename=%~nx0"
set "self_name=%~n0"
set "file_extension=.vrnt"
if exist %1 set "file_load_input=%1"

if not defined parms_array set "parms_array=%*"
for %%G in (!parms_array!) do (
    if defined tknxt (
        set "!tknxt!=%%G"
        set tknxt=
    ) else (
        if /i "%%G"=="/s" set tknxt=canvas_size
        if /i "%%G"=="/l" set tknxt=file_load_input
        if /i "%%G"=="/n" set parm_new=1
        if /i "%%G"=="/c" set parm_compress=1
        if /i "%%G"=="/NoMode" set nomode=1
        if /i "%%G"=="/chkup" call :chkup virint & exit /b
        if /i "%%G"=="/NoCompression" set noCompression=1
        if /i "%%G"=="/NewCFG" call :cfg_create & exit /b
        if /i "%%G"=="/NoOldWarn" set NoOldWarn=1
        if /i "%%G"=="/NoFileMgr" set NoFileMgr=1
    )
)
if defined parm_new (
    if defined nomode call :window_opt newbuffer
    call :file_create
    if defined invalid (
        if defined nomode timeout /t 3 >nul & call :window_opt oldbuffer
        exit /b 1
    )
    call :start
    exit /b
)
if defined file_load_input (
    if defined parm_compress set LoadDoCompress=1
    if defined nomode call :window_opt newbuffer
    call :file_load
    if defined invalid (
        if defined nomode timeout /t 3 >nul & call :window_opt oldbuffer
        exit /b 1
    )
    call :start
    exit /b
)
if defined CheckUpdates call :chkup virint quiet








::Start menu.
if !cols_current! LSS 30 call :display_message "ERROR: Cannot draw menu." red newline & exit /b 1
if defined nomode call :window_opt newbuffer

call :menu_draw new

choice /c 1234 /n >nul
set start_input=!errorlevel!
if !start_input!==1 (
    call :menu_draw 1
    echo:
    echo !menu_hr!
    set /p canvas_size="[94mCanvas size? [!canvas_X!x!canvas_Y!]: [0m"
    call :file_create
)
if !start_input!==2 (
    call :menu_draw 2
    if not defined NoFileMgr (call :file_mgr) else (
        echo:
        echo !menu_hr!
        set /p file_load_input="[94mFilename?: [0m"
    )
    call :file_load
)
if !start_input!==3 (
    call :menu_draw 3
    call :window_opt cls
    call :help noLoad
    call :window_opt oldbuffer
    exit /b 0
)
if !start_input!==4 (
    call :menu_draw 4
    <nul set /p =[10F[J
    if defined nomode call :window_opt oldbuffer
    exit /b 0
)
if defined invalid (
    if defined nomode timeout /t 3 >nul & call :window_opt oldbuffer
	call :window_opt show
    exit /b 1
)







:start
    ::Set required variables for drawing the UI.
    
    set /a draw_barh_size=canvas_X+2
    set /a draw_barh_offset=canvas_Y+6
    set /a draw_barv_size=canvas_Y+5
    set /a draw_barv_offset=(canvas_X*2)+7
    set /a draw_options_offset=draw_barh_offset+1
    for /l %%G in (1,1,!draw_barh_size!) do set draw_barh_done=!draw_barh_done!▒▒
    for /l %%G in (4,1,!draw_barv_size!) do (set draw_barv_done=!draw_barv_done![%%G;1f▒▒& set draw_barv2_done=!draw_barv2_done![%%G;!draw_barv_offset!f▒▒)
    
    set "draw_info_titlebar=VIRINT !ver! - [*'!draw_filename!']"
    call :strlen draw_info_titlebar_size draw_info_titlebar







:MAIN
    ::Main loop routine.
    
    call :window_opt hide

    call :draw
    call :collide
    call :getkey
    if not defined run_exit (
        goto MAIN
    ) else (
        call :window_opt show
        if not defined NoMode (
            cls
            mode con cols=!cols_current!
        ) else call :window_opt oldbuffer
        del /q "!wip1!"
        exit /b 0
    )








:draw
    ::Draw the entire UI.

    set /a draw_cursor_X=(brush_X-2)/2
    set /a draw_cursor_Y=brush_Y-4

    ::Info bar
    if !draw_info_titlebar_size! GTR !cols_current! (
		set /a draw_info_titlebar_cutVal=draw_info_titlebar_size-cols_current+6
        call set draw_info_titlebar=%%draw_filename:~0,-!draw_info_titlebar_cutVal!%%
        set "draw_info_titlebar=VIRINT !ver! - [!draw_filename_state!'!draw_info_titlebar!...']"
    ) else (
        set "draw_info_titlebar=VIRINT !ver! - [!draw_filename_state!'!draw_filename!']"
    )
    <nul set /p "=[H[7m[96m!draw_info_titlebar![K[0m"
    <nul set /p "=[2;1fColor A: !brush_color!!brush_type![0m   Color B: !brush_color2!!brush_type![0m   X: !draw_cursor_X!/!canvas_X! Y: !draw_cursor_Y!/!canvas_Y![K"

    ::Horizontal top
    <nul set /p =[3;1f▓▓[0m!draw_barh_done!▓▓[0m
    <nul set /p =[3;!brush_X!f[96m▄▄[0m

    ::Vertical left
    <nul set /p =!draw_barv_done!
    echo [!brush_Y!;1f[96m █[0m

    ::Vertical right
    <nul set /p =!draw_barv2_done!
    echo [!brush_Y!;!draw_barv_offset!f[96m█ [0m

    ::Horizontal bottom
    <nul set /p =[!draw_barh_offset!;1f▓▓[0m!draw_barh_done!▓▓[0m
    <nul set /p =[!draw_barh_offset!;!brush_X!f[96m▀▀[0m

    ::Status bar
    <nul set /p =[!draw_barh_offset!;1f
    echo:
    <nul set /p ="[96mMove: WASD  |  "
    if defined brushToggle (<nul set /p "=[7mBrush: B[27m  |  ") else (<nul set /p "=Brush: B  |  ")
    if defined brushErase (<nul set /p "=[7mErase: E[27m  |  ") else (<nul set /p "=Erase: E  |  ")
    <nul set /p ="Color: C  |  Toggle Color: T  | Brush Type: Z |  Coord: F  |  Fill: X  |  [95mSave: V  |  Exit: M[0m"
    echo [J

    ::Draw brush on screen, and save the position in screen, the color, and the brush type to a temporary file.
    if defined brushToggle (
        echo [!brush_Y!;!brush_X!f!brush_color!!brush_type![0m
        if not defined brushErase (echo !brush_Y!:!brush_X!:!brush_color!:!brush_type!>> "!wip1!") else (echo !brush_Y!:!brush_X!::!brush_type!>> "!wip1!")
        set draw_filename_state=*
    )
exit /b





:collide
    ::Detect if the cursor is getting close to the boundaries, and deny it's movement.
    
    set /a canvas_limitX=(canvas_X*2)+5
    set /a canvas_limitY=canvas_Y+6
    set /a brush_X_next=brush_X+2
    set /a brush_X_prev=brush_X-2
    set /a brush_Y_next=brush_Y+2
    set /a brush_Y_prev=brush_Y-1
    if !brush_X_prev! LEQ 4 (set brush_leftq=0) else (set brush_leftq=1)
    if !brush_X_next! GEQ !canvas_limitX! (set brush_rightq=0) else (set brush_rightq=1)
    if !brush_Y_prev! LEQ 4 (set brush_upq=0) else (set brush_upq=1)
    if !brush_Y_next! GEQ !canvas_limitY! (set brush_downq=0) else (set brush_downq=1)
exit /b





:getkey
    ::Get the key that the user presses. The script won't continue until the user presses any key.
    
    ::        123456789ABCDEF
    choice /c WASDBECTFXMVHRZ /n >nul
    set getkey_input=!errorlevel!

    if !getkey_input!==1 if !brush_upq!==1 set /a brush_Y-=1
    if !getkey_input!==3 if !brush_downq!==1 set /a brush_Y+=1
    if !getkey_input!==2 if !brush_leftq!==1 set /a brush_X-=2
    if !getkey_input!==4 if !brush_rightq!==1 set /a brush_X+=2
    if !getkey_input!==5 if not defined brushToggle (set brushToggle=1) else (set brushToggle=)
    if !getkey_input!==6 if not defined brushErase (
            set brushErase=1
            set brush_type=!space!!space!
        ) else (
            set brushErase=
            set brush_type=!brushErase_oldType!
        )
    if !getkey_input!==7 call :option_color_select
    if !getkey_input!==8 (
        set tmp=!brush_color!
        set brush_color=!brush_color2!
        set brush_color2=!tmp!
    )
    if !getkey_input!==9 call :option_coord_select
    if !getkey_input!==10 call :option_canvas_fill
    if !getkey_input!==11 (
        if "!draw_filename_state!"=="*" (
            call :display_message "Exit VIRINT? All unsaved changes will be lost. [Y/N]" red
            choice /c yn /n >nul
            if !errorlevel!==1 set run_exit=1
            exit /b
        )
        set run_exit=1 & exit /b
    )
    if !getkey_input!==12 call :file_save
    if !getkey_input!==13 call :help
    if !getkey_input!==14 call :file_reload
    if !getkey_input!==15 call :option_brush_select
exit /b


















:option_color_select
    call :display_message "Select a color:" white
    echo:&echo:
    echo [7m[34m 1 [32m 2 [36m 3 [31m 4 [35m 5 [33m 6 [37m 7 [90m 8 [94m 9 [92m A [96m B [91m C [95m D [93m E [97m F [0m
    echo  G: Pick RGB.

    choice /c 123456789ABCDEFG /n >nul
    set brush_color2=!brush_color!

    if !errorlevel!==1 set brush_color=[34m
    if !errorlevel!==2 set brush_color=[32m
    if !errorlevel!==3 set brush_color=[36m
    if !errorlevel!==4 set brush_color=[31m
    if !errorlevel!==5 set brush_color=[35m
    if !errorlevel!==6 set brush_color=[33m
    if !errorlevel!==7 set brush_color=[37m
    if !errorlevel!==8 set brush_color=[90m
    if !errorlevel!==9 set brush_color=[94m
    if !errorlevel!==10 set brush_color=[92m
    if !errorlevel!==11 set brush_color=[96m
    if !errorlevel!==12 set brush_color=[91m
    if !errorlevel!==13 set brush_color=[95m
    if !errorlevel!==14 set brush_color=[93m
    if !errorlevel!==15 set brush_color=[97m
    if !errorlevel!==16 (
        set option_color_select_input=
        call :display_message "Select a color value [255-255-255]:" white
        call :window_opt show
        set /p option_color_select_input=
        call :window_opt hide
        if not defined option_color_select_input set brush_color=[97m& exit /b
        for /f "tokens=1-3 delims=-" %%G in ("!option_color_select_input!") do (
            set /a option_color_select_R=%%G 2> nul
            set /a option_color_select_G=%%H 2> nul
            set /a option_color_select_B=%%I 2> nul
        )
        set brush_color=[38;2;!option_color_select_R!;!option_color_select_G!;!option_color_select_B!m
    )
exit /b





:option_brush_select
    call :display_message "Select a brush:" white
    echo:&echo:
    echo !brush_color!██ ▓▓ ▒▒ ░░ ╔═ ╗  ╚═ ╝  ══ ║  ▄▄ ▀▀ ▌▐ ▐▌[0m
    echo ── ── ── ── ── ── ── ── ── ── ── ── ── ──
    echo 1  2  3  4  5  6  7  8  9  A  B  C  D  E
    choice /c 123456789ABCDE /n >nul
    if !errorlevel!==1 set  option_brush_type=██
    if !errorlevel!==2 set option_brush_type=▓▓
    if !errorlevel!==3 set option_brush_type=▒▒
    if !errorlevel!==4 set option_brush_type=░░
    if !errorlevel!==5 set option_brush_type=╔═
    if !errorlevel!==6 set option_brush_type=╗!space!
    if !errorlevel!==7 set option_brush_type=╚═
    if !errorlevel!==8 set option_brush_type=╝!space!
    if !errorlevel!==9 set option_brush_type=══
    if !errorlevel!==10 set option_brush_type=║!space!
    if !errorlevel!==11 set option_brush_type=▄▄
    if !errorlevel!==12 set option_brush_type=▀▀
    if !errorlevel!==13 set option_brush_type=▌▐
    if !errorlevel!==14 set option_brush_type=▐▌

    if not defined brushErase set brush_type=!option_brush_type!
    set brushErase_oldType=!option_brush_type!
exit /b





:option_coord_select
    ::Select the coordinates of the cursor to move. Check if the user is trying to get out of bounds.

    call :display_message "Select the coordinate [1-1]:" white
    call :window_opt show
    set option_coord_input=
    set /p option_coord_input=
    call :window_opt hide
    if defined option_coord_input (
        for /f "tokens=1-2 delims=-" %%G in ("!option_coord_input!") do (
            set option_coord_X=%%G
            set option_coord_Y=%%H
        )
        if /i "!option_coord_X!"=="E" set option_coord_X=!canvas_X!
        if /i "!option_coord_Y!"=="E" set option_coord_Y=!canvas_Y!
    ) else (
        set /a option_coord_X=1
        set /a option_coord_Y=1
    )
    if !option_coord_X! GTR !canvas_X! call :display_message "ERROR: Cursor out of bounds." red wait &exit /b
    if !option_coord_X! LSS 1 call :display_message "ERROR: Cursor out of bounds." red wait &exit /b
    if !option_coord_Y! GTR !canvas_Y! call :display_message "ERROR: Cursor out of bounds." red wait &exit /b
    if !option_coord_Y! LSS 1 call :display_message "ERROR: Cursor out of bounds." red wait &exit /b

    set /a brush_X=((option_coord_X+2)*2)-1
    set /a brush_Y=option_coord_Y+4
exit /b





:option_canvas_fill
    ::Fill the canvas with the current color. If Erase is on, just do cls and clear the file. Here it types XX:XX as the X and Y coords to the
    ::file because we don't need to store every single line. The file_reload function will parse it correctly to draw it on screen.
    
    call :display_message "Fill canvas with current brush options? [Y/N]" red
    choice /c yn /n >nul
    if !errorlevel!==1 (
        echo VIRINTFile > "!wip1!"
        set option_canvas_fill_brush=
        if not defined brushErase (
            for /l %%G in (1,1,!canvas_X!) do (set option_canvas_fill_brush=!brush_type!!option_canvas_fill_brush!)
            for /l %%G in (1,1,!canvas_Y!) do (
                set /a option_canvas_fill_Y=%%G+4 2>nul
                echo [!option_canvas_fill_Y!;5f!brush_color!!option_canvas_fill_brush![0m
            )
            echo XX:XX:!brush_color!:!brush_type!>> "!wip1!"
        ) else call :window_opt cls
        set draw_filename_state=*
        exit /b
    )
exit /b





:file_load
    ::Loading file function. This will parse all the the data in the header, which constains the script version number, the canvas size
    ::in the X and Y axis, the brush position in the X and Y axis, the brush colors A and B, and a mark that is just 'VIRINTFile'.

    if not defined file_load_input call :display_message "ERROR: Invalid filename." red newline &set invalid=1 &exit /b
    set file_load_input=!file_load_input:"=!

    for %%G in ("!file_load_input!") do set file_load_input=%%~fG
    if exist "!file_load_input!\*" call :display_message "ERROR: File '!file_load_input!' is a directory." red newline &set invalid=1 &exit /b
    if not exist "!file_load_input!" call :display_message "ERROR: File '!file_load_input!' does not exist." red newline &set invalid=1 &exit /b

    set /p load_header=<"!file_load_input!"
    for /f "tokens=1-8 delims=:" %%G in ("!load_header!") do (
        set /a file_build=%%G 2> nul
        set /a canvas_X=%%H 2> nul
        set /a canvas_Y=%%I 2> nul
        set /a brush_X=%%J 2> nul
        set /a brush_Y=%%K 2> nul
        set brush_color=%%L
        set brush_color2=%%M
        set header_mark=%%N
    )
    if not "!header_mark!"=="VIRINTFile" call :display_message "ERROR: Invalid file structure." red newline &set invalid=1 &exit /b
    if not defined NoOldWarn (
        if !file_build! LSS !build! (
            echo This file has been edited in an older version of VIRINT. Proceed? [Y/N]
            choice /c yn /n >nul
            if !errorlevel!==2 set invalid=1 & exit /b
        )
    )

    if defined LoadDoCompress (
        copy "!file_load_input!" "!temp1!" >nul
        call :file_compress
        copy "!temp1!" "!file_load_input!" >nul
        exit /b
    )

    call :checksize
    if defined invalid exit /b
    copy "!file_load_input!" "!wip1!" >nul
    call :file_reload
    set draw_filename=!file_load_input!
exit /b






:file_reload
    ::Parse the picture data inside the file. It basically reads every line to get the coordinates, color, and brush type to draw on screen.
    ::If it finds a line containing XX:XX as the coordinates, it fills up the entire screen with the color and brush type.
    
    call :checksize
    <nul set /p "=[H[7m[96mVIRINT !ver! - Loading, please wait...[K[0m"
    findstr /r /c:"^^XX:XX:.*$" "!wip1!" > "!temp1!"
    if !errorlevel!==0 (
        set file_load_full=
        for /f "usebackq tokens=3-4 delims=:" %%A in ("!temp1!") do (
            for /l %%G in (1,1,!canvas_X!) do (set file_load_full=!file_load_full!%%B)
            for /l %%G in (1,1,!canvas_Y!) do (
                set /a option_canvas_fill_Y=%%G+4 2>nul
                <nul set /p =[!option_canvas_fill_Y!;5f%%A!file_load_full![0m
            )
        )
        for /f "usebackq skip=2 tokens=1-4 delims=:" %%G in ("!wip1!") do (
            <nul set /p =[%%G;%%Hf%%I%%J[0m
        )
    ) else (
        for /f "usebackq skip=1 tokens=1-4 delims=:" %%G in ("!wip1!") do (
            <nul set /p =[%%G;%%Hf%%I%%J[0m
        )
    )
exit /b






:file_create
    ::Changes the size of the screen to match the selected canvas size. It also changes the filename to 'Untitled', and clears up the wip file.

    if defined canvas_size (
        for /f "tokens=1-2 delims=x" %%G in ("!canvas_size!") do (
            set /a canvas_X=%%G 2>nul
            set /a canvas_Y=%%H 2>nul
        )
    )
    call :checksize
    set draw_filename=Untitled
    echo VIRINTFile > "!wip1!"
exit /b







:file_save
    ::Save a file. Copies the temp file where all the data is stored to the path that the user specified. It also builds the header that
    ::file_load can understand.
    
    set file_save_input=
    call :display_message "Select a filename [!draw_filename!]:" white
    call :window_opt show
    set /p file_save_input=
    call :window_opt hide
    if not defined file_save_input set file_save_input="!draw_filename!"
    set file_save_input=!file_save_input:"=!
    if /i "!file_save_input!"=="con" call :display_message "ERROR: Invalid filename." red wait & exit /b 1
    if exist "!file_save_input!\*" call :display_message "ERROR: File '!file_save_input!' is a directory." red wait & exit /b 1
    for %%G in ("!file_save_input!") do set "file_save_input=%%~fG"

    if exist "!file_save_input!" (
        call :display_message "Found file '!file_save_input!'. Overwrite? [Y/N]" white
        choice /c yn /n >nul
        if !errorlevel!==2 exit /b
    )

    findstr /v "VIRINTFile" "!wip1!" > "!temp1!"

    if not defined noCompression (
        call :display_message "Applying compression. Please, wait..." yellow
        call :file_compress
    )

    echo !build!:!canvas_X!:!canvas_Y!:!brush_X!:!brush_Y!:!brush_color!:!brush_color2!:VIRINTFile> "!wip1!"
    type "!temp1!" >> "!wip1!"
    copy "!wip1!" "!file_save_input!" >nul

    if exist "!file_save_input!" (
        call :display_message "File saved succesfully as '!file_save_input!'." green wait
        set draw_filename=!file_save_input!
        set draw_filename_state=
    ) else call :display_message "ERROR: An error occurred while trying to save the file as '!file_save_input!'." red wait
    call :file_reload
    set brushToggle=
exit /b






:file_compress
    ::Compression algorithm for making virint files smaller. Takes the content of the file !tmp1! (WITHOUT HEADER), and applies a search
    ::for any duplicated X or Y value. If it finds duplicates, it will only save the last occurence. This is done for every single line in the file.
    ::After finishing, it outputs the compressed file in !temp1!
    
    if defined LoadDoCompress (
        echo Applying compression. Please wait... ^(Started at !time!^)
        for /f "usebackq" %%G in ("!temp1!") do set /a file_compress_lines1+=1
    )
    for /f "usebackq tokens=1-2 delims=:" %%G in ("!temp1!") do (
        set /a file_compress_counter=0
        for /f "usebackq" %%G in (`findstr /r /c:"^^%%G:%%H:.*$" "!temp1!"`) do (
            set /a file_compress_counter+=1
            set file_save_lastLine=%%G
        )
        if !file_compress_counter! GTR 1 (
            findstr /v /r /c:"^^%%G:%%H:.*$" "!temp1!" > "!temp1!3"
            echo !file_save_lastLine!>> "!temp1!3"
            type "!temp1!3" > "!temp1!"
        )
    )
    if defined LoadDoCompress (
        for /f "usebackq" %%G in ("!temp1!") do set /a file_compress_lines2+=1
        set /a file_compress_result=file_compress_lines1-file_compress_lines2
        call :display_message "Done. !file_compress_result! lines removed. [!file_compress_lines1! ^> !file_compress_lines2!^] ^(Finished at !time!^)" green newline
        rem Here we set invalid to 1 because we don't want to load the file on screen.
        set invalid=1
    )
exit /b






:checksize
    ::Check if the canvas size is valid, and calculate the number of columns and lines for MODE.
    
    if !canvas_X! LSS 20 call :display_message "ERROR: Exceeded minimum canvas horizontal size." red newline &set invalid=1 & exit /b
    if !canvas_X! GTR 128 call :display_message "ERROR: Exceeded maximun canvas horizontal size." red newline &set invalid=1 & exit /b
    if !canvas_Y! LSS 20 call :display_message "ERROR: Exceeded minimum canvas vertical size." red newline &set invalid=1 & exit /b
    if !canvas_Y! GTR 128 call :display_message "ERROR: Exceeded maximun canvas vertical size." red newline &set invalid=1 & exit /b

    set /a window_cols="(canvas_X+4)*2"
    set /a window_lines=canvas_Y+12

    call :mode_get
    if not defined nomode (
        mode con cols=!window_cols! lines=!window_lines!
    ) else (
        if !cols_current! LSS !window_cols! call :checksize_wait
        if !lines_current! LSS !window_lines! call :checksize_wait
    )
	call :window_opt cls
exit /b




:checksize_wait
    call :mode_get
    if !cols_current! GEQ !window_cols! if !lines_current! GEQ !window_lines! exit /b 0
    call :display_message "[HERROR: Waiting for window resize.[K" red newline
    if !cols_current! GEQ !window_cols! (call :display_message "Columns: !cols_current! ^> !window_cols![K" green newline) else (call :display_message "Columns: !cols_current! ^< !window_cols![K" red newline)
    if !lines_current! GEQ !window_lines! (call :display_message "Lines: !lines_current! ^> !window_lines![K" green newline) else (call :display_message "Lines: !lines_current! ^< !window_lines![K" red newline)
    <nul set /p =[J
    
    ping localhost -n 1 >nul
goto checksize_wait





:display_message
    ::Display a message under the canvas. Usage: string [red green yellow white] [wait/newline]
    
    set display_message_msg=%1
    set display_message_msg=!display_message_msg:"=!
    if "%2"=="red" set display_message_color=[91m
    if "%2"=="green" set display_message_color=[92m
    if "%2"=="yellow" set display_message_color=[33m
    if "%2"=="white" set display_message_color=[97m
    if "%3"=="newline" (echo !display_message_color!!display_message_msg![0m) else (<nul set /p =[!draw_options_offset!;1f!display_message_color![7m!display_message_msg![0m [J)
    if "%3"=="wait" timeout /t 3 >nul
exit /b






:help
    ::Display help on screen. [noLoad]
    
    if not defined nomode (
        mode con cols=112 lines=57
    ) else (
        call :mode_get
        if !cols_current! LSS 112 call :display_message "ERROR: Not enough horizontal size for displaying the help page." red wait & exit /b
    )
    <nul set /p =[3;r
    call :window_opt cls
    echo [7m[96mVIRINT !ver! - Help[K
    if defined nomode (echo Press any key to display the next two lines on screen.[K[0m) else (echo [K[0m)
    echo:
    
    (
        echo !space!Script that allows the user to paint on a canvas on the Windows console with different colors.
        echo !space!Supporting the ability to save and load files generated by this script.
        echo !space![90mWritten by DarviL ^(David Losantos^) in batch. Using version !ver! ^(Build !build!^)
        echo !space!Repository available at: [4mhttps://github.com/DarviL82/DarviLStuff[24m[0m
        echo !space!
        echo !space!
        echo !space![96m!self_name! [/N [/S NxN]] [/L file [/C]] [/NoCompression] [/NoMode] [/NoOldWarn] [/NoFileMgr] [/CHKUP]
        echo !space!
        echo !space!/N[0m	Create a new canvas.
        echo !space![96m/S[0m	[37mSelect the size of the canvas to create. The value must be specified with two numbers between
        echo !space!	20 and 128 separated by 'x'.
        echo !space![96m/L[0m	Load the specified file.
        echo !space!
        echo !space!The script shows a quick menu if it is launched normally, so using the parameters above is not necessary.
        echo !space!
        echo !space![96m/C[0m		Compress the specified file with '/L'.
        echo !space![96m/NoCompression[0m	[37mDisables the file compression algorithm. This will make file saving much faster,
        echo !space!		but files will be much bigger, and they will take more time to load.
        echo !space![96m/NoMode[0m	Stops resizing the window automatically. Enabling this option will make VIRINT use a
        echo !space!		secundary console buffer to not clear the original one, but no automatic resizing will be done.
        echo !space![96m/NoOldWarn[0m	[37mDo not warn about old files being loaded.
        echo !space![96m/NoFileMgr[0m	[0mDo not use the file viewer when searching for files.
        echo !space![96m/CHKUP[37m		Check if you are using the minimum necessary Windows build for ANSI escape codes
        echo !space!		and the newest versions of VIRINT. If it finds a newer version of it, it will ask for a folder
        echo !space!		to download VIRINT in. Pressing ENTER without entering a path will select the default option,
        echo !space!		which is the folder that contains the currently running script, overriding the old version.
        echo !space!
        echo !space![94mTools provided for working on the canvas:
        echo !space! - Brush ^(B^)[0m		Toggle the brush. Enabling it will start painting on the canvas with the current
        echo !space!			color selected ^(Color A^).
        echo !space! [94m- Erase ^(E^)[0m		[37mToggle the eraser. Enabling it will start erasing content on the canvas. This
        echo !space!			tool only works when used with the Brush tool.
        echo !space! [94m- Color ^(C^)[0m		Select a color from the list, or select a custom RGB value. After selecting a
        echo !space!			color, it will be displayed at the Info bar ^(Color A^). If you select a new color,
        echo !space!			The previously selected color will be saved in Color B.
        echo !space! [94m- Toggle Color ^(T^)[0m	[37mToggle between the primary and secundary selected colors ^(Color A and B^).
        echo !space! [94m- Brush Type ^(Z^)[0m	Select a type of brush from the list. After selecting a brush, it will be
        echo !space!			displayed at the Info bar ^(Color A and Color B^).
        echo !space! [94m- Coord ^(F^)[0m		[37mSelect a coordinate to move the cursor on the canvas ^(x-y^). Pressing ENTER
        echo !space!			without entering any value will move the cursor to position X1 and Y1. Use a value of
        echo !space!			'E' to move the cursor to the limit of the canvas on the specified axis.
        echo !space! [94m- Fill ^(X^)[0m		Fill the current canvas with the Color A. If the Erase tool is enabled, the entire
        echo !space!			canvas will be cleared.
        echo !space!
        echo !space!- Pressing 'R' will reload the UI ^(Useful if the canvas ended up getting messy^).
        echo !space!- You can open this help page from the canvas by pressing 'H'.
        echo !space!- Dragging a file onto the script will make VIRINT attempt to load it.
        echo !space!
        echo !space!- VIRINT will try to load a configuration file called 'vrnt.cfg', located where the script is.
        echo !space!  If you would like to create the default one, use '/NewCFG'.
        echo !space!
        echo !space!
        echo !space![90mMore in depth help can be found at: [4mhttps://github.com/DarviL82/DarviLStuff/wiki/VIRINT[24m[0m
    ) > "!temp1!"


    if defined nomode (
        set /a help_counter=6
        for /f "usebackq tokens=*" %%G in ("!temp1!") do (
            set /a help_counter+=1
            if not defined help_doSkip (
                if !help_counter! GTR !lines_current! pause >nul
                set help_doSkip=1
            ) else set help_doSkip=
            echo %%G
        )
        echo: & echo:
        <nul set /p =[100;0f[7m[92mPress 'Q' to exit, or 'R' to read again.[K
        <nul set /p =[1FFinished reading help.[K
        timeout /t 1 /nobreak >nul
        choice /c QR /n >nul
        if !errorlevel!==2 goto help
    ) else (
        for /f "usebackq tokens=*" %%G in ("!temp1!") do (echo %%G)
        pause >nul
    )
    <nul set /p =[;r
    if not "%1"=="noLoad" (call :file_reload) else (call :window_opt cls & mode con cols=!cols_current!)
exit /b





:chkup
    if not "%2"=="quiet" (
        rem Check if the user is using windows 1909 at least
        <nul set /p =Checking Windows build... 
        for /f "usebackq skip=1 tokens=4,6 delims=[]. " %%G in (`ver`) do (
            set /a ver_windows=%%G
            set /a build_windows=%%H
        )
        if !ver_windows!==10 (
            if !build_windows! GEQ 17763 (
                echo [92mUsing Windows 10 !build_windows!, with ANSI escape codes support.[0m
            ) else echo Windows 10 1909 or higher is required for displaying ANSI escape codes.
        ) else echo Windows 10 1909 or higher is required for displaying ANSI escape codes.
    )


    ::Check for updates.
    if not "%2"=="quiet" <nul set /p =Checking for new versions of %1... 
    ping github.com /n 1 > nul
    if !errorlevel! == 1 echo [91mUnable to connect to GitHub.[0m & exit /b 1
    curl -s https://raw.githubusercontent.com/L89David/DarviLStuff/master/versions > "!temp1!"
    for /f "usebackq skip=2 tokens=3*" %%G in (`find /I "%1" "!temp1!"`) do set /a build_gh=%%G
    if !build_gh! GTR !build! (
        echo [33mFound a new version. ^(Using build: !build!. Latest build: !build_gh!^)[0m
        echo:
        set /p "chkup_in=Select a destination folder to download %1 in. ['%~dp0'] "
        if not defined chkup_in set chkup_in=%~dp0
        set chkup_in=!chkup_in:"=!
        set chkup_in=!chkup_in:/=\!
        
        <nul set /p =Downloading... 
        if not exist "!chkup_in!\" (
            echo [91mThe folder '!chkup_in!' doesn't exist. Download aborted.[0m
            exit /b 1
        ) else (
            curl -s https://raw.githubusercontent.com/L89David/DarviLStuff/master/%1.bat > "!chkup_in!\!self_filename!"
            if not !errorlevel! == 0 echo [91mAn error occurred while trying to download %1.[0m & exit /b 1
            echo [92mDownloaded %1 succesfully in '!chkup_in!'.[0m
            exit /b 0
        )
    ) else if not "%2"=="quiet" echo [92mUsing latest version.[0m
exit /b 0





:cfg_create
    ::Create the vrnt.cfg config file that VIRINT will load when running.

    (
        echo #VIRINT config file. Use '#' to comment out the values that you don't want to modify.
        echo:
        echo #Select the default size of the canvas, horizontally and vertically. ^(20-128^)
        echo 	Canvas_X=32
        echo 	Canvas_Y=24
        echo:
        echo:
        echo #Enable/Disable the file compression algorithm. Disabling it will make file saving much faster,
        echo #but files will be much bigger, and they will take more time to load. ^(0/1^)
        echo 	NoCompression=0
        echo:
        echo:
        echo #Enable/Disable the automatic window resizing. Enabling this option will make VIRINT use a
        echo #secundary console buffer to not clear the original one, but no automatic resizing will be done. ^(0/1^)
        echo 	NoMode=0
        echo:
        echo:
        echo #Check for updates silently automatically when running the script. ^(0/1^)
        echo 	CheckUpdates=0
        echo:
        echo:
        echo #Do not warn about old files being loaded. ^(0/1^)
        echo 	NoOldWarn=0
        echo:
        echo:
        echo #Do not use the file viewer when searching for files. ^(0/1^)
        echo 	NoFileMgr=0
        echo:
        echo:
        echo #File extension definition. Currently only used to highlight the files with this extension in the
        echo #file viewer. ^(string^)
        echo 	file_extension=.vrnt
    ) > "!cfg1!"
    
    if not exist "!cfg1!" (call :display_message "ERROR: Couldn't create config file '!cfg1!'." red newline) else (call :display_message "Created configuration file succesfully at '!cfg1!'." green newline)
exit /b





:window_opt
    ::Some quick terminal options:
    ::    show: Show cursor.
    ::    hide: Hide cursor.
    ::    newbuffer: New console buffer
    ::    oldbuffer: Return to old console buffer.
    ::    cls: Clear screen. If NoMode being used, we can't use CLS, because everything breaks.

    if "%1"=="show" <nul set /p=[?25h
    if "%1"=="hide" <nul set /p=[?25l
    if "%1"=="newbuffer" <nul set /p =[?1049h
    if "%1"=="oldbuffer" <nul set /p =[?1049l
    if "%1"=="cls" if defined nomode (<nul set /p =[0m[2J) else (cls)
exit /b





:mode_get
    ::Get the size of the terminal.
    
    for /f "usebackq skip=3 tokens=2 delims=: " %%G in (`mode`) do (
        if defined mode_get-looped (
            set /a cols_current=%%G
            set /a cols_center=%%G/2
            set mode_get-looped=
            exit /b
        ) else (
            set /a lines_current=%%G
            set mode_get-looped=1
        )
    )
exit /b





:menu_draw
    ::Draw the main menu.

    set /a menu_center=cols_center - 13 & set menu_center=[!menu_center!C
    set menu_hr=
    for /l %%G in (1,1,!cols_current!) do set menu_hr=!menu_hr!─
    if not "%1"=="new" <nul set /p =[10F
    echo [96mVIRINT !ver! - Start menu[0m
    echo:
    echo !menu_center!╔══════════════════════════╗
    echo !menu_center!║ Select an option:        ║
    if "%1"=="1" (echo !menu_center!║   [94m1^)[0m [7mCreate new canvas.[27m  ║) else (echo !menu_center!║   [94m1^)[0m Create new canvas.  ║)
    if "%1"=="2" (echo !menu_center!║   [94m2^)[0m [7mLoad file.[27m          ║) else (echo !menu_center!║   [94m2^)[0m Load file.          ║)
    echo !menu_center!║                          ║
    if "%1"=="3" (echo !menu_center!║   [94m3^)[0m [7mHelp.[27m               ║) else (echo !menu_center!║   [94m3^)[0m Help.               ║)
    if "%1"=="4" (echo !menu_center!║   [91m4^)[0m [7mExit.[27m               ║) else (echo !menu_center!║   [91m4^)[0m Exit.               ║)
    echo !menu_center!╚══════════════════════════╝
    ::timeout /t 1 > nul
    for /l %%G in (0,1,20) do (ping localhost -n 1 >nul)
exit /b





:file_mgr
    ::Small file manager
    
    type nul > "!temp1!"
    set file_mgr_fileCounter=1
    setlocal
    for /f "usebackq tokens=*" %%G in (`dir /b "!cd!"`) do echo %%~fG >> "!temp1!"
    endlocal
    set /a file_mgr_selectPointer=0
    set file_mgr_hr=
    set /a file_mgr_vertsize=lines_current-10
    
    call :mode_get
    call :window_opt cls
	call :window_opt hide
    
    for /l %%G in (1,1,!cols_current!) do set file_mgr_hr=!file_mgr_hr!─
    
    
    
:file_mgr_loop
    <nul set /p =[H
    set file_mgr_fileCounter=
    set "file_mgr_currentDir=!cd!"
    for /f "usebackq" %%G in ("!temp1!") do set /a file_mgr_fileCounter+=1
    
    echo [K[96mVIRINT !ver! - File Selector[0m
    echo [K
    echo [K  [96mUp: W  ^|  Down: S  ^|  Select: F  ^|  Drive: R[0m
    echo [K
    echo !file_mgr_hr!
    echo [K[7m Current directory: [27m !file_mgr_currentDir:\=[92m\[0m!
    echo [K
    if !file_mgr_selectPointer! == 0 (echo [K  [7m▲ Parent directory[27m) else (echo [K  ▲ Parent directory)
    setlocal
    for /f "usebackq tokens=*" %%G in ("!temp1!") do (
        set /a file_mgr_loopcounter+=1
        set "file_mgr_filename=%%~nxG"
        if !file_mgr_loopcounter! GEQ !file_mgr_vertsize! (
            if !file_mgr_selectPointer! GEQ !file_mgr_loopcounter! (echo   │ [7m ... [27m) else (echo   │  ... )
            goto file_mgr_endloop
        )
        
        set strWrapper=
        if !file_mgr_selectPointer! == !file_mgr_loopcounter! set strWrapper=[7m
        if exist "%%~nxG\*" set strWrapper=!strWrapper![96m
        if "%%~xG" == "!file_extension!" set strWrapper=!strWrapper![94m
        
        echo [K  │ !strWrapper! !file_mgr_filename! [27m[0m
    )
    :file_mgr_endloop
    endlocal
    echo   └─[J

    choice /c WSFR /n >nul
    if !errorlevel! == 1 if !file_mgr_selectPointer! GTR 0 (set /a file_mgr_selectPointer -= 1) else (set /a file_mgr_selectPointer = !file_mgr_fileCounter! 2> nul)
    if !errorlevel! == 2 if !file_mgr_selectPointer! LSS !file_mgr_fileCounter! (set /a file_mgr_selectPointer += 1) else (set /a file_mgr_selectPointer = 0)
    if !errorlevel! == 3 (
        if !file_mgr_selectPointer! == 0 (
            cd "!file_mgr_currentDir!\.." 2> nul
        ) else (
            if !file_mgr_selectPointer! LSS !file_mgr_vertsize! (
                set selectCounter=
                for /f "tokens=*" %%G in (!temp1!) do (
                    set /a selectCounter+=1
                    if !selectCounter!==!file_mgr_selectPointer! set file_mgr_selector=%%~nxG
                )
                if exist "!file_mgr_selector!\*" (
                    cd "!file_mgr_selector!" 2> nul
                ) else (
                    set "file_load_input=!file_mgr_selector!"
                    exit /b 0
                )
            )
        )
        goto file_mgr
    )
    if !errorlevel! == 4 (
        echo [2A!file_mgr_hr!
        set alphabet=0ABCEDFGHIJKLMNOPQRSTUWXYZ
        <nul set /p =Select a drive letter [A-Z]
        choice /c ABCEDFGHIJKLMNOPQRSTUWXYZ /n >nul
        call set file_mgr_newdrive=%%alphabet:~!errorlevel!,1%%
        !file_mgr_newdrive!: 2> nul
        goto file_mgr
    )
    goto file_mgr_loop
exit /b







:strlen
    ::strlen <resultVar> <stringVar> function by jeb (https://stackoverflow.com/a/5841587)
    (   
        setlocal EnableDelayedExpansion
        (set^ tmp=!%~2!)
        if defined tmp (
            set "len=1"
            for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
                if "!tmp:~%%P,1!" NEQ "" ( 
                    set /a "len+=%%P"
                    set "tmp=!tmp:~%%P!"
                )
            )
        ) ELSE (
            set len=0
        )
    )
    ( 
        endlocal
        set "%~1=%len%"
        exit /b
    )