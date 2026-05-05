<?php
// ─── Secure File Download ─────────────────────────────────────────────────
// GET /api/download.php?token=X
// Validates order token, then streams the file with a forced download header.
// The real file path is never exposed to the browser.

require_once __DIR__ . '/config.php';

$token = trim($_GET['token'] ?? '');
if (!$token || strlen($token) !== 64 || !ctype_xdigit($token)) {
    http_response_code(400);
    die('Token invalide');
}

$db   = getDB();
$stmt = $db->prepare("
    SELECT o.status, o.product_name, p.file_path, p.format
    FROM orders o
    JOIN products p ON p.id = o.product_id
    WHERE o.download_token = :token
    LIMIT 1
");
$stmt->execute([':token' => $token]);
$row = $stmt->fetch();

if (!$row) {
    http_response_code(404);
    die('Commande introuvable');
}

if (!in_array($row['status'], ['completed', 'accessed'], true)) {
    http_response_code(403);
    die('Paiement non confirmé. Contactez-nous sur WhatsApp si vous avez bien payé.');
}

$filePath = UPLOAD_DIR . ltrim($row['file_path'], '/');
if (!$row['file_path'] || !file_exists($filePath)) {
    http_response_code(404);
    die('Fichier introuvable. Contactez le support.');
}

// Build a clean filename for the download
$ext      = pathinfo($filePath, PATHINFO_EXTENSION);
$safeName = preg_replace('/[^a-zA-Z0-9\-_]/', '_', $row['product_name']);
$filename = $safeName . '.' . $ext;

$mime = match(strtolower($ext)) {
    'pdf'  => 'application/pdf',
    'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'xls'  => 'application/vnd.ms-excel',
    'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'doc'  => 'application/msword',
    'zip'  => 'application/zip',
    default=> 'application/octet-stream',
};

// Stream file
header('Content-Type: ' . $mime);
header('Content-Disposition: attachment; filename="' . $filename . '"');
header('Content-Length: ' . filesize($filePath));
header('Cache-Control: no-cache, no-store, must-revalidate');
header('Pragma: no-cache');
header('Expires: 0');
readfile($filePath);
exit;
