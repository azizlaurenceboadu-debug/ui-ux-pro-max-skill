<?php
// ─── Database Configuration ────────────────────────────────────────────────
// Edit these values with your Systalink credentials (cPanel → MySQL Databases)

define('DB_HOST',     'localhost');
define('DB_NAME',     'xoho_db');
define('DB_USER',     'xoho_user');
define('DB_PASS',     'CHANGE_ME_STRONG_PASSWORD');
define('DB_CHARSET',  'utf8mb4');

// ─── App Settings ──────────────────────────────────────────────────────────
define('BASE_URL',    'https://xoho.bj');          // No trailing slash
define('UPLOAD_DIR',  __DIR__ . '/../uploads/');
define('UPLOAD_URL',  BASE_URL . '/uploads/');
define('MAX_FILE_MB', 50);

// ─── Session ───────────────────────────────────────────────────────────────
define('SESSION_NAME',    'xoho_admin');
define('SESSION_TIMEOUT', 3600 * 8);               // 8 hours

// ─── PDO Connection ────────────────────────────────────────────────────────
function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET;
        $options = [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ];
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    }
    return $pdo;
}

// ─── CORS & JSON helpers ───────────────────────────────────────────────────
function setCorsHeaders(): void {
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';
    // Allow same origin only in production; adjust if needed
    header('Access-Control-Allow-Origin: ' . (BASE_URL));
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');
    header('Access-Control-Allow-Credentials: true');
    if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

function jsonResponse(mixed $data, int $code = 200): never {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function jsonError(string $message, int $code = 400): never {
    jsonResponse(['error' => $message], $code);
}

function getBody(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}

// ─── Auth guard ────────────────────────────────────────────────────────────
function requireAdmin(): void {
    session_name(SESSION_NAME);
    session_start();
    if (empty($_SESSION['admin_id'])) {
        jsonError('Non autorisé', 401);
    }
    // Timeout check
    if (isset($_SESSION['last_active']) && (time() - $_SESSION['last_active']) > SESSION_TIMEOUT) {
        session_destroy();
        jsonError('Session expirée, reconnectez-vous', 401);
    }
    $_SESSION['last_active'] = time();
}
