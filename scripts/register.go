package main

import (
    "crypto/md5"
    "database/sql"
    "fmt"
    "log"

    _ "github.com/go-sql-driver/mysql"
)

const (
    dbDriver = "mysql"
    dbSource = "root:1234@tcp(localhost:3306)/mywebapp"
)

type User struct {
	ID       int
	Username string
	Password string
}

func main() {
    // Connect to the database
    db, err := sql.Open(dbDriver, dbSource)
    if err != nil {
        log.Fatal(err)
    }
    defer db.Close()

    // Test the connection
    err = db.Ping()
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println("Connected to the database!")


	// Retrieve all users from the database
	users, err := getUsers(db)
	if err != nil {
		log.Fatal(err)
	}
  
	fmt.Println(users)
	//for _, user := range users {
//		fmt.Printf("ID: %d, Username: %s\n", user.ID, user.Username)
//	}

	

    // Execute the DELETE statement
    //result, err := db.Exec(deleteQuery, "Paul")
    //if err != nil {
    //    log.Fatal(err)
    //}

    // Check the number of affected rows
    //rowsAffected, err := result.RowsAffected()
    //if err != nil {
    //    log.Fatal(err)
    //}

    //fmt.Printf("Deleted %d user(s)\n", rowsAffected)
    // Ask the user for the username and password
	var username, password string
	fmt.Print("Enter username: ")
	fmt.Scanln(&username)
	fmt.Print("Enter password: ")
	fmt.Scanln(&password)

    // Check if the username already exists
	exists, err := usernameExists(db, username)
	if err != nil {
		log.Fatal(err)
	}

	if exists {
		fmt.Println("Username already exists. User not created.")
		return
	}

    hashedPassword := fmt.Sprintf("%x", md5.Sum([]byte(password)))
    fmt.Print(hashedPassword)
    insertUserQuery := `
        INSERT INTO users (username, password) VALUES (?, ?)`
    _, err = db.Exec(insertUserQuery, username, hashedPassword)
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println("User registered successfully!")

  
}


func usernameExists(db *sql.DB, username string) (bool, error) {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM users WHERE username=?", username).Scan(&count)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

func getUsers(db *sql.DB) ([]User, error) {
	query := "SELECT id, username, password FROM users"
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		err := rows.Scan(&user.ID, &user.Username, &user.Password)
		if err != nil {
			return nil, err
		}
		users = append(users, user)
	}

	return users, nil
}