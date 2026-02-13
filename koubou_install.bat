@echo off
chcp 65001 >nul 2>&1
title multi-agent-daiku Installer

echo.
echo   ╔══════════════════════════════════════════════════════════╗
echo   ║  🪚 multi-agent-daiku - Auto Installer                  ║
echo   ║     全自動セットアップ                                   ║
echo   ╚══════════════════════════════════════════════════════════╝
echo.

REM ===== Step 1: Check/Install WSL2 =====
echo   [1/4] Checking WSL2...
echo         WSL2 確認中...

wsl.exe --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   WSL2 not found. Installing automatically...
    echo   WSL2 が見つかりません。自動インストール中...
    echo.

    REM 管理者権限で実行されているか確認
    net session >nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo   ╔══════════════════════════════════════════════════════════╗
        echo   ║  ⚠️  Administrator privileges required!                  ║
        echo   ║     管理者権限が必要です                                 ║
        echo   ╚══════════════════════════════════════════════════════════╝
        echo.
        echo   Right-click koubou_install.bat and select "Run as administrator"
        echo   koubou_install.bat を右クリック→「管理者として実行」
        echo.
        pause
        exit /b 1
    )

    echo   Installing WSL2...
    wsl --install --no-launch

    echo.
    echo   ╔══════════════════════════════════════════════════════════╗
    echo   ║  🔄 Restart required!                                    ║
    echo   ║     再起動が必要です                                     ║
    echo   ╚══════════════════════════════════════════════════════════╝
    echo.
    echo   After restart, run koubou_install.bat again.
    echo   再起動後、もう一度 koubou_install.bat を実行してください。
    echo.
    pause
    exit /b 0
)
echo   ✅ WSL2 OK
echo.

REM ===== Step 2: Check/Install Ubuntu =====
echo   [2/4] Checking Ubuntu...
echo         Ubuntu 確認中...

wsl.exe -l -q 2>nul | findstr /i "ubuntu" >nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   Ubuntu not found. Installing automatically...
    echo   Ubuntu が見つかりません。自動インストール中...
    echo.

    wsl --install -d Ubuntu --no-launch

    echo.
    echo   ╔══════════════════════════════════════════════════════════╗
    echo   ║  📝 Ubuntu initial setup required!                       ║
    echo   ║     Ubuntu の初期設定が必要です                          ║
    echo   ╚══════════════════════════════════════════════════════════╝
    echo.
    echo   1. Open Ubuntu from Start Menu
    echo      スタートメニューから Ubuntu を開く
    echo.
    echo   2. Set your username and password
    echo      ユーザー名とパスワードを設定
    echo.
    echo   3. Run koubou_install.bat again
    echo      もう一度 koubou_install.bat を実行
    echo.
    pause
    exit /b 0
)
echo   ✅ Ubuntu OK
echo.

REM ===== Step 3: Get script path for WSL =====
echo   [3/4] Preparing WSL path...
echo         WSL パス準備中...

REM 現在のディレクトリをWSLパスに変換
set "WIN_PATH=%~dp0"
set "WIN_PATH=%WIN_PATH:\=/%"
set "WIN_PATH=%WIN_PATH:C:=/mnt/c%"
set "WIN_PATH=%WIN_PATH:D:=/mnt/d%"
set "WIN_PATH=%WIN_PATH:E:=/mnt/e%"
REM 末尾のスラッシュを削除
if "%WIN_PATH:~-1%"=="/" set "WIN_PATH=%WIN_PATH:~0,-1%"

echo   ✅ Path: %WIN_PATH%
echo.

REM ===== Step 4: Run koubou_junbi.sh =====
echo   [4/4] Running koubou_junbi.sh...
echo         koubou_junbi.sh 実行中...
echo.

wsl.exe -e bash -c "cd '%WIN_PATH%' && chmod +x *.sh && ./koubou_junbi.sh"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   ╔══════════════════════════════════════════════════════════╗
    echo   ║  ❌ Setup failed!                                        ║
    echo   ╚══════════════════════════════════════════════════════════╝
    echo.
    pause
    exit /b 1
)

echo.
echo   ╔══════════════════════════════════════════════════════════╗
echo   ║  ✅ Installation completed!                              ║
echo   ║     インストール完了！                                   ║
echo   ╚══════════════════════════════════════════════════════════╝
echo.
echo   ┌──────────────────────────────────────────────────────────┐
echo   │  🚀 NEXT: Start the system                               │
echo   │     次のステップ: システム起動                           │
echo   ├──────────────────────────────────────────────────────────┤
echo   │                                                          │
echo   │  Open WSL terminal and run:                              │
echo   │  WSL ターミナルを開いて実行:                             │
echo   │                                                          │
echo   │    cd %WIN_PATH%
echo   │    ./koubou_hajime.sh                              │
echo   │                                                          │
echo   └──────────────────────────────────────────────────────────┘
echo.
pause
exit /b 0
