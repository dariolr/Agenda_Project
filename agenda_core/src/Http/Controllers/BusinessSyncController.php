<?php

declare(strict_types=1);

namespace Agenda\Http\Controllers;

use Agenda\Http\Request;
use Agenda\Http\Response;
use Agenda\UseCases\Admin\ExportBusiness;
use Agenda\UseCases\Admin\ImportBusiness;
use Agenda\Infrastructure\Repositories\UserRepository;
use Agenda\Infrastructure\Support\Json;

/**
 * Controller per sincronizzazione business tra ambienti
 * Accessibile SOLO ai superadmin
 */
final class BusinessSyncController
{
    public function __construct(
        private ExportBusiness $exportBusiness,
        private ImportBusiness $importBusiness,
        private UserRepository $userRepo
    ) {}

    /**
     * GET /v1/admin/businesses/{id}/export
     * Esporta tutti i dati di un business in JSON
     */
    public function export(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        if (!$this->userRepo->isSuperadmin($userId)) {
            return Response::error('access_denied', 'Accesso riservato ai superadmin', 403);
        }
        
        $businessId = (int)$request->getRouteParam('id');
        
        try {
            $data = $this->exportBusiness->execute($businessId);
            return Response::success($data);
        } catch (\InvalidArgumentException $e) {
            return Response::error('not_found', $e->getMessage(), 404);
        } catch (\Exception $e) {
            return Response::error('export_failed', $e->getMessage(), 500);
        }
    }
    
    /**
     * GET /v1/admin/businesses/by-slug/{slug}/export
     * Esporta business tramite slug
     */
    public function exportBySlug(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        if (!$this->userRepo->isSuperadmin($userId)) {
            return Response::error('access_denied', 'Accesso riservato ai superadmin', 403);
        }
        
        $slug = $request->getRouteParam('slug');
        
        try {
            $data = $this->exportBusiness->executeBySlug($slug);
            return Response::success($data);
        } catch (\InvalidArgumentException $e) {
            return Response::error('not_found', $e->getMessage(), 404);
        } catch (\Exception $e) {
            return Response::error('export_failed', $e->getMessage(), 500);
        }
    }
    
    /**
     * POST /v1/admin/businesses/import
     * Importa dati business da JSON export
     * 
     * Body: { 
     *   "data": { ...export JSON... },
     *   "skip_sessions_and_notifications": false  // Opzionale, default false
     * }
     * 
     * Se skip_sessions_and_notifications=true, NON vengono importate:
     * - notification_queue
     * - auth_sessions
     * - client_sessions
     */
    public function import(Request $request): Response
    {
        $logFile = __DIR__ . '/../../../logs/import_debug.log';
        
        $userId = $request->getAttribute('user_id');
        file_put_contents($logFile, date('Y-m-d H:i:s') . " Import: user_id=$userId\n", FILE_APPEND);
        
        if (!$this->userRepo->isSuperadmin($userId)) {
            return Response::error('access_denied', 'Accesso riservato ai superadmin', 403);
        }
        
        $body = $request->getBody();
        file_put_contents($logFile, date('Y-m-d H:i:s') . " Import: body keys=" . implode(',', array_keys($body ?? [])) . "\n", FILE_APPEND);
        
        $exportData = $body['data'] ?? null;
        $skipSessionsAndNotifications = (bool)($body['skip_sessions_and_notifications'] ?? false);
        
        file_put_contents($logFile, date('Y-m-d H:i:s') . " Import: skip_sessions_and_notifications=$skipSessionsAndNotifications\n", FILE_APPEND);
        
        if (empty($exportData)) {
            file_put_contents($logFile, date('Y-m-d H:i:s') . " Import: exportData is empty\n", FILE_APPEND);
            return Response::error('invalid_request', 'Campo "data" richiesto con export JSON', 400);
        }
        
        file_put_contents($logFile, date('Y-m-d H:i:s') . " Import: business=" . ($exportData['business']['name'] ?? 'N/A') . "\n", FILE_APPEND);
        
        try {
            $stats = $this->importBusiness->execute($exportData, $skipSessionsAndNotifications);
            file_put_contents($logFile, date('Y-m-d H:i:s') . " Import: SUCCESS\n", FILE_APPEND);
            return Response::success([
                'message' => "Business '{$stats['business_name']}' importato con successo",
                'stats' => $stats,
            ]);
        } catch (\InvalidArgumentException $e) {
            file_put_contents($logFile, date('Y-m-d H:i:s') . " Import InvalidArg: " . $e->getMessage() . "\n", FILE_APPEND);
            return Response::error('invalid_data', $e->getMessage(), 400);
        } catch (\Exception $e) {
            file_put_contents($logFile, date('Y-m-d H:i:s') . " Import ERROR: " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine() . "\n", FILE_APPEND);
            file_put_contents($logFile, date('Y-m-d H:i:s') . " Trace: " . $e->getTraceAsString() . "\n", FILE_APPEND);
            return Response::error('import_failed', $e->getMessage(), 500);
        }
    }
    
    /**
     * POST /v1/admin/businesses/sync-from-production
     * Sincronizza un business da produzione
     * 
     * Body: { "business_id": 1 } oppure { "slug": "mio-business" }
     */
    public function syncFromProduction(Request $request): Response
    {
        $userId = $request->getAttribute('user_id');
        if (!$this->userRepo->isSuperadmin($userId)) {
            return Response::error('access_denied', 'Accesso riservato ai superadmin', 403);
        }
        
        // Verifica ambiente
        $appEnv = $_ENV['APP_ENV'] ?? 'production';
        if ($appEnv === 'production') {
            return Response::error('invalid_environment', 'Questa funzione non è disponibile in produzione', 400);
        }
        
        $body = $request->getBody();
        $businessId = $body['business_id'] ?? null;
        $slug = $body['slug'] ?? null;
        
        if (empty($businessId) && empty($slug)) {
            return Response::error('invalid_request', 'Specificare business_id o slug', 400);
        }
        
        // URL API produzione
        $prodApiUrl = $_ENV['PRODUCTION_API_URL'] ?? 'https://api.romeolab.it';
        
        try {
            // 1. Chiama API produzione per esportare
            if ($businessId) {
                $exportUrl = "$prodApiUrl/v1/admin/businesses/$businessId/export";
            } else {
                $exportUrl = "$prodApiUrl/v1/admin/businesses/by-slug/$slug/export";
            }
            
            // Usa lo stesso token dell'utente corrente per autenticarsi su produzione
            $authHeader = $request->getHeaderLine('Authorization');
            
            $ch = curl_init($exportUrl);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => [
                    'Authorization: ' . $authHeader,
                    'Content-Type: application/json',
                ],
                CURLOPT_TIMEOUT => 60,
            ]);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $error = curl_error($ch);
            curl_close($ch);
            
            if ($error) {
                return Response::error('production_unreachable', "Impossibile contattare API produzione: $error", 502);
            }
            
            if ($httpCode !== 200) {
                $errorData = Json::decodeAssoc((string) $response);
                $errorMsg = $errorData['error']['message'] ?? 'Errore sconosciuto';
                return Response::error('production_error', "Errore da produzione: $errorMsg", $httpCode >= 400 ? $httpCode : 500);
            }
            
            $exportResponse = Json::decodeAssoc((string) $response);
            if (!is_array($exportResponse) || !($exportResponse['success'] ?? false) || empty($exportResponse['data'])) {
                return Response::error('invalid_export', 'Risposta export non valida', 500);
            }
            
            $exportData = $exportResponse['data'];
            
            // 2. Importa i dati
            $stats = $this->importBusiness->execute($exportData);
            
            return Response::success([
                'message' => "Business '{$stats['business_name']}' sincronizzato da produzione",
                'stats' => $stats,
            ]);
            
        } catch (\Exception $e) {
            return Response::error('sync_failed', $e->getMessage(), 500);
        }
    }
}
