 
//
//       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗
//       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝
//       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗
//       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║
//       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║
//       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
//       DRAFTED BY [https://nih.ar] ON 01-06-2025
//       SOURCE [headerize.go] LAST MODIFIED ON 01-06-2025
//
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
	"io/ioutil"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: headerize <filename>")
		os.Exit(1)
	}

	filePath := os.Args[1]
	fileName := filepath.Base(filePath)
	ext := filepath.Ext(filePath)
	today := time.Now().Format("02-01-2006")
	website := "https://nih.ar"

	// Determine comment prefix
	comment := "#"
	switch ext {
	case ".go", ".js", ".ts", ".java", ".c", ".cpp", ".h", ".rs", ".kt", ".swift", ".scala", ".php":
		comment = "//"
	case ".hs", ".lua":
		comment = "--"
	case ".py", ".sh", ".yaml", ".yml", ".toml", ".json", ".rb":
		comment = "#"
	case ".html":
		comment = "<!--"
	default:
		comment = "#"
	}

	headerLines := []string{
		fmt.Sprintf("%s", comment),
		fmt.Sprintf("%s       ███╗   ██╗██╗██╗  ██╗ █████╗ ██████╗ ███████╗", comment),
		fmt.Sprintf("%s       ████╗  ██║██║██║  ██║██╔══██╗██╔══██╗██╔════╝", comment),
		fmt.Sprintf("%s       ██╔██╗ ██║██║███████║███████║██████╔╝███████╗", comment),
		fmt.Sprintf("%s       ██║╚██╗██║██║██╔══██║██╔══██║██╔══██╗╚════██║", comment),
		fmt.Sprintf("%s       ██║ ╚████║██║██║  ██║██║  ██║██║  ██║███████║", comment),
		fmt.Sprintf("%s       ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝", comment),
		fmt.Sprintf("%s       DRAFTED BY [%s] ON %s", comment, website, today),
		fmt.Sprintf("%s       SOURCE [%s] LAST MODIFIED ON %s.", comment, fileName, today),
		fmt.Sprintf("%s", comment),
	}

	header := strings.Join(headerLines, "\n") + "\n\n"

	contentBytes, err := ioutil.ReadFile(filePath)
	if err != nil {
		fmt.Printf("Error reading file: %v\n", err)
		os.Exit(1)
	}
	content := string(contentBytes)

	// Check if header already exists
	if strings.Contains(content, "DRAFTED BY ["+website+"]") {
		lines := strings.Split(content, "\n")
		for i, line := range lines {
			if strings.Contains(line, "SOURCE [") && strings.Contains(line, "LAST MODIFIED ON") {
				lines[i] = fmt.Sprintf("%s       SOURCE [%s] LAST MODIFIED ON %s.", comment, fileName, today)
				break
			}
		}
		content = strings.Join(lines, "\n")
	} else {
		content = header + content
	}

	err = ioutil.WriteFile(filePath, []byte(content), 0644)
	if err != nil {
		fmt.Printf("Error writing file: %v\n", err)
		os.Exit(1)
	}
}

