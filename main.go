package main

import (
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"os"
	"time"
	"fmt"
	"strconv"
	//"strings"
	"web/scripts/check"
	"web/scripts/handelrs"
	"web/scripts/grcp"
	"web/scripts/session"
	"web/scripts/smartfunc"
	"net/http"
	"strings"
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/sessions"
	"github.com/gin-contrib/sessions/cookie"
	"html/template"
    _ "github.com/go-sql-driver/mysql"
)

type Asset struct {
	DocumentID string
	Owner      string
	DocumentCID		string
	Timestamp 	string
	IsChecked bool
}

type AssetOwner struct {
	DocumentID string
	Owner      string
	DocumentCID		string
	Timestamp 	string
	AccessList []string
	CheckList []string
	WaitingList []string
}

type Document struct {
	ID          int
	UserID      string
	DocumentID  string
	OwnerID     string
	DocumentCID string
	CreatedAt   string
	IsChecked    bool
}	


const (
	mspID        = "org2MSP"
	cryptoPath   = "/home/kevin/project/organizations/org2"
	certPath     = cryptoPath + "/users/user/msp/signcerts/cert.pem"
	keyPath      = cryptoPath + "/users/user/msp/keystore/"
	tlsCertPath  = cryptoPath + "/peers/ws/tls-msp/tlscacerts/ca.crt"
	peerEndpoint = "localhost:2012"
	gatewayPeer  = "ws.org2"
)

func main() {

	//var username string

	// The gRPC client connection should be shared by all Gateway connections to this endpoint
	clientConnection := connection.NewGrpcConnection(tlsCertPath, gatewayPeer, peerEndpoint)
	defer clientConnection.Close()

	id := connection.NewIdentity(certPath, mspID)
	sign := connection.NewSign(keyPath)

	// Create a Gateway connection for a specific client identity
	gw, err := client.Connect(
		id,
		client.WithSign(sign),
		client.WithClientConnection(clientConnection),
		// Default timeouts for different gRPC calls
		client.WithEvaluateTimeout(5*time.Second),
		client.WithEndorseTimeout(15*time.Second),
		client.WithSubmitTimeout(5*time.Second),
		client.WithCommitStatusTimeout(1*time.Minute),
	)
	if err != nil {
		panic(err)
	}
	defer gw.Close()

	// Override default values for chaincode and channel name as they may differ in testing contexts.
	chaincodeName := "basis"
	if ccname := os.Getenv("CHAINCODE_NAME"); ccname != "" {
		chaincodeName = ccname
	}

	channelName := "connect.channel"
	if cname := os.Getenv("CHANNEL_NAME"); cname != "" {
		channelName = cname
	}

	network := gw.GetNetwork(channelName)
	contract := network.GetContract(chaincodeName)



	r := gin.Default()

	store := cookie.NewStore([]byte("secret")) // Change "secret" to your desired session secret
	store.Options(sessions.Options{
		Path:     "/",
		MaxAge:   0, // Set MaxAge to 0 to generate a new session ID on each login
		HttpOnly: true,
	})
	r.Use(sessions.Sessions("session", store))


	// Serve the frontend files
	r.Static("/static", ".")
	r.SetHTMLTemplate(template.Must(template.New("").Funcs(template.FuncMap{
		"join": joinStrings,
	}).ParseFiles("upload.html", "login.html", "Ownfiles.html", "Checkfiles.html", "Home.html", "account.html")))

	// Middleware to clear session on login page access
	r.Use(func(c *gin.Context) {
		if c.Request.URL.Path == "/login" {
			session := sessions.Default(c)
			session.Clear()
			session.Save()
		}
		c.Next()
	})

	r.GET("/login", func(c *gin.Context) {
		session := sessions.Default(c)
		if session.Get("authenticated") == true {
			c.Redirect(http.StatusFound, "/")
			return
		}
		
		c.HTML(http.StatusOK, "login.html", gin.H{})
	})

	r.POST("/login",func(c *gin.Context) {
		username, err := session.LoginHandler(c)
		if err != true {
			fmt.Println(err)
		}

		// Store the username in the session
		session := sessions.Default(c)
		session.Set("username", username)
		session.Save()
		c.Redirect(http.StatusFound, "/")
	})
	

	r.GET("/saveCheckedFile", func(c *gin.Context) {
		// Retrieve the assets
		session := sessions.Default(c)
		username := session.Get("username")
		assets, error := smartfunc.GetAssetsWithCID(contract, username.(string))
		if error != nil {
			fmt.Errorf("failed to parse JSON result: %w", err)
		}

		//fmt.Println(assets)
		
		checkedFiles := check.Retrieve(username.(string))

		filteredAssets := make([]*Asset, 0)
		checkedAssets := make([]*Asset, 0)


		// Check if each asset should be included in the filtered assets
		for _, asset := range assets {
			exclude := false

			for _, checkedFile := range checkedFiles {
				if asset.Timestamp == checkedFile.Timestamp {
					exclude = true
					break
				}
			}

			if exclude {
				newAsset := &Asset{
					DocumentID:  asset.DocumentID,
					Owner:       asset.Owner,
					DocumentCID: asset.DocumentCID,
					Timestamp:   asset.Timestamp,
					IsChecked: true,
				}
				checkedAssets = append(checkedAssets, newAsset)
			} else {
				newAsset := &Asset{
					DocumentID:  asset.DocumentID,
					Owner:       asset.Owner,
					DocumentCID: asset.DocumentCID,
					Timestamp: asset.Timestamp,
				}

				filteredAssets = append(filteredAssets, newAsset)
			}
		}

		c.HTML(http.StatusOK, "Checkfiles.html", gin.H{
			"Assets":       filteredAssets,
			"CheckedFiles": checkedAssets,
		})

	})




	r.POST("/saveCheckedFile", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		//fmt.Println(username)
		timestamp := c.PostForm("timestamp")
		isChecked := c.PostForm("isChecked")
		isCheckedBool, err := strconv.ParseBool(isChecked)
		if err != nil {
			fmt.Println(err)
		}
		check.Insert(username.(string), timestamp, isCheckedBool)
	})
	
	

	r.GET("/upload", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		
		users, err := check.GetUsernames()
		if err != nil {
			fmt.Println("Failed to connect to MySQL:", err)
		}

		c.HTML(http.StatusOK, "upload.html", gin.H{
			"Username": username,
			"Users": users,
		})
	})

	r.GET("/", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		if session.Get("authenticated") != true {
			c.Redirect(http.StatusFound, "/login")
			return
		}
		if username == nil {
			c.Redirect(http.StatusFound, "/login")
			return
		}

		c.HTML(http.StatusOK, "Home.html", gin.H{})
	})
	
	r.GET("/update-access", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		
		assetsowner, error := smartfunc.GetOwnerWithCID(contract, username.(string))
		if error != nil {
			fmt.Errorf("failed to parse JSON result: %w", err)
			
		}

		//checkedname := make([]*Asset, 0)
		assetOwner := make([]*AssetOwner, 0)
		//fmt.Println(assetsowner)

		for _, asset := range assetsowner {
			assetlist := &AssetOwner{
				DocumentID: asset.DocumentID,
				Owner: asset.Owner,  
				DocumentCID: asset.DocumentCID,
				Timestamp: asset.Timestamp,
				AccessList: asset.AccessList,
			}
			fmt.Println("Asset:", asset.AccessList)
			for _, access := range asset.AccessList{
				foundMatch := false
				checkedFiles := check.Retrieve(access)
				for _, checkedFile := range checkedFiles {
					if asset.Timestamp == checkedFile.Timestamp {
						assetlist.CheckList = append(assetlist.CheckList, access)
						foundMatch = true
					} 
				}
				if !foundMatch {
					assetlist.WaitingList = append(assetlist.WaitingList, access)
				}
			}
			assetOwner=append(assetOwner, assetlist)
			
		} 

		// /checkedFiles := check.Retrieve(username.(string))

		c.HTML(http.StatusOK, "Ownfiles.html", gin.H{
			"AssetsOwner": assetOwner,
		})
	})
	

	r.POST("/update-access", func(c *gin.Context) {
		documentID := c.PostForm("documentID")
		owner := c.PostForm("ownerID")
		accessListStr := c.PostForm("accessList")
	  
		fmt.Println(documentID, owner, accessListStr)
	  
	
		  // Update the access list for the documentID and owner
		  smartfunc.UpdateAccess(contract, accessListStr, documentID, owner)
		  c.String(http.StatusOK, "Access list updated successfully")
	})

	r.POST("/delete", func(c *gin.Context) {
		documentID := c.PostForm("documentID")
		owner := c.PostForm("ownerID")
		
	  
		fmt.Println(documentID, owner)
	  
		// Perform specific actions based on the request
		// Delete the file associated with the documentID and owner
		smartfunc.DeleteAsset(contract, documentID, owner)
		c.String(http.StatusOK, "File deleted successfully")
		
	})



	r.GET("/logout", func(c *gin.Context) {
		session.LogoutHandler(c)
	})

	r.POST("/upload", func(c *gin.Context) {

		documentID := c.PostForm("documentID")
  		owner := c.PostForm("owner")
  		accessListStr := c.PostForm("accessList")
		fmt.Println(documentID, owner, accessListStr)
		//accessList := strings.Split(accessListStr, ",")
		cid, error := handelrs.UploadHandler(c)
		if error != true {
			fmt.Println(error)
		}
		smartfunc.CreateAsset(contract, documentID, cid, owner, accessListStr)
		c.String(http.StatusOK, "File uploaded successfully")
		
	})
	r.GET("/download/:cid", func(c *gin.Context) {
		handelrs.DownloadHandler(c)
	})


	r.GET("account", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		c.HTML(http.StatusOK, "account.html", gin.H{
			"username": username,
		})
	})

	r.POST("account", func(c *gin.Context) {
		session := sessions.Default(c)
		username := session.Get("username")
		password := c.PostForm("password")
		check.ChangeUserPassword(username.(string), password)

		successMessage := "Password changed successfully"
		c.String(http.StatusOK, successMessage)
	  })

	
	//smartfunc.DeleteAsset(contract, "", "")
	// /smartfunc.AllAsset(contract)
	r.Run(":8080")

}


func contains(files []Document, asset Asset) bool {
	for _, file := range files {
		if file.DocumentCID == asset.DocumentCID &&
			file.DocumentID == asset.DocumentID &&
			file.OwnerID == asset.Owner {
			return true
		}
	}
	return false
}


func joinStrings(slice []string, separator string) string {
	return strings.Join(slice, separator)
}