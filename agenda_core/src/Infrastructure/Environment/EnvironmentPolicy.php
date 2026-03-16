<?php

declare(strict_types=1);

namespace Agenda\Infrastructure\Environment;

final class EnvironmentPolicy
{
    public function __construct(private readonly EnvironmentConfig $config)
    {
    }

    public static function current(): self
    {
        return new self(EnvironmentConfig::current());
    }

    public function isDemoEnvironment(): bool
    {
        return $this->config->isDemo;
    }

    public function canSendRealEmails(): bool
    {
        return $this->config->allowRealEmails;
    }

    public function canSendRealWhatsapp(): bool
    {
        return $this->config->allowRealWhatsapp;
    }

    public function canUseRealPayments(): bool
    {
        return $this->config->allowRealPayments;
    }

    public function canCallExternalWebhooks(): bool
    {
        return $this->config->allowExternalWebhooks;
    }

    public function canExecuteDestructiveBusinessActions(): bool
    {
        return $this->config->allowDestructiveBusinessActions;
    }

    public function canChangeSubscriptionPlan(): bool
    {
        return $this->config->allowPlanChanges;
    }

    public function canDeleteBusiness(): bool
    {
        return $this->canExecuteDestructiveBusinessActions();
    }

    public function canDeleteLocation(): bool
    {
        return $this->canExecuteDestructiveBusinessActions();
    }

    public function canDeleteCriticalData(): bool
    {
        return $this->canExecuteDestructiveBusinessActions();
    }

    public function canRunRealNotifications(): bool
    {
        return $this->canSendRealEmails() || $this->canSendRealWhatsapp();
    }

    public function canRunRealExports(): bool
    {
        return $this->config->allowRealExports;
    }
}
