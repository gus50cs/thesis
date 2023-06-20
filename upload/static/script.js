function uploadFile(event) {
    event.preventDefault();

    const fileInput = document.getElementById("file-upload");
    const file = fileInput.files[0];

    if (!file) {
        displayError("No file selected.");
        return false;
    }

    const allowedTypes = ["text/plain", "application/pdf"]; // Update with the allowed file types
    if (!allowedTypes.includes(file.type)) {
        displayError("Invalid file type. Please select a text file or PDF.");
        return false;
    }

    const formData = new FormData();
    formData.append("file", file);

    fetch("/upload", { method: 'POST', body: formData })
        .then(response => response.text())
        .then(data => {
            const messageContainer = document.getElementById("message-container");
            messageContainer.innerText = `Uploaded file: ${file.name}`;
        })
        .catch(error => displayError(error));

    return false;
}

function displayError(errorMessage) {
    const messageContainer = document.getElementById("message-container");
    messageContainer.innerText = `Error: ${errorMessage}`;
}
