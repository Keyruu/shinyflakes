{ ... }:
{
  programs.k9s = {
    enable = true;

    aliases = {
      aliases = {
        ss = "statefulsets";
        sec = "secrets";
        dep = "deployments";
        dp = "deployments";
      };
    };

    hotkey = {
      hotKeys = {
        shift-0 = {
          shortCut = "Shift-0";
          description = "Viewing pods";
          command = "pods";
        };

        shift-1 = {
          shortCut = "Shift-1";
          description = "View deployments";
          command = "dp";
        };

        shift-2 = {
          shortCut = "Shift-2";
          description = "View statefulsets";
          command = "ss";
        };

        shift-3 = {
          shortCut = "Shift-3";
          description = "View jobs";
          command = "jobs";
        };

        shift-4 = {
          shortCut = "Shift-4";
          description = "View secrets";
          command = "sec";
        };

        shift-5 = {
          shortCut = "Shift-5";
          description = "View configmaps";
          command = "cm";
        };

        shift-6 = {
          shortCut = "Shift-6";
          description = "View services";
          command = "svc";
        };

        shift-7 = {
          shortCut = "Shift-7";
          description = "View ingress";
          command = "ing";
        };

        shift-8 = {
          shortCut = "Shift-8";
          description = "View PVCs";
          command = "pvc";
        };

        shift-9 = {
          shortCut = "Shift-9";
          description = "View namespaces";
          command = "ns";
        };

        f1 = {
          shortCut = "F1";
          description = "Galaxy";
          command = "ctx galaxy";
        };

        f2 = {
          shortCut = "F2";
          description = "caas-shared-devl-2";
          command = "ctx caas-shared-devl-2";
        };

        f3 = {
          shortCut = "F3";
          description = "caas-shared-prod-2";
          command = "ctx caas-shared-prod-2";
        };

        f4 = {
          shortCut = "F4";
          description = "View nodes";
          command = "no";
        };
      };
    };

    plugin = {
      plugins = {
        # See https://k9scli.io/topics/plugins/
        raw-logs-follow = {
          shortCut = "Ctrl-L";
          description = "logs -f";
          scopes = [ "po" ];
          command = "kubectl";
          background = false;
          args = [
            "logs"
            "-f"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
            "--kubeconfig"
            "$KUBECONFIG"
          ];
        };
        log-less = {
          shortCut = "Shift-L";
          description = "logs|less";
          scopes = [ "po" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''"$@" | less''
            "dummy-arg"
            "kubectl"
            "logs"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
            "--kubeconfig"
            "$KUBECONFIG"
          ];
        };
        log-less-container = {
          shortCut = "Shift-L";
          description = "logs|less";
          scopes = [ "containers" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''"$@" | less''
            "dummy-arg"
            "kubectl"
            "logs"
            "-c"
            "$NAME"
            "$POD"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
            "--kubeconfig"
            "$KUBECONFIG"
          ];
        };
        dive = {
          shortCut = "Shift-I";
          confirm = false;
          description = "Dive image";
          scopes = [ "containers" ];
          command = "dive";
          background = false;
          args = [ "$COL-IMAGE" ];
        };
        debug = {
          shortCut = "Shift-B";
          description = "Add debug container";
          dangerous = true;
          scopes = [ "containers" ];
          command = "bash";
          background = false;
          confirm = true;
          args = [
            "-c"
            "kubectl debug -it --context $CONTEXT -n=$NAMESPACE $POD --target=$NAME --image=nicolaka/netshoot:v0.12 --share-processes -- bash"
          ];
        };
        stern = {
          shortCut = "Shift-Q";
          confirm = false;
          description = "Logs <Stern>";
          scopes = [ "pods" ];
          command = "stern";
          background = false;
          args = [
            "--tail"
            "50"
            "$FILTER"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
          ];
        };
      };
    };
  };
}
