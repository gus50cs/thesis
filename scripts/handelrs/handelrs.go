package handelrs

import (
	"fmt"
	"strings"
	pdfcpu "github.com/pdfcpu/pdfcpu/pkg/api"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"bytes"
	"github.com/gin-gonic/gin"
	//"log"
	shell "github.com/ipfs/go-ipfs-api"
    _ "github.com/go-sql-driver/mysql"
)


type CheckedData struct {
	DocumentID   string
	Owner string
}


func UploadHandler(c *gin.Context) (string, bool){

	// Get the uploaded file
	file, err := c.FormFile("file")
	if err != nil {
		c.String(http.StatusBadRequest, fmt.Sprintf("Error uploading file: %s", err.Error()))
	return "", false
	}

	// Save the file temporarily
	tempPath := filepath.Join("./temp", file.Filename)
	err = c.SaveUploadedFile(file, tempPath)
	if err != nil {
		c.String(http.StatusInternalServerError, fmt.Sprintf("Error saving file: %s", err.Error()))
	return "", false
	}

	
	// Read the file contents
	fileContents, err := ioutil.ReadFile(tempPath)
		if err != nil {
			c.String(http.StatusInternalServerError, fmt.Sprintf("Error reading file contents: %s", err.Error()))
		return "", false
		}
	fileType := http.DetectContentType(fileContents)

	// Check if the file type is an image
	if strings.HasPrefix(fileType, "image/") {
		fileName := file.Filename + ".pdf"
		pdfPath := filepath.Join("./temp", fileName)
		err := pdfcpu.ImportImagesFile([]string{tempPath}, pdfPath, nil, nil)
		if err != nil {
			c.String(http.StatusInternalServerError, fmt.Sprintf("Error reading file contents: %s", err.Error()))
			return "", false
		}
		fileContents, err = ioutil.ReadFile(pdfPath)
		if err != nil {
			c.String(http.StatusInternalServerError, fmt.Sprintf("Error reading file contents: %s", err.Error()))
		return "", false
		}
	}else {
		fileContents, err = ioutil.ReadFile(tempPath)
		if err != nil {
			c.String(http.StatusInternalServerError, fmt.Sprintf("Error reading file contents: %s", err.Error()))
		return "", false
		}
	}


	

	// Create IPFS shell connection
	sh := shell.NewShell("localhost:5001")

	// Add the file to IPFS
	Cid, err := sh.Add(bytes.NewReader(fileContents))
	if err != nil {
		c.String(http.StatusInternalServerError, fmt.Sprintf("Error adding file to IPFS: %s", err.Error()))
		return "", false
	}

	// Delete the temporary file
	err = os.Remove(tempPath)
	if err != nil {
		c.String(http.StatusInternalServerError, fmt.Sprintf("Error deleting temporary file: %s", err.Error()))
		return "", false
	}

	c.String(http.StatusOK, fmt.Sprintf("File uploaded successfully. CID: %s %s", Cid, fileType))

	return Cid, true

}



func DownloadHandler(c *gin.Context) {
	// Get the CID from the route parameter
	cid := c.Param("cid")

	// Create IPFS shell connection
	sh := shell.NewShell("localhost:5001")

	// Get the file by CID from IPFS
	file, err := sh.Cat(cid)
	if err != nil {
		c.String(http.StatusInternalServerError, fmt.Sprintf("Error retrieving file from IPFS: %s", err.Error()))
		return
	}
	defer file.Close()

	// Read the file contents
	fileContents, err := ioutil.ReadAll(file)
	if err != nil {
		c.String(http.StatusInternalServerError, fmt.Sprintf("Error reading file contents: %s", err.Error()))
		return
	}

	// Set the appropriate headers for file download
	filename := "file.pdf"
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))
	c.Header("Content-Type", "application/pdf")
	c.Data(http.StatusOK, "application/pdf", fileContents)
}