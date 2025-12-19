<?php
$logFile = 'storage/logs/laravel.log';
if (!file_exists($logFile)) {
    echo "Log file not found.";
    exit;
}

// Lire tout le fichier en mémoire (attention si gros fichier)
$content = file_get_contents($logFile);
// Découper par lignes
$lines = explode("\n", $content);
// Prendre les 20 dernières
$lastLines = array_slice($lines, -20);
$lastLines = array_reverse($lastLines);

foreach ($lastLines as $line) {
    // Nettoyer caractères bizarres
    $line = preg_replace('/[\x00-\x1F\x7F]/', '', $line);
    echo trim($line) . "\n";
}
