<?php
// backend/generate_pdf.php
// Ensure Dompdf is installed: composer require dompdf/dompdf

require 'vendor/autoload.php';
// include 'db_connect.php'; // TODO: Include your database connection script here

use Dompdf\Dompdf;
use Dompdf\Options;

if (!isset($_GET['regsno'])) {
    die("Registration Number (regsno) is required.");
}

$regNo = $_GET['regsno'];

/**
 * Fetch student data from database.
 * TODO: Replace this mock/logic with your actual DB query.
 */
function getStudentData($regNo) {
    // Example DB connection (Replace with yours)
    /*
    global $conn;
    $stmt = $conn->prepare("SELECT * FROM students WHERE reg_no = ?");
    $stmt->bind_param("s", $regNo);
    $stmt->execute();
    $result = $stmt->get_result();
    $student = $result->fetch_assoc();
    */

    // MOCK DATA (Remove this when DB is connected)
    return [
        'regNo' => $regNo,
        'marksheetNo' => 'MS-' . rand(1000, 9999),
        'name' => 'Demo Student', // Replace with DB data
        'fatherName' => 'Father Name',
        'course' => 'ADCA',
        'courseDuration' => 'Jan-2025 to Dec-2025',
        'centre' => 'Sanjeet Jaiswal Computer Training Centre',
        'subjects' => [
            ['name' => 'Computer Fundamental', 'obtainedMarks' => 85],
            ['name' => 'MS-Office', 'obtainedMarks' => 90],
            ['name' => 'Programming C++', 'obtainedMarks' => 78]
        ],
        'totalObtained' => 253,
        'percentage' => 84.3,
        'result' => 'PASS',
        'grade' => 'A',
        'issueDate' => date('d-m-Y')
    ];
}

$student = getStudentData($regNo);

if (!$student) {
    die("Student not found.");
}

// Asset Paths (Adjust base URL as needed for images)
// Dompdf needs absolute paths or enabled remote access for images
$bgImage = 'assets/documents/marksheet.jpg'; 
$logoUrl = 'assets/documents/school_logo.png';
$isoLogo = 'assets/documents/iso.png';
$msmeLogo = 'assets/documents/msme.png';
$skillLogo = 'assets/documents/skill.png';
// Convert to base64 if local file, or use URL if isRemoteEnabled is true.
// Here assuming local files in same directory structure for Dompdf to find.
// Helper to convert image to base64 for reliable embedding
function imageToBase64($path) {
    if (file_exists($path)) {
        $type = pathinfo($path, PATHINFO_EXTENSION);
        $data = file_get_contents($path);
        return 'data:image/' . $type . ';base64,' . base64_encode($data);
    }
    return ''; // Return placeholder or empty
}

// Overwrite variables with Base64 for template
$bgImage = imageToBase64($bgImage);
$logoUrl = imageToBase64($logoUrl);
$isoLogo = imageToBase64($isoLogo);
$msmeLogo = imageToBase64($msmeLogo);
$skillLogo = imageToBase64($skillLogo);

// QR Code generation (You might need a library like endroid/qr-code or use an API)
// Using a public API for demo purposes or your existing logic
$qrCode = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=' . urlencode("https://www.gokulshreeschool.com/verify?id=" . $student['marksheetNo']);

$generatedAt = date("d/m/Y, h:i:s A") . ' IST';
$photoUrl = ''; // Fetch from DB or use placeholder

// Render PDF
$options = new Options();
$options->set('isRemoteEnabled', true); // Allow loading images from URLs
$dompdf = new Dompdf($options);

ob_start();
include 'marksheet_template.php'; 
$html = ob_get_clean();

$dompdf->loadHtml($html);
$dompdf->setPaper('A4', 'portrait');
$dompdf->render();

// Stream the file
$dompdf->stream("Marksheet_" . $regNo . ".pdf", ["Attachment" => true]);
?>
