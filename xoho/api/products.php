<?php
// ─── Products API ─────────────────────────────────────────────────────────
// GET  /api/products.php               → all published products (public)
// GET  /api/products.php?id=X          → single product (public if published)
// GET  /api/products.php?pole=X        → filter by pole (public)
// GET  /api/products.php?top=1         → top sellers (public)
// GET  /api/products.php?all=1         → all products including unpublished (admin only)
// POST /api/products.php               → create product (admin)
// PUT  /api/products.php?id=X          → update product (admin)
// DELETE /api/products.php?id=X        → delete product (admin)

require_once __DIR__ . '/config.php';

$method = $_SERVER['REQUEST_METHOD'];
$id     = isset($_GET['id']) ? (int)$_GET['id'] : null;

match(true) {
    $method === 'GET' && $id !== null  => getOne($id),
    $method === 'GET'                  => getList(),
    $method === 'POST'                 => createProduct(),
    $method === 'PUT'  && $id !== null => updateProduct($id),
    $method === 'DELETE' && $id !== null => deleteProduct($id),
    default => jsonError('Route invalide', 404),
};

// ──────────────────────────────────────────────────────────────────────────

function getList(): void {
    $db    = getDB();
    $where = [];
    $params = [];

    $isAdmin = !empty($_GET['all']);
    if ($isAdmin) {
        requireAdmin();
    } else {
        $where[]          = 'p.published = 1';
    }

    if (!empty($_GET['pole'])) {
        $where[]          = 'p.pole = :pole';
        $params[':pole']  = $_GET['pole'];
    }
    if (!empty($_GET['top'])) {
        $where[]          = 'p.top_sell = 1';
    }

    $whereSQL = $where ? 'WHERE ' . implode(' AND ', $where) : '';
    $stmt = $db->prepare("SELECT * FROM products $whereSQL ORDER BY created_at DESC");
    $stmt->execute($params);
    jsonResponse($stmt->fetchAll());
}

function getOne(int $id): void {
    $db   = getDB();
    $stmt = $db->prepare("SELECT * FROM products WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $product = $stmt->fetch();
    if (!$product) jsonError('Produit introuvable', 404);
    // Public can only see published products
    if (!$product['published'] && empty($_GET['admin'])) jsonError('Produit introuvable', 404);
    jsonResponse($product);
}

function createProduct(): void {
    requireAdmin();
    $data = getBody();
    $v    = validateProduct($data);

    $db   = getDB();
    $stmt = $db->prepare("
        INSERT INTO products
          (name, pole, price, short_desc, full_desc, bullets, format, file_size,
           file_path, preview_url, published, top_sell, featured)
        VALUES
          (:name, :pole, :price, :short_desc, :full_desc, :bullets, :format, :file_size,
           :file_path, :preview_url, :published, :top_sell, :featured)
    ");
    $stmt->execute($v);
    $newId = (int)$db->lastInsertId();
    $stmt2 = $db->prepare("SELECT * FROM products WHERE id = :id");
    $stmt2->execute([':id' => $newId]);
    jsonResponse($stmt2->fetch(), 201);
}

function updateProduct(int $id): void {
    requireAdmin();
    $db   = getDB();
    $stmt = $db->prepare("SELECT id FROM products WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    if (!$stmt->fetch()) jsonError('Produit introuvable', 404);

    $data = getBody();
    $v    = validateProduct($data);
    $v[':id'] = $id;

    $db->prepare("
        UPDATE products SET
          name=:name, pole=:pole, price=:price, short_desc=:short_desc, full_desc=:full_desc,
          bullets=:bullets, format=:format, file_size=:file_size, file_path=:file_path,
          preview_url=:preview_url, published=:published, top_sell=:top_sell, featured=:featured
        WHERE id=:id
    ")->execute($v);

    $stmt3 = $db->prepare("SELECT * FROM products WHERE id = :id");
    $stmt3->execute([':id' => $id]);
    jsonResponse($stmt3->fetch());
}

function deleteProduct(int $id): void {
    requireAdmin();
    $db   = getDB();
    $stmt = $db->prepare("SELECT file_path FROM products WHERE id = :id LIMIT 1");
    $stmt->execute([':id' => $id]);
    $p = $stmt->fetch();
    if (!$p) jsonError('Produit introuvable', 404);

    // Delete physical file if stored locally
    if ($p['file_path'] && file_exists(UPLOAD_DIR . $p['file_path'])) {
        unlink(UPLOAD_DIR . $p['file_path']);
    }

    $db->prepare("DELETE FROM products WHERE id = :id")->execute([':id' => $id]);
    jsonResponse(['success' => true]);
}

function validateProduct(array $d): array {
    $poles = ['administratif','academique','citoyen','business','vie-pratique'];
    $pole  = $d['pole'] ?? '';
    if (!in_array($pole, $poles, true)) jsonError('Pôle invalide');

    $price = (int)($d['price'] ?? 0);
    if ($price < 50 || $price > 100000) jsonError('Prix invalide (50 – 100 000 FCFA)');

    $name = trim($d['name'] ?? '');
    if (strlen($name) < 3 || strlen($name) > 255) jsonError('Nom invalide');

    return [
        ':name'        => $name,
        ':pole'        => $pole,
        ':price'       => $price,
        ':short_desc'  => trim($d['shortDesc'] ?? $d['short_desc'] ?? ''),
        ':full_desc'   => trim($d['fullDesc']  ?? $d['full_desc']  ?? ''),
        ':bullets'     => trim($d['bullets']   ?? ''),
        ':format'      => trim($d['format']    ?? ''),
        ':file_size'   => trim($d['fileSize']  ?? $d['file_size']  ?? ''),
        ':file_path'   => trim($d['filePath']  ?? $d['file_path']  ?? ''),
        ':preview_url' => trim($d['previewUrl']?? $d['preview_url']?? ''),
        ':published'   => (int)(bool)($d['published'] ?? false),
        ':top_sell'    => (int)(bool)($d['topSell']   ?? $d['top_sell']   ?? false),
        ':featured'    => (int)(bool)($d['featured']  ?? false),
    ];
}
