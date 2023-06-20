package check

import (
	"crypto/md5"
	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

type Document struct {
	UserID      string
	Timestamp 	string
	IsChecked    bool
}	


func Insert (userID string, Timestamp string, IsChecked bool) {
	
	dsn := "root:1234@tcp(localhost:3306)/checkboxes"

	// Connect to the MySQL server
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Println("Failed to connect to MySQL:", err)
		return
	}
	defer db.Close()


	exists, err := documentExists(db, userID, Timestamp)
	if err != nil {
		fmt.Println("Failed to insert data into Documents table:", err)
		return
	}


	if exists {	
		// Update the IsChecked value for an existing document
		_, err := db.Exec(`UPDATE checkbox SET IsChecked = ? WHERE UserID = ? AND Timestamp  = ?`,
			IsChecked, userID, Timestamp)
		if err != nil {
			fmt.Println("Failed to update IsChecked value:", err)
			return
		}

		fmt.Println("Data updated successfully!")
	}else {
		// Insert data into the Documents table
		_, err = db.Exec(`INSERT INTO checkbox (UserID, Timestamp, IsChecked) VALUES (?, ?, ?)`, userID, Timestamp, IsChecked)
		//fmt.Println(userID, Timestamp, IsChecked)
		if err != nil {
			fmt.Println("Failed to insert data into checkbox table:", err)
			return
		}
		fmt.Println("Data inserted successfully!")
	}
}

func Retrieve (userID string) []*Document {

	// Replace the connection details with your MySQL configuration
	dsn := "root:1234@tcp(localhost:3306)/checkboxes"

	// Connect to the MySQL server
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Println("Failed to connect to MySQL:", err)
		return nil
	}
	defer db.Close()

	// Query the checked files for a specific user
	query := "SELECT * FROM checkbox WHERE UserID = ? AND IsChecked = ?"
	rows, err := db.Query(query, userID, true)
	if err != nil {
		fmt.Println("Failed to retrieve data from checkbox table:", err)
		return nil
	}
	defer rows.Close()

	// Store the retrieved documents in a slice
	documents := []*Document{}
	for rows.Next() {
		var doc Document
		err := rows.Scan(&doc.UserID, &doc.Timestamp, &doc.IsChecked)
		if err != nil {
			fmt.Println("Failed to scan row:", err)
			return nil
		}
		// Create a new Document pointer and assign the values
		document := &Document{
			UserID:      doc.UserID,
			Timestamp: 	 doc.Timestamp,
			IsChecked: 	 doc.IsChecked, 
		}
		documents = append(documents, document)
	}

	// Check for any errors occurred during rows iteration
	if err = rows.Err(); err != nil {
		fmt.Println("Error occurred during rows iteration:", err)
		return nil
	}

	assets := make([]*Document, len(documents))

	// Iterate over the assetInfos and populate the assets slice
	for i, document := range documents {
	assets[i] = document
	}
	return assets
}



func documentExists(db *sql.DB, userID string, Timestamp string) (bool, error) {
	var count int
	query := `
		SELECT COUNT(*) FROM checkbox
		WHERE UserID = ? AND Timestamp = ?
	`
	err := db.QueryRow(query, userID, Timestamp).Scan(&count)
	if err != nil {
		log.Println("Error querying the database:", err)
		return false, err
	}

	return count > 0, nil
}

func GetUsernames() ([]string, error) {
	dsn := "root:1234@tcp(localhost:3306)/mywebapp"

	// Connect to the MySQL server
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Println("Failed to connect to MySQL:", err)
		return nil, err
	}
	defer db.Close()

	// Execute the query to retrieve usernames
	rows, err := db.Query("SELECT username FROM users")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Iterate over the rows and retrieve the usernames
	var usernames []string
	for rows.Next() {
		var username string
		err := rows.Scan(&username)
		if err != nil {
			return nil, err
		}
		usernames = append(usernames, username)
	}

	// Check for any errors during iteration
	err = rows.Err()
	if err != nil {
		return nil, err
	}

	return usernames, nil
}

func ChangeUserPassword(username, newPassword string) error {

	dsn := "root:1234@tcp(localhost:3306)/mywebapp"

	// Connect to the MySQL server
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		fmt.Println("Failed to connect to MySQL:", err)
		return err
	}
	defer db.Close()

	hashedPassword := fmt.Sprintf("%x", md5.Sum([]byte(newPassword)))

	// Prepare the update statement
	stmt, err := db.Prepare("UPDATE users SET password = ? WHERE username = ?")
	if err != nil {
		return err
	}
	defer stmt.Close()

	// Execute the update statement
	_, err = stmt.Exec(hashedPassword, username)
	if err != nil {
		return err
	}

	fmt.Println("Password updated successfully")
	return nil
}