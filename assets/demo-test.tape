Output assets/demo-test.gif

Set FontSize 20
Set Width 1200
Set Height 600
Set Theme "Catppuccin Frappe"
Set Shell /usr/local/bin/pwsh
Set TypingSpeed 0
Set Padding 20

# Hidden setup — isolated temp repo so we don't touch the real one
Hide
Type "Set-StrictMode -Off"
Enter
Sleep 200ms
Type "$env:GWT_POST_CREATE_CMD = $null"
Enter
Sleep 200ms
Type "$GWT_MODULE_DIR = (Get-Location).Path"
Enter
Sleep 200ms
Type "$DEMO_DIR = Join-Path $GWT_MODULE_DIR 'demo-repo'"
Enter
Sleep 200ms
Type "if (Test-Path $DEMO_DIR) { Remove-Item $DEMO_DIR -Recurse -Force }"
Enter
Sleep 200ms
Type "New-Item -ItemType Directory -Path $DEMO_DIR -Force | Out-Null"
Enter
Sleep 200ms
Type "Set-Location $DEMO_DIR"
Enter
Sleep 200ms
Type "git init -q -b main && git config user.email demo@test.com && git config user.name Demo"
Enter
Sleep 200ms
Type "echo init > README.md && git add . && git commit -q -m init"
Enter
Sleep 500ms
Type "Import-Module (Join-Path $GWT_MODULE_DIR 'GWT/GWT.psd1') -Force"
Enter
Sleep 500ms
Ctrl+L
Show

# 1. Create worktrees
Type "# Create worktrees — just type gwt <branch>"
Enter
Sleep 500ms
Type "gwt feature/api-v2"
Enter
Sleep 1s

Type "gwt feature/api-v2-tests"
Enter
Sleep 1s

Ctrl+L
Sleep 200ms

# 2. Navigate between worktrees
Type "# Navigate up with gwt .. and to root with gwt ..."
Enter
Sleep 500ms
Type "gwt .."
Enter
Sleep 500ms

Type "gwt feature/api-v2-tests"
Enter
Sleep 500ms
Type "gwt ..."
Enter
Sleep 500ms

Ctrl+L
Sleep 200ms

# 3. List all worktrees
Type "# See all worktrees at a glance"
Enter
Sleep 500ms
Type "gwt -List"
Enter
Sleep 1s

Ctrl+L
Sleep 200ms

# 4. Show worktree info
Type "# Show stack info for current worktree"
Enter
Sleep 500ms
Type "gwt feature/api-v2"
Enter
Sleep 500ms
Type "gwt -Info"
Enter
Sleep 1s

Ctrl+L
Sleep 200ms

# 5. Prune worktrees
Type "# Clean up with interactive pruning"
Enter
Sleep 500ms
Type "gwt -Prune"
Enter
Sleep 500ms
Type "1"
Enter
Sleep 500ms
Type "y"
Enter
Sleep 200ms
Type "DELETE"
Enter
Sleep 1s

Ctrl+L
Sleep 200ms

# 6. Show help
Type "# Full help available"
Enter
Sleep 500ms
Type "gwt -Help"
Enter
Sleep 1s

# Clean up (hidden)
Hide
Type "Set-Location $GWT_MODULE_DIR"
Enter
Sleep 200ms
Type "Remove-Item $DEMO_DIR -Recurse -Force -ErrorAction SilentlyContinue"
Enter
Sleep 200ms
Type "Remove-Item (Join-Path (Split-Path $DEMO_DIR) 'demo-repo-*') -Recurse -Force -ErrorAction SilentlyContinue"
Enter
Sleep 200ms
Show
