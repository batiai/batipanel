# batipanel demo recording — requires: https://github.com/charmbracelet/vhs
# Run: vhs docs/demo.tape

Output docs/demo.gif
Set FontFamily "MesloLGS Nerd Font"
Set FontSize 14
Set Width 1200
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms
Set Padding 20

# --- Scene 1: Fresh server (before) ---
Type "# Fresh Linux server — nothing installed"
Enter
Sleep 500ms
Type "which tmux claude lazygit btop 2>/dev/null || echo 'nothing here'"
Enter
Sleep 1.5s

# --- Scene 2: One-command install ---
Type "curl -fsSL batipanel.com/install.sh | bash"
Enter
Sleep 15s

# --- Scene 3: Activate ---
Type "exec $SHELL -l"
Enter
Sleep 2s

# --- Scene 4: Launch workspace ---
Type "b myproject"
Enter
Sleep 5s

# --- Scene 5: Show the result ---
Sleep 3s
