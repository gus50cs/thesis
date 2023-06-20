package main

import (
	"bytes"
	"fmt"
	"html/template"
	"io"
	"log"
	"mime/multipart"
	"net/http"
	//"os"
	"strings"

	shell "github.com/ipfs/go-ipfs-api"
	"github.com/signintech/gopdf"
)

func main() {
	http.HandleFunc("/", indexHandler)
	http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))
	http.HandleFunc("/upload", uploadFile)

	log.Println("Server started on port 8000")
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Fatal(err)
	}
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.ParseFiles("./static/index.html")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	err = tmpl.Execute(w, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func uploadFile(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(10 << 20) // Set maximum file size to 10MB

	file, handler, err := r.FormFile("file")
	if err != nil {
		fmt.Println("Error retrieving the file:", err)
		return
	}
	defer file.Close()

	// Validate file type
	if !isValidFileType(handler) {
		fmt.Println("Invalid file type")
		return
	}

	// Convert the file to PDF
	pdfBuf, err := convertToPDF(file)
	if err != nil {
		fmt.Println("Error converting file to PDF:", err)
		return
	}

	// Upload the PDF to IPFS
	shell := shell.NewShell("localhost:5001")
	cid, err := uploadToIPFS(shell, pdfBuf)
	if err != nil {
		fmt.Println("Error uploading file to IPFS:", err)
		return
	}

	fmt.Println("File uploaded to IPFS with CID:", cid)

	fmt.Fprintf(w, "File uploaded successfully!")
}


func isValidFileType(fileHeader *multipart.FileHeader) bool {
	validExtensions := []string{".txt", ".pdf"} // Only allow TXT and PDF files

	// Get the file extension
	ext := strings.ToLower(fileHeader.Filename[strings.LastIndex(fileHeader.Filename, "."):])

	// Validate the extension
	for _, validExt := range validExtensions {
		if ext == validExt {
			return true
		}
	}

	return false
}


func uploadToIPFS(shell *shell.Shell, file *bytes.Buffer) (string, error) {
	// Upload the file to IPFS
	cid, err := shell.Add(bytes.NewReader(file.Bytes()))
	if err != nil {
		return "", err
	}

	return cid, nil
}


func convertToPDF(file multipart.File) (*bytes.Buffer, error) {
	pdf := gopdf.GoPdf{}
	pdf.Start(gopdf.Config{PageSize: *gopdf.PageSizeA4})

	// Create a new buffer to store the PDF content
	pdfBuf := new(bytes.Buffer)

	// Copy the file content to the PDF buffer
	_, err := io.Copy(pdfBuf, file)
	if err != nil {
		return nil, err
	}

	return pdfBuf, nil
}
