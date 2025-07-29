# Copyright (C) 2025 Shota FUJI
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-only

{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        nativeBuildInputs = with pkgs; [
          zig
          asciidoctor
        ];

        buildInputs = with pkgs; [
          # Database of current and historical time zones
          # http://www.iana.org/time-zones
          tzdata
        ];
      in
      {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          inherit buildInputs;

          pname = "sunwaitz";
          version = "0.91.0";
          src = pkgs.lib.sourceByRegex ./. [
            "^src.*"
            "^docs.*"
            "^dist.*"
            "build.zig"
          ];

          meta = {
            mainProgram = "sunwait";
          };

          nativeBuildInputs = nativeBuildInputs ++ [ pkgs.zig.hook ];

          zigBuildFlags = [
            "-Dman"
            "-Dzsh-completion"
            "-Dfish-completion"
            "-Dbash-completion"
          ];
        };

        apps =
          let
            sunwait = self.packages.${system}.default;
          in
          {
            # $ nix run .#zsh
            # Bare-bone Zsh session for testing completion
            zsh =
              let
                test-zsh = pkgs.symlinkJoin {
                  name = "sunwait-test-zsh";

                  nativeBuildInputs = [ pkgs.makeWrapper ];

                  paths = [
                    pkgs.zsh
                    self.packages.${system}.default
                  ];

                  postBuild = ''
                    mkdir -p $out/share/$name
                    echo 'fpath+=${sunwait}/share/zsh/site-functions' >> $out/share/$name/.zshrc
                    echo 'autoload -U compinit && compinit' >> $out/share/$name/.zshrc
                    chmod +x $out/share/$name/.zshrc

                    wrapProgram $out/bin/zsh \
                      --set ZDOTDIR $out/share/$name \
                      --set MANPATH :${sunwait}/share/man \
                      --prefix PATH : ${pkgs.lib.makeBinPath [ sunwait ]}
                  '';
                };
              in
              {
                type = "app";
                program = "${test-zsh}/bin/zsh";
              };

            # $ nix run .#fish
            # Fish session with completion configured
            fish =
              let
                test-fish = pkgs.symlinkJoin {
                  name = "sunwait-test-fish";

                  nativeBuildInputs = [ pkgs.makeWrapper ];

                  paths = [
                    pkgs.fish
                    self.packages.${system}.default
                  ];

                  postBuild = ''
                    wrapProgram $out/bin/fish \
                      --set MANPATH :${sunwait}/share/man \
                      --prefix fish_complete_path : ${sunwait}/share/fish/vendor_completions.d \
                      --prefix PATH : ${pkgs.lib.makeBinPath [ sunwait ]}
                  '';
                };
              in
              {
                type = "app";
                program = "${test-fish}/bin/fish";
              };

            # $ nix run .#bash
            # Bare-bone bash session for testing completion
            bash =
              let
                test-bash = pkgs.symlinkJoin {
                  name = "sunwait-test-bash";

                  nativeBuildInputs = [ pkgs.makeWrapper ];

                  paths = [
                    pkgs.bash
                    pkgs.bash-completion
                    self.packages.${system}.default
                  ];

                  postBuild = ''
                    mkdir -p $out/share/$name
                    echo 'if ! shopt -oq posix; then' >> $out/share/$name/.bashrc
                    echo '  source ${pkgs.bash-completion}/share/bash-completion/bash_completion' >> $out/share/$name/.bashrc
                    echo 'fi' >> $out/share/$name/.bashrc
                    chmod +x $out/share/$name/.bashrc

                    wrapProgram $out/bin/bash \
                      --set MANPATH :${sunwait}/share/man \
                      --prefix PATH : ${pkgs.lib.makeBinPath [ sunwait ]} \
                      --add-flags '--rcfile' \
                      --add-flags $out/share/$name/.bashrc
                  '';
                };
              in
              {
                type = "app";
                program = "${test-bash}/bin/bash";
              };
          };

        devShell = pkgs.mkShell {
          inherit nativeBuildInputs buildInputs;

          packages = with pkgs; [
            # Code formatter
            # https://dprint.dev/
            dprint

            # Official formatter for Nix code
            # https://hackage.haskell.org/package/nixfmt
            nixfmt-rfc-style

            # Copyright and license linter based on SPDX
            # https://github.com/fsfe/reuse-tool
            reuse

            # Open Source implementation of the Windows API on top of X, OpenGL, and Unix
            # https://www.winehq.org/
            wineWowPackages.stable

            # For text editors, optional.
            # > ZLS is a non-official implementation of the Language Server Protocol for Zig
            # https://github.com/zigtools/zls
            zls
          ];
        };
      }
    );
}
