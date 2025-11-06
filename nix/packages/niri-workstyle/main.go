package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/pelletier/go-toml/v2"
)

type Config struct {
	Default       string            `toml:"default"`
	FocusedFormat string            `toml:"focused_format"`
	Matches       map[string]string `toml:"matches"`
}

type Window struct {
	AppID       string `json:"app_id"`
	IsFocused   bool   `json:"is_focused"`
	WorkspaceID int    `json:"workspace_id"`
	IsFloating  bool   `json:"is_floating"`
	Layout      struct {
		PosInScrollingLayout []int `json:"pos_in_scrolling_layout"`
	} `json:"layout"`
}

func loadConfig() (*Config, error) {
	configDir := os.Getenv("XDG_CONFIG_HOME")
	if configDir == "" {
		home, _ := os.UserHomeDir()
		configDir = filepath.Join(home, ".config")
	}

	configPath := filepath.Join(configDir, "niri", "workstyle.toml")

	cfg := &Config{Default: "*"}

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return cfg, nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	err = toml.Unmarshal(data, cfg)
	return cfg, err
}

func (c *Config) getIcon(appID string) string {
	if icon, ok := c.Matches[appID]; ok {
		return icon
	}
	return c.Default
}

func (c *Config) formatIcon(icon string, focused bool) string {
	if focused && c.FocusedFormat != "" {
		return strings.ReplaceAll(c.FocusedFormat, "{}", icon)
	}
	return icon
}

func getWindows() ([]Window, error) {
	cmd := exec.Command("niri", "msg", "--json", "windows")
	output, err := cmd.Output()
	if err != nil {
		return nil, err
	}

	var windows []Window
	err = json.Unmarshal(output, &windows)
	return windows, err
}

func getWorkspaceIcons(cfg *Config, workspaceID int) (string, error) {
	windows, err := getWindows()
	if err != nil {
		return "", err
	}

	var workspaceWindows []Window
	for _, w := range windows {
		if w.WorkspaceID == workspaceID {
			workspaceWindows = append(workspaceWindows, w)
		}
	}

	sort.Slice(workspaceWindows, func(i, j int) bool {
		if workspaceWindows[i].IsFloating != workspaceWindows[j].IsFloating {
			return !workspaceWindows[i].IsFloating
		}

		posI := 999
		if len(workspaceWindows[i].Layout.PosInScrollingLayout) > 0 {
			posI = workspaceWindows[i].Layout.PosInScrollingLayout[0]
		}

		posJ := 999
		if len(workspaceWindows[j].Layout.PosInScrollingLayout) > 0 {
			posJ = workspaceWindows[j].Layout.PosInScrollingLayout[0]
		}

		return posI < posJ
	})

	var icons []string
	for _, w := range workspaceWindows {
		icon := cfg.getIcon(w.AppID)
		icon = cfg.formatIcon(icon, w.IsFocused)
		icons = append(icons, icon)
	}

	return strings.Join(icons, " "), nil
}

func main() {
	cfg, err := loadConfig()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to load config: %v\n", err)
		os.Exit(1)
	}

	cmd := exec.Command("niri", "msg", "--json", "event-stream")
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create pipe: %v\n", err)
		os.Exit(1)
	}

	if err := cmd.Start(); err != nil {
		fmt.Fprintf(os.Stderr, "failed to start niri msg: %v\n", err)
		os.Exit(1)
	}

	currentWorkspaceID := 0
	scanner := bufio.NewScanner(stdout)

	for scanner.Scan() {
		line := scanner.Bytes()

		var event map[string]any
		if err := json.Unmarshal(line, &event); err != nil {
			continue
		}

		if data, ok := event["WorkspaceActivated"].(map[string]any); ok {
			if id, ok := data["id"].(float64); ok && id != 0 {
				currentWorkspaceID = int(id)
			}
		} else if data, ok := event["WorkspacesChanged"].(map[string]any); ok {
			if workspaces, ok := data["workspaces"].([]any); ok {
				for _, ws := range workspaces {
					if wsMap, ok := ws.(map[string]any); ok {
						if focused, ok := wsMap["is_focused"].(bool); ok && focused {
							if id, ok := wsMap["id"].(float64); ok {
								currentWorkspaceID = int(id)
								break
							}
						}
					}
				}
			}
		} else if _, ok := event["WindowFocusChanged"]; ok {
			windows, err := getWindows()
			if err != nil {
				continue
			}

			for _, w := range windows {
				if w.IsFocused {
					currentWorkspaceID = w.WorkspaceID
					icons, err := getWorkspaceIcons(cfg, currentWorkspaceID)
					if err == nil {
						fmt.Println(icons)
					}
					break
				}
			}
		}
	}

	cmd.Wait()
}
