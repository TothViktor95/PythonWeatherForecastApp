<?php
if (isset($_GET['city'])) {
    // Redirect to the appropriate endpoint URL
    $city = urlencode($_GET['city']);
    header("Location: http://localhost:5000/weather/$city");
    exit();
} else {
    // If the 'city' parameter is not set, return a 400 Bad Request error
    header("HTTP/1.0 400 Bad Request");
    echo "Missing 'city' parameter";
    exit();
}
?>