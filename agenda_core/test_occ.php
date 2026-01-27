<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Hardcode for test
$pdo = new PDO("mysql:host=localhost;dbname=db5hleekkbuuhm", "u5hleekkbuuhm", "Romanina23!");
$stmt = $pdo->query("SELECT id FROM staff WHERE business_id = 2 AND is_active = 1");
$staffList = $stmt->fetchAll(PDO::FETCH_COLUMN);
echo "Staff found: " . implode(",", $staffList) . "\n";

$totalMinutes = 0;
$startDate = "2026-01-24";
$endDate = "2026-01-27";

foreach ($staffList as $staffId) {
    $stmt = $pdo->prepare("SELECT id, type, valid_from, valid_to FROM staff_planning WHERE staff_id = ?");
    $stmt->execute([$staffId]);
    $plannings = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "\nStaff $staffId: " . count($plannings) . " plannings\n";
    
    $start = new DateTime($startDate);
    $end = new DateTime($endDate);
    $end->modify('+1 day');
    $period = new DatePeriod($start, new DateInterval('P1D'), $end);
    
    foreach ($period as $date) {
        $dateStr = $date->format('Y-m-d');
        $dayOfWeek = (int)$date->format('N');
        
        foreach ($plannings as $p) {
            if ($dateStr >= $p["valid_from"] && ($p["valid_to"] === null || $dateStr <= $p["valid_to"])) {
                $stmt = $pdo->prepare("SELECT slots FROM staff_planning_week_template WHERE staff_planning_id = ? AND week_label = 'A' AND day_of_week = ?");
                $stmt->execute([$p["id"], $dayOfWeek]);
                $template = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($template && $template["slots"]) {
                    $slots = json_decode($template["slots"], true);
                    $mins = count($slots) * 15;
                    $totalMinutes += $mins;
                    echo "  $dateStr (dow=$dayOfWeek): " . count($slots) . " slots = $mins min\n";
                }
                break;
            }
        }
    }
}
echo "\nTotal: $totalMinutes minutes = " . ($totalMinutes/60) . " hours\n";
