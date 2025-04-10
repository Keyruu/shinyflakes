{lib, pkgs, ...}: {
  imports = [
    ./theme.nix
  ];

  home.packages = with pkgs; [ 
    walker
  ];

  home.file.".config/walker/config.toml".text = /* toml */ ''
    app_launch_prefix = ""
    terminal_title_flag = ""
    locale = ""
    close_when_open = false
    theme = "shiny"
    monitor = ""
    hotreload_theme = true
    as_window = false
    timeout = 0
    disable_click_to_close = false
    force_keyboard_focus = false

    [keys]
    accept_typeahead = ["tab"]
    trigger_labels = "lalt"
    next = ["ctrl j", "ctrl n", "down"]
    prev = ["ctrl k", "ctrl p", "up"]
    close = ["esc", "ctrl q"]
    remove_from_history = ["shift backspace"]
    resume_query = ["ctrl r"]
    toggle_exact_search = ["ctrl m"]

    [keys.activation_modifiers]
    keep_open = "shift"
    alternate = "alt"

    [keys.ai]
    clear_session = ["ctrl x"]
    copy_last_response = ["ctrl c"]
    resume_session = ["ctrl r"]
    run_last_response = ["ctrl e"]

    [events]
    on_activate = ""
    on_selection = ""
    on_exit = ""
    on_launch = ""
    on_query_change = ""

    [list]
    dynamic_sub = true
    keyboard_scroll_style = "vim"
    max_entries = 50
    show_initial_entries = true
    single_click = true
    visibility_threshold = 20
    placeholder = "No Results"

    [search]
    argument_delimiter = "#"
    placeholder = "Search..."
    delay = 0
    resume_last_query = false

    [activation_mode]
    labels = "123456789"

    [builtins.applications]
    weight = 5
    name = "applications"
    placeholder = "Applications"
    prioritize_new = true
    hide_actions_with_empty_query = true
    context_aware = true
    refresh = true
    show_sub_when_single = true
    show_icon_when_single = true
    show_generic = true
    history = true

    [builtins.applications.actions]
    enabled = true
    hide_category = false
    hide_without_query = true

    [builtins.bookmarks]
    weight = 5
    placeholder = "Bookmarks"
    name = "bookmarks"
    icon = "bookmark"
    switcher_only = true

    [[builtins.bookmarks.entries]]
    label = "Walker"
    url = "https://github.com/abenz1267/walker"
    keywords = ["walker", "github"]

    [builtins.xdph_picker]
    hidden = true
    weight = 5
    placeholder = "Screen/Window Picker"
    show_sub_when_single = true
    name = "xdphpicker"
    switcher_only = true

    [builtins.ai]
    weight = 5
    placeholder = "AI"
    name = "ai"
    icon = "help-browser"
    switcher_only = true

    [[builtins.ai.anthropic.prompts]]
    model = "claude-3-5-sonnet-20241022"
    temperature = 1
    max_tokens = 1_000
    label = "General Assistant"
    prompt = "You are a helpful general assistant. Keep your answers short and precise."

    [builtins.calc]
    require_number = true
    weight = 5
    name = "calc"
    icon = "accessories-calculator"
    placeholder = "Calculator"
    min_chars = 4

    [builtins.windows]
    weight = 5
    icon = "view-restore"
    name = "windows"
    placeholder = "Windows"
    show_icon_when_single = true

    [builtins.clipboard]
    always_put_new_on_top = true
    exec = "wl-copy"
    weight = 5
    name = "clipboard"
    avoid_line_breaks = true
    placeholder = "Clipboard"
    image_height = 300
    max_entries = 10
    switcher_only = true

    [builtins.commands]
    weight = 5
    icon = "utilities-terminal"
    switcher_only = true
    name = "commands"
    placeholder = "Commands"

    [builtins.custom_commands]
    weight = 5
    icon = "utilities-terminal"
    name = "custom_commands"
    placeholder = "Custom Commands"

    [builtins.emojis]
    exec = "wl-copy"
    weight = 5
    name = "emojis"
    placeholder = "Emojis"
    switcher_only = true
    history = true
    typeahead = true
    show_unqualified = false

    [builtins.symbols]
    after_copy = ""
    weight = 5
    name = "symbols"
    placeholder = "Symbols"
    switcher_only = true
    history = true
    typeahead = true

    [builtins.finder]
    use_fd = false
    weight = 5
    icon = "file"
    name = "finder"
    placeholder = "Finder"
    switcher_only = true
    ignore_gitignore = true
    refresh = true
    concurrency = 8
    show_icon_when_single = true
    preview_images = false

    [builtins.runner]
    eager_loading = true
    weight = 5
    icon = "utilities-terminal"
    name = "runner"
    placeholder = "Runner"
    typeahead = true
    history = true
    generic_entry = false
    refresh = true
    use_fd = false

    [builtins.ssh]
    weight = 5
    icon = "preferences-system-network"
    name = "ssh"
    placeholder = "SSH"
    switcher_only = true
    history = true
    refresh = true

    [builtins.switcher]
    weight = 5
    name = "switcher"
    placeholder = "Switcher"
    prefix = "/"

    [builtins.websearch]
    keep_selection = true
    weight = 5
    icon = "applications-internet"
    name = "websearch"
    placeholder = "Websearch"

    [[builtins.websearch.entries]]
    name = "Google"
    url = "https://www.google.com/search?q=%TERM%"

    [[builtins.websearch.entries]]
    name = "DuckDuckGo"
    url = "https://duckduckgo.com/?q=%TERM%"
    switcher_only = true

    [[builtins.websearch.entries]]
    name = "Ecosia"
    url = "https://www.ecosia.org/search?q=%TERM%"
    switcher_only = true

    [[builtins.websearch.entries]]
    name = "Yandex"
    url = "https://yandex.com/search/?text=%TERM%"
    switcher_only = true

    [builtins.dmenu]
    hidden = true
    weight = 5
    name = "dmenu"
    placeholder = "Dmenu"
    switcher_only = true

    [builtins.translation]
    delay = 1000
    weight = 5
    name = "translation"
    icon = "accessories-dictionary"
    placeholder = "Translation"
    switcher_only = true
    provider = "googlefree"

    [[plugins]]
    keep_sort = false
    name = "power"
    placeholder = "Power"
    recalculate_score = true
    show_icon_when_single = true
    switcher_only = true

    [[plugins.entries]]
    exec = "systemctl poweroff"
    icon = "system-shutdown"
    label = "Shutdown"

    [[plugins.entries]]
    exec = "systemctl reboot"
    icon = "system-reboot"
    label = "Reboot"

    [[plugins.entries]]
    exec = "${lib.getExe pkgs.hyprlock}"
    icon = "system-lock-screen"
    label = "Lock Screen"

    [[plugins.entries]]
    exec = "systemctl suspend"
    icon = "system-suspend"
    label = "Suspend"

    [[plugins.entries]]
    exec = "hyprctl dispatch exit"
    icon = "system-logout"
    label = "Logout"
  '';
}
