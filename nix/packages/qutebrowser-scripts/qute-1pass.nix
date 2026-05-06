{ pkgs }:
pkgs.writeShellApplication {
  name = "qute-1pass";
  runtimeInputs = with pkgs; [
    vicinae
    jq
    wl-clipboard
    gawk
    gnused
    systemd
    coreutils
    bash
  ];
  excludeShellChecks = [
    "SC1003"
    "SC2001"
    "SC2181"
    "SC2016"
  ];
  text = ''
    set +e
    export PATH="/run/wrappers/bin:$PATH"

    _op() {
      systemd-run --user --pipe --wait --quiet \
        op "$@" 2>/dev/null
    }

    js_escape() {
      local s="$1"
      s=$(printf '%s' "$s" | sed 's/\\/\\\\/g; s/"/\\"/g; s/'"'"'/\\'"'"'/g; s/`/\\`/g')
      s=$(printf '%s' "$s" | tr '\n' ' ')
      printf '%s' "$s"
    }

    fill_form_js() {
      local submit="$1"
      cat <<JSEOF
    (function() {
      var username = "$(js_escape "$USERNAME")";
      var password = "$(js_escape "$PASSWORD")";
      var doSubmit = $([ "$submit" = "1" ] && echo "true" || echo "false");

      function isVisible(el) {
        var s = getComputedStyle(el);
        return s.visibility !== "hidden" && s.display !== "none" && s.opacity !== "0"
          && el.offsetWidth > 0 && el.offsetHeight > 0;
      }

      function fillInput(el, value) {
        if (!el) return;
        var proto = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
        if (proto && proto.set) proto.set.call(el, value);
        else el.value = value;
        el.dispatchEvent(new Event('input', {bubbles: true}));
        el.dispatchEvent(new Event('change', {bubbles: true}));
      }

      function findPassword(root) {
        return root.querySelector('input[type="password"]:not([hidden])');
      }

      function findUsername(root) {
        var selectors = [
          'input[autocomplete="username"]',
          'input[autocomplete="email"]',
          'input[name="username"]',
          'input[name="login"]',
          'input[name="user"]',
          'input[name="email"]',
          'input[id="username"]',
          'input[id="login"]',
          'input[id="email"]',
          'input[type="email"]',
          'input[type="text"]'
        ];
        for (var i = 0; i < selectors.length; i++) {
          var el = root.querySelector(selectors[i]);
          if (el && isVisible(el)) return el;
        }
        return null;
      }

      function fillScope(root) {
        var pw = findPassword(root);
        if (!pw) return false;
        fillInput(pw, password);
        var user = findUsername(root);
        if (user) fillInput(user, username);
        if (doSubmit) {
          var form = pw.closest('form');
          if (form) {
            var btn = form.querySelector('button[type="submit"], input[type="submit"]')
              || form.querySelector('button:not([type="button"])');
            if (btn) btn.click();
            else form.requestSubmit();
          }
        }
        return true;
      }

      var forms = document.querySelectorAll('form');
      var filled = false;
      forms.forEach(function(f) { if (findPassword(f)) filled = fillScope(f) || filled; });
      if (!filled) fillScope(document);
    })();
    JSEOF
    }

    MODE="''${1:-fill}"

    if [ -z "$QUTE_FIFO" ]; then
      echo "This script must be run as a qutebrowser userscript" >&2
      exit 1
    fi

    FULL_DOMAIN=$(echo "$QUTE_URL" | awk -F/ '{print $3}' | sed 's/^www\.//')
    BASE_DOMAIN=$(echo "$FULL_DOMAIN" | awk -F. '{if(NF>2) print $(NF-1)"."$NF; else print $0}')

    echo "message-info 'Searching 1Password for $FULL_DOMAIN...'" >> "$QUTE_FIFO"

    ITEMS=$(_op item list --categories Login --format json)
    if [ $? -ne 0 ] || [ -z "$ITEMS" ]; then
      echo "message-error '1Password: failed to list items (is the app unlocked?)'" >> "$QUTE_FIFO"
      exit 1
    fi

    MATCHES=$(echo "$ITEMS" | jq -r --arg full "$FULL_DOMAIN" --arg base "$BASE_DOMAIN" '
      [.[] | select(.urls // [] | any(.href | test($full; "i") or test($base; "i")))]
    ')
    COUNT=$(echo "$MATCHES" | jq 'length')

    pick_item() {
      local items="$1" prompt="$2"
      local selection
      selection=$(echo "$items" | jq -r '.[] | "\(.id)\t\(.title) (\(.additional_information // "no user"))"' | vicinae dmenu -p "$prompt")
      echo "$selection" | cut -f1
    }

    if [ "$COUNT" -eq 0 ]; then
      echo "message-warning '1Password: no match for $FULL_DOMAIN, showing all items'" >> "$QUTE_FIFO"
      ITEM_ID=$(pick_item "$ITEMS" "1Password item:")
    elif [ "$COUNT" -eq 1 ]; then
      ITEM_ID=$(echo "$MATCHES" | jq -r '.[0].id')
    else
      ITEM_ID=$(pick_item "$MATCHES" "1Password ($FULL_DOMAIN):")
    fi

    if [ -z "$ITEM_ID" ]; then
      echo "message-error '1Password: no item selected'" >> "$QUTE_FIFO"
      exit 1
    fi

    RESULT=$(systemd-run --user --pipe --wait --quiet bash -c "
      ITEM=\$(op item get '$ITEM_ID' --format json 2>/dev/null)
      echo \"\$ITEM\"
      echo '___SEPARATOR___'
      op item get '$ITEM_ID' --otp 2>/dev/null || true
    ")

    ITEM=$(echo "$RESULT" | sed '/^___SEPARATOR___$/,$d')
    TOTP=$(echo "$RESULT" | sed '1,/^___SEPARATOR___$/d')

    if [ -z "$ITEM" ]; then
      echo "message-error '1Password: failed to get item'" >> "$QUTE_FIFO"
      exit 1
    fi

    USERNAME=$(echo "$ITEM" | jq -r '[.fields[] | select(.purpose == "USERNAME")] | first | .value // empty')
    PASSWORD=$(echo "$ITEM" | jq -r '[.fields[] | select(.purpose == "PASSWORD")] | first | .value // empty')

    if [ -z "$PASSWORD" ]; then
      echo "message-error '1Password: no password found'" >> "$QUTE_FIFO"
      exit 1
    fi

    SUBMIT=$([ "$MODE" = "submit" ] && echo "1" || echo "0")
    JS=$(fill_form_js "$SUBMIT" | tr '\n' ' ')
    echo "jseval -q $JS" >> "$QUTE_FIFO"

    if [ -n "$TOTP" ]; then
      echo "$TOTP" | wl-copy
      echo "message-info '1Password: filled $FULL_DOMAIN (TOTP copied to clipboard)'" >> "$QUTE_FIFO"
    else
      echo "message-info '1Password: filled $FULL_DOMAIN'" >> "$QUTE_FIFO"
    fi
  '';
}
