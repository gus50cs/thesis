package session

import (
	"fmt"
	"crypto/md5"
	"log"
	"net/http"
	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/sessions"
	"database/sql"
    _ "github.com/go-sql-driver/mysql"
)


func LoginHandler(c *gin.Context) (string, bool){
	username := c.PostForm("username")
		password := c.PostForm("password")
		hashedPassword := fmt.Sprintf("%x", md5.Sum([]byte(password)))
		
		// Connect to the MySQL database
		db, err := sql.Open("mysql", "root:1234@tcp(localhost:3306)/mywebapp")
		if err != nil {
			log.Fatal(err)
		}
		defer db.Close()
	
		// Prepare the SQL statement
		stmt, err := db.Prepare("SELECT username FROM users WHERE BINARY username=? AND password=?")
		if err != nil {
			log.Fatal(err)
		}
		defer stmt.Close()
	
		// Execute the SQL statement
		var result string
		err = stmt.QueryRow(username, hashedPassword).Scan(&result)
		if err != nil {
			if err == sql.ErrNoRows {
				// Authentication failed
				c.Redirect(http.StatusFound, "/login")
				return "", false
			}
			log.Fatal(err)
		}
	
		// Authentication successful
		session := sessions.Default(c)
		session.Set("authenticated", true)
		session.Save()
	
		c.Redirect(http.StatusFound, "/")
		return username, true
}

func LogoutHandler(c *gin.Context) {
	session := sessions.Default(c)
	session.Clear()
	session.Save()
	c.Redirect(http.StatusFound, "/login")
}