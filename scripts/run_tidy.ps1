$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$compileCommands = Join-Path $root "build\build_tidy\compile_commands.json"
$tidy = "C:\Program Files\LLVM\bin\clang-tidy.exe"

Write-Host "Running clang-tidy using database: $compileCommands"

if (!(Test-Path $compileCommands)) {
    Write-Host "compile_commands.json not found: $compileCommands"
    pause
    exit 1
}

$paths = @(
    Join-Path $root "src"
    Join-Path $root "include"
)

# Get all the fire cpp/cc/h/hpp recursively
$files = foreach ($p in $paths) {
    Get-ChildItem -Path $p -Recurse -File | Where-Object { $_.Extension -in '.cpp', '.cc', '.h', '.hpp' }
}

if ($files.Count -eq 0) {
    Write-Host "No source/header files found"
    pause
    exit 1
}

$failed = 0

foreach ($f in $files) {
    Write-Host "`n--- Tidy: $($f.FullName)"

    & $tidy `
        -p "$compileCommands" `
        --config-file="$root\.clang-tidy" `
        --warnings-as-errors="*" `
        "$($f.FullName)"

    if ($LASTEXITCODE -ne 0) {
        $failed = 1
    }
}

if ($failed -ne 0) {
    Write-Host "`nclang-tidy failed."
    pause
    exit 1
}

Write-Host "`nclang-tidy finished successfully."
pause
exit 0
