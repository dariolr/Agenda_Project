#!/usr/bin/env php
<?php
/**
 * Genera hash bcrypt per password superadmin
 * 
 * Uso:
 *   php bin/generate-password-hash.php "MiaPasswordSicura123!"
 *   
 * Output:
 *   Hash da copiare nel seed SQL
 */

if ($argc < 2) {
    echo "Uso: php bin/generate-password-hash.php \"password\"\n";
    exit(1);
}

$password = $argv[1];

// Validazione base
if (strlen($password) < 8) {
    echo "⚠️  Errore: La password deve avere almeno 8 caratteri\n";
    exit(1);
}

if (!preg_match('/[A-Z]/', $password)) {
    echo "⚠️  Errore: La password deve contenere almeno una lettera maiuscola\n";
    exit(1);
}

if (!preg_match('/[a-z]/', $password)) {
    echo "⚠️  Errore: La password deve contenere almeno una lettera minuscola\n";
    exit(1);
}

if (!preg_match('/[0-9]/', $password)) {
    echo "⚠️  Errore: La password deve contenere almeno un numero\n";
    exit(1);
}

$hash = password_hash($password, PASSWORD_BCRYPT);

echo "\n";
echo "✅ Hash generato con successo!\n";
echo "\n";
echo "Password: {$password}\n";
echo "Hash:     {$hash}\n";
echo "\n";
echo "SQL da eseguire:\n";
echo "----------------\n";
echo "UPDATE users SET password_hash = '{$hash}' WHERE email = 'dario@romeolab.it';\n";
echo "\n";
