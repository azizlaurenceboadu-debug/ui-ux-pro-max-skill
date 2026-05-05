<?php
// ─── Run once to create/update the admin account ──────────────────────────
// Usage: php api/seed_admin.php
// Or visit: https://yoursite.com/api/seed_admin.php?email=admin@xoho.bj&pass=MonMotDePasse123
// DELETE this file after use!

require_once __DIR__ . '/config.php';

$email    = $_GET['email'] ?? 'admin@xoho.bj';
$password = $_GET['pass']  ?? 'admin123';
$name     = $_GET['name']  ?? 'Admin XOHO';

if (strlen($password) < 8) {
    die("Erreur: mot de passe trop court (min 8 caractères)\n");
}

$hash = password_hash($password, PASSWORD_DEFAULT);

$db = getDB();
$stmt = $db->prepare("
    INSERT INTO admin_users (email, password_hash, name)
    VALUES (:email, :hash, :name)
    ON DUPLICATE KEY UPDATE password_hash = :hash2, name = :name2
");
$stmt->execute([
    ':email' => $email,
    ':hash'  => $hash,
    ':name'  => $name,
    ':hash2' => $hash,
    ':name2' => $name,
]);

echo "✅ Admin créé/mis à jour:\n";
echo "   Email    : $email\n";
echo "   Password : $password\n";
echo "   Hash     : $hash\n";
echo "\n⚠️  Supprimez ce fichier après utilisation!\n";
