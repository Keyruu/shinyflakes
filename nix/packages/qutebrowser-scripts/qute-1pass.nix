{ pkgs }:
pkgs.writeShellApplication {
  name = "qute-1pass";
  runtimeInputs = with pkgs; [ vicinae jq wl-clipboard gawk gnused systemd coreutils ];
  excludeShellChecks = [ "SC2001" "SC2181" ];
  text = ''
    set +e
    export PATH="/run/wrappers/bin:$PATH"

    _op() {
      systemd-run --user --pipe --wait --quiet \
        /run/wrappers/bin/op "$@" 2>/dev/null
    }

    js_escape() {
      sed "s,[\\\\\\\'\"\\/],\\\\\&,g" <<< "$1"
    }

    fill_form_js() {
      cat <<JSEOF
    (function() {
      function isVisible(el) {
        var s = getComputedStyle(el);
        return s.visibility === "visible" && s.display !== "none" && s.opacity !== "0"
          && el.offsetWidth > 0 && el.offsetHeight > 0;
      }
      var filled = false;
      document.querySelectorAll("form").forEach(function(form) {
        var pw = form.querySelector('input[type="password"]');
        if (!pw) return;
        pw.focus(); pw.value = "$(js_escape "$PASSWORD")";
        pw.dispatchEvent(new Event("input", {bubbles:true}));
        pw.dispatchEvent(new Event("change", {bubbles:true}));
        pw.blur();
        var user = form.querySelector('input[type="text"], input[type="email"]');
        if (user && isVisible(user)) {
          user.focus(); user.value = "$(js_escape "$USERNAME")";
          user.dispatchEvent(new Event("input", {bubbles:true}));
          user.dispatchEvent(new Event("change", {bubbles:true}));
          user.blur();
        }
        filled = true;
      });
      if (!filled) {
        var pw = document.querySelector('input[type="password"]');
        if (pw) {
          pw.focus(); pw.value = "$(js_escape "$PASSWORD")";
          pw.dispatchEvent(new Event("input", {bubbles:true}));
          pw.dispatchEvent(new Event("change", {bubbles:true}));
        }
        var user = document.querySelector('input[type="text"], input[type="email"]');
        if (user && isVisible(user)) {
          user.focus(); user.value = "$(js_escape "$USERNAME")";
          user.dispatchEvent(new Event("input", {bubbles:true}));
          user.dispatchEvent(new Event("change", {bubbles:true}));
        }
      }
    })();
    JSEOF
    }

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

    ITEM=$(_op item get "$ITEM_ID" --format json)
    if [ $? -ne 0 ] || [ -z "$ITEM" ]; then
      echo "message-error '1Password: failed to get item'" >> "$QUTE_FIFO"
      exit 1
    fi

    USERNAME=$(echo "$ITEM" | jq -r '[.fields[] | select(.purpose == "USERNAME")] | first | .value // empty')
    PASSWORD=$(echo "$ITEM" | jq -r '[.fields[] | select(.purpose == "PASSWORD")] | first | .value // empty')

    if [ -z "$PASSWORD" ]; then
      echo "message-error '1Password: no password found'" >> "$QUTE_FIFO"
      exit 1
    fi

    JS=$(fill_form_js | sed 's,//.*$,,' | tr '\n' ' ')
    echo "jseval -q $JS" >> "$QUTE_FIFO"

    TOTP=$(_op item get "$ITEM_ID" --otp) || true
    if [ -n "$TOTP" ]; then
      echo "$TOTP" | wl-copy
      echo "message-info '1Password: filled $FULL_DOMAIN (TOTP copied to clipboard)'" >> "$QUTE_FIFO"
    else
      echo "message-info '1Password: filled $FULL_DOMAIN'" >> "$QUTE_FIFO"
    fi
  '';
}
