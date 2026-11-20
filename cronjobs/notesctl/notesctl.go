//
//       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
//       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
//       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
//       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
//       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
//       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
//       DRAFTED BY [https://nih.ar] ON 03-04-2026
//       SOURCE [notesctl.go] LAST MODIFIED ON 28-05-2026
//

package main

import (
	"flag"
	"fmt"
	"io"
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

type Config struct {
	Paths struct {
		NotesDir   string `yaml:"notes_dir"`
		ArchiveDir string `yaml:"archive_dir"`
		LogsDir    string `yaml:"logs_dir"`
		TempDir    string `yaml:"temp_dir"`
	} `yaml:"paths"`

	Archive struct {
		ArchiveAfterDays int      `yaml:"archive_after_days"`
		ExcludePatterns  []string `yaml:"exclude_patterns"`
	} `yaml:"archive"`

	UntitledWatcher struct {
		Enabled          bool   `yaml:"enabled"`
		InboxFile        string `yaml:"inbox_file"`
		DeleteAfterMerge bool   `yaml:"delete_after_merge"`
	} `yaml:"untitled_watcher"`

	MonthEnd struct {
		Enabled bool `yaml:"enabled"`
	} `yaml:"month_end"`

	Rclone struct {
		Enabled     bool   `yaml:"enabled"`
		Remote      string `yaml:"remote"`
		RemotePath  string `yaml:"remote_path"`
		RcloneFlags string `yaml:"rclone_flags"`
	} `yaml:"rclone"`

	Encryption struct {
		Enabled    bool   `yaml:"enabled"`
		Method     string `yaml:"method"`
		Passphrase string `yaml:"passphrase"`
	} `yaml:"encryption"`

	Notify struct {
		Script string `yaml:"script"` // path to notify.sh
	} `yaml:"notify"`
}

func loadConfig(path string) *Config {
	data, err := os.ReadFile(path)
	if err != nil {
		fatal("config read: %v", err)
	}
	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		fatal("config parse: %v", err)
	}
	return &cfg
}

// ============================================================
// LOGGER
// ============================================================

var (
	logWriter      io.Writer
	telegramBuffer []string
	notifyScript   string
)

func log(s string) {
	fmt.Fprintln(logWriter, s)
	telegramBuffer = append(telegramBuffer, s)
}

func logf(format string, args ...any) {
	log(fmt.Sprintf(format, args...))
}

func divider() {
	log("─────────────────────────")
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "FATAL: "+format+"\n", args...)
	os.Exit(1)
}

func setupLogging(logDir string) {
	os.MkdirAll(logDir, 0755)
	path := filepath.Join(logDir, "notesctl_"+time.Now().Format("200601")+".log")
	f, err := os.OpenFile(path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		fatal("log open: %v", err)
	}
	logWriter = io.MultiWriter(os.Stdout, f)
}

func header(t time.Time) {
	divider()
	logf("📝 NOTESCTL | %s", t.Format("02 Jan 06 15:04"))
	divider()
}

func footer(t time.Time) {
	divider()
	logf("✅ done | %s", t.Format("15:04:05"))
	divider()
}

// ============================================================
// TELEGRAM
// ============================================================

func sendTelegram(msg string) {
	if notifyScript == "" {
		return
	}
	exec.Command("bash", notifyScript, msg).Run()
}

func resolveNotifyScript(cfg *Config) {
	// 1. explicit config value
	if cfg.Notify.Script != "" {
		notifyScript = cfg.Notify.Script
		return
	}
	// 2. next to the binary
	exe, _ := os.Executable()
	candidate := filepath.Join(filepath.Dir(exe), "notify.sh")
	if _, err := os.Stat(candidate); err == nil {
		notifyScript = candidate
		return
	}
	// 3. repo root (two levels up from cronjobs/notesctl/)
	candidate = filepath.Join(filepath.Dir(exe), "..", "..", "notify.sh")
	if _, err := os.Stat(candidate); err == nil {
		notifyScript = candidate
	}
}

// ============================================================
// HELPERS
// ============================================================

func isExcluded(name string, patterns []string) bool {
	for _, p := range patterns {
		if m, _ := filepath.Match(p, name); m {
			return true
		}
	}
	return false
}

func isMonthEnd(t time.Time) bool {
	return t.AddDate(0, 0, 1).Month() != t.Month()
}

func isUntitled(name string) bool {
	base := strings.TrimSuffix(name, filepath.Ext(name))
	return strings.Contains(strings.ToLower(base), "untitled")
}

func appendToInbox(srcPath, inboxPath string, t time.Time) error {
	content, err := os.ReadFile(srcPath)
	if err != nil {
		return fmt.Errorf("read src: %w", err)
	}
	os.MkdirAll(filepath.Dir(inboxPath), 0755)
	f, err := os.OpenFile(inboxPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("open inbox: %w", err)
	}
	defer f.Close()
	fmt.Fprintf(f, "\n\n---\n<!-- merged: %s | %s -->\n\n",
		filepath.Base(srcPath), t.Format("2006-01-02 15:04:05"))
	f.Write(content)
	return nil
}

// ============================================================
// TASKS
// ============================================================

func untitledWatcher(cfg *Config, today time.Time) {
	log("📥 UNTITLED")
	if !cfg.UntitledWatcher.Enabled {
		log("  — disabled")
		return
	}

	inboxPath := filepath.Join(cfg.Paths.NotesDir, cfg.UntitledWatcher.InboxFile)
	entries, _ := os.ReadDir(cfg.Paths.NotesDir)
	count := 0

	for _, e := range entries {
		if e.IsDir() || !isUntitled(e.Name()) {
			continue
		}
		srcPath := filepath.Join(cfg.Paths.NotesDir, e.Name())
		if err := appendToInbox(srcPath, inboxPath, today); err != nil {
			logf("  ❌ %s — %v", e.Name(), err)
			continue
		}
		count++
		if cfg.UntitledWatcher.DeleteAfterMerge {
			os.Remove(srcPath)
		}
	}

	logf("  ✅ merged %d file(s)", count)
}

func archiveNotes(cfg *Config, today time.Time) {
	log("📦 ARCHIVE")
	cutoff := today.AddDate(0, 0, -cfg.Archive.ArchiveAfterDays)
	files, _ := os.ReadDir(cfg.Paths.NotesDir)
	count := 0

	for _, f := range files {
		name := f.Name()
		if f.IsDir() || strings.HasPrefix(name, ".") || !strings.HasSuffix(name, ".md") {
			continue
		}
		if isExcluded(name, cfg.Archive.ExcludePatterns) {
			continue
		}
		src := filepath.Join(cfg.Paths.NotesDir, name)
		info, _ := os.Stat(src)
		if info.ModTime().After(cutoff) {
			continue
		}
		os.MkdirAll(cfg.Paths.ArchiveDir, 0755)
		os.Rename(src, filepath.Join(cfg.Paths.ArchiveDir, name))
		count++
	}

	logf("  ✅ archived %d file(s)", count)
}

func monthEnd(cfg *Config, today time.Time) {
	log("📅 MONTH-END")
	if !cfg.MonthEnd.Enabled {
		log("  — disabled")
		return
	}
	if !isMonthEnd(today) {
		log("  — not month-end")
		return
	}

	target := filepath.Join(cfg.Paths.ArchiveDir, today.Format("200601"))
	files, _ := os.ReadDir(cfg.Paths.ArchiveDir)
	count := 0

	for _, f := range files {
		if f.IsDir() || strings.HasPrefix(f.Name(), ".") {
			continue
		}
		os.MkdirAll(target, 0755)
		os.Rename(
			filepath.Join(cfg.Paths.ArchiveDir, f.Name()),
			filepath.Join(target, f.Name()),
		)
		count++
	}

	logf("  ✅ moved %d file(s) → %s", count, today.Format("200601"))
}

func backup(cfg *Config, today time.Time) {
	log("🔐 BACKUP")
	if !cfg.Rclone.Enabled {
		log("  — disabled")
		return
	}

	tmpDir := cfg.Paths.TempDir
	os.MkdirAll(tmpDir, 0755)

	base    := "notes_" + today.Format("20060102_150405")
	tarFile := filepath.Join(tmpDir, base+".tar.gz")
	encFile := tarFile + ".gpg"

	log("  📦 compressing...")
	exec.Command("tar", "-czf", tarFile, "-C", cfg.Paths.NotesDir, ".").Run()

	log("  🔒 encrypting...")
	exec.Command(
		"gpg", "--batch", "--yes",
		"--passphrase", cfg.Encryption.Passphrase,
		"--symmetric", "--cipher-algo", "AES256",
		"-o", encFile, tarFile,
	).Run()
	os.Remove(tarFile)

	dest := fmt.Sprintf("%s:%s", cfg.Rclone.Remote, cfg.Rclone.RemotePath)
	logf("  ☁️  uploading → %s", dest)

	cmd := exec.Command("rclone", "copy", encFile, dest, "-P")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		logf("  ❌ upload failed: %v", err)
		return
	}

	os.Remove(encFile)
	log("  ✅ backup complete")
}

// ============================================================
// MAIN
// ============================================================

func main() {
	configPath := flag.String("config", "notesconfig.yml", "path to config file")
	flag.Parse()

	cfg := loadConfig(*configPath)
	setupLogging(cfg.Paths.LogsDir)
	resolveNotifyScript(cfg)

	today := time.Now()
	header(today)

	untitledWatcher(cfg, today)
	archiveNotes(cfg, today)
	monthEnd(cfg, today)
	backup(cfg, today)

	footer(time.Now())

//	sendTelegram(strings.Join(telegramBuffer, "\n"))
}
