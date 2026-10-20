{
  description = "%hits: a leaderboard for app installs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Kernel source for the marks desk/ leaves out. Keep in step with
    # desk/sys.kelvin.
    urbit = {
      url = "github:urbit/urbit/408k-2";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      urbit,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # The %hits desk: desk/ laid over the marks that |new-desk copies
          # from %base. Store files are read-only and Vere crashes when it
          # can't delete a file in a mount, so replace the mounted desk with
          # a writable copy, then `|commit %hits`:
          #   find <pier>/hits -mindepth 1 -delete
          #   cp -R result/. <pier>/hits/ && chmod -R u+w <pier>/hits
          # For a pier on another machine (macOS rsync ignores --chmod):
          #   rm -rf hits-rw && cp -RL result hits-rw && chmod -R u+w hits-rw
          #   rsync -rpc --delete hits-rw/ <host>:<pier>/hits/
          desk = pkgs.runCommand "hits-desk" { } ''
            mkdir -p $out/mar
            cp -L --no-preserve=mode ${urbit}/pkg/arvo/mar/{hoon,kelvin,noun,txt}.hoon $out/mar/
            cp -r --no-preserve=mode ${./desk}/. $out/
          '';

          default = self.packages.${system}.desk;
        }
      );
    };
}
