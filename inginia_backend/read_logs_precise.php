<?php
$logFile = 'storage/logs/laravel.log';
if (!file_exists($logFile)) {
    echo "Log file not found.";
    exit;
}

$content = file_get_contents($logFile);
$search = "Erreur Broadcast SOS";
$pos = strrpos($content, $search);

if ($pos !== false) {
    echo "--- DERNIERE ERREUR ---\n";
    // Extraire et nettoyer
    $fragment = substr($content, $pos, 600);
    $fragment = preg_replace('/[^\x20-\x7E\n\r\t]/', '', $fragment);
    echo $fragment;
} else {
    echo "Aucune erreur de broadcast trouvee dans le log.";
}
