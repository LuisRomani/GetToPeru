<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST['name'];
    $email = $_POST['email'];
    $country_code = $_POST['country-code']; // Agregar el country code
    $phone = $_POST['phone'];
    // radio group uses name="travelers" in markup
    $travelers = isset($_POST['travelers']) ? $_POST['travelers'] : '';
    // tour checkboxes may be sent as array
    if (isset($_POST['tour'])) {
        if (is_array($_POST['tour'])) {
            $tour = implode(', ', $_POST['tour']);
        } else {
            $tour = $_POST['tour'];
        }
    } else {
        $tour = '';
    }
    $date = $_POST['date'];
    $message = $_POST['message'];

    $to = 'romanilm@yahoo.com';
    $subject = 'New Tour Booking';
    $body = "Name: $name\nEmail: $email\nCountry Code: $country_code\nPhone: $phone\nTravelers: $travelers\nTour: $tour\nDate: $date\nMessage: $message";
    $headers = "From: noreply@yourdomain.com\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";

    

    if (mail($to, $subject, $body, $headers)) {
        http_response_code(200); // Envío exitoso
    } else {
        http_response_code(500); // Error en el envío
    }
} else {
    http_response_code(403); // Método no permitido
}