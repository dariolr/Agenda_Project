ALTER TABLE `staff_planning`
  ADD COLUMN `planning_slot_minutes` tinyint UNSIGNED NOT NULL DEFAULT 15
  COMMENT 'Passo (in minuti) usato per generare il planning'
  AFTER `type`;
