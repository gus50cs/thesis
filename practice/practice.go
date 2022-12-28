package main

import (
	"bufio"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"github.com/skip2/go-qrcode"
	"os"
	//"reflect"
	"strconv"
	"strings"
	"time"
)

type Asset struct {
	AppraisedValue int                    `json:"AppraisedValue"`
	Color          string                 `json:"Color"`
	ID             string                 `json:"ID"`
	Owner          string                 `json:"Owner"`
	Size           int                    `json:"Size"`
	Time           string                 `json:"Time"`
	Additional     map[string]interface{} `json:"Additional"`
	QR             string                 `json:"Additional"`
}

func input() string {
	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')
	input = strings.TrimSpace(input)
	return input

}

func hash(newasset Asset) Asset {
	hash := sha256.New()
	structString := fmt.Sprintf("%+v", newasset)
	_, err := hash.Write([]byte(structString))
	if err != nil {
		fmt.Println("Error creating SHA256 hash:", err)
	}
	hashValue := hash.Sum(nil)
	hexString := hex.EncodeToString(hashValue)
	newasset.QR = hexString
	return newasset

}

func add(newasset Asset) Asset {
	// Create a map and add some key-value pairs to it
	data := make(map[string]interface{})
	for true {

		fmt.Println("Do you want to add extra categories ?(YES/NO)")
		user := input()
		if strings.EqualFold(user, "NO") {
			break
		} else if strings.EqualFold(user, "YES") {
			fmt.Println("Category to add:")
			keyInput := input()
			fmt.Println("Add to", keyInput)
			data[keyInput] = input()
		} else {
			fmt.Println("Invalid input")
		}

		// Create a new struct and add the map to it
	}
	newasset.Additional = data
	// Return the struct
	//fmt.Println(newasset)
	return newasset

}

func data(asset []Asset, newasset Asset) ([]Asset, bool) {

	asset = append(asset, newasset)
	fmt.Println("Stop or continue")
	input := input()
	if strings.EqualFold(input, "stop") || strings.EqualFold(input, "end") {
		return asset, false
	} else {
		return asset, true
	}

}

func insert() Asset {
	var set Asset
	fmt.Println("AppraisedValue:")
	data := input()
	appraisedValue, err := strconv.Atoi(data)
	if err != nil {
		// Handle the error here
	}
	fmt.Println("Color:")
	color := input()
	fmt.Println("ID:")
	id := input()
	fmt.Println("Owner:")
	owner := input()
	fmt.Println("Size:")
	data = input()
	size, err := strconv.Atoi(data)
	if err != nil {
		// Handle the error here
	}
	set = Asset{ID: id, Color: color, Size: size, Owner: owner, AppraisedValue: appraisedValue, Time: time.Now().Format("15:04:05 02-01-2006")}
	set = add(set)
	set = hash(set)
	code(set)
	return set
}

func print_element(asset []Asset) {

	for _, data := range asset {
		fmt.Println(data.ID)
		fmt.Println(data.Color)
		fmt.Println(data.Owner)
		fmt.Println(data.Size)
		fmt.Println(data.Time)
		fmt.Println(data.AppraisedValue)
	}

}

func code(newasset Asset) {

	err := qrcode.WriteFile(newasset.QR, qrcode.High, 256, fmt.Sprintf("%s.png", newasset.ID))
	if err != nil {
		fmt.Println("Error generating QR code:", err)
	}

}

func main() {
	var asset []Asset
	asset = []Asset{}
	//myMap := make(map[string]string)
	for true {
		newasset := insert()
		fmt.Println(asset)
		set, result := data(asset, newasset)
		asset = set
		if result == false {
			fmt.Println(set)
			break
		}

	}

}
