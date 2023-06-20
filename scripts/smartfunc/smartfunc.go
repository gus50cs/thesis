package smartfunc

import (
	//"strings"
	"encoding/json"
	"bytes"
	"github.com/hyperledger/fabric-gateway/pkg/client"
	"fmt"
    _ "github.com/go-sql-driver/mysql"
)

type Asset struct {
	DocumentID string
	Owner      string
	DocumentCID		string
	Timestamp string
}

type AssetOwner struct {
	DocumentID string
	Owner      string
	DocumentCID		string
	AccessList []string
	Timestamp string
}

func CreateAsset(contract *client.Contract, documentid string, code string, owner string, access string) {
	fmt.Printf("Submit Transaction: CreateAsset, creates new asset with ID, Color, Size, Owner and AppraisedValue arguments \n")
	//var list string
	//fmt.Scan(&list)
	
	_, err := contract.SubmitTransaction("CreateDocument", documentid, code, owner, access)
	if err != nil {
		panic(fmt.Errorf("failed to submit transaction: %w", err))
	}
	fmt.Printf("*** Transaction committed successfully\n")
}


func UpdateAccess(contract *client.Contract, access string, DocumentID string, Owner string ) {
	fmt.Printf("Submit Transaction: UpdateAccess \n")
	//var list string
	
	//fmt.Println("Add access list ?(use comma)")
	//fmt.Scan(&list)
	
	_, err := contract.SubmitTransaction("UpdateAccess", access, DocumentID, Owner)
	if err != nil {
		panic(fmt.Errorf("failed to submit transaction: %w", err))
	}
	fmt.Printf("*** Transaction committed successfully\n")
}

func ReadAsset(contract *client.Contract) {
	fmt.Printf("Evaluate Transaction: ReadAsset, function returns asset attributes\n")

	evaluateResult, err := contract.EvaluateTransaction("ReturnAsset", "document1", "Ship1")
	if err != nil {
		panic(fmt.Errorf("failed to evaluate transaction: %w", err))
	}
	result := formatJSON(evaluateResult)

	fmt.Printf("*** Result:%s\n", result)
}

func AllAsset(contract *client.Contract) {
	
	evaluateResult, err := contract.EvaluateTransaction("GetAllAssets")
	if err != nil {
		panic(fmt.Errorf("failed to evaluate transaction: %w", err))
	}
	result := formatJSON(evaluateResult)

	fmt.Printf("*** Result:%s\n", result)
}

func GetAssetsWithCID(contract *client.Contract, accessName string) ([]Asset, error) {
	// Evaluate the GetCIDByAccessName transaction
	evaluateResult, err := contract.EvaluateTransaction("GetCIDByAccessName", accessName)
	if err != nil {
		return nil, fmt.Errorf("failed to evaluate transaction: %w", err)
	}

	//result := formatJSON(evaluateResult)

	//fmt.Printf("*** Result:%s\n", result)

	// Parse the JSON response into an array of AssetInfo
	var assetInfos []Asset
	err = json.Unmarshal(evaluateResult, &assetInfos)
	if err != nil {
		return nil, fmt.Errorf("failed to parse JSON result: %w", err)
	}

	// Initialize the assets slice
	assets := make([]Asset, len(assetInfos))

	// Iterate over the assetInfos and populate the assets slice
	for i, assetInfo := range assetInfos {
		// Create the Asset object with DocumentID, Owner, and an empty CID
		assets[i] = Asset{
			DocumentID: assetInfo.DocumentID,
			Owner:      assetInfo.Owner,
			DocumentCID: 		assetInfo.DocumentCID,
			Timestamp : assetInfo.Timestamp,
		}
	}

	return assets, nil
}

func GetOwnerWithCID(contract *client.Contract, accessName string) ([]AssetOwner, error) {
	// Evaluate the GetCIDByAccessName transaction
	evaluateResult, err := contract.EvaluateTransaction("GetCIDByOwnerName", accessName)
	if err != nil {
		return nil, fmt.Errorf("failed to evaluate transaction: %w", err)
	}

	//result := formatJSON(evaluateResult)

	//fmt.Printf("*** Result:%s\n", result)

	// Parse the JSON response into an array of AssetInfo
	var assetInfos []AssetOwner
	err = json.Unmarshal(evaluateResult, &assetInfos)
	if err != nil {
		return nil, fmt.Errorf("failed to parse JSON result: %w", err)
	}

	// Initialize the assets slice
	assets := make([]AssetOwner, len(assetInfos))

	// Iterate over the assetInfos and populate the assets slice
	for i, assetInfo := range assetInfos {
		// Create the Asset object with DocumentID, Owner, and an empty CID
		assets[i] = AssetOwner{
			DocumentID: assetInfo.DocumentID,
			Owner:      assetInfo.Owner,
			AccessList: assetInfo.AccessList,
			DocumentCID: 		assetInfo.DocumentCID,
			Timestamp: assetInfo.Timestamp,
		}
	}
	return assets, nil
}





func DeleteAsset(contract *client.Contract, documentid string, owner string) {
	
	_, err := contract.SubmitTransaction("DeleteAsset", documentid, owner)
	if err != nil {
		panic(fmt.Errorf("failed to evaluate transaction: %w", err))
	}
}


// Format JSON data
func formatJSON(data []byte) string {
	if len(data) == 0 {
		// Return an empty string if the data is empty
		return ""
	}

	// Check if the input data is a valid JSON string.
	var temp interface{}
	if err := json.Unmarshal(data, &temp); err != nil {
		panic(fmt.Errorf("failed to parse JSON: %w", err))
	}

	// Format the JSON string with indentation.
	var prettyJSON bytes.Buffer
	if err := json.Indent(&prettyJSON, data, " ", ""); err != nil {
		panic(fmt.Errorf("failed to format JSON: %w", err))
	}

	// Return the formatted JSON string.
	return prettyJSON.String()
}