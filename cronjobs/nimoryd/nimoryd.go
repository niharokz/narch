//
//       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
//       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
//       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
//       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
//       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
//       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
//       DRAFTED BY [https://nih.ar] ON 28-05-2026
//       SOURCE [nimoryd.go] LAST MODIFIED ON 28-05-2026
//

package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// ============================================================
// CONFIG
// ============================================================

type DockerComposeConfig struct {
	Enabled            bool   `yaml:"enabled"`
	BasePath           string `yaml:"base_path"`
	UpdateIntervalDays int    `yaml:"update_interval_days"`
}

type Config struct {
	Log struct {
		Dir    string `yaml:"dir"`
		Prefix string `yaml:"prefix"`
	} `yaml:"log"`

	System struct {
		ShowStats bool `yaml:"show_stats"`
	} `yaml:"system"`

	Tailscale struct {
		Enabled   bool   `yaml:"enabled"`
		UpCommand string `yaml:"up_command"`
	} `yaml:"tailscale"`

	Docker struct {
		Enabled           bool                `yaml:"enabled"`
		RestartContainers []string            `yaml:"restart_containers"`
		Compose           DockerComposeConfig `yaml:"compose"`
	} `yaml:"docker"`

	Git struct {
		Paths []string `yaml:"paths"`
	} `yaml:"git"`

	Build struct {
		Paths []string `yaml:"paths"`
	} `yaml:"build"`

	Backup struct {
		Source     string   `yaml:"source"`
		Target     string   `yaml:"target"`
		Extensions []string `yaml:"extensions"`
	} `yaml:"backup"`

	CustomCommands []struct {
		Name string `yaml:"name"`
		Cmd  string `yaml:"cmd"`
	} `yaml:"custom_commands"`
}

// ============================================================
// LOGGER
// ============================================================

var (
	logFile        *os.File
	telegramBuffer []string
	notifyScript   string
)

// log writes a line to stdout, the log file, and the Telegram buffer.
func log(s string) {
	fmt.Println(s)
	logFile.WriteString(s + "\n")
	telegramBuffer = append(telegramBuffer, s)
}

func logf(format string, args ...any) {
	log(fmt.Sprintf(format, args...))
}

func divider() {
	log("─────────────────────────")
}

// ============================================================
// SETUP
// ============================================================

func getConfigPath() string {
	if _, err := os.Stat("config.yaml"); err == nil {
		return "config.yaml"
	}
	exe, _ := os.Executable()
	return filepath.Join(filepath.Dir(exe), "config.yaml")
}

func loadConfig(path string) Config {
	var cfg Config
	data, _ := os.ReadFile(path)
	yaml.Unmarshal(data, &cfg)
	return cfg
}

func initLogger(cfg Config) {
	now := time.Now()
	name := fmt.Sprintf("%s_%d%02d.log", cfg.Log.Prefix, now.Year(), now.Month())
	path := filepath.Join(cfg.Log.Dir, name)
	os.MkdirAll(cfg.Log.Dir, 0755)
	f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Println("LOG ERROR:", err)
		os.Exit(1)
	}
	logFile = f
}

func loadSecrets() {
	home, _ := os.UserHomeDir()
	data, err := os.ReadFile(filepath.Join(home, ".config", ".secrets"))
	if err != nil {
		return
	}
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		line = strings.TrimPrefix(line, "export ")
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		os.Setenv(
			strings.TrimSpace(parts[0]),
			strings.Trim(strings.TrimSpace(parts[1]), `"'`),
		)
	}
}

func resolveNotifyScript() {
	exe, _ := os.Executable()
	candidate := filepath.Join(filepath.Dir(exe), "notify.sh")
	if _, err := os.Stat(candidate); err == nil {
		notifyScript = candidate
		return
	}
	// fallback: same repo root
	notifyScript = filepath.Join(filepath.Dir(exe), "..", "..", "notify.sh")
}

// ============================================================
// HELPERS
// ============================================================

func run(cmd string) string {
	out, _ := exec.Command("bash", "-c", cmd).CombinedOutput()
	return string(out)
}

func sendTelegram(msg string) {
	exec.Command("bash", notifyScript, msg).Run()
}

// ============================================================
// HEADER / FOOTER
// ============================================================

func header() {
	host, _ := os.Hostname()
	divider()
	logf("🤖 %s | %s", strings.ToUpper(host), time.Now().Format("02 Jan 06 15:04"))
	divider()
}

func footer() {
	now := time.Now()
	month := now.Format("2006-01")
	cmd := fmt.Sprintf(`/usr/bin/vnstat -m | awk '/%s/ {print $8 " " $9}'`, month)
	data := strings.TrimSpace(run(cmd))
	if data == "" {
		data = "N/A"
	}
	divider()
	logf("📡 %s used  ⚓ %s", data, now.Format("15:04:05"))
	divider()
}

// ============================================================
// TASKS
// ============================================================

func systemStats() {
	cpu  := strings.TrimSpace(run("top -bn1 | grep 'Cpu(s)' | awk '{print $2}'"))
	mem  := strings.TrimSpace(run("free | grep Mem | awk '{print $3/$2 * 100.0}'"))
	disk := strings.TrimSpace(run("df / | tail -1 | awk '{print $5}'"))
	upt  := strings.TrimSpace(run("uptime -p"))

	log("🖥️ SYSTEM")
	logf("  cpu %s%%  mem %s%%  disk %s", cpu, mem, disk)
	logf("  uptime: %s", upt)
}

func checkUpdates() {
	out := run("apt list --upgradable 2>/dev/null | grep -v Listing")
	if out == "" {
		return
	}
	log("📦 UPDATES — upgrading...")
	run("apt update && apt upgrade -y")
	log("  ✅ done")
}

func handleTailscale(cfg Config) {
	if !cfg.Tailscale.Enabled {
		return
	}
	out := run("tailscale status")
	if strings.Contains(out, "stopped") || out == "" {
		run(cfg.Tailscale.UpCommand)
		log("🔐 tailscale — started")
	} else {
		log("🔐 tailscale — ok")
	}
}

func handleDocker(cfg Config) {
	if !cfg.Docker.Enabled {
		return
	}

	log("🐳 DOCKER")

	stopped := run(`docker ps -a --filter "status=exited" --format "{{.Names}}"`)
	for _, c := range strings.Split(stopped, "\n") {
		if c == "" {
			continue
		}
		run("docker start " + c)
		logf("  ▶ started %s", c)
	}

	for _, c := range cfg.Docker.RestartContainers {
		run("docker restart " + c)
		logf("  🔄 restarted %s", c)
	}

	dry := run("docker image prune -a --dry-run")
	if strings.Contains(dry, "0B") {
		log("  🧹 images — nothing to prune")
	} else {
		run("docker image prune -a -f")
		log("  🧹 images — pruned")
	}
}

func handleDockerCompose(cfg Config) {
	if !cfg.Docker.Compose.Enabled {
		return
	}

	log("📦 COMPOSE")

	lastRunFile := "/tmp/nimoryd_docker_update"
	if data, err := os.ReadFile(lastRunFile); err == nil {
		lastRun, _ := time.Parse(time.RFC3339, string(data))
		if time.Since(lastRun).Hours() < float64(cfg.Docker.Compose.UpdateIntervalDays*24) {
			log("  ⏪ skipped (interval not reached)")
			return
		}
	}

	dirs, _ := os.ReadDir(cfg.Docker.Compose.BasePath)
	for _, d := range dirs {
		if !d.IsDir() {
			continue
		}
		path := filepath.Join(cfg.Docker.Compose.BasePath, d.Name())
		hasCompose :=
			fileExists(filepath.Join(path, "docker-compose.yml")) ||
				fileExists(filepath.Join(path, "compose.yaml"))
		if !hasCompose {
			continue
		}

		pull := run("cd " + path + " && docker compose pull")
		if strings.Contains(pull, "Downloaded") || strings.Contains(pull, "Pull complete") {
			run("cd " + path + " && docker compose up -d")
			logf("  ⬇️  %s — updated", d.Name())
		} else {
			logf("  ✅ %s — up-to-date", d.Name())
		}
	}

	os.WriteFile(lastRunFile, []byte(time.Now().Format(time.RFC3339)), 0644)
}

func handleGit(cfg Config) {
	log("📂 GIT")
	for _, p := range cfg.Git.Paths {
		run("git -C " + p + " pull")
		logf("  ✅ %s", filepath.Base(p))
	}
}

func handleBuild(cfg Config) {
	log("⚙️ BUILD")
	for _, p := range cfg.Build.Paths {
		run("cd " + p + " && ./buildgo.sh")
		logf("  ✅ %s", filepath.Base(p))
	}
}

func handleBackup(cfg Config) {
	log("💾 BACKUP")
	os.MkdirAll(cfg.Backup.Target, 0755)
	files, _ := os.ReadDir(cfg.Backup.Source)
	count := 0
	for _, f := range files {
		for _, ext := range cfg.Backup.Extensions {
			if strings.HasSuffix(f.Name(), ext) {
				os.Rename(
					filepath.Join(cfg.Backup.Source, f.Name()),
					filepath.Join(cfg.Backup.Target, f.Name()),
				)
				count++
			}
		}
	}
	logf("  ✅ moved %d file(s)", count)
}

func handleCustom(cfg Config) {
	log("🔧 COMMANDS")
	for _, c := range cfg.CustomCommands {
		run(c.Cmd)
		logf("  ✅ %s", c.Name)
	}
}

// ============================================================
// UTIL
// ============================================================

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// ============================================================
// MAIN
// ============================================================

func main() {
	cfg := loadConfig(getConfigPath())
	initLogger(cfg)
	loadSecrets()
	resolveNotifyScript()

	header()

	if cfg.System.ShowStats {
		systemStats()
	}

	checkUpdates()
	handleTailscale(cfg)
	handleDocker(cfg)
	handleDockerCompose(cfg)
	handleGit(cfg)
	handleBuild(cfg)
	handleBackup(cfg)
	handleCustom(cfg)

	footer()

    //	sendTelegram(strings.Join(telegramBuffer, "\n"))
}
