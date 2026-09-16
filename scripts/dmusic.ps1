# ==========================================
# DMUSIC - PowerShell version
# winget install Gyan.FFmpeg yt-dlp.yt-dlp junegunn.fzf
# ==========================================

# PATH SCRIPT
# ==========================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TitleDir  = $ScriptDir

# MUSIC DIRECTORY
# ==========================================

$TargetDir = Join-Path $HOME "Music"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir | Out-Null
}

# HELPER: READ SINGLE KEY (read -n1 -s)
# ==========================================

function Get-SingleKey {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    return $key.Character.ToString()
}

# SHOW TITLE
# ==========================================

function Show-Title {

    Clear-Host

    $TitleFile = Join-Path $TitleDir "titledmusic.txt"

    if (Test-Path $TitleFile) {
        Write-Host (Get-Content $TitleFile -Raw) -ForegroundColor Cyan
    }
    else {
        Write-Host "DMUSIC" -ForegroundColor Cyan
    }
}

# SEARCH MUSIC
# ==========================================

function Search-Music {

    Write-Host "Search Music" -ForegroundColor Cyan

    $query = Read-Host "Artist / Song Name"

    if ([string]::IsNullOrWhiteSpace($query)) {
        return
    }

    Write-Host "Loading list..." -ForegroundColor Yellow

    $results = yt-dlp `
        --flat-playlist `
        --print "%(title)s`t%(id)s" `
        --geo-bypass `
        "https://music.youtube.com/search?q=$query" 2>$null |
        Select-Object -First 60

    if (-not $results) {
        Write-Host "No results found." -ForegroundColor Red
        Start-Sleep -Seconds 1
        return
    }

    $selected = $results |
        fzf `
            --header="[j/k: Move | Enter: Select | ESC: Cancel]" `
            --prompt="Music Search: "

    if (-not [string]::IsNullOrWhiteSpace($selected)) {

        $videoId = ($selected -split "`t")[-1]

        $url = "https://music.youtube.com/watch?v=$videoId"

        Download-Music $url
    }
}

# DOWNLOAD MUSIC
# ==========================================

function Download-Music {

    param (
        [string]$DlUrl
    )

    Write-Host ""
    Write-Host "Select Format:" -ForegroundColor Yellow

    Write-Host "m) mp3 (Audio standard)"
    Write-Host "f) flac (High quality)"
    Write-Host -NoNewline "Select option [m/f]: "

    $formatChoice = Get-SingleKey
    Write-Host $formatChoice

    switch ($formatChoice.ToLower()) {

        "m" {
            $ext = "mp3"
        }

        "f" {
            $ext = "flac"
        }

        default {
            Write-Host "Invalid option. Defaulting to mp3..."
            $ext = "mp3"
        }
    }

    Write-Host ""
    Write-Host "Downloading and processing artwork..." -ForegroundColor Cyan

    $outputTemplate = Join-Path $TargetDir "%(title)s.%(ext)s"

    yt-dlp `
        -x `
        --audio-format $ext `
        --audio-quality 0 `
        --format "bestaudio/best" `
        --geo-bypass `
        --no-playlist `
        --add-metadata `
        --embed-thumbnail `
        --convert-thumbnails jpg `
        --ppa "EmbedThumbnail+ffmpeg_o:-c:v mjpeg -vf crop='ih:ih'" `
        -o "$outputTemplate" `
        "$DlUrl"

    Write-Host ""

    Write-Host "Music saved to: $TargetDir" -ForegroundColor Yellow

    Start-Sleep -Seconds 1
}

# MAIN MENU
# ==========================================

while ($true) {

    Clear-Host

    Show-Title

    Write-Host ""
    Write-Host "--------------------------"
    Write-Host "s)     Search Music"
    Write-Host "u)     Paste URL manually"
    Write-Host "q)     Quit"
    Write-Host "--------------------------"
    Write-Host -NoNewline "Select action: "

    $mainChoice = Get-SingleKey
    Write-Host $mainChoice

    switch ($mainChoice.ToLower()) {

        "s" {
            Search-Music
        }

        "u" {

            Write-Host ""
            Write-Host "Paste URL manually (Press Enter to cancel)"

            $manualUrl = Read-Host ">"

            if (-not [string]::IsNullOrWhiteSpace($manualUrl)) {
                Download-Music $manualUrl
            }
        }

        "q" {
            Write-Host "Quit"
            exit 0
        }

        default {
            Write-Host "Invalid option" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
