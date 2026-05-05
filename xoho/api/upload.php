<?php
// ─── File Upload API (Admin only) ─────────────────────────────────────────
// POST /api/upload.php?type=product  → upload product file
// POST /api/upload.php?type=preview  → upload preview image
// Returns: { url: "...", path: "..." }

require_once __DIR__ . '/config.php';
requireAdmin();

$type    = $_GET['type'] ?? 'product';
$allowed = match($type) {
    'product' => ['pdf', 'xlsx', 'xls', 'docx', 'doc', 'zip'],
    'preview' => ['jpg', 'jpeg', 'png', 'webp'],
    default   => [],
};
if (!$allowed) jsonError('Type de fichier invalide');

$file = $_FILES['file'] ?? null;
if (!$file || $file['error'] !== UPLOAD_ERR_OK) jsonError('Aucun fichier reçu ou erreur d\'upload');

// Validate extension
$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
if (!in_array($ext, $allowed, true)) {
    jsonError('Extension non autorisée. Formats: ' . implode(', ', $allowed));
}

// Validate size
$maxBytes = MAX_FILE_MB * 1024 * 1024;
if ($file['size'] > $maxBytes) {
    jsonError("Fichier trop grand (max " . MAX_FILE_MB . " Mo)");
}

// Validate MIME via finfo
$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime  = $finfo->file($file['tmp_name']);
$safeMimes = [
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/msword',
    'application/zip',
    'application/x-zip-compressed',
    'image/jpeg',
    'image/png',
    'image/webp',
];
if (!in_array($mime, $safeMimes, true)) jsonError('Type MIME non autorisé: ' . $mime);

// Generate unique filename
$subdir   = ($type === 'preview') ? 'previews/' : 'products/';
$newName  = $subdir . bin2hex(random_bytes(16)) . '.' . $ext;
$destPath = UPLOAD_DIR . $newName;

if (!move_uploaded_file($file['tmp_name'], $destPath)) {
    jsonError('Erreur lors de la sauvegarde du fichier', 500);
}

jsonResponse([
    'success' => true,
    'path'    => $newName,
    'url'     => UPLOAD_URL . $newName,
    'size'    => round($file['size'] / 1024 / 1024, 2) . ' Mo',
]);
