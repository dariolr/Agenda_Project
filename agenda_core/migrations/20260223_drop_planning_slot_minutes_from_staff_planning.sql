-- Rimuove il campo planning_slot_minutes: lo step planning è fisso a 5 minuti.
ALTER TABLE `staff_planning`
  DROP COLUMN `planning_slot_minutes`;

