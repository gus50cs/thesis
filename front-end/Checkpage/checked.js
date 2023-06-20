function goToOwn() {
window.location.href = "/update-access";
}	

function goToUpload() {
window.location.href = "/upload";
}

function goToHome() {
window.location.href = "/";
}
$(document).ready(function() {
    // Move checked files to "Checked Files" category
    $('.check-btn').on('change', function() {
        var isChecked = $(this).is(':checked');
        var timestamp = $(this).data('document-time');

        $.ajax({
            url: '/saveCheckedFile',
            type: 'POST',
            data: {
                timestamp: timestamp,
                isChecked: isChecked,
            },
            success: function(response) {
                // Handle the success response
                console.log(response); // Log the response to the console
            },
            error: function(xhr, status, error) {
                // Handle the error response
                alert('Error saving checked file: ' + error);
            }
        });
    });
});



