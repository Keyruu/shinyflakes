{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "dictate";
  runtimeInputs = with pkgs; [
    pipewire # pw-record
    curl
    jq
    wtype
    libnotify # notify-send
    coreutils
  ];
  # Toggle dictation: first call records, second stops and types the transcript.
  # Scaleway STT (OpenAI-compatible). Key read from the HM sops secret file
  # (default path below) so it works when launched from a niri keybind, where
  # the interactive shell.env is not sourced. Endpoint/model/key overridable.
  text = ''
    endpoint="''${DICTATE_ENDPOINT:-https://api.scaleway.ai/28f14df5-01a1-40d6-b09f-046cadfaf4c9/v1}"
    model="''${DICTATE_MODEL:-whisper-large-v3}"
    key_file="''${DICTATE_KEY_FILE:-$HOME/.config/sops-nix/secrets/scalewayKey}"

    runtime="''${XDG_RUNTIME_DIR:-/tmp}"
    wav="$runtime/dictate.wav"
    pidfile="$runtime/dictate.pid"

    fail() { notify-send -u critical "dictate" "$1"; exit 1; }

    # Second invocation while recording: stop, transcribe, type.
    if [[ -f $pidfile ]] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
      kill -INT "$(cat "$pidfile")" 2>/dev/null || true
      rm -f "$pidfile"
      # Give pw-record a moment to flush the WAV header/footer.
      for _ in 1 2 3 4 5 6 7 8 9 10; do [[ -s $wav ]] && break; sleep 0.1; done

      [[ -s $wav ]] || fail "no audio captured"
      [[ -r $key_file ]] || fail "missing key file: $key_file"

      notify-send -t 1500 "dictate" "transcribing…"
      resp=$(curl -sf --max-time 60 "$endpoint/audio/transcriptions" \
        -H "Authorization: Bearer $(cat "$key_file")" \
        -F "model=$model" \
        -F "file=@$wav;type=audio/wav") || fail "transcription request failed"

      text=$(jq -r '.text // empty' <<<"$resp")
      [[ -n $text ]] || fail "empty transcript"

      printf '%s' "$text" | wtype -
      exit 0
    fi

    # First invocation: start recording in the background.
    rm -f "$wav"
    pw-record --rate 16000 --channels 1 "$wav" &
    echo $! >"$pidfile"
    notify-send -t 1500 "dictate" "recording… (press again to stop)"
  '';
}
