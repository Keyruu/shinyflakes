{
  programs.zed-editor.userTasks = [
    {
      label = "lazygit";
      command = "lazygit -p $ZED_WORKTREE_ROOT";
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "center";
    }
    {
      label = "yazi";
      command = "yazi $ZED_FILE";
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "center";
    }
    {
      label = "yazi-root";
      command = "yazi $ZED_WORKTREE_ROOT";
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "center";
    }
    {
      label = "nvim";
      command = "nvim $ZED_FILE";
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "center";
    }
    {
      label = "nvim-root";
      command = "nvim $ZED_WORKTREE_ROOT";
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "center";
    }
    {
      label = "tv-text";
      command = ''sel=$(tv text) && [ -n "$sel" ] && zeditor "$sel"'';
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "center";
    }
    {
      label = "claude";
      command = "claude";
      shell = {
        program = "sh";
      };
      hide = "always";
      reveal_target = "right";
    }
  ];
}
