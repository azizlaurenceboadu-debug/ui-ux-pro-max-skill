<?php
// ─── Orders API ───────────────────────────────────────────────────────────
// POST /api/orders.php                          → create order (public)
// GET  /api/orders.php?token=X                  → get order by download token (public)
// GET  /api/orders.php?all=1[&status=X]         → all orders (admin)
// PUT  /api/orders.php?id=X                     → update status (admin)
// POST /api/orders.php?action=confirm&txid=X    → Kkiapay webhook / confirm payment

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? '';

match(true) {
    $method === 'POST' && $action === 'confirm' => confirmPayment(),
    $method === 'POST'                          => createOrder(),
    $method === 'GET' && !empty($_GET['token']) => getByToken(),
    $method === 'GET' && !empty($_GET['all'])   => listOrders(),
    $method === 'GET' && !empty($_GET['id'])    => getOne((int)$_GET['id']),
    $method === 'PUT' && !empty($_GET['id'])    => updateStatus((int)$_GET['id']),
    default => jsonError('Route invalide', 404),
};

// ──────────────────────────────────────────────────────────────────────────

function createOrder(): void {
    $data = getBody();

    $name  = trim($data['buyerName']  ?? '');
    $email = trim($data['buyerEmail'] ?? '');
    $phone = preg_replace('/\D/', '', $data['buyerPhone'] ?? '');
    $pid   = (int)($data['productId'] ?? 0);

    if (!$name || strlen($name) < 2)     jsonError('Nom requis');
    if (!$phone || strlen($phone) < 8)   jsonError('Téléphone invalide');
    if ($pid < 1)                         jsonError('Produit invalide');

    $db   = getDB();
    $stmt = $db->prepare("SELECT id, name, price, published FROM products WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $pid]);
    $product = $stmt->fetch();
    if (!$product || !$product['published']) jsonError('Produit introuvable', 404);

    $token = bin2hex(random_bytes(32)); // 64-char hex token

    $ins = $db->prepare("
        INSERT INTO orders
          (product_id, product_name, amount, buyer_name, buyer_email, buyer_phone, download_token)
        VALUES
          (:pid, :pname, :amount, :name, :email, :phone, :token)
    ");
    $ins->execute([
        ':pid'    => $product['id'],
        ':pname'  => $product['name'],
        ':amount' => $product['price'],
        ':name'   => $name,
        ':email'  => $email,
        ':phone'  => $phone,
        ':token'  => $token,
    ]);

    $orderId = (int)$db->lastInsertId();

    jsonResponse([
        'orderId' => $orderId,
        'token'   => $token,
        'amount'  => $product['price'],
        'product' => $product['name'],
    ], 201);
}

function confirmPayment(): void {
    // Called after Kkiapay widget success event (client-side POST)
    // or by Kkiapay server webhook
    $data   = getBody();
    $txid   = trim($data['transactionId'] ?? $_GET['txid'] ?? '');
    $token  = trim($data['token'] ?? '');

    if (!$token) jsonError('Token manquant');

    $db   = getDB();
    $stmt = $db->prepare("SELECT * FROM orders WHERE download_token = :token LIMIT 1");
    $stmt->execute([':token' => $token]);
    $order = $stmt->fetch();
    if (!$order) jsonError('Commande introuvable', 404);

    if ($order['status'] === 'completed' || $order['status'] === 'accessed') {
        jsonResponse(['success' => true, 'orderId' => $order['id'], 'token' => $token]);
        return;
    }

    $db->prepare("UPDATE orders SET status='completed', kkiapay_txid=:txid WHERE id=:id")
       ->execute([':txid' => $txid, ':id' => $order['id']]);

    jsonResponse(['success' => true, 'orderId' => $order['id'], 'token' => $token]);
}

function getByToken(): void {
    $token = trim($_GET['token']);
    $db    = getDB();
    $stmt  = $db->prepare("
        SELECT o.*, p.file_path, p.format, p.file_size
        FROM orders o
        JOIN products p ON p.id = o.product_id
        WHERE o.download_token = :token
        LIMIT 1
    ");
    $stmt->execute([':token' => $token]);
    $order = $stmt->fetch();
    if (!$order) jsonError('Commande introuvable', 404);

    // Mark as accessed
    if ($order['status'] === 'completed') {
        $db->prepare("UPDATE orders SET status='accessed' WHERE id=:id")
           ->execute([':id' => $order['id']]);
        $order['status'] = 'accessed';
    }

    // Build download URL (hide real path — serve via download.php)
    $order['download_url'] = BASE_URL . '/api/download.php?token=' . $token;

    // Don't expose file_path to client
    unset($order['file_path']);

    jsonResponse($order);
}

function listOrders(): void {
    requireAdmin();
    $db     = getDB();
    $where  = [];
    $params = [];

    if (!empty($_GET['status'])) {
        $where[]          = 'status = :status';
        $params[':status']= $_GET['status'];
    }

    $whereSQL = $where ? 'WHERE ' . implode(' AND ', $where) : '';
    $stmt = $db->prepare("SELECT * FROM orders $whereSQL ORDER BY created_at DESC LIMIT 500");
    $stmt->execute($params);
    jsonResponse($stmt->fetchAll());
}

function getOne(int $id): void {
    requireAdmin();
    $db   = getDB();
    $stmt = $db->prepare("SELECT * FROM orders WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $order = $stmt->fetch();
    if (!$order) jsonError('Commande introuvable', 404);
    jsonResponse($order);
}

function updateStatus(int $id): void {
    requireAdmin();
    $data   = getBody();
    $status = $data['status'] ?? '';
    $allowed = ['pending', 'completed', 'accessed', 'failed'];
    if (!in_array($status, $allowed, true)) jsonError('Statut invalide');

    $db = getDB();
    $db->prepare("UPDATE orders SET status=:s WHERE id=:id")->execute([':s'=>$status,':id'=>$id]);
    jsonResponse(['success' => true]);
}
