<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST['name'];
    $email = $_POST['email'];
    $country_code = $_POST['country-code'];
    $phone = $_POST['phone'];
    $message = $_POST['message'];

    $to = 'romanilm@yahoo.com';
    $subject = 'Contact Form Message';
    $body = "Name: $name\nEmail: $email\nCountry Code: $country_code\nPhone: $phone\nMessage: $message";
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