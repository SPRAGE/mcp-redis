{
  description = "Redis MCP Server development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python313;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Python and uv
            python
            uv
            
            # Redis server for local development/testing
            redis
            
            # C/C++ build tools and libraries (required for numpy and other compiled packages)
            gcc
            stdenv.cc.cc.lib
            zlib
            
            # Additional development tools
            git
          ];

          shellHook = ''
            echo "Redis MCP Server development environment"
            echo "Python version: $(python --version)"
            echo "uv version: $(uv --version)"
            echo ""
            echo "Available commands:"
            echo "  uv sync          - Install project dependencies"
            echo "  uv run python    - Run Python with project environment"
            echo "  redis-server     - Start Redis server"
            echo ""
            
            # Set up Python environment variables
            export PYTHONPATH="$PWD/src:$PYTHONPATH"
            
            # Ensure uv uses the correct Python version
            export UV_PYTHON="${python}/bin/python"
            
            # Set up library paths for compiled packages
            export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"
          '';

          # Environment variables
          env = {
            # Force uv to use the specified Python version
            UV_PYTHON = "${python}/bin/python";
            PYTHONPATH = "$PWD/src";
            # Library paths for compiled packages
            LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib";
          };
        };

        # Package definition for the Redis MCP Server
        packages.default = python.pkgs.buildPythonPackage rec {
          pname = "redis-mcp-server";
          version = "0.2.0-alpha";
          
          src = ./.;
          
          format = "pyproject";
          
          nativeBuildInputs = with python.pkgs; [
            setuptools
            wheel
          ];
          
          propagatedBuildInputs = with python.pkgs; [
            # Note: These may need to be adjusted based on available nixpkgs versions
            # You might need to use pip/uv for some MCP-specific packages
          ];
          
          # Skip tests for now as they may require Redis server
          doCheck = false;
          
          meta = with pkgs.lib; {
            description = "Redis MCP Server, by Redis";
            homepage = "https://github.com/redis/mcp-redis";
            license = licenses.mit; # Adjust based on your LICENSE file
            maintainers = [ ];
          };
        };

        # Apps for easy running
        apps = {
          default = {
            type = "app";
            program = "${pkgs.writeShellScript "redis-mcp-server" ''
              export UV_PYTHON="${python}/bin/python"
              export PYTHONPATH="$PWD/src:$PYTHONPATH"
              cd ${self}
              exec ${pkgs.uv}/bin/uv run python -m src.main "$@"
            ''}";
          };
          
          redis-server = {
            type = "app";
            program = "${pkgs.redis}/bin/redis-server";
          };
        };
      });
}
