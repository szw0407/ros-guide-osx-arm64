{
  description = "Nix + Conda (RoboStack ROS1 Noetic) example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # micromamba 用于轻量级 conda 管理
        micromamba = pkgs.micromamba;

        # 使用本地 env.yaml 作为 Conda 环境定义
        condaEnv = ./env.yaml;
      in {
        devShells.default = pkgs.mkShell {
          name = "ros1-conda";
          packages = [ micromamba pkgs.bashInteractive ];

          shellHook = ''
            echo "[NIX] Setting up Conda environment from ./env.yaml ..."
            export MAMBA_ROOT_PREFIX="$PWD/.conda"
            # 读取 env.yaml 里的 name 字段
            ENV_NAME=$(awk '/^name:/ {print $2}' ./env.yaml)
            export CONDA_PREFIX="$MAMBA_ROOT_PREFIX/envs/$ENV_NAME"

            if [ ! -d "$CONDA_PREFIX" ]; then
              echo "[NIX] Creating conda environment $ENV_NAME in ./.conda ..."
              micromamba create -y -f ${condaEnv} -p "$CONDA_PREFIX"
            fi


            eval "$(micromamba shell hook --shell zsh)"
            micromamba activate "$CONDA_PREFIX"

            echo "[ROS1] Environment ready!"
            echo "Run: roscore  / rostopic list  / rosrun turtlesim turtlesim_node"
          '';
        };
      });
}

