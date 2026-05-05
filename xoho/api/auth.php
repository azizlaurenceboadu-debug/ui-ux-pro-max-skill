<?php
// ─── Admin Authentication API ─────────────────────────────────────────────
// POST /api/auth.php?action=login   → { email, password }
// POST /api/auth.php?action=logout
// GET  /api/auth.php?action=check   → { loggedIn: bool, name?, email? }

require_once __DIR__ . '/config.php';

session_name(SESSION_NAME);
session_start();

$action = $_GET['action'] ?? '';

match($action) {
    'login'  => handleLogin(),
    'logout' => handleLogout(),
    'check'  => handleCheck(),
    default  => jsonError('Action invalide', 400),
};

// ──────────────────────────────────────────────────────────────────────────

function handleLogin(): void {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') jsonError('Méthode invalide', 405);

    $body  = getBody();
    $email = trim($body['email'] ?? '');
    $pass  = $body['password'] ?? '';

    if (!$email || !$pass) jsonError('Email et mot de passe requis');

    $db   = getDB();
    $stmt = $db->prepare("SELECT id, name, email, password_hash FROM admin_users WHERE email = :email LIMIT 1");
    $stmt->execute([':email' => $email]);
    $admin = $stmt->fetch();

    if (!$admin || !password_verify($pass, $admin['password_hash'])) {
        // Constant-time delay to mitigate timing attacks
        usleep(500000);
        jsonError('Identifiants incorrects', 401);
    }

    $_SESSION['admin_id']    = $admin['id'];
    $_SESSION['admin_name']  = $admin['name'];
    $_SESSION['admin_email'] = $admin['email'];
    $_SESSION['last_active'] = time();

    jsonResponse([
        'success' => true,
        'name'    => $admin['name'],
        'email'   => $admin['email'],
    ]);
}

function handleLogout(): void {
    session_unset();
    session_destroy();
    jsonResponse(['success' => true]);
}

function handleCheck(): void {
    if (empty($_SESSION['admin_id'])) {
        jsonResponse(['loggedIn' => false]);
        return;
    }
    if (isset($_SESSION['last_active']) && (time() - $_SESSION['last_active']) > SESSION_TIMEOUT) {
        session_destroy();
        jsonResponse(['loggedIn' => false]);
        return;
    }
    jsonResponse([
        'loggedIn' => true,
        'name'     => $_SESSION['admin_name'],
        'email'    => $_SESSION['admin_email'],
    ]);
}
