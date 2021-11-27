package main

import (
	"log"
	"os"
	"os/exec"
	"strings"
	"time"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

func GetLenovoSettings() *fyne.Container {
	conservationModeButton := widget.NewButton("Conservation Mode: N/A", func() {})
	if IsConservationModeAvailable() {
		var updateConservationModeButton func()
		updateConservationModeButton = func() {
			if IsConservationModeEnabled() {
				conservationModeButton.SetText("Conservation Mode: Enabled")
				conservationModeButton.OnTapped = func() {
					SetConservationModeStatus(false)
					updateConservationModeButton()
				}
			} else {
				conservationModeButton.SetText("Conservation Mode: Disabled")
				conservationModeButton.OnTapped = func() {
					SetConservationModeStatus(true)
					updateConservationModeButton()
				}
			}
		}
		go (func() {
			for {
				updateConservationModeButton()
				<-time.After(1 * time.Second)
			}
		})()
	} else {
		conservationModeButton.Disable()
	}
	return container.NewVBox(
		widget.NewLabel("Lenovo"),
		conservationModeButton,
	)
}

const ConservationModeSysFs = "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

func IsConservationModeAvailable() bool {
	modulesInfo, err := exec.Command("lsmod").Output()
	if err != nil {
		log.Println("Failed to run lsmod!")
		return false
	}
	modules := strings.Split(string(modulesInfo), "\n")
	for _, module := range modules {
		if strings.Fields(module)[0] == "ideapad_laptop" {
			// TODO: VPC2004:00 can vary.
			_, err := os.ReadFile(ConservationModeSysFs)
			if os.IsNotExist(err) {
				return false
			} else if err != nil {
				log.Println("An unknown error occurred when checking for Lenovo conservation mode", err)
				return false
			}
			return true
		}
	}
	return false
}

func IsConservationModeEnabled() bool {
	data, err := os.ReadFile(ConservationModeSysFs)
	if os.IsNotExist(err) {
		log.Println("Lenovo conservation mode status was checked despite no support for it", err)
		return false
	} else if err != nil {
		log.Println("An unknown error occurred when checking for Lenovo conservation mode", err)
		return false
	}
	return string(data) == "1\n"
}

func SetConservationModeStatus(mode bool) bool {
	if !IsConservationModeAvailable() { // Don't accidentally write to the file.
		return false
	}
	data := []byte("0")
	if mode {
		data = []byte("1")
	}
	err := os.WriteFile(ConservationModeSysFs, data, os.ModePerm)
	if err != nil {
		log.Println("Failed to set Lenovo conservation mode", err)
	}
	return err == nil
}
