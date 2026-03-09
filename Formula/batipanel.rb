class Batipanel < Formula
  desc "AI-powered terminal workspace manager for tmux"
  homepage "https://github.com/batiai/batipanel-cli"
  url "https://github.com/batiai/batipanel-cli/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on "tmux"

  # optional tools — installed by default, skip with --without-<name>
  depends_on "lazygit" => :recommended
  depends_on "btop"    => :recommended
  depends_on "yazi"    => :recommended
  depends_on "eza"     => :recommended

  def install
    # install source files to share/batipanel/
    pkgshare.install "bin/start.sh"
    (pkgshare/"lib").install Dir["lib/*.sh"]
    pkgshare.install "VERSION"
    (pkgshare/"layouts").install Dir["layouts/*.sh"]
    (pkgshare/"config").install "config/tmux.conf"
    (pkgshare/"completions").install "completions/batipanel.bash", "completions/_batipanel.zsh"
    (pkgshare/"examples").install "examples/project.sh"

    # wrapper: version-aware sync to ~/.batipanel/ on every invocation
    (bin/"batipanel").write <<~SH
      #!/usr/bin/env bash
      set -euo pipefail
      export BATIPANEL_HOME="$HOME/.batipanel"
      BATIPANEL_SRC="#{pkgshare}"

      # sync core files when brew version differs from local version
      BREW_VER=$(cat "$BATIPANEL_SRC/VERSION" 2>/dev/null || echo "0")
      LOCAL_VER=$(cat "$BATIPANEL_HOME/VERSION" 2>/dev/null || echo "")

      if [ "$BREW_VER" != "$LOCAL_VER" ]; then
        mkdir -p "$BATIPANEL_HOME"/{bin,lib,layouts,projects,config}
        cp "$BATIPANEL_SRC/start.sh"       "$BATIPANEL_HOME/bin/"
        cp "$BATIPANEL_SRC/lib/"*.sh       "$BATIPANEL_HOME/lib/"
        cp "$BATIPANEL_SRC/VERSION"        "$BATIPANEL_HOME/"
        cp "$BATIPANEL_SRC/layouts/"*.sh   "$BATIPANEL_HOME/layouts/"
        # completions
        mkdir -p "$BATIPANEL_HOME/completions"
        cp "$BATIPANEL_SRC/completions/"* "$BATIPANEL_HOME/completions/" 2>/dev/null || true
        # config: don't overwrite user customizations
        cp -n "$BATIPANEL_SRC/config/tmux.conf" "$BATIPANEL_HOME/config/" 2>/dev/null || true
        chmod +x "$BATIPANEL_HOME"/bin/*.sh "$BATIPANEL_HOME"/lib/*.sh "$BATIPANEL_HOME"/layouts/*.sh
      fi

      exec bash "$BATIPANEL_HOME/bin/start.sh" "$@"
    SH
  end

  def post_install
    # set up tmux.conf source line
    tmux_conf = File.expand_path("~/.tmux.conf")
    source_line = "source-file #{HOMEBREW_PREFIX}/share/batipanel/config/tmux.conf"
    batipanel_conf = "#{Dir.home}/.batipanel/config/tmux.conf"
    source_line_local = "source-file #{batipanel_conf}"

    if File.exist?(tmux_conf)
      content = File.read(tmux_conf)
      unless content.include?("batipanel")
        File.open(tmux_conf, "a") do |f|
          f.puts ""
          f.puts "# batipanel"
          f.puts source_line_local
        end
      end
    else
      File.write(tmux_conf, "# batipanel\n#{source_line_local}\n")
    end
  end

  def caveats
    <<~EOS
      Get started:
        batipanel              # first-run setup wizard
        batipanel help         # show all commands

      Add the short alias 'b':
        echo "alias b='batipanel'" >> ~/.zshrc   # or ~/.bashrc
        source ~/.zshrc

      Uninstall:
        brew uninstall batipanel
        bash ~/.batipanel/uninstall.sh   # remove config & aliases (optional)
    EOS
  end

  test do
    assert_match "batipanel", shell_output("#{bin}/batipanel --version")
  end
end
